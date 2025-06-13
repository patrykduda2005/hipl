local main = require "./main"

---@class test helper functions for testing
local test = {}

---Check if statement is true otherwise print error message
---@param statement boolean
---@param errorMessage string
---@return boolean
function test.check(statement, errorMessage)
    if statement then
        return true
    else
        print("FAILED: ", errorMessage)
        return false
    end
end

---Pretify type
---@param thing any
---@param funcName string?
---@param args table?
---@param output any?
---@param expected any?
---@return string
function test.pretty(thing, funcName, args, output, expected)
    if thing == nil then return "nil" end
    local type = type(thing)
    if type == "string" then
        return thing
    elseif type == "boolean" then
        if thing then return "true"
        else return "false" end
    elseif type == "table" then
        return "{\"" .. table.concat(thing, "\", \"") ..  "\"}"
    elseif type == "function" then
        if funcName == nil or args == nil or output == nil or expected == nil then
            return "nil"
        end
        local funcSign = funcName .. "("
        for k, v in pairs(args) do
            funcSign = funcSign .. test.pretty(v)
            if args[k + 1] ~= nil then
                funcSign = funcSign .. ", "
            end
        end
        funcSign = funcSign .. ")\nreturns: " .. test.pretty(output) .. "; expected: " .. test.pretty(expected)
        return funcSign
    end
    return "unreachable in" .. debug.getinfo(1).name
end


---Check if arrays have the same content
---@param a table
---@param b table
---@return boolean
function table.equals(a, b)
    for k, v in pairs(a) do
        if v ~= b[k] then
            return false
        end
    end

    for k, v in pairs(b) do
        if v ~= a[k] then
            return false
        end
    end
    return true
end

local unit_test = {
    PATH = {},
    test = {},
    FS = {},
}

function unit_test.test.equals()
    print("Testing test.equals(a, b)...")
    local a = {}
    local b = {}
    local o = false

    a = { "test", "table", "of", "strings" }
    b = { "test", "table", "of", "strings" }
    o = table.equals(a, b)
    test.check(
        o == true,
        test.pretty(table.equals, "table.equals", {a, b}, o, true)
    )

    a = { "test", "table", "of", "different" , "strings" }
    b = { "test", "table", "of", "strings" }
    o = table.equals(a, b)
    test.check(
        o == false,
        test.pretty(table.equals, "table.equals", {a, b}, o, false)
    )

    a = { "test", "table", "of", "strings" }
    b = { "test", "table", "of", "strings", "ups" }
    o = table.equals(a, b)
    test.check(
        o == false,
        test.pretty(table.equals, "table.equals", {a, b}, o, false)
    )
end

function unit_test.PATH.concatPaths()
    print("Testing PATH.concatPaths(lhs, rhs)...")
    local lhs = ""
    local rhs = ""
    local o = ""
    local exp = ""

    lhs = "./src/index/randomword/"
    rhs = "../../hipls/navincluder.hipl"
    o = PATH.concatPaths(lhs, rhs)
    exp = "./src/hipls/navincluder.hipl"
    test.check(
        o == exp,
        test.pretty(PATH.concatPaths, "PATH.concatPaths", {lhs, rhs}, o, exp)
    )

    lhs = "./src/hipl/"
    rhs = "file.html"
    o = PATH.concatPaths(lhs, rhs)
    exp = "./src/hipl/file.html"
    test.check(
        o == exp,
        test.pretty(PATH.concatPaths, "PATH.concatPaths", {lhs, rhs}, o, exp)
    )

    lhs = ""
    rhs = "file.html"
    o = PATH.concatPaths(lhs, rhs)
    exp = "file.html"
    test.check(
        o == exp,
        test.pretty(PATH.concatPaths, "PATH.concatPaths", {lhs, rhs}, o, exp)
    )

    lhs = "./../"
    rhs = "whatever"
    o = PATH.concatPaths(lhs, rhs)
    exp = nil
    test.check(
        o == exp,
        test.pretty(PATH.concatPaths, "PATH.concatPaths", {lhs, rhs}, o, exp)
    )

end

function unit_test.PATH.convertToRelativePath()
    print("Testing PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath)...")
    local absoluteFilePath = ""
    local relativeToFolderPath = ""
    local o = ""
    local exp = ""

    absoluteFilePath = "./src/hipls/navincluder.hipl"
    relativeToFolderPath = "./src/index/"
    o = PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    exp = "../hipls/navincluder.hipl"
    test.check(
        o == exp,
        test.pretty(PATH.convertToRelativePath, "PATH.convertToRelativePath", {absoluteFilePath, relativeToFolderPath}, o, exp)
    )

    absoluteFilePath = "./src/hipls/navincluder.hipl"
    relativeToFolderPath = "./src/index/andrew/different/folder/"
    o = PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    exp = "../../../../hipls/navincluder.hipl"
    test.check(
        o == exp,
        test.pretty(PATH.convertToRelativePath, "PATH.convertToRelativePath", {absoluteFilePath, relativeToFolderPath}, o, exp)
    )

    absoluteFilePath = "./src/index/andrew/different/folder/navincluder.hipl"
    relativeToFolderPath = "./src/hipls/"
    o = PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    exp = "../index/andrew/different/folder/navincluder.hipl"
    test.check(
        o == exp,
        test.pretty(PATH.convertToRelativePath, "PATH.convertToRelativePath", {absoluteFilePath, relativeToFolderPath}, o, exp)
    )
end

function unit_test.PATH.getFileName()
    print("Testing PATH.getFileName(filePath)...")
    local filePath = ""
    local o = ""
    local exp = ""

    filePath = "./src/somefolder/index.html"
    o = PATH.getFileName(filePath)
    exp = "index.html"
    test.check(
        o == exp,
        test.pretty(PATH.getFileName, "PATH.getFileName", {filePath}, o, exp)
    )

    filePath = "./src/somefolder/"
    o = PATH.getFileName(filePath)
    exp = nil
    test.check(
        o == exp,
        test.pretty(PATH.getFileName, "PATH.getFileName", {filePath}, o, exp)
    )
end

function unit_test.PATH.getFolderPath()
    print("Testing PATH.getFolderPath(filePath)...")
    local filePath = ""
    local o = ""
    local exp = ""

    filePath = "./src/somefolder/index.html"
    o = PATH.getFolderPath(filePath)
    exp = "./src/somefolder/"
    test.check(
        o == exp,
        test.pretty(PATH.getFolderPath, "PATH.getFolderPath", {filePath}, o, exp)
    )
end

function unit_test.PATH.getPathBuilder()
    print("Testing PATH.getPathBuilder(filePath)...")
    local filePath = ""
    local o = ""
    local exp = {}

    filePath = "./src/somefolder/index.html"
    o = PATH.getPathBuilder(filePath)
    exp = {"./", "src/", "somefolder/", "index.html"}
    test.check(
        table.equals(o, exp),
        test.pretty(PATH.getPathBuilder, "PATH.getPathBuilder", {filePath}, o, exp)
    )
end

function unit_test.FS.ls()
    print("Testing FS.ls(type, path)...")
--FS.ls(type, path)
    local type = FS.LSOPTION.FILES
    local path = ""
    local o = {}
    local exp = {}
    FS.mkdir("./.test_folder/")
    local f = FS.touch("./.test_folder/file.txt")
    io.output(f)
    io.write("fsd")

    type = FS.LSOPTION.FILES
    path = "./.test_folder/"
    o = FS.ls(type, path)
    print(test.pretty(o))
end

function unit_test.testall()
    for _, v in pairs(unit_test.PATH) do
        if type(v) == "function" and v ~= debug.getinfo(1).func then
            v()
        end
    end
    for _, v in pairs(unit_test.test) do
        if type(v) == "function" and v ~= debug.getinfo(1).func then
            v()
        end
    end
    for _, v in pairs(unit_test.FS) do
        FS.detectShell()
        if type(v) == "function" and v ~= debug.getinfo(1).func then
            v()
        end
    end
end

local function run_tests()
    unit_test.testall()
end

run_tests()
