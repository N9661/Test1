local function safeGetHWID()
    if getexecutorhwid then
        return getexecutorhwid()
    elseif get_hwid then
        return get_hwid()
    elseif gethwid then
        return gethwid()
    elseif Executor and Executor.HWID then
        return Executor.HWID
    elseif syn and syn.hwid then
        return syn.hwid()
    else
        local computerName = getcomputername and getcomputername() or "Unknown"
        local userName = getusername and getusername() or "Unknown"
        return string.format("Delta_%s_%s", computerName, userName)
    end
end

local clientId = game:GetService("RbxAnalyticsService"):GetClientId()

local hwid = safeGetHWID()

local clipboardText = "HWID: " .. hwid .. "\nClientID: " .. clientId

setclipboard(clipboardText)

print("Information copied to clipboard:")
print(clipboardText)
