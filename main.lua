CONFIG = {
    src_folder = "./src",
    dist_folder = "./dist",
}

FS = {
    LSOPTION = {
        FOLDERS = {},
        FILES = {},
    },
    getFileName = function(filePath)
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
    end,
    getFolderPath = function(filePath)
        return filePath:gsub("/[^/]*$", "")
    end,
    concatPaths = function(lhs, rhs)
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
    end,
    mkdir = function(folderPath)
        local mkdirUnix = string.format("mkdir -p %s", folderPath)
        local folderPathWindows = folderPath:gsub("/", "\\")
        local mkdirWindows = string.format("mkdir%s 2>/dev/null", folderPathWindows)
        print("MKDIR COMMAND: ", mkdirUnix)
        local command = io.popen(string.format("%s || %s", mkdirWindows, mkdirUnix))
        return command
    end,
    ls = function(type, path)
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
    end,
}



local hashCommands = {
    ["include"] = function(filePath, currentFilename) --{{#include filepath}}
        print("INLUDE; ", filePath .. "dupa; " .. currentFilename)
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
                replacementLine = extractCommand(withoutBrackets, templatefilePath)
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
    ["filepath"] = function(hostFilePath, templatePOVPath) --{{!filepath templatePOVPath}}
        print("curent file: " .. hostFilePath .. "template file; " .. templatePOVPath)
        return FS.concatPaths(FS.getFolderPath(hostFilePath), templatePOVPath)
        --TODO
    end
}

function extractCommand(thingy, filename) -- {{#command arg}} {{!command arg}}
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
        return templateCommands[command](filename, commandArgs)
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
            replacementLine = extractCommand(withoutBrackets, filePath)
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


--openFolderAndPerformOperations(CONFIG.src_folder)
