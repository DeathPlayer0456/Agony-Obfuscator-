local Wrapper = {}

function Wrapper.generateAntiDebug()
    return [[
local function __checkDebug()
    local __start = os.clock()
    for __i = 1, 10000 do end
    if os.clock() - __start > 0.05 then
        error("\68\101\98\117\103\103\101\114\32\100\101\116\101\99\116\101\100")
    end
    
    if debug or jit then
        error("\68\101\98\117\103\32\108\105\098\32\100\101\116\101\99\116\101\100")
    end
end
]]
end

function Wrapper.generateIntegrityCheck(checksum)
    return string.format([[
local function __verifyIntegrity(__code)
    local __sum = 0
    for __i = 1, #__code do
        __sum = bit32.bxor(__sum, string.byte(__code, __i))
        __sum = bit32.lrotate(__sum, 1)
    end
    if __sum ~= %d then
        error("\84\097\109\112\101\114\101\100")
    end
end
]], checksum)
end

function Wrapper.calculateChecksum(code)
    local sum = 0
    for i = 1, #code do
        sum = bit32.bxor(sum, string.byte(code, i))
        sum = bit32.lrotate(sum, 1)
    end
    return sum
end

function Wrapper.generateRefCounter()
    return [[
local __refs = {}
local __refCount = 0

local function __allocRef()
    __refCount = __refCount + 1
    __refs[__refCount] = 1
    return __refCount
end

local function __incRef(__id)
    if __refs[__id] then
        __refs[__id] = __refs[__id] + 1
    end
end

local function __decRef(__id)
    if __refs[__id] then
        __refs[__id] = __refs[__id] - 1
        if __refs[__id] <= 0 then
            __refs[__id] = nil
        end
    end
end
]]
end

function Wrapper.wrapCode(code, encoded, decoder, options)
    options = options or {}
    
    local checksum = Wrapper.calculateChecksum(code)
    
    local wrapper = "return(function(...)\n"
    
    if options.antiDebug then
        wrapper = wrapper .. Wrapper.generateAntiDebug() .. "\n__checkDebug()\n"
    end
    
    if options.integrityCheck then
        wrapper = wrapper .. Wrapper.generateIntegrityCheck(checksum) .. "\n"
    end
    
    if options.refCounter then
        wrapper = wrapper .. Wrapper.generateRefCounter() .. "\n"
    end
    
    wrapper = wrapper .. decoder .. "\n"
    wrapper = wrapper .. string.format('local __encoded = %q\n', encoded)
    
    wrapper = wrapper .. [[
local __decoded = decode(__encoded)

if __verifyIntegrity then
    __verifyIntegrity(__decoded)
end

local __func = loadstring(__decoded)
if not __func then
    error("Failed to load")
end

local __env = getfenv and getfenv() or _ENV
setfenv(__func, __env)

return __func(...)
end)(...)
]]
    
    return wrapper
end

return Wrapper
