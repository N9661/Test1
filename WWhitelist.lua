local WhitelistSystem = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constants
local VERIFICATION_INTERVAL = 30 -- Check every 30 seconds

-- Function to get HWID based on executor
local function getHWID()
    -- Try different executor-specific HWID functions
    if syn and syn.request then
        -- Synapse X
        return syn.request({Url = "https://httpbin.org/get"}).Headers["Syn-Fingerprint"] or "Unknown"
    elseif syn and syn.get_hwid then
        return syn.get_hwid()
    elseif Krnl and Krnl.GetHWID then
        -- Krnl
        return Krnl.GetHWID()
    elseif identifyexecutor and gethwid then
        -- Script-Ware and some others
        return gethwid()
    elseif getexecutorname and gethwid then
        return gethwid()
    elseif executor and executor.identifier then
        -- Generic approach
        return executor.identifier()
    elseif fluxus and fluxus.get_hwid then
        -- Fluxus
        return fluxus.get_hwid()
    elseif getexecutorname and getexecutorname():find("ScriptWare") and get_hwid then
        -- Script-Ware alternative method
        return get_hwid()
    elseif oxygen_get_hwid then
        -- Oxygen U
        return oxygen_get_hwid()
    elseif SENTINEL_HWID then
        -- Sentinel
        return SENTINEL_HWID
    elseif SHADOW_HWID then
        -- Shadow
        return SHADOW_HWID
    elseif KRNL_HWID then
        -- Krnl alternative
        return KRNL_HWID
    else
        -- Fallback: generate a pseudo-HWID based on available system info
        local hwid = ""
        pcall(function()
            -- Try to get some unique device info
            local screenSize = workspace.CurrentCamera.ViewportSize
            local timeInfo = os.time() % 1000
            hwid = game.JobId .. "-" .. screenSize.X .. "x" .. screenSize.Y .. "-" .. timeInfo
        end)
        return hwid ~= "" and hwid or "Unavailable"
    end
end

-- Function to get ClientID
local function getClientID()
    -- Try different methods to get ClientID
    if game:GetService("RbxAnalyticsService") then
        local success, clientId = pcall(function()
            return game:GetService("RbxAnalyticsService"):GetClientId()
        end)
        if success and clientId then
            return clientId
        end
    end
    
    -- Fallback: generate a pseudo-ClientID
    return "Generated-" .. string.format("%x", os.time() + math.random(1000000, 9999999))
end

-- Get player identifiers
function WhitelistSystem:GetIdentifiers()
    local player = Players.LocalPlayer
    if not player then
        return nil, "Player not found"
    end
    
    -- Get the basic identifiers
    local userId = player.UserId
    local username = player.Name
    local hwid = getHWID()
    local clientId = getClientID()
    
    return {
        UserID = userId,
        Username = username,
        HWID = hwid,
        ClientID = clientId
    }
end

WhitelistSystem.Whitelist = {
    -- UserIDs
    UserIDs = {
        [8367759083] = true,
    },
    
    -- Usernames
    Usernames = {
        ["HVX_Havoc"] = true,
    },
    
    -- HWIDs
    HWIDs = {
      ["e9b170f70b95881d19abdb753e64d6513e354bc72e37c7d45b13b1f36ec3aa60"] = true,
    },
    
    -- ClientIDs
    ClientIDs = {
        ["fba078e1-e7a1-4082-ad2d-877b7094797b"] = true,
    }
}

-- Check if player is whitelisted
function WhitelistSystem:IsWhitelisted()
    local identifiers, error = self:GetIdentifiers()
    if not identifiers then
        return false, "Failed to get identifiers: " .. (error or "Unknown error")
    end
    
    -- Check UserID
    if self.Whitelist.UserIDs[identifiers.UserID] then
        return true, "UserID", identifiers
    end
    
    -- Check Username
    if self.Whitelist.Usernames[identifiers.Username] then
        return true, "Username", identifiers
    end
    
    -- Check HWID
    if self.Whitelist.HWIDs[identifiers.HWID] then
        return true, "HWID", identifiers
    end
    
    -- Check ClientID
    if self.Whitelist.ClientIDs[identifiers.ClientID] then
        return true, "ClientID", identifiers
    end
    
    return false, "Not Whitelisted", identifiers
end

-- Start continuous verification to detect runtime tampering
function WhitelistSystem:StartContinuousVerification()
    -- Store initial verification data
    self.initialIdentifiers = self:GetIdentifiers()
    
    -- Set up a loop to periodically verify the player
    self.verificationConnection = RunService.Heartbeat:Connect(function()
        task.wait(VERIFICATION_INTERVAL)
        
        -- Skip if the script is unloading
        if self.isUnloading then return end
        
        local currentIdentifiers = self:GetIdentifiers()
        
        -- Check for critical changes that shouldn't happen during gameplay
        if currentIdentifiers.UserID ~= self.initialIdentifiers.UserID then
            -- Critical tampering detected - kick the player
            self:HandleTampering("UserID change detected during session")
        end
        
        -- Check if still whitelisted
        local isWhitelisted = self:IsWhitelisted()
        if not isWhitelisted then
            self:HandleTampering("Whitelist verification failed during session")
        end
    end)
end

-- Handle tampering detection
function WhitelistSystem:HandleTampering(reason)
    -- Log the tampering attempt
    warn("Tampering detected: " .. reason)
    
    -- Notify the player
    if game:GetService("CoreGui"):FindFirstChild("FluentNotification") then
        -- Use Fluent UI if available
        local Library = getgenv().Library
        if Library and Library.Notify then
            Library:Notify{
                Title = "Security Violation",
                Content = "Unauthorized modification detected",
                Duration = 5
            }
        end
    end
    
    -- Wait a moment for notification to show
    task.wait(1)
    
    -- Kick the player
    Players.LocalPlayer:Kick("Security violation: " .. reason)
end

-- Clean up resources
function WhitelistSystem:Cleanup()
    self.isUnloading = true
    if self.verificationConnection then
        self.verificationConnection:Disconnect()
    end
end

-- Initialize the whitelist system
function WhitelistSystem:Initialize()
    -- Start continuous verification
    self:StartContinuousVerification()
    
    return self
end

return WhitelistSystem
