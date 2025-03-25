local main = require "./main"

local function check(statement, errorMessage)
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
function Pretty(thing, funcName, args, output, expected)
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
            funcSign = funcSign .. Pretty(v)
            if args[k + 1] ~= nil then
                funcSign = funcSign .. ", "
            end
        end
        funcSign = funcSign .. ")\nreturns: " .. Pretty(output) .. "; expected: " .. Pretty(expected)
        return funcSign
    end
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

local function test_equals()
    local a = {}
    local b = {}
    local o = false

    a = { "test", "table", "of", "strings" }
    b = { "test", "table", "of", "strings" }
    o = table.equals(a, b)
    check(
        o == true,
        Pretty(table.equals, "table.equals", {a, b}, o, true)
    )

    a = { "test", "table", "of", "different" , "strings" }
    b = { "test", "table", "of", "strings" }
    o = table.equals(a, b)
    check(
        o == false,
        Pretty(table.equals, "table.equals", {a, b}, o, false)
    )

    a = { "test", "table", "of", "strings" }
    b = { "test", "table", "of", "strings", "ups" }
    o = table.equals(a, b)
    check(
        o == false,
        Pretty(table.equals, "table.equals", {a, b}, o, false)
    )
end

local function test_concatPaths()
    local lhs = ""
    local rhs = ""
    local o = ""
    local exp = ""

    lhs = "./src/index/randomword/"
    rhs = "../../hipls/navincluder.hipl"
    o = PATH.concatPaths(lhs, rhs)
    exp = "./src/hipls/navincluder.hipl"
    check(
        o == exp,
        Pretty(PATH.concatPaths, "PATH.concatPaths", {lhs, rhs}, o, exp)
    )

    lhs = "./src/hipl/"
    rhs = "file.html"
    o = PATH.concatPaths(lhs, rhs)
    exp = "./src/hipl/file.html"
    check(
        o == exp,
        Pretty(PATH.concatPaths, "PATH.concatPaths", {lhs, rhs}, o, exp)
    )

    lhs = ""
    rhs = "file.html"
    o = PATH.concatPaths(lhs, rhs)
    exp = "file.html"
    check(
        o == exp,
        Pretty(PATH.concatPaths, "PATH.concatPaths", {lhs, rhs}, o, exp)
    )

    lhs = "./../"
    rhs = "whatever"
    o = PATH.concatPaths(lhs, rhs)
    exp = nil
    check(
        o == exp,
        Pretty(PATH.concatPaths, "PATH.concatPaths", {lhs, rhs}, o, exp)
    )

end

local function test_convertToRelativePath()
    local absoluteFilePath = ""
    local relativeToFolderPath = ""
    local o = ""
    local exp = ""

    absoluteFilePath = "./src/hipls/navincluder.hipl"
    relativeToFolderPath = "./src/index/"
    o = PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    exp = "../hipls/navincluder.hipl"
    check(
        o == exp,
        Pretty(PATH.convertToRelativePath, "PATH.convertToRelativePath", {absoluteFilePath, relativeToFolderPath}, o, exp)
    )

    absoluteFilePath = "./src/hipls/navincluder.hipl"
    relativeToFolderPath = "./src/index/andrew/different/folder/"
    o = PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    exp = "../../../../hipls/navincluder.hipl"
    check(
        o == exp,
        Pretty(PATH.convertToRelativePath, "PATH.convertToRelativePath", {absoluteFilePath, relativeToFolderPath}, o, exp)
    )

    absoluteFilePath = "./src/index/andrew/different/folder/navincluder.hipl"
    relativeToFolderPath = "./src/hipls/"
    o = PATH.convertToRelativePath(absoluteFilePath, relativeToFolderPath)
    exp = "../index/andrew/different/folder/navincluder.hipl"
    check(
        o == exp,
        Pretty(PATH.convertToRelativePath, "PATH.convertToRelativePath", {absoluteFilePath, relativeToFolderPath}, o, exp)
    )
end

local function test_getFileName()
    local filePath = ""
    local o = ""
    local exp = ""

    filePath = "./src/somefolder/index.html"
    o = PATH.getFileName(filePath)
    exp = "index.html"
    check(
        o == exp,
        Pretty(PATH.getFileName, "PATH.getFileName", {filePath}, o, exp)
    )

    filePath = "./src/somefolder/"
    o = PATH.getFileName(filePath)
    exp = nil
    check(
        o == exp,
        Pretty(PATH.getFileName, "PATH.getFileName", {filePath}, o, exp)
    )
end

local function test_getFolderPath()
    local filePath = ""
    local o = ""
    local exp = ""

    filePath = "./src/somefolder/index.html"
    o = PATH.getFolderPath(filePath)
    exp = "./src/somefolder/"
    check(
        o == exp,
        Pretty(PATH.getFolderPath, "PATH.getFolderPath", {filePath}, o, exp)
    )
end

local function test_getPathBuilder()
    local filePath = ""
    local o = ""
    local exp = {}

    filePath = "./src/somefolder/index.html"
    o = PATH.getPathBuilder(filePath)
    exp = {"./", "src/", "somefolder/", "index.html"}
    check(
        table.equals(o, exp),
        Pretty(PATH.getPathBuilder, "PATH.getPathBuilder", {filePath}, o, exp)
    )
end

local function test_templateCommand_filepath()
end


local function run_tests()
    local result = true
    local tests = {
        test_equals, test_concatPaths, test_getFileName,
        test_getFolderPath, test_getPathBuilder, test_templateCommand_filepath,
        test_convertToRelativePath
    }

    for _, v in pairs(tests) do
        if v() == false then result = false end
    end

    --if result then
    --    print("\nTests passed !")
    --else
    --    print("\nTests failed !")
    --end
end

run_tests()
