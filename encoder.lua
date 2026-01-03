local Encoder = {}

-- Generate random key
function Encoder.generateKey(length)
    local key = {}
    for i = 1, length do
        table.insert(key, math.random(0, 255))
    end
    return key
end

-- Multi-layer XOR encryption
function Encoder.multiLayerXOR(data, keys)
    local result = data
    for _, key in ipairs(keys) do
        local encrypted = {}
        for i = 1, #result do
            local keyByte = key[((i - 1) % #key) + 1]
            local dataByte = string.byte(result, i)
            table.insert(encrypted, string.char(bit32.bxor(dataByte, keyByte)))
        end
        result = table.concat(encrypted)
    end
    return result
end

-- Custom base encoding (not standard base64)
function Encoder.customBaseEncode(str, alphabet)
    alphabet = alphabet or "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@"
    local result = {}
    
    for i = 1, #str, 3 do
        local a, b, c = string.byte(str, i, i + 2)
        b = b or 0
        c = c or 0
        
        local n = a * 65536 + b * 256 + c
        
        local b1 = math.floor(n / 262144)
        local b2 = math.floor((n % 262144) / 4096)
        local b3 = math.floor((n % 4096) / 64)
        local b4 = n % 64
        
        table.insert(result, alphabet:sub(b1 + 1, b1 + 1))
        table.insert(result, alphabet:sub(b2 + 1, b2 + 1))
        table.insert(result, i + 1 <= #str and alphabet:sub(b3 + 1, b3 + 1) or '=')
        table.insert(result, i + 2 <= #str and alphabet:sub(b4 + 1, b4 + 1) or '=')
    end
    
    return table.concat(result)
end

-- Shuffle array indices
function Encoder.shuffleArray(arr, seed)
    math.randomseed(seed)
    local shuffled = {}
    local indices = {}
    
    for i = 1, #arr do
        table.insert(indices, i)
    end
    
    for i = #indices, 2, -1 do
        local j = math.random(1, i)
        indices[i], indices[j] = indices[j], indices[i]
    end
    
    for _, idx in ipairs(indices) do
        table.insert(shuffled, arr[idx])
    end
    
    return shuffled, indices
end

-- Generate complex decoder
function Encoder.generateComplexDecoder(keys, alphabet, shuffleSeed, layerCount)
    local keyStrings = {}
    for i, key in ipairs(keys) do
        local keyBytes = {}
        for _, byte in ipairs(key) do
            table.insert(keyBytes, tostring(byte))
        end
        keyStrings[i] = "{" .. table.concat(keyBytes, ",") .. "}"
    end
    
    local decoder = string.format([[
local function decode(data)
    local alphabet = %q
    local keys = {%s}
    local seed = %d
    
    -- Custom base decode
    local function customBaseDecode(str)
        local result = {}
        str = str:gsub('[^' .. alphabet:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]','%%%1') .. '=]', '')
        
        for i = 1, #str, 4 do
            local a = alphabet:find(str:sub(i, i)) - 1
            local b = alphabet:find(str:sub(i+1, i+1)) - 1
            local c = str:sub(i+2, i+2) ~= '=' and (alphabet:find(str:sub(i+2, i+2)) - 1) or 0
            local d = str:sub(i+3, i+3) ~= '=' and (alphabet:find(str:sub(i+3, i+3)) - 1) or 0
            
            local n = a * 262144 + b * 4096 + c * 64 + d
            
            table.insert(result, string.char(math.floor(n / 65536)))
            if str:sub(i+2, i+2) ~= '=' then
                table.insert(result, string.char(math.floor((n %% 65536) / 256)))
            end
            if str:sub(i+3, i+3) ~= '=' then
                table.insert(result, string.char(n %% 256))
            end
        end
        
        return table.concat(result)
    end
    
    -- Multi-layer XOR decrypt
    local function multiLayerXORDecrypt(encrypted, keyList)
        local result = encrypted
        for i = #keyList, 1, -1 do
            local key = keyList[i]
            local decrypted = {}
            for j = 1, #result do
                local keyByte = key[((j - 1) %% #key) + 1]
                local dataByte = string.byte(result, j)
                table.insert(decrypted, string.char(bit32.bxor(dataByte, keyByte)))
            end
            result = table.concat(decrypted)
        end
        return result
    end
    
    -- Unshuffle array
    local function unshuffleArray(arr, originalSeed)
        math.randomseed(originalSeed)
        local indices = {}
        for i = 1, #arr do
            table.insert(indices, i)
        end
        
        for i = #indices, 2, -1 do
            local j = math.random(1, i)
            indices[i], indices[j] = indices[j], indices[i]
        end
        
        local unshuffled = {}
        for i, idx in ipairs(indices) do
            unshuffled[idx] = arr[i]
        end
        
        return unshuffled
    end
    
    -- Decode pipeline
    data = customBaseDecode(data)
    data = multiLayerXORDecrypt(data, keys)
    
    local chunks = {}
    for chunk in data:gmatch("[^|]+") do
        table.insert(chunks, chunk)
    end
    
    chunks = unshuffleArray(chunks, seed)
    data = table.concat(chunks)
    
    return data
end
]], alphabet, table.concat(keyStrings, ","), shuffleSeed)
    
    return decoder
end

-- Encode with all layers
function Encoder.advancedEncode(code, options)
    options = options or {}
    local layerCount = options.layers or 3
    local alphabet = options.alphabet or "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!@"
    local shuffleSeed = options.seed or os.time()
    
    -- Split into chunks
    local chunkSize = math.ceil(#code / 10)
    local chunks = {}
    for i = 1, #code, chunkSize do
        table.insert(chunks, code:sub(i, i + chunkSize - 1))
    end
    
    -- Shuffle chunks
    local shuffled, indices = Encoder.shuffleArray(chunks, shuffleSeed)
    code = table.concat(shuffled, "|")
    
    -- Generate encryption keys
    local keys = {}
    for i = 1, layerCount do
        table.insert(keys, Encoder.generateKey(16))
    end
    
    -- Multi-layer XOR
    code = Encoder.multiLayerXOR(code, keys)
    
    -- Custom base encode
    code = Encoder.customBaseEncode(code, alphabet)
    
    -- Generate decoder
    local decoder = Encoder.generateComplexDecoder(keys, alphabet, shuffleSeed, layerCount)
    
    return code, decoder
end

return Encoder
