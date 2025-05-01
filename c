-- Safe function to get HWID with multiple fallback options
local function safeGetHWID()
    -- Try different methods to get HWID
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
        -- Create a pseudo-HWID if no function is available
        local computerName = getcomputername and getcomputername() or "Unknown"
        local userName = getusername and getusername() or "Unknown"
        return string.format("Delta_%s_%s", computerName, userName)
    end
end

-- Get ClientID (this should work reliably)
local clientId = game:GetService("RbxAnalyticsService"):GetClientId()

-- Get HWID safely
local hwid = safeGetHWID()

-- Format and copy to clipboard
local clipboardText = "HWID: " .. hwid .. "\nClientID: " .. clientId

-- Copy to clipboard
setclipboard(clipboardText)

-- Notify the user
print("Information copied to clipboard:")
print(clipboardText)
