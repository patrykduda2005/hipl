local main = require "./main"

local function test_concatPaths()
    local lhs = ""
    local rhs = ""
    local o = ""

    lhs = "./src/index/randomword/"
    rhs = "../../hipls/navincluder.hipl"
    o = FS.concatPaths(lhs, rhs)
    assert(o == "./src/hipls/navincluder.hipl",
        "Function FS.concatPaths(lhs, rhs) test failed:"
        .. " lhs: " .. lhs .. " rhs: " .. rhs .. " got: " .. o)

    lhs = "./src/hipl/"
    rhs = "file.html"
    o = FS.concatPaths(lhs, rhs)
    assert(o == "./src/hipl/file.html",
        "Function FS.concatPaths(lhs, rhs) test failed:"
        .. " lhs: " .. lhs .. " rhs: " .. rhs .. " got: " .. o)

    lhs = ""
    rhs = "file.html"
    o = FS.concatPaths(lhs, rhs)
    assert(o == "file.html",
        "Function FS.concatPaths(lhs, rhs) test failed:"
        .. " lhs: " .. lhs .. " rhs: " .. rhs .. " got: " .. o)

    lhs = "./../"
    rhs = "whatever"
    o = FS.concatPaths(lhs, rhs)
    assert(o == nil,
        "Function FS.concatPaths(lhs, rhs) test failed:"
        .. " lhs: " .. lhs .. " rhs: " .. rhs)

end

local function test_convertToRelativePath()
    local absoluteFilePath = ""
    local relativeToFolderPath = ""
    local o = ""
    absoluteFilePath = "./src/hipls/navincluder.hipl"
    relativeToFolderPath = "./src/index/"
    o = FS.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    assert(o == "../hipls/navincluder.hipl",
        "Function FS.convertToRelativePath(absoluteFilePath, relativeToFolderPath) test failed:"
        .. " absoluteFilePath: " .. absoluteFilePath .. " relativeToFolderPath: " .. relativeToFolderPath .. " got: " .. o)

    absoluteFilePath = "./src/hipls/navincluder.hipl"
    relativeToFolderPath = "./src/index/andrew/different/folder/"
    o = FS.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    assert(o == "../../../../hipls/navincluder.hipl",
        "Function FS.convertToRelativePath(absoluteFilePath, relativeToFolderPath) test failed:"
        .. " absoluteFilePath: " .. absoluteFilePath .. " relativeToFolderPath: " .. relativeToFolderPath .. " got: " .. o)

    absoluteFilePath = "./src/index/andrew/different/folder/navincluder.hipl"
    relativeToFolderPath = "./src/hipls/"
    o = FS.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    assert(o == "../index/andrew/different/folder/navincluder.hipl",
        "Function FS.convertToRelativePath(absoluteFilePath, relativeToFolderPath) test failed:"
        .. " absoluteFilePath: " .. absoluteFilePath .. " relativeToFolderPath: " .. relativeToFolderPath .. " got: " .. o)
end

local function test_getFileName()
    local filePath = ""
    local o = ""

    filePath = "./src/somefolder/index.html"
    o = FS.getFileName(filePath)
    assert(o == "index.html",
        "Function FS.getFileName(filePath) test failed:"
        .. " filePath: " .. filePath .. " got: " .. o)

    filePath = "./src/somefolder/"
    o = FS.getFileName(filePath)
    assert(o == nil,
        "Function FS.getFileName(filePath) test failed:"
        .. " filePath: " .. filePath)
end

local function test_getFolderPath()
    local filePath = ""
    local o = ""

    filePath = "./src/somefolder/index.html"
    o = FS.getFolderPath(filePath)
    assert(o == "./src/somefolder/",
        "Function FS.getFolderPath(filePath) test failed:"
        .. " filePath: " .. filePath .. " got: " .. o)
end

local function test_templateCommand_filepath()
end


local function run_tests()
    print("Testing FS.concatPaths(lhs, rhs)..")
    test_concatPaths()
    print("Testing FS.getFileName(filePath)..")
    test_getFileName()
    print("Testing FS.getFolderPath(filePath)..")
    test_getFolderPath()
    print("Testing template command {{!filepath filepath}}..")
    test_templateCommand_filepath()
    print("Testing FS.convertToRelativePath()..")
    test_convertToRelativePath()

    print("\nTests passed !")
end

run_tests()
