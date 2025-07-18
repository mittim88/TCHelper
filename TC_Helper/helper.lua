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
function helper.fetchXML(url)
    local handle = io.popen('curl -s -w "%{http_code}" -o - "' .. url .. '"')
    local result = handle:read("*a")
    handle:close()

    local code = tonumber(result:sub(-3))
    local content = result:sub(1, -4)

    if code ~= 200 then
        return nil, code
    end
    return content, code
end
function helper.copyFile(source, destination)
    local os_name = reaper.GetOS()
    local command

    if os_name:find("OSX") or os_name:find("macOS") then
        command = string.format('cp "%s" "%s"', source, destination)
    elseif os_name:find("Win") then
        command = string.format('copy "%s" "%s"', source:gsub("/", "\\"), destination:gsub("/", "\\"))
    elseif os_name:find("Linux") then
        command = string.format('cp "%s" "%s"', source, destination)
    else
        reaper.ShowMessageBox("Unsupported OS: " .. os_name, "Error", 0)
        return
    end

    local result = os.execute(command)
    -- if result ~= 0 then
    --     reaper.ShowMessageBox("Fehler beim Kopieren der Datei: " .. source.. ' nach: '..destination, "Fehler", 0)
    -- end
end
return helper