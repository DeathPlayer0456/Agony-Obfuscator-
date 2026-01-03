
local Lexer = {}
Lexer.__index = Lexer

local keywords = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
    ["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
    ["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
    ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
    ["while"] = true
}

function Lexer.new(source)
    return setmetatable({
        source = source,
        pos = 1,
        current = source:sub(1, 1)
    }, Lexer)
end

function Lexer:advance()
    self.pos = self.pos + 1
    self.current = self.source:sub(self.pos, self.pos)
end

function Lexer:peek(offset)
    offset = offset or 1
    return self.source:sub(self.pos + offset, self.pos + offset)
end

function Lexer:skipWhitespace()
    while self.current:match("%s") do
        self:advance()
    end
end

function Lexer:skipComment()
    if self.current == "-" and self:peek() == "-" then
        if self:peek(2) == "[" and self:peek(3) == "[" then
            self:advance() self:advance() self:advance() self:advance()
            while not (self.current == "]" and self:peek() == "]") do
                if self.current == "" then break end
                self:advance()
            end
            if self.current == "]" then
                self:advance() self:advance()
            end
        else
            while self.current ~= "\n" and self.current ~= "" do
                self:advance()
            end
        end
        return true
    end
    return false
end

function Lexer:readString(quote)
    local str = ""
    self:advance()
    
    while self.current ~= quote and self.current ~= "" do
        if self.current == "\\" then
            self:advance()
            local escapes = {
                n = "\n", t = "\t", r = "\r", 
                ["\\"] = "\\", ["\""] = "\"", ["'"] = "'"
            }
            str = str .. (escapes[self.current] or self.current)
        else
            str = str .. self.current
        end
        self:advance()
    end
    
    self:advance()
    return {type = "string", value = str}
end

function Lexer:readNumber()
    local num = ""
    while self.current:match("[%d%.]") do
        num = num .. self.current
        self:advance()
    end
    return {type = "number", value = tonumber(num)}
end

function Lexer:readIdentifier()
    local id = ""
    while self.current:match("[%w_]") do
        id = id .. self.current
        self:advance()
    end
    
    if keywords[id] then
        return {type = "keyword", value = id}
    end
    
    return {type = "identifier", value = id}
end

function Lexer:tokenize()
    local tokens = {}
    
    while self.current ~= "" do
        self:skipWhitespace()
        
        if self.current == "" then break end
        
        if self:skipComment() then
            goto continue
        end
        
        if self.current == '"' or self.current == "'" then
            table.insert(tokens, self:readString(self.current))
            goto continue
        end
        
        if self.current:match("%d") then
            table.insert(tokens, self:readNumber())
            goto continue
        end
        
        if self.current:match("[%a_]") then
            table.insert(tokens, self:readIdentifier())
            goto continue
        end
        
        local double = self.current .. self:peek()
        if double == "==" or double == "~=" or double == "<=" or 
           double == ">=" or double == ".." or double == "//" then
            table.insert(tokens, {type = "operator", value = double})
            self:advance()
            self:advance()
            goto continue
        end
        
        local ops = {
            ["("] = "lparen", [")"] = "rparen",
            ["{"] = "lbrace", ["}"] = "rbrace",
            ["["] = "lbracket", ["]"] = "rbracket",
            [","] = "comma", [";"] = "semicolon",
            ["."] = "dot", [":"] = "colon",
            ["="] = "assign", ["+"] = "plus",
            ["-"] = "minus", ["*"] = "star",
            ["/"] = "slash", ["%"] = "percent",
            ["#"] = "hash", ["<"] = "lt",
            [">"] = "gt", ["~"] = "tilde"
        }
        
        if ops[self.current] then
            table.insert(tokens, {type = ops[self.current], value = self.current})
            self:advance()
            goto continue
        end
        
        self:advance()
        
        ::continue::
    end
    
    return tokens
end

return Lexer
