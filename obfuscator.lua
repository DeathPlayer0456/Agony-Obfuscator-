
local Lexer = require("lexer")
local Encoder = require("encoder")
local Wrapper = require("wrapper")
local VM = require("vm")

local Obfuscator = {}

local function randomName(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
    local name = chars:sub(math.random(1, 52), math.random(1, 52))
    for i = 2, len or 12 do
        name = name .. chars:sub(math.random(1, 53), math.random(1, 53))
    end
    return name
end

function Obfuscator.obfuscate(source, options)
    options = options or {}
    
    options.renameVariables = options.renameVariables ~= false
    options.encryptStrings = options.encryptStrings ~= false
    options.layers = options.layers or 5
    options.antiDebug = options.antiDebug ~= false
    options.integrityCheck = options.integrityCheck ~= false
    options.refCounter = options.refCounter ~= false
    options.junkCode = options.junkCode
    options.stateMachine = options.stateMachine
    options.seed = options.seed or os.time()
    
    local lexer = Lexer.new(source)
    local tokens = lexer:tokenize()
    
    local nameMap = {}
    local obfuscatedCode = {}
    
    for i, token in ipairs(tokens) do
        if token.type == "identifier" and options.renameVariables then
            if not nameMap[token.value] then
                nameMap[token.value] = randomName(15)
            end
            table.insert(obfuscatedCode, nameMap[token.value])
            
        elseif token.type == "string" and options.encryptStrings then
            local octal = {}
            for j = 1, #token.value do
                table.insert(octal, string.format("\\%03d", string.byte(token.value, j)))
            end
            table.insert(obfuscatedCode, '"' .. table.concat(octal) .. '"')
            
        else
            table.insert(obfuscatedCode, token.value or "")
        end
        
        if token.type ~= "lparen" and token.type ~= "lbracket" and 
           token.type ~= "dot" and token.type ~= "colon" then
            if i < #tokens then
                local next = tokens[i+1]
                if next.type ~= "rparen" and next.type ~= "rbracket" and 
                   next.type ~= "comma" and next.type ~= "semicolon" and
                   next.type ~= "dot" and next.type ~= "colon" then
                    table.insert(obfuscatedCode, " ")
                end
            end
        end
    end
    
    local code = table.concat(obfuscatedCode)
    
    if options.junkCode then
        code = VM.addJunkCode(code)
    end
    
    if options.stateMachine then
        code = VM.generateStateMachine(code)
    end
    
    local encoded, decoder = Encoder.advancedEncode(code, {
        layers = options.layers,
        seed = options.seed
    })
    
    local wrapped = Wrapper.wrapCode(code, encoded, decoder, options)
    
    return wrapped
end

return Obfuscator
