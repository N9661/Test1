-- Create a table to store all identifiers
local identifiers = {}

-- 1. Basic Identifiers
identifiers.HWID = safeGetHWID() -- Using the function that worked for you
identifiers.ClientID = game:GetService("RbxAnalyticsService"):GetClientId()
identifiers.UserID = game:GetService("Players").LocalPlayer.UserId

-- 2. Player Information
identifiers.PlayerName = game:GetService("Players").LocalPlayer.Name
identifiers.DisplayName = game:GetService("Players").LocalPlayer.DisplayName
identifiers.AccountAge = game:GetService("Players").LocalPlayer.AccountAge

-- 3. Device Information
identifiers.DeviceID = (identifyexecutor and identifyexecutor()) or "Unknown"
identifiers.ComputerName = (getcomputername and getcomputername()) or "Unknown"
identifiers.UserName = (getusername and getusername()) or "Unknown"

-- 4. Game Information
identifiers.PlaceID = game.PlaceId
identifiers.GameID = game.GameId
identifiers.JobID = game.JobId

-- 5. IP-Related (if available)
pcall(function()
    identifiers.IP = (getip and getip()) or "Unknown"
    identifiers.IPv4 = (getipv4 and getipv4()) or "Unknown"
end)

-- 6. Executor-Specific
pcall(function()
    identifiers.ExecutorVersion = (getexecutorversion and getexecutorversion()) or "Unknown"
    identifiers.ExecutorName = (getexecutorname and getexecutorname()) or identifiers.DeviceID
end)

-- 7. Hardware-Specific
pcall(function()
    identifiers.HardwareID = (gethardwareid and gethardwareid()) or "Unknown"
    identifiers.DiskID = (getdiskid and getdiskid()) or "Unknown"
    identifiers.CPUID = (getcpuid and getcpuid()) or "Unknown"
    identifiers.GPUID = (getgpuid and getgpuid()) or "Unknown"
    identifiers.RAMID = (getramid and getramid()) or "Unknown"
    identifiers.BIOSID = (getbiosid and getbiosid()) or "Unknown"
    identifiers.MBID = (getmotherboardid and getmotherboardid()) or "Unknown"
end)

-- 8. Delta-Specific
pcall(function()
    identifiers.DeltaID = (Delta and Delta.ID) or "Unknown"
    identifiers.DeltaVersion = (Delta and Delta.Version) or "Unknown"
    identifiers.DeltaFingerprint = (Delta and Delta.Fingerprint) or "Unknown"
end)

-- 9. Session Information
identifiers.SessionID = (getsessionid and getsessionid()) or HttpService:GenerateGUID(false)
identifiers.JoinTime = os.time()

-- 10. Roblox-Specific
pcall(function()
    identifiers.RobloxVersion = version()
    identifiers.FFlagValues = {}
    for i, v in pairs(getfflags and getfflags() or {}) do
        identifiers.FFlagValues[i] = v
    end
end)

-- Print all available identifiers
print("\n--- All Available Identifiers ---\n")
for name, value in pairs(identifiers) do
    if type(value) ~= "table" then
        print(name .. ": " .. tostring(value))
    end
end

-- Copy to clipboard
local clipboardText = "--- Delta Executor Identifiers ---\n"
for name, value in pairs(identifiers) do
    if type(value) ~= "table" then
        clipboardText = clipboardText .. name .. ": " .. tostring(value) .. "\n"
    end
end

setclipboard(clipboardText)
print("\nAll identifiers copied to clipboard!")
