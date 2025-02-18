CONFIG = {
    src_folder = "./src",
    dist_folder = "./dist",
}

LSOPTION = {
    FOLDERS = {},
    FILES = {},
}

local function mkdir(folderPath)
    local mkdirUnix = string.format("mkdir -p %s", folderPath)
    local folderPathWindows = folderPath:gsub("/", "\\")
    local mkdirWindows = string.format("mkdir%s 2>/dev/null", folderPathWindows)
    print("MKDIR COMMAND: ", mkdirUnix)
    local command = io.popen(string.format("%s || %s", mkdirWindows, mkdirUnix))
end

local function ls(type, path)
    if type == LSOPTION.FILES then
        local findFilesWindows = string.format("dir/a:-d /b %s 2>/dev/null", path)
        local findFilesUnix = string.format("ls -p %s | grep -v /", path)
        local files = io.popen(string.format("%s || %s", findFilesWindows, findFilesUnix))
        return files
    elseif type == LSOPTION.FOLDERS then
        local findFoldersWindows = string.format("dir/a:d /b %s 2>/dev/null", path)
        local findFoldersUnix = string.format("ls -p %s | grep /", path)
        local folders = io.popen(string.format("%s || %s", findFoldersWindows, findFoldersUnix))
        return folders --unix has slash at the end, but windows does not (shouldn't be a problem, but is not pretty)
    end
end

local function pathAdd(currentFolderPath, relativePath)
    return currentFolderPath .. relativePath
end


local hashCommands = {
    ["include"] = function(filepath, currentFilename) --{{#include filepath}}
        print("INLUDE; ", filepath .. "dupa; " .. currentFilename)
        local templateFilepath = pathAdd(currentFilename:gsub("/[^/]*$", ""), filepath)
        local f = io.open(templateFilepath, "r")
        if f == nil then
            print("FILE NOT FOUND " .. templateFilepath)
            return "FILE NOT FOUND"
        end
        local includedContent = ""
        for line in f:lines() do
            local replacementLine = line
            local start, ending = line:find("{{.*}}")
            if start then
                local withoutBrackets = line:sub(start+2, ending-2)
                replacementLine = extractCommand(withoutBrackets, templateFilepath)
            end
            includedContent = includedContent .. replacementLine .. "\n"
        end
        f:close()
        return includedContent
    end,
    ["sharedFile"] = function(filepath) --{{#sharedFile filepath}}
        --don't copy over some files to save space
        return "TODO"
    end
}

local templateCommands = {
    ["filepath"] = function(hostFilePath, templatePOVPath) --{{!filepath templatePOVPath}}
        print("curent file: " .. hostFilePath .. "template file; " .. templatePOVPath)
        return "TODO"
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


local function compileFile(filepath)
    print("    File: ", filepath)
    local srcf = io.open(filepath, "r")
    if srcf == nil then return end
    local distfPath = filepath:gsub(CONFIG.src_folder, CONFIG.dist_folder, 1)
    --print("                      DIST FILE PATH: ", distfPath)
    local distf = io.open(distfPath, "w")
    if distf == nil then return end
    io.output(distf)

    for line in srcf:lines() do
        local replacementLine = line
        local start, ending = line:find("{{.*}}")
        if start then
            local withoutBrackets = line:sub(start+2, ending-2)
            replacementLine = extractCommand(withoutBrackets, filepath)
        end
        io.write(replacementLine .. "\n")
    end
end

local function fileOperations(filepath)
    local isTemplate = string.match(filepath, ".*.hipl")
    if isTemplate == nil then
        compileFile(filepath)
    end
end

local function openFolderAndPerformOperations(folderPath)
    print("PATH: " .. folderPath)
    local files = ls(LSOPTION.FILES, folderPath)
    if files then
        for filename in files:lines() do
            fileOperations(folderPath .. "/" .. filename)
        end
        files:close()
    end

    local folders = ls(LSOPTION.FOLDERS, folderPath)
    if folders == nil then return end
    for foldername in folders:lines() do
        mkdir(string.gsub(folderPath .. "/" .. foldername, CONFIG.src_folder, CONFIG.dist_folder, 1))
        openFolderAndPerformOperations(folderPath .. "/" .. foldername)
    end
    folders:close()
end


openFolderAndPerformOperations(CONFIG.src_folder)
