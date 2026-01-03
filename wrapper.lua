local Encoder = require("encoder")

local Wrapper = {}

-- Generate obfuscated function wrapper
function Wrapper.generateFunctionWrapper()
    return [[
local function wrap(f, upvals)
    return function(...)
        local env = {}
        for k, v in pairs(_ENV) do
            env[k] = v
        end
        for k, v in pairs(upvals) do
            env[k] = v
        end
        setfenv(f, env)
        return f(...)
    end
end
]]
end

-- Generate reference counter
function Wrapper.generateRefCounter()
    return [[
local refs = {}
local refCount = 0

local function allocRef()
    refCount = refCount + 1
    refs[refCount] = 1
    return refCount
end

local function incRef(id)
    if refs[id] then
        refs[id] = refs[id] + 1
    end
end

local function decRef(id)
    if refs[id] then
        refs[id] = refs[id] - 1
        if refs[id] <= 0 then
            refs[id] = nil
        end
    end
end
]]
end

-- Generate VM state machine
function Wrapper.generateVMStateMachine()
    return [[
local function createVM(bytecode, constants)
    local stack = {}
    local pc = 1
    local registers = {}
    
    local function execute()
        while pc <= #bytecode do
            local instr = bytecode[pc]
            local op = bit32.rshift(instr, 24)
            local a = bit32.band(bit32.rshift(instr, 16), 0xFF)
            local b = bit32.band(bit32.rshift(instr, 8), 0xFF)
            local c = bit32.band(instr, 0xFF)
            
            if op == 1 then -- LOADK
                registers[a] = constants[b]
            elseif op == 2 then -- MOVE
                registers[a] = registers[b]
            elseif op == 3 then -- CALL
                local func = registers[a]
                local args = {}
                for i = 1, b do
                    table.insert(args, registers[a + i])
                end
                local results = {func(unpack(args))}
                for i = 1, c do
                    registers[a + i - 1] = results[i]
                end
            elseif op == 4 then -- RETURN
                local results = {}
                for i = 1, b do
                    table.insert(results, registers[a + i - 1])
                end
                return unpack(results)
            end
            
            pc = pc + 1
        end
    end
    
    return {execute = execute}
end
]]
end

-- Generate anti-debug checks
function Wrapper.generateAntiDebug()
    return [[
local function checkDebug()
    -- Timing check
    local start = os.clock()
    for i = 1, 10000 do end
    if os.clock() - start > 0.05 then
        error("\68\101\98\117\103\103\101\114\32\100\101\116\101\99\116\101\100")
    end
    
    -- Environment check
    if debug or jit then
        error("\68\101\98\117\103\32\108\105\098\32\100\101\116\101\99\116\101\100")
    end
    
    -- Hook check
    local env = getfenv and getfenv() or _ENV
    for k, v in pairs(env) do
        if type(v) == "function" then
            local info = debug and debug.getinfo(v)
            if info and info.what == "C" and info.name ~= k then
                error("\72\111\111\107\32\100\101\116\101\99\116\101\100")
            end
        end
    end
end
]]
end

-- Generate integrity check
function Wrapper.generateIntegrityCheck(checksum)
    return string.format([[
local function verifyIntegrity(code)
    local sum = 0
    for i = 1, #code do
        sum = bit32.bxor(sum, string.byte(code, i))
        sum = bit32.lrotate(sum, 1)
    end
    if sum ~= %d then
        error("\84\097\109\112\101\114\101\100")
    end
end
]], checksum)
end

-- Calculate checksum
function Wrapper.calculateChecksum(code)
    local sum = 0
    for i = 1, #code do
        sum = bit32.bxor(sum, string.byte(code, i))
        sum = bit32.lrotate(sum, 1)
    end
    return sum
end

-- Generate full wrapper
function Wrapper.wrapCode(code, encoded, decoder, options)
    options = options or {}
    
    local checksum = Wrapper.calculateChecksum(code)
    
    local wrapper = "(function(...)\n"
    
    -- Add anti-debug
    if options.antiDebug then
        wrapper = wrapper .. Wrapper.generateAntiDebug() .. "\ncheckDebug()\n"
    end
    
    -- Add integrity check
    if options.integrityCheck then
        wrapper = wrapper .. Wrapper.generateIntegrityCheck(checksum) .. "\n"
    end
    
    -- Add ref counter
    if options.refCounter then
        wrapper = wrapper .. Wrapper.generateRefCounter() .. "\n"
    end
    
    -- Add function wrapper
    if options.functionWrapper then
        wrapper = wrapper .. Wrapper.generateFunctionWrapper() .. "\n"
    end
    
    -- Add VM
    if options.vm then
        wrapper = wrapper .. Wrapper.generateVMStateMachine() .. "\n"
    end
    
    -- Add decoder
    wrapper = wrapper .. decoder .. "\n"
    
    -- Add encoded data
    wrapper = wrapper .. string.format('local encoded = %q\n', encoded)
    
    -- Decode and execute
    wrapper = wrapper .. [[
local decoded = decode(encoded)

if verifyIntegrity then
    verifyIntegrity(decoded)
end

local func = loadstring(decoded)
if not func then
    error("Failed to load")
end

local env = getfenv and getfenv() or _ENV
setfenv(func, env)

return func(...)
end)(...)
]]
    
    return "return " .. wrapper
end

return Wrapper
