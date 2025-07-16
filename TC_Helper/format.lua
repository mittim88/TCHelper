local format = {}
function format.formatFadeTime(data)
  local string = data
    string = string:gsub(",",".")
    string = string:gsub("[^%d%.]", "")
     local pre, post = string:match("^(%d*)%.?(%d*)$")
    if pre == "" and post == "" then return "0.00" end
    if post ~= "" then
        post = post:sub(1,2)                  -- Maximal 2 Nachkommastellen
        return pre .. "." .. (post .. "00"):sub(1,2)
    else
        return pre .. ".00"
    end
end
function format.replaceSpecialCharacters(inputString)
    local replacements = {
        { "ä", "ae" },
        { "ö", "oe" },
        { "ü", "ue" },
        { "Ä", "Ae" },
        { "Ö", "Oe" },
        { "Ü", "Ue" }
    }
    for _, replacement in ipairs(replacements) do
        inputString = string.gsub(inputString, replacement[1], replacement[2])
    end
    return inputString
end
return format