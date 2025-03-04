local main = require "./main"

function test_concatPaths()
    local lhs = "./src/index/randomword/"
    local rhs = "../../hipls/navincluder.hipl"
    local o = FS.concatPaths(lhs, rhs) -- ./src/hipls/navincluder.hipl
    assert(o == "./src/hipls/navincluder.hipl",
        "Function FS.concatPaths(lhs, rhs) test failed:"
        .. " lhs: " .. lhs .. " rhs: " .. rhs)
end


function run_tests()
    test_concatPaths()
end

run_tests()
