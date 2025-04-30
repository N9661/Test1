local WhitelistSystem = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Constants
local VERIFICATION_INTERVAL = 15 -- Check more frequently
local KICK_DELAY = 15 -- Wait 15 seconds before kicking

-- Enhanced anti-spoofing measures
local function generateDeviceFingerprint()
    local fingerprint = {}
    
    -- Collect various environment data that's harder to spoof
    pcall(function()
        -- Screen resolution and pixel density
        local camera = workspace.CurrentCamera
        if camera then
            fingerprint.screenSize = tostring(camera.ViewportSize.X) .. "x" .. tostring(camera.ViewportSize.Y)
        end
        
        -- Game instance data
        fingerprint.placeId = game.PlaceId
        fingerprint.jobId = game.JobId
        
        -- Graphics quality and FPS
        fingerprint.graphicsQuality = UserSettings():GetService("UserGameSettings").SavedQualityLevel
        
        -- Time-based data
        fingerprint.timezone = os.time() - os.time(os.date("!*t"))
        
        -- Memory usage patterns
        fingerprint.memoryUsage = gcinfo()
        
        -- Device performance metrics
        local startTime = os.clock()
        local counter = 0
        for i = 1, 100000 do counter = counter + 1 end
        fingerprint.performanceMetric = os.clock() - startTime
        
        -- Input device info if available
        if UserInputService then
            fingerprint.touchEnabled = UserInputService.TouchEnabled
            fingerprint.keyboardEnabled = UserInputService.KeyboardEnabled
            fingerprint.mouseEnabled = UserInputService.MouseEnabled
        end
    end)
    
    -- Combine all collected data into a single string
    local combinedData = ""
    for k, v in pairs(fingerprint) do
        combinedData = combinedData .. tostring(k) .. ":" .. tostring(v) .. ";"
    end
    
    -- Create a hash of the combined data
    local hash = 0
    for i = 1, #combinedData do
        hash = ((hash << 5) - hash) + string.byte(combinedData, i)
        hash = bit32.band(hash, 0xFFFFFFFF) -- Keep within 32 bits
    end
    
    return tostring(hash)
end

-- Multiple HWID collection methods to make spoofing harder
local function getHWID()
    local hwids = {}
    
    -- Try different executor-specific HWID functions
    if syn and syn.request then
        hwids.synapse = syn.request({Url = "https://httpbin.org/get"}).Headers["Syn-Fingerprint"] or "Unknown"
    end
    
    if syn and syn.get_hwid then
        hwids.synapseAlt = syn.get_hwid()
    end
    
    if Krnl and Krnl.GetHWID then
        hwids.krnl = Krnl.GetHWID()
    end
    
    if identifyexecutor and gethwid then
        hwids.scriptware = gethwid()
    end
    
    if getexecutorname and gethwid then
        hwids.generic = gethwid()
    end
    
    if executor and executor.identifier then
        hwids.executor = executor.identifier()
    end
    
    if fluxus and fluxus.get_hwid then
        hwids.fluxus = fluxus.get_hwid()
    end
    
    -- Add our custom device fingerprint
    hwids.deviceFingerprint = generateDeviceFingerprint()
    
    -- Combine all collected HWIDs into a single string
    local combinedHWID = ""
    for k, v in pairs(hwids) do
        combinedHWID = combinedHWID .. tostring(v) .. ";"
    end
    
    -- Create a hash of the combined HWIDs
    local hash = 0
    for i = 1, #combinedHWID do
        hash = ((hash << 5) - hash) + string.byte(combinedHWID, i)
        hash = bit32.band(hash, 0xFFFFFFFF) -- Keep within 32 bits
    end
    
    -- Return the final HWID hash
    return tostring(hash)
end

-- Enhanced ClientID collection
local function getClientID()
    local clientIds = {}
    
    -- Try RbxAnalyticsService method
    if game:GetService("RbxAnalyticsService") then
        pcall(function()
            clientIds.analytics = game:GetService("RbxAnalyticsService"):GetClientId()
        end)
    end
    
    -- Try to get from cookies if possible
    if request then
        pcall(function()
            local response = request({
                Url = "https://www.roblox.com/home",
                Method = "GET"
            })
            
            -- Extract .ROBLOSECURITY cookie
            local cookie = response.Headers["Set-Cookie"]
            if cookie and cookie:find(".ROBLOSECURITY") then
                clientIds.cookie = "Cookie-Based-ID-" .. string.sub(cookie, 1, 8)
            end
        end)
    end
    
    -- Add additional device info
    pcall(function()
        -- Try to get some unique device info
        local screenSize = workspace.CurrentCamera.ViewportSize
        clientIds.screen = screenSize.X .. "x" .. screenSize.Y
        
        -- Add time-based component that changes slowly
        clientIds.timeComponent = math.floor(os.time() / 86400) -- Changes daily
    end)
    
    -- Combine all collected ClientIDs into a single string
    local combinedClientID = ""
    for k, v in pairs(clientIds) do
        combinedClientID = combinedClientID .. tostring(v) .. ";"
    end
    
    -- If we have RbxAnalyticsService ClientID, prioritize it
    if clientIds.analytics then
        return clientIds.analytics
    end
    
    -- Otherwise use our combined approach
    if #combinedClientID > 0 then
        -- Create a hash of the combined ClientIDs
        local hash = 0
        for i = 1, #combinedClientID do
            hash = ((hash << 5) - hash) + string.byte(combinedClientID, i)
            hash = bit32.band(hash, 0xFFFFFFFF) -- Keep within 32 bits
        end
        return tostring(hash)
    end
    
    -- Fallback
    return "Generated-" .. string.format("%x", os.time() + math.random(1000000, 9999999))
end

-- Get player identifiers with anti-spoofing measures
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
    
    -- Additional verification
    local accountAge = player.AccountAge
    local membershipType = player.MembershipType.Name
    local deviceFingerprint = generateDeviceFingerprint()
    
    -- Create a verification hash combining all identifiers
    local verificationString = userId .. "|" .. username .. "|" .. hwid .. "|" .. clientId
    local verificationHash = tostring(
        string.len(verificationString) * 
        string.byte(username, 1) * 
        (userId % 1000)
    )
    
    return {
        UserID = userId,
        Username = username,
        HWID = hwid,
        ClientID = clientId,
        AccountAge = accountAge,
        MembershipType = membershipType,
        DeviceFingerprint = deviceFingerprint,
        VerificationHash = verificationHash
    }
end

-- Whitelist data structure
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
    },
    
    -- Complete user entries for comprehensive checking
    CompleteEntries = {
        {
            UserID = 8367759083,
            Username = "HVX_Havoc",
            HWID = "e9b170f70b95881d19abdb753e64d6513e354bc72e37c7d45b13b1f36ec3aa60",
            ClientID = "fba078e1-e7a1-4082-ad2d-877b7094797b"
        }
    }
}

-- Check if player is whitelisted with comprehensive checks
function WhitelistSystem:IsWhitelisted()
    local identifiers, error = self:GetIdentifiers()
    if not identifiers then
        return false, "Failed to get identifiers: " .. (error or "Unknown error")
    end
    
    -- First check: Verify all identifiers match a complete entry
    for _, entry in ipairs(self.Whitelist.CompleteEntries) do
        if entry.UserID == identifiers.UserID then
            -- Found a UserID match, now check if all other identifiers match
            local mismatches = {}
            
            if entry.Username ~= identifiers.Username then
                table.insert(mismatches, "Username")
            end
            
            if entry.HWID ~= identifiers.HWID then
                table.insert(mismatches, "HWID")
            end
            
            if entry.ClientID ~= identifiers.ClientID then
                table.insert(mismatches, "ClientID")
            end
            
            -- If no mismatches, user is fully verified
            if #mismatches == 0 then
                return true, "All identifiers verified", identifiers
            else
                -- Return partial match with mismatches
                return false, "Mismatched identifiers: " .. table.concat(mismatches, ", "), identifiers
            end
        end
    end
    
    -- Second check: Individual identifier checks
    local matches = {}
    
    -- Check UserID
    if self.Whitelist.UserIDs[identifiers.UserID] then
        table.insert(matches, "UserID")
    end
    
    -- Check Username
    if self.Whitelist.Usernames[identifiers.Username] then
        table.insert(matches, "Username")
    end
    
    -- Check HWID
    if self.Whitelist.HWIDs[identifiers.HWID] then
        table.insert(matches, "HWID")
    end
    
    -- Check ClientID
    if self.Whitelist.ClientIDs[identifiers.ClientID] then
        table.insert(matches, "ClientID")
    end
    
    -- If all four identifiers match individually, user is verified
    if #matches == 4 then
        return true, "All identifiers verified individually", identifiers
    elseif #matches > 0 then
        -- Some identifiers match but not all
        return false, "Only " .. table.concat(matches, ", ") .. " matched, but all are required", identifiers
    else
        -- No identifiers match
        return false, "No identifiers matched whitelist", identifiers
    end
end

-- Start continuous verification with anti-spoofing checks
function WhitelistSystem:StartContinuousVerification()
    -- Store initial verification data
    self.initialIdentifiers = self:GetIdentifiers()
    
    -- Initial whitelist check
    local isWhitelisted, reason, identifiers = self:IsWhitelisted()
    if not isWhitelisted then
        self:HandleFailedVerification(reason, identifiers)
        return
    end
    
    -- Set up a loop to periodically verify the player
    self.verificationConnection = RunService.Heartbeat:Connect(function()
        task.wait(VERIFICATION_INTERVAL)
        
        -- Skip if the script is unloading
        if self.isUnloading then return end
        
        local currentIdentifiers = self:GetIdentifiers()
        
        -- Check for critical changes that shouldn't happen during gameplay
        if currentIdentifiers.UserID ~= self.initialIdentifiers.UserID then
            self:HandleTampering("UserID change detected during session")
            return
        end
        
        if currentIdentifiers.Username ~= self.initialIdentifiers.Username then
            self:HandleTampering("Username change detected during session")
            return
        end
        
        -- Check for HWID/ClientID changes which could indicate spoofing
        if currentIdentifiers.HWID ~= self.initialIdentifiers.HWID then
            self:HandleTampering("HWID change detected during session (possible spoofing attempt)")
            return
        end
        
        if currentIdentifiers.ClientID ~= self.initialIdentifiers.ClientID then
            self:HandleTampering("ClientID change detected during session (possible spoofing attempt)")
            return
        end
        
        -- Check if still whitelisted with all methods
        local isWhitelisted, reason = self:IsWhitelisted()
        if not isWhitelisted then
            self:HandleTampering("Whitelist verification failed: " .. reason)
            return
        end
    end)
end

-- Handle failed verification
function WhitelistSystem:HandleFailedVerification(reason, identifiers)
    -- Log the verification failure
    warn("Whitelist verification failed: " .. reason)
    
    -- Show detailed information
    print("Current identifiers:")
    print("UserID: " .. identifiers.UserID)
    print("Username: " .. identifiers.Username)
    print("HWID: " .. identifiers.HWID)
    print("ClientID: " .. identifiers.ClientID)
    
    -- Notify the player
    if game:GetService("CoreGui"):FindFirstChild("FluentNotification") then
        -- Use Fluent UI if available
        local Library = getgenv().Library
        if Library and Library.Notify then
            Library:Notify{
                Title = "Access Denied",
                Content = "You are not authorized to use this script",
                SubContent = "Reason: " .. reason .. " | Kicking in " .. KICK_DELAY .. " seconds",
                Duration = KICK_DELAY
            }
        end
    else
        -- Fallback notification
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "WhitelistNotification"
        screenGui.Parent = game:GetService("CoreGui")
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 150)
        frame.Position = UDim2.new(0.5, -150, 0.5, -75)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 30)
        title.Size = UDim2.new(1, 0, 0, 30)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.TextSize = 18
        title.Font = Enum.Font.SourceSansBold
        title.Text = "Access Denied"
        title.Parent = frame
        
        local content = Instance.new("TextLabel")
        content.Size = UDim2.new(1, -20, 0, 60)
        content.Position = UDim2.new(0, 10, 0, 40)
        content.BackgroundTransparency = 1
        content.TextColor3 = Color3.fromRGB(255, 255, 255)
        content.TextSize = 16
        content.Font = Enum.Font.SourceSans
        content.Text = "You are not authorized to use this script"
        content.TextWrapped = true
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.TextYAlignment = Enum.TextYAlignment.Top
        content.Parent = frame
        
        local subContent = Instance.new("TextLabel")
        subContent.Size = UDim2.new(1, -20, 0, 60)
        subContent.Position = UDim2.new(0, 10, 0, 80)
        subContent.BackgroundTransparency = 1
        subContent.TextColor3 = Color3.fromRGB(200, 200, 200)
        subContent.TextSize = 14
        subContent.Font = Enum.Font.SourceSans
        subContent.Text = "Reason: " .. reason .. "\nKicking in " .. KICK_DELAY .. " seconds"
        subContent.TextWrapped = true
        subContent.TextXAlignment = Enum.TextXAlignment.Left
        subContent.TextYAlignment = Enum.TextYAlignment.Top
        subContent.Parent = frame
    end
    
    -- Wait before kicking
    task.wait(KICK_DELAY)
    
    -- Kick the player
    Players.LocalPlayer:Kick("Access denied: " .. reason)
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
                SubContent = "Reason: " .. reason .. " | Kicking in " .. KICK_DELAY .. " seconds",
                Duration = KICK_DELAY
            }
        end
    else
        -- Fallback notification
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "WhitelistNotification"
        screenGui.Parent = game:GetService("CoreGui")
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 150)
        frame.Position = UDim2.new(0.5, -150, 0.5, -75)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BorderSizePixel = 0
        frame.Parent = screenGui
        
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 30)
        title.Position = UDim2.new(0, 0, 0, 0)
        title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        title.TextColor3 = Color3.fromRGB(255, 0, 0)  -- Red for security violation
        title.TextSize = 18
        title.Font = Enum.Font.SourceSansBold
        title.Text = "Security Violation"
        title.Parent = frame
        
        local content = Instance.new("TextLabel")
        content.Size = UDim2.new(1, -20, 0, 60)
        content.Position = UDim2.new(0, 10, 0, 40)
        content.BackgroundTransparency = 1
        content.TextColor3 = Color3.fromRGB(255, 255, 255)
        content.TextSize = 16
        content.Font = Enum.Font.SourceSans
        content.Text = "Unauthorized modification detected"
        content.TextWrapped = true
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.TextYAlignment = Enum.TextYAlignment.Top
        content.Parent = frame
        
        local subContent = Instance.new("TextLabel")
        subContent.Size = UDim2.new(1, -20, 0, 60)
        subContent.Position = UDim2.new(0, 10, 0, 80)
        subContent.BackgroundTransparency = 1
        subContent.TextColor3 = Color3.fromRGB(200, 200, 200)
        subContent.TextSize = 14
        subContent.Font = Enum.Font.SourceSans
        subContent.Text = "Reason: " .. reason .. "\nKicking in " .. KICK_DELAY .. " seconds"
        subContent.TextWrapped = true
        subContent.TextXAlignment = Enum.TextXAlignment.Left
        subContent.TextYAlignment = Enum.TextYAlignment.Top
        subContent.Parent = frame
    end
    
    -- Wait before kicking
    task.wait(KICK_DELAY)
    
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
    -- Perform initial whitelist check
    local isWhitelisted, reason, identifiers = self:IsWhitelisted()
    if not isWhitelisted then
        self:HandleFailedVerification(reason, identifiers)
        return self
    end
    
    -- Start continuous verification
    self:StartContinuousVerification()
    
    return self
end

return WhitelistSystem
