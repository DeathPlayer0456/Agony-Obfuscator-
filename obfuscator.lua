local Lexer = require("lexer")
local Encoder = require("encoder")
local Wrapper = require("wrapper")

local Obfuscator = {}

function Obfuscator.obfuscate(source, options)
    options = options or {
        renameVariables = true,
        encryptStrings = true,
        layers = 5,
        antiDebug = true,
        integrityCheck = true,
        refCounter = true,
        functionWrapper = true,
        vm = false,
        seed = os.time()
    }
    
    -- Tokenize
    local lexer = Lexer.new(source)
    local tokens = lexer:tokenize()
    
    -- Obfuscate tokens
    local nameMap = {}
    local obfuscatedCode = {}
    
    local function randomName(len)
        local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
        local name = ""
        for i = 1, len or 12 do
            name = name .. chars:sub(math.random(1, #chars), math.random(1, #chars))
        end
        return name
    end
    
    for i, token in ipairs(tokens) do
        if token.type == "identifier" and options.renameVariables then
            if not nameMap[token.value] then
                nameMap[token.value] = randomName(15)
            end
            table.insert(obfuscatedCode, nameMap[token.value])
            
        elseif token.type == "string" and options.encryptStrings then
            -- Convert to octal
            local octal = {}
            for j = 1, #token.value do
                table.insert(octal, string.format("\\%03d", string.byte(token.value, j)))
            end
            table.insert(obfuscatedCode, '"' .. table.concat(octal) .. '"')
            
        else
            table.insert(obfuscatedCode, token.value or "")
        end
        
        -- Spacing
        if token.type ~= "lparen" and token.type ~= "lbracket" and 
           token.type ~= "dot" and token.type ~= "colon" then
            if i < #tokens and tokens[i+1].type ~= "rparen" and 
               tokens[i+1].type ~= "rbracket" and tokens[i+1].type ~= "comma" then
                table.insert(obfuscatedCode, " ")
            end
        end
    end
    
    local code = table.concat(obfuscatedCode)
    
    -- Advanced encoding
    local encoded, decoder = Encoder.advancedEncode(code, {
        layers = options.layers,
        seed = options.seed
    })
    
    -- Wrap in complex loader
    local wrapped = Wrapper.wrapCode(code, encoded, decoder, options)
    
    return wrapped
end

return Obfuscator
