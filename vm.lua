local VM = {}

function VM.generateStateMachine(code)
    local lines = {}
    
    for line in code:gmatch("[^\r\n]+") do
        if line:match("%S") then
            table.insert(lines, line)
        end
    end
    
    if #lines == 0 then
        return code
    end
    
    local stateCode = "local __state = 0\nwhile __state do\n"
    
    for i, line in ipairs(lines) do
        local nextState = i < #lines and i + 1 or 0
        stateCode = stateCode .. string.format([[
    if __state == %d then
        %s
        __state = %d
    end
]], i - 1, line, nextState)
    end
    
    stateCode = stateCode .. "end\n"
    
    return stateCode
end

function VM.addJunkCode(code)
    local junk = {
        "local _unused = math.random(1, 100)",
        "local _temp = string.rep('x', 10)",
        "local _data = {1, 2, 3, 4, 5}",
        "if false then return end",
        "local _check = type('test')"
    }
    
    local lines = {}
    for line in code:gmatch("[^\r\n]+") do
        table.insert(lines, line)
        if math.random() > 0.6 then
            table.insert(lines, junk[math.random(1, #junk)])
        end
    end
    
    return table.concat(lines, "\n")
end

function VM.addControlFlowObfuscation(code)
    local obfuscated = {}
    
    table.insert(obfuscated, "do")
    table.insert(obfuscated, "    local __cf = true")
    table.insert(obfuscated, "    if __cf then")
    
    for line in code:gmatch("[^\r\n]+") do
        table.insert(obfuscated, "        " .. line)
    end
    
    table.insert(obfuscated, "    end")
    table.insert(obfuscated, "end")
    
    return table.concat(obfuscated, "\n")
end

return VM
