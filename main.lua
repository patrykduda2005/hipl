CONFIG = {
    src_folder = "./src",
    dist_folder = "./dist",
}

--FS
FS = {
    LSOPTION = {
        FOLDERS = {},
        FILES = {},
    },
}

function FS.getFileName(filePath)
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

function FS.getFolderPath(filePath)
    return filePath:gsub("/[^/]*$", "") .. '/'
end
function FS.getPathBuilder(filepath)
    if filepath == nil then return nil end
    local pathBuilder = {}
    for folderName in string.gmatch(FS.getFolderPath(filepath), "[^/]*/") do
        table.insert(pathBuilder, folderName)
    end
    local filename = FS.getFileName(filepath)
    if filename ~= nil then
        table.insert(pathBuilder, filename)
    end
    return pathBuilder
end

function FS.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    if absoluteFilePath == nil or relativeToFolderPath == nil then return nil end
    local pathBuilder = {}
    local afpPathBuilder = FS.getPathBuilder(FS.getFolderPath(absoluteFilePath))
    local rtfpPathBuilder = FS.getPathBuilder(FS.getFolderPath(relativeToFolderPath))
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

    table.insert(pathBuilder, FS.getFileName(absoluteFilePath))

    local output = ""
    for _, folderName in pairs(pathBuilder) do
        output = output .. folderName
    end

    return output
end

function FS.concatPaths(lhs, rhs)
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
    local rhsFileName = FS.getFileName(rhs)
    if rhsFileName == nil then return nil end
    table.insert(pathBuilder, FS.getFileName(rhs))
    local output = ""
    for _, folderName in pairs(pathBuilder) do
        output = output .. folderName
    end
    return output
end

function FS.mkdir(folderPath)
    local mkdirUnix = string.format("mkdir -p %s", folderPath)
    local folderPathWindows = folderPath:gsub("/", "\\")
    local mkdirWindows = string.format("mkdir%s 2>/dev/null", folderPathWindows)
    print("MKDIR COMMAND: ", mkdirUnix)
    local command = io.popen(string.format("%s || %s", mkdirWindows, mkdirUnix))
    return command
end

function FS.ls(type, path)
    local output = {}
    local command_output = nil

    if type == FS.LSOPTION.FILES then
        local findFilesWindows = string.format("dir/a:-d /b %s 2>/dev/null", path)
        local findFilesUnix = string.format("ls -p %s | grep -v /", path)
        command_output = io.popen(string.format("%s || %s", findFilesWindows, findFilesUnix))
    elseif type == FS.LSOPTION.FOLDERS then
        local findFoldersWindows = string.format("dir/a:d /b %s 2>/dev/null", path)
        local findFoldersUnix = string.format("ls -p %s | grep /", path)
        command_output = io.popen(string.format("%s || %s", findFoldersWindows, findFoldersUnix))
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

--FS end

local hashCommands = {
    ["include"] = function(filePath, currentFilename) --{{#include filepath}}
        print("INLUDE; ", filePath .. "dupa; " .. FS.getFolderPath(currentFilename))
        local templatefilePath = FS.concatPaths(FS.getFolderPath(currentFilename), filePath)
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
                replacementLine = extractCommand(withoutBrackets, templatefilePath, currentFilename)
            end
            includedContent = includedContent .. replacementLine .. "\n"
        end
        f:close()
        return includedContent
    end,
    ["sharedFile"] = function(filePath, currentFilename) --{{#sharedFile filepath}}
        --don't copy over some files to save space
        return "TODO"
    end
}

local templateCommands = {
    ["filepath"] = function(templateFilePath, filePathRelativeToTemplate, filePathOfTemplateHost) --{{!filepath templatePOVPath}}
        local globalPath = FS.concatPaths(FS.getFolderPath(templateFilePath), filePathRelativeToTemplate)
        local output = FS.convertToRelativePath(globalPath, FS.getFolderPath(filePathOfTemplateHost))
        return output
    end
}

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


local function compileFile(filePath)
    print("    File: ", filePath)
    local srcf = io.open(filePath, "r")
    if srcf == nil then return end
    local distfPath = filePath:gsub(CONFIG.src_folder, CONFIG.dist_folder, 1)
    --print("                      DIST FILE PATH: ", distfPath)
    local distf = io.open(distfPath, "w")
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

local function fileOperations(filePath)
    local isTemplate = string.match(filePath, ".*.hipl")
    if isTemplate == nil then
        compileFile(filePath)
    end
end

local function openFolderAndPerformOperations(folderPath)
    print("PATH: " .. folderPath)
    local files = FS.ls(FS.LSOPTION.FILES, folderPath)
    if files then
        for _,filename in pairs(files) do
            fileOperations(FS.concatPaths(folderPath, filename))
        end
    end

    local folders = FS.ls(FS.LSOPTION.FOLDERS, folderPath)
    if folders == nil then return end
    for _,foldername in pairs(folders) do
        FS.mkdir(string.gsub(FS.concatPaths(folderPath, foldername), CONFIG.src_folder, CONFIG.dist_folder, 1))
        openFolderAndPerformOperations(FS.concatPaths(folderPath, foldername))
    end
end


openFolderAndPerformOperations(CONFIG.src_folder)
