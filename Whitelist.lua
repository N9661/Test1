local WhitelistSystem = {}

-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")
local RunService = game:GetService("RunService")

-- Constants
local ENCRYPTION_KEY = 42 -- Change this to something unique
local VERIFICATION_INTERVAL = 30 -- Check every 30 seconds

-- Encryption function
local function encrypt(str)
    local result = ""
    for i = 1, #str do
        local char = string.byte(str, i)
        result = result .. string.char(bit32.bxor(char, ENCRYPTION_KEY))
    end
    return result
end

-- Hash function
local function hash(str)
    local h = 5381
    for i = 1, #str do
        h = bit32.bxor(h * 33 + string.byte(str, i), 0)
    end
    return tostring(h)
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
    local hwid = RbxAnalyticsService:GetClientId() -- This is the HWID
    local clientId = HttpService:GenerateGUID(false) -- Session ID
    
    -- Create a verification hash
    local verificationString = userId .. "|" .. username .. "|" .. hwid
    local verificationHash = hash(verificationString)
    
    return {
        UserID = userId,
        Username = username,
        HWID = hwid,
        ClientID = clientId,
        VerificationHash = verificationHash
    }
end

-- Whitelist data
WhitelistSystem.Whitelist = {
    -- UserIDs
    UserIDs = {
        -- [12345678] = true,
    },
    
    -- Usernames
    Usernames = {
        -- ["ExampleUser"] = true,
    },
    
    -- HWIDs
    HWIDs = {
        -- ["example-hwid-string"] = true,
    },
    
    -- Verification hashes (most secure)
    VerificationHashes = {
        -- ["hash-value"] = true,
    }
}

-- Check if player is whitelisted
function WhitelistSystem:IsWhitelisted()
    local identifiers, error = self:GetIdentifiers()
    if not identifiers then
        return false, "Failed to get identifiers: " .. (error or "Unknown error")
    end
    
    -- Check verification hash first (most secure)
    if self.Whitelist.VerificationHashes[identifiers.VerificationHash] then
        return true, "Verification Hash", identifiers
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
    
    return false, "Not Whitelisted", identifiers
end

-- Add a user to the whitelist
function WhitelistSystem:AddToWhitelist(userId, username, hwid)
    if not userId or not username or not hwid then
        return false, "UserID, Username, and HWID are all required"
    end
    
    -- Add to individual lists
    self.Whitelist.UserIDs[userId] = true
    self.Whitelist.Usernames[username] = true
    self.Whitelist.HWIDs[hwid] = true
    
    -- Create and add verification hash
    local verificationString = userId .. "|" .. username .. "|" .. hwid
    local verificationHash = hash(verificationString)
    self.Whitelist.VerificationHashes[verificationHash] = true
    
    return true, verificationHash
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
        if currentIdentifiers.UserID ~= self.initialIdentifiers.UserID or
           currentIdentifiers.HWID ~= self.initialIdentifiers.HWID then
            -- Critical tampering detected - kick the player
            self:HandleTampering("Identity change detected during session")
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

-- Initialize the whitelist system with your whitelist data
function WhitelistSystem:Initialize()
    -- Add your whitelisted users here
    -- Format: self:AddToWhitelist(userId, username, hwid)
    
    -- Example users (replace with your actual whitelist)
    self:AddToWhitelist(123456789, "User1", "HWID1")
    self:AddToWhitelist(987654321, "User2", "HWID2")
    self:AddToWhitelist(111222333, "User3", "HWID3")
    
    -- Start continuous verification
    self:StartContinuousVerification()
    
    return self
end

return WhitelistSystem
