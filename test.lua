local Obfuscator = require("obfuscator")

local code = [[
local function factorial(n)
    if n <= 1 then
        return 1
    end
    return n * factorial(n - 1)
end

print("Factorial of 5:", factorial(5))
print("Factorial of 10:", factorial(10))
]]

print("=== ORIGINAL CODE ===")
print(code)
print("\n=== OBFUSCATING ===\n")

local obfuscated = Obfuscator.obfuscate(code, {
    renameVariables = true,
    encryptStrings = true,
    layers = 5,
    antiDebug = true,
    integrityCheck = true,
    refCounter = true,
    junkCode = false,
    stateMachine = false
})

print("=== OBFUSCATED CODE ===")
print(obfuscated)
print("\n=== TESTING OBFUSCATED CODE ===\n")

local func, err = loadstring(obfuscated)
if func then
    local success, result = pcall(func)
    if success then
        print("\n✓ Obfuscated code works!")
    else
        print("\n✗ Runtime error:", result)
    end
else
    print("\n✗ Load error:", err)
end
