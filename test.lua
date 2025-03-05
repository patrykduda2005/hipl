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


local function run_tests()
    print("Testing FS.concatPaths(lhs, rhs)..")
    test_concatPaths()
    print("Testing FS.getFileName(filePath)..")
    test_getFileName()

    print("\nTests passed !")
end

run_tests()
