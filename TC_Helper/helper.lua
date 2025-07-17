local helper = {}
function helper.tableToString(tbl)
    local result = {}
    local function serialize(tbl, indent)
        for k, v in pairs(tbl) do
            local key = type(k) == "string" and string.format("%q", k) or tostring(k)
            if type(v) == "table" then
                table.insert(result, string.format("%s[%s] = {", indent, key))
                serialize(v, indent .. "  ")
                table.insert(result, string.format("%s},", indent))
            else
                local value = type(v) == "string" and string.format("%q", v) or tostring(v)
                table.insert(result, string.format("%s[%s] = %s,", indent, key, value))
            end
        end
    end
    table.insert(result, "{")
    serialize(tbl, "  ")
    table.insert(result, "}")
    return table.concat(result, "\n")
end
function helper.stringToTable(str)
    local func = load("return " .. str)
    if func then
        return func()
    else
        return nil
    end
end
function helper.consoleMSG(x)
    reaper.ShowConsoleMsg(x..'\n')
end
function helper.defineBash()
    local platform = reaper.GetOS()
    local system = 'empty'
    local bash = 'empty'
    local winBash = 'cmd.exe /C '
    local macBash = "/bin/sh -c "
    if platform == 'Win64' then
        bash = winBash
        system = 'win'
    elseif platform == 'Win32' then
        bash = winBash
        system = 'win'
    elseif platform == 'OSX32' then
        bash = macBash
        system = 'macOS'
    elseif platform == 'OSX64' then
        bash = macBash
        system = 'macOS'
    elseif platform == 'macOS-arm64' then
        bash = macBash
        system = 'macOS'
    else
        helper.consoleMSG('NO SUPPORTED OS')
    end
return bash,system
end
function helper.copy3(obj, seen)
    -- Handle non-tables and previously-seen tables.
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[obj] = res
    for k, v in pairs(obj) do res[helper.copy3(k, s)] = helper.copy3(v, s) end
    return setmetatable(res, getmetatable(obj))
end
function helper.sleep (a) 
    local sec = tonumber(os.clock() + a); 
    while (os.clock() < sec) do 
    end 
end
return helper