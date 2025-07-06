CONFIG = {
    src_folder = "./src",
    dist_folder = "./dist",
    dry_run = false,
    shell = nil,
}

---@alias pathbuilder table path separated into array by folders
---@alias absolutepath string forward slashed path relative to lua script; expected to look like ./path/to/file.html or ./path/to/folder/

---@class fs
FS = {
    ---@enum lsoption
    LSOPTION = {
        FOLDERS = 0,
        FILES = 1,
    },
    SHELL = nil,
    PSPIPE = nil,
}

local function unreachable(msg)
    print("Reached unreachable in code \"" .. msg .. "\"")
    os.exit()
end

---Determines what shell script is running on
function FS.detectShell()
    local checkIfPowershell = os.getenv("PSModulePath")
    local checkIfPosix = os.getenv("SHELL")
    local detectedShell = nil
    if checkIfPowershell ~= nil then
        detectedShell = "PowerShell"
    elseif checkIfPosix ~= nil then
        detectedShell = "POSIX"
    end

    if CONFIG.shell == "PowerShell" or CONFIG.shell == "POSIX" then
        if CONFIG.shell == detectedShell then
            print("Found " .. CONFIG.shell .. " in config. Setting it...")
            FS.SHELL = CONFIG.shell
        else 
            print("[WARNING] Detected " .. detectedShell .. ", but config is set to " .. CONFIG.shell .. "... Using " .. CONFIG.shell)
            FS.SHELL = CONFIG.shell
        end
        if detectedShell == "PowerShell" then 
            FS.PSPIPE = io.popen("powershell -command -", "w")
        end
        return
    end

    if CONFIG.shell ~= nil then
        print("Wrong shell option (" .. CONFIG.shell .. ") in config. Expected PowerShell or POSIX")
    end

    print("Found " .. detectedShell .. ". Is it correct (y/n)?")
    res = io.read()
    if res == "y" then
        print("Setting " .. detectedShell .. " then...")
        FS.SHELL = detectedShell
        if detectedShell == "PowerShell" then 
            FS.PSPIPE = io.popen("powershell -command -", "w")
        end
        return
    end

    print("Is it 1-PowerShell or 2-POSIX (1/2)?")
    res = io.read()
    if res == "1" then
        FS.SHELL = "PowerShell"
        FS.PSPIPE = io.popen("powershell -command -", "w")
        print("Setting " .. FS.SHELL .. " then...")
    elseif res == "2" then
        FS.SHELL = "POSIX"
        print("Setting " .. FS.SHELL .. " then...")
    else
        print("Invalid input. Exiting...")
        os.exit()
    end

    if FS.SHELL == nil then
        print("Detection failed. Advise the script's author")
        os.exit()
    end
end

---Creates folder with a shell command that should work on Windows and POSIX systems
---@param folderPath absolutepath
function FS.mkdir(folderPath)
    local mkdirUnix = string.format("mkdir -p %s", folderPath)
    local mkdirPowerShell = string.format("New-Item -Name '%s' -ItemType 'Directory'", folderPath)
    print("Creating folder: ", folderPath)
    if CONFIG.dry_run == true then
        --TODO: check if command would fail
        return
    end

    if FS.SHELL == "POSIX" then
        local command = os.execute(mkdirUnix)
    elseif FS.SHELL == "PowerShell" then
        FS.PSPIPE:write(mkdirPowerShell)
        --local command = os.execute(mkdirPowerShell)
    else
        unreachable("Non-exhaustive mkdir shell switch")
    end

    if command == false then
        print("mkdir failed, please check shell configuration. Exiting..")
    end
end

---Lists files or folders in path in a way that should work on Windows and POSIX systems
---@param type lsoption list files or list folders
---@param path absolutepath
---@return table|nil table of found elements
function FS.ls(type, path)
    local output = {}
    local command_output = nil
    local findFilesPowerShell = ""
    local findFilesUnix = ""

    if type == FS.LSOPTION.FILES then
        findFilesPowerShell = string.format("powershell -Command - Get-ChildItem -Name -Attributes !Directory %s", path)
        findFilesUnix = string.format("ls -p %s | grep -v /", path)
    elseif type == FS.LSOPTION.FOLDERS then
        findFilesPowerShell = string.format("powershell -Command - Get-ChildItem -Name -Attributes Directory %s", path)
        findFilesUnix = string.format("ls -p %s | grep /", path)
    end

    if FS.SHELL == "POSIX" then
        command_output = io.popen(findFilesUnix)
    elseif FS.SHELL == "PowerShell" then
        command_output = io.popen(findFilesPowerShell)
    else
        unreachable("Non-exhaustive ls shell switch")
    end

    if command_output == nil then return nil end
    for folderOrFilename in command_output:lines() do
        if type == FS.LSOPTION.FOLDERS and folderOrFilename:sub(-1) ~= '/' then --unix has slash at the end, but windows does not 
            folderOrFilename = folderOrFilename .. "/"
        end
        table.insert(output, folderOrFilename)
    end
    command_output:close()
    return output
end

---Creates file
---@param filePath absolutepath
function FS.touch(filePath)
    local f = io.open(filePath, "r")
    if f ~= nil then
        print("Modifying file: " .. filePath)
    else
        print("Creating file: " .. filePath)
    end
    if CONFIG.dry_run == false then
        f = io.open(filePath, "w")
    end
end
--fs end

---@class path
PATH = {}

---Get name of file from path
---@param filePath string
---@return string|nil
function PATH.getFileName(filePath)
    local fileNameOffset = filePath:find("/[^/]*$")
    if fileNameOffset ~= nil then
        fileNameOffset = fileNameOffset + 1
    else
        fileNameOffset = 0
    end
    local output = filePath:sub(fileNameOffset)
    if output == "" then return nil
    else return output
    end
end

---Get folder path from path
---@param filePath string
---@return string
function PATH.getFolderPath(filePath)
    return filePath:gsub("/[^/]*$", "") .. '/'
end

---Create path builder
---@param filepath string
---@return pathbuilder|nil
function PATH.getPathBuilder(filepath)
    if filepath == nil then return nil end
    local pathBuilder = {}
    for folderName in string.gmatch(PATH.getFolderPath(filepath), "[^/]*/") do
        table.insert(pathBuilder, folderName)
    end
    local filename = PATH.getFileName(filepath)
    if filename ~= nil then
        table.insert(pathBuilder, filename)
    end
    return pathBuilder
end

---Convert relative path to lua script to relative path of relativeToFolderPath
---@param absoluteFilePath absolutepath
---@param relativeToFolderPath absolutepath
---@return string|nil
function PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    if absoluteFilePath == nil or relativeToFolderPath == nil then return nil end
    local pathBuilder = {}
    local afpPathBuilder = PATH.getPathBuilder(PATH.getFolderPath(absoluteFilePath))
    local rtfpPathBuilder = PATH.getPathBuilder(PATH.getFolderPath(relativeToFolderPath))
    if afpPathBuilder == nil or rtfpPathBuilder == nil then return nil end
    local offsetToAppendTheRest = nil
    for k, v in pairs(rtfpPathBuilder) do
        if v == afpPathBuilder[k] then
            offsetToAppendTheRest = k + 1
        else
            table.insert(pathBuilder, "../")
        end
    end
    for i = offsetToAppendTheRest, #afpPathBuilder, 1 do
        table.insert(pathBuilder, afpPathBuilder[i])
    end

    table.insert(pathBuilder, PATH.getFileName(absoluteFilePath))

    local output = ""
    for _, folderName in pairs(pathBuilder) do
        output = output .. folderName
    end

    return output
end

---Concatenate paths
---@param lhs string
---@param rhs string
---@return string|nil
function PATH.concatPaths(lhs, rhs)
    if lhs == '' then return rhs end
    if lhs:find("%.%.") ~= nil then return nil end
    --simple concat
    if rhs:find("%.%.") == nil then
        if lhs:sub(-1) == '/' then
            return lhs .. rhs
        end
        return lhs .. '/' .. rhs
    end

    --complex concat
    local pathBuilder = {}
    for folderName in lhs:gmatch("[^/]*/") do
        table.insert(pathBuilder, folderName)
    end
    for folderName in rhs:gmatch("[^/]*/") do
        if folderName == "../" then
            table.remove(pathBuilder)
        else
            table.insert(pathBuilder, folderName)
        end
    end
    local rhsFileName = PATH.getFileName(rhs)
    if rhsFileName == nil then return nil end
    table.insert(pathBuilder, PATH.getFileName(rhs))
    local output = ""
    for _, folderName in pairs(pathBuilder) do
        output = output .. folderName
    end
    return output
end
--path end

local hashCommands = {
    ---{{#include filepath}} html function that copies over template or other html file
    ---@param filePath absolutepath
    ---@param currentFilename absolutepath
    ---@return string
    ["include"] = function(filePath, currentFilename)
        print("INLUDE; ", filePath .. "dupa; " .. PATH.getFolderPath(currentFilename))
        local templatefilePath = PATH.concatPaths(PATH.getFolderPath(currentFilename), filePath)
        local f = io.open(templatefilePath, "r")
        if f == nil then
            print("FILE NOT FOUND " .. templatefilePath)
            return "FILE NOT FOUND"
        end
        local includedContent = ""
        for line in f:lines() do
            local replacementLine = line
            local start, ending = line:find("{{.*}}")
            if start then
                local withoutBrackets = line:sub(start+2, ending-2)
                replacementLine = string.gsub(line, "{{.*}}", extractCommand(withoutBrackets, templatefilePath, currentFilename))
            end
            --if start then
            --    local withoutBrackets = line:sub(start+2, ending-2)
            --    replacementLine = extractCommand(withoutBrackets, templatefilePath, currentFilename)
            --end
            includedContent = includedContent .. replacementLine .. "\n"
        end
        f:close()
        return includedContent
    end,
    ---{{#sharedFile filepath}} html function that provides a pointer to not copied resource
    ---@param filePath absolutepath
    ---@param currentFilename absolutepath
    ---@return string
    ["sharedFile"] = function(filePath, currentFilename) --{{#sharedFile filepath}}
        --don't copy over some files to save space
        return "TODO"
    end
}

local templateCommands = {
    ---{{!filepath templatePOVPath}} template function that ensures path is still valid after copying
    ---@param templateFilePath absolutepath
    ---@param filePathRelativeToTemplate string
    ---@param filePathOfTemplateHost absolutepath
    ---@return string
    ["filepath"] = function(templateFilePath, filePathRelativeToTemplate, filePathOfTemplateHost)
        local globalPath = PATH.concatPaths(PATH.getFolderPath(templateFilePath), filePathRelativeToTemplate)
        if globalPath == nil then return "" end
        local output = PATH.convertToRelativePath(globalPath, PATH.getFolderPath(filePathOfTemplateHost))
        if output == nil then return "" end
        return output
    end
}

---Documentation TODO
---@param thingy string entire {{command}} thingy without brackets
---@param filename absolutepath filepath on which it is run
---@param hostFilePath absolutepath filepath in which it is present
---@return string
function extractCommand(thingy, filename, hostFilePath) -- {{#command arg}} {{!command arg}}
    local commandType = thingy:sub(1,1)
    if commandType == "#" then
        local middle = thingy:find(" ")
        local command = thingy:sub(2, middle-1)
        local commandArgs = thingy:sub(middle+1)
        return hashCommands[command](commandArgs, filename)
    elseif commandType == "!" then
        local middle = thingy:find(" ")
        local command = thingy:sub(2, middle-1)
        local commandArgs = thingy:sub(middle+1)
        return templateCommands[command](filename, commandArgs, hostFilePath)
    end
end

---Copy over file and execute commands inside of it
---@param filePath absolutepath
local function compileFile(filePath)
    print("    File: ", filePath)
    local srcf = io.open(filePath, "r")
    if srcf == nil then return end
    local distfPath = filePath:gsub(CONFIG.src_folder, CONFIG.dist_folder, 1)
    --print("                      DIST FILE PATH: ", distfPath)
    local distf = FS.touch(distfPath)
    if distf == nil then return end
    io.output(distf)

    for line in srcf:lines() do
        local replacementLine = line
        local start, ending = line:find("{{.*}}")
        if start then
            local withoutBrackets = line:sub(start+2, ending-2)
            replacementLine = extractCommand(withoutBrackets, filePath, filePath)
        end
        io.write(replacementLine .. "\n")
    end
end

---Filter template files
---@param filePath absolutepath
local function fileOperations(filePath)
    local isTemplate = string.match(filePath, ".*.hipl")
    if isTemplate == nil then
        compileFile(filePath)
    end
end

---Recursively copy over files
---@param folderPath absolutepath
local function openFolderAndPerformOperations(folderPath)
    print("PATH: " .. folderPath)
    local files = FS.ls(FS.LSOPTION.FILES, folderPath)
    if files then
        for _,filename in pairs(files) do
            fileOperations(PATH.concatPaths(folderPath, filename))
        end
    end

    local folders = FS.ls(FS.LSOPTION.FOLDERS, folderPath)
    if folders == nil then return end
    for _,foldername in pairs(folders) do
        print(foldername)
        FS.mkdir(string.gsub(PATH.concatPaths(folderPath, foldername), CONFIG.src_folder, CONFIG.dist_folder, 1))
        openFolderAndPerformOperations(PATH.concatPaths(folderPath, foldername))
    end
end


if test == nil then
    FS.detectShell()
    openFolderAndPerformOperations(CONFIG.src_folder)
end
