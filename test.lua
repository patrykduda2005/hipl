local main = require "./main"

local function test_concatPaths()
    local lhs = ""
    local rhs = ""
    local o = ""

    lhs = "./src/index/randomword/"
    rhs = "../../hipls/navincluder.hipl"
    o = PATH.concatPaths(lhs, rhs)
    assert(o == "./src/hipls/navincluder.hipl",
        "Function PATH.concatPaths(lhs, rhs) test failed:"
        .. " lhs: " .. lhs .. " rhs: " .. rhs .. " got: " .. o)

    lhs = "./src/hipl/"
    rhs = "file.html"
    o = PATH.concatPaths(lhs, rhs)
    assert(o == "./src/hipl/file.html",
        "Function PATH.concatPaths(lhs, rhs) test failed:"
        .. " lhs: " .. lhs .. " rhs: " .. rhs .. " got: " .. o)

    lhs = ""
    rhs = "file.html"
    o = PATH.concatPaths(lhs, rhs)
    assert(o == "file.html",
        "Function PATH.concatPaths(lhs, rhs) test failed:"
        .. " lhs: " .. lhs .. " rhs: " .. rhs .. " got: " .. o)

    lhs = "./../"
    rhs = "whatever"
    o = PATH.concatPaths(lhs, rhs)
    assert(o == nil,
        "Function PATH.concatPaths(lhs, rhs) test failed:"
        .. " lhs: " .. lhs .. " rhs: " .. rhs)

end

local function test_convertToRelativePath()
    local absoluteFilePath = ""
    local relativeToFolderPath = ""
    local o = ""
    absoluteFilePath = "./src/hipls/navincluder.hipl"
    relativeToFolderPath = "./src/index/"
    o = PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    assert(o == "../hipls/navincluder.hipl",
        "Function PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath) test failed:"
        .. " absoluteFilePath: " .. absoluteFilePath .. " relativeToFolderPath: " .. relativeToFolderPath .. " got: " .. o)

    absoluteFilePath = "./src/hipls/navincluder.hipl"
    relativeToFolderPath = "./src/index/andrew/different/folder/"
    o = PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    assert(o == "../../../../hipls/navincluder.hipl",
        "Function PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath) test failed:"
        .. " absoluteFilePath: " .. absoluteFilePath .. " relativeToFolderPath: " .. relativeToFolderPath .. " got: " .. o)

    absoluteFilePath = "./src/index/andrew/different/folder/navincluder.hipl"
    relativeToFolderPath = "./src/hipls/"
    o = PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    assert(o == "../index/andrew/different/folder/navincluder.hipl",
        "Function PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath) test failed:"
        .. " absoluteFilePath: " .. absoluteFilePath .. " relativeToFolderPath: " .. relativeToFolderPath .. " got: " .. o)
end

local function test_getFileName()
    local filePath = ""
    local o = ""

    filePath = "./src/somefolder/index.html"
    o = PATH.getFileName(filePath)
    assert(o == "index.html",
        "Function PATH.getFileName(filePath) test failed:"
        .. " filePath: " .. filePath .. " got: " .. o)

    filePath = "./src/somefolder/"
    o = PATH.getFileName(filePath)
    assert(o == nil,
        "Function PATH.getFileName(filePath) test failed:"
        .. " filePath: " .. filePath)
end

local function test_getFolderPath()
    local filePath = ""
    local o = ""

    filePath = "./src/somefolder/index.html"
    o = PATH.getFolderPath(filePath)
    assert(o == "./src/somefolder/",
        "Function PATH.getFolderPath(filePath) test failed:"
        .. " filePath: " .. filePath .. " got: " .. o)
end

local function test_templateCommand_filepath()
end


local function run_tests()
    print("Testing PATH.concatPaths(lhs, rhs)..")
    test_concatPaths()
    print("Testing PATH.getFileName(filePath)..")
    test_getFileName()
    print("Testing PATH.getFolderPath(filePath)..")
    test_getFolderPath()
    print("Testing template command {{!filepath filepath}}..")
    test_templateCommand_filepath()
    print("Testing PATH.convertToRelativePath()..")
    test_convertToRelativePath()

    print("\nTests passed !")
end

run_tests()
