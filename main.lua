CONFIG = {
    src_folder = "./src/",
    dist_folder = "./dist/",
}

local hashCommands = {
    ["include"] = function(filepath) --{{#include filepath}}
        local f = io.open(CONFIG.src_folder .. filepath, "r")
        if f == nil then
            print("FILE NOT FOUND " .. filepath)
            return "FILE NOT FOUND"
        end
        local includedContent = f:read("a")
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
        return "TODO"
    end
}

local function extractCommand(thingy, filename) -- {{#command arg}} {{!command arg}}
    local commandType = thingy:sub(1,1)
    if commandType == "#" then
        local middle = thingy:find(" ")
        local command = thingy:sub(2, middle-1)
        local commandArgs = thingy:sub(middle+1)
        return hashCommands[command](commandArgs)
    elseif commandType == "!" then
        local middle = thingy:find(" ")
        local command = thingy:sub(2, middle-1)
        local commandArgs = thingy:sub(middle+1)
        return templateCommands[command](filename, commandArgs)
    end
end


local function copyFile(filename)
    local srcf = io.open(CONFIG.src_folder .. filename, "r")
    if srcf == nil then return end
    local distf = io.open(CONFIG.dist_folder .. filename, "w")
    if distf == nil then return end
    io.output(distf)

    for line in srcf:lines() do
        local replacementLine = line
        local start, ending = line:find("{{.*}}")
        if start then
            local withoutBrackets = line:sub(start+2, ending-2)
            replacementLine = extractCommand(withoutBrackets, filename)
        end
        io.write(replacementLine .. "\n")
    end
end

local function fileOperations(path)
    local isTemplate = string.match(path, ".*.hipl")
    if isTemplate == nil then
        copyFile(path:sub(CONFIG.src_folder:len() + 1))
    end
end

local function openFolderAndPerformOperations(folderPath)
    print("PATH: " .. folderPath)
    local findFilesWindows = string.format("dir/a:-d /b %s", folderPath)
    local findFilesUnix = string.format("ls -p %s | grep -v /", folderPath)
    local files = io.popen(string.format("%s || %s", findFilesWindows, findFilesUnix))
    if files then
        for filename in files:lines() do
            fileOperations(folderPath .. "/" .. filename)
        end
        files:close()
    end

    local findFoldersWindows = string.format("dir/a:d /b %s", folderPath)
    local findFoldersUnix = string.format("ls -p %s | grep /", folderPath)
    local folders = io.popen(string.format("%s || %s", findFoldersWindows, findFoldersUnix))
    if folders == nil then return end
    for foldername in folders:lines() do
        openFolderAndPerformOperations(folderPath .. "/" .. foldername)
    end
    folders:close()
end

openFolderAndPerformOperations(CONFIG.src_folder)
