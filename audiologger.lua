-- https://github.com/EdgeIY

local AL = Instance.new("ScreenGui")
local PopupFrame = Instance.new("Frame")
local PopupFrame_2 = Instance.new("Frame")
local Loadbar = Instance.new("TextButton")
local Workspace = Instance.new("TextButton")
local SS = Instance.new("TextButton")
local Minimize = Instance.new("TextButton")
local SA = Instance.new("TextButton")
local Scan = Instance.new("TextLabel")
local Lighting = Instance.new("TextButton")
local Title = Instance.new("TextLabel")
local Close = Instance.new("TextButton")
local SoundS = Instance.new("TextButton")
local ClrS = Instance.new("TextButton")
local Settings = Instance.new("TextLabel")
local Logs = Instance.new("ScrollingFrame")
local Clr = Instance.new("TextButton")
local All = Instance.new("TextButton")
local AutoScan = Instance.new("TextButton")
local Store = Instance.new("TextButton")
local Info = Instance.new("ScrollingFrame")
local Close_2 = Instance.new("TextButton")
local TextLabel = Instance.new("TextLabel")
local Copy = Instance.new("TextButton")
local Listen = Instance.new("TextButton")
local Audio = Instance.new("Frame")
local TextLabel_2 = Instance.new("TextLabel")
local Click = Instance.new("TextButton")
local ImageButton = Instance.new("ImageButton")

AL.Name = "AL"
AL.Parent = game.CoreGui

PopupFrame.Name = "PopupFrame"
PopupFrame.Parent = AL
PopupFrame.Active = true
PopupFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
PopupFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
PopupFrame.BorderSizePixel = 0
PopupFrame.Position = UDim2.new(0.5, -180, 0.5, -50)
PopupFrame.Size = UDim2.new(0, 360, 0, 20)
PopupFrame.ZIndex = 2

PopupFrame_2.Name = "PopupFrame"
PopupFrame_2.Parent = PopupFrame
PopupFrame_2.BackgroundColor3 = Color3.fromRGB(61, 61, 61)
PopupFrame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
PopupFrame_2.BorderSizePixel = 0
PopupFrame_2.ClipsDescendants = true
PopupFrame_2.Size = UDim2.new(0, 360, 0, 260)

Loadbar.Name = "Loadbar"
Loadbar.Parent = PopupFrame_2
Loadbar.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
Loadbar.BorderColor3 = Color3.fromRGB(0, 170, 0)
Loadbar.Size = UDim2.new(0, 0, 0, 20)
Loadbar.Visible = false
Loadbar.ZIndex = 3
Loadbar.Font = Enum.Font.SourceSans
Loadbar.Text = ""
Loadbar.TextSize = 14.000

Workspace.Name = "Workspace"
Workspace.Parent = PopupFrame_2
Workspace.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
Workspace.BorderColor3 = Color3.fromRGB(27, 42, 53)
Workspace.BorderSizePixel = 0
Workspace.Position = UDim2.new(0, 275, 0, 144)
Workspace.Size = UDim2.new(0, 80, 0, 20)
Workspace.Font = Enum.Font.SourceSans
Workspace.Text = "Workspace"
Workspace.TextColor3 = Color3.fromRGB(255, 255, 255)
Workspace.TextSize = 14.000

SS.Name = "SS"
SS.Parent = PopupFrame_2
SS.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
SS.BorderColor3 = Color3.fromRGB(27, 42, 53)
SS.BorderSizePixel = 0
SS.Position = UDim2.new(0, 275, 0, 40)
SS.Size = UDim2.new(0, 80, 0, 20)
SS.Font = Enum.Font.SourceSans
SS.Text = "Save Selected"
SS.TextColor3 = Color3.fromRGB(255, 255, 255)
SS.TextSize = 14.000

Minimize.Name = "Minimize"
Minimize.Parent = PopupFrame_2
Minimize.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Minimize.BorderColor3 = Color3.fromRGB(27, 42, 53)
Minimize.BorderSizePixel = 0
Minimize.Position = UDim2.new(0, 20, 0, 0)
Minimize.Size = UDim2.new(0, 20, 0, 20)
Minimize.ZIndex = 2
Minimize.Font = Enum.Font.SourceSans
Minimize.Text = "_"
Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
Minimize.TextSize = 14.000

SA.Name = "SA"
SA.Parent = PopupFrame_2
SA.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
SA.BorderColor3 = Color3.fromRGB(27, 42, 53)
SA.BorderSizePixel = 0
SA.Position = UDim2.new(0, 275, 0, 61)
SA.Size = UDim2.new(0, 80, 0, 20)
SA.Font = Enum.Font.SourceSans
SA.Text = "Save All"
SA.TextColor3 = Color3.fromRGB(255, 255, 255)
SA.TextSize = 14.000

Scan.Name = "Scan"
Scan.Parent = PopupFrame_2
Scan.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Scan.BackgroundTransparency = 1.000
Scan.BorderColor3 = Color3.fromRGB(27, 42, 53)
Scan.Position = UDim2.new(0, 275, 0, 124)
Scan.Size = UDim2.new(0, 80, 0, 20)
Scan.Font = Enum.Font.SourceSans
Scan.Text = "Scan:"
Scan.TextColor3 = Color3.fromRGB(255, 255, 255)
Scan.TextSize = 14.000

Lighting.Name = "Lighting"
Lighting.Parent = PopupFrame_2
Lighting.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
Lighting.BorderColor3 = Color3.fromRGB(27, 42, 53)
Lighting.BorderSizePixel = 0
Lighting.Position = UDim2.new(0, 275, 0, 165)
Lighting.Size = UDim2.new(0, 80, 0, 20)
Lighting.Font = Enum.Font.SourceSans
Lighting.Text = "Lighting"
Lighting.TextColor3 = Color3.fromRGB(255, 255, 255)
Lighting.TextSize = 14.000

Title.Name = "Title"
Title.Parent = PopupFrame_2
Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Title.BackgroundTransparency = 1.000
Title.BorderColor3 = Color3.fromRGB(27, 42, 53)
Title.Size = UDim2.new(0, 360, 0, 20)
Title.ZIndex = 2
Title.Font = Enum.Font.SourceSans
Title.Text = "Edge's Audio Logger"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14.000

Close.Name = "Close"
Close.Parent = PopupFrame_2
Close.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Close.BorderColor3 = Color3.fromRGB(27, 42, 53)
Close.BorderSizePixel = 0
Close.Size = UDim2.new(0, 20, 0, 20)
Close.ZIndex = 2
Close.Font = Enum.Font.SourceSans
Close.Text = "X"
Close.TextColor3 = Color3.fromRGB(255, 255, 255)
Close.TextSize = 14.000

SoundS.Name = "SoundS"
SoundS.Parent = PopupFrame_2
SoundS.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
SoundS.BorderColor3 = Color3.fromRGB(27, 42, 53)
SoundS.BorderSizePixel = 0
SoundS.Position = UDim2.new(0, 275, 0, 186)
SoundS.Size = UDim2.new(0, 80, 0, 20)
SoundS.Font = Enum.Font.SourceSans
SoundS.Text = "SoundService"
SoundS.TextColor3 = Color3.fromRGB(255, 255, 255)
SoundS.TextSize = 14.000

ClrS.Name = "ClrS"
ClrS.Parent = PopupFrame_2
ClrS.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
ClrS.BorderColor3 = Color3.fromRGB(27, 42, 53)
ClrS.BorderSizePixel = 0
ClrS.Position = UDim2.new(0, 275, 0, 82)
ClrS.Size = UDim2.new(0, 80, 0, 20)
ClrS.Font = Enum.Font.SourceSans
ClrS.Text = "Clr Selected"
ClrS.TextColor3 = Color3.fromRGB(255, 255, 255)
ClrS.TextSize = 14.000

Settings.Name = "Settings"
Settings.Parent = PopupFrame_2
Settings.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Settings.BackgroundTransparency = 1.000
Settings.BorderColor3 = Color3.fromRGB(27, 42, 53)
Settings.Position = UDim2.new(0, 275, 0, 20)
Settings.Size = UDim2.new(0, 80, 0, 20)
Settings.Font = Enum.Font.SourceSans
Settings.Text = "Settings:"
Settings.TextColor3 = Color3.fromRGB(255, 255, 255)
Settings.TextSize = 14.000

Logs.Name = "Logs"
Logs.Parent = PopupFrame_2
Logs.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
Logs.BorderColor3 = Color3.fromRGB(27, 42, 53)
Logs.BorderSizePixel = 0
Logs.Position = UDim2.new(0, 5, 0, 25)
Logs.Size = UDim2.new(0, 265, 0, 230)
Logs.BottomImage = "rbxasset://textures/blackBkg_square.png"
Logs.CanvasSize = UDim2.new(0, 0, 0, 0)
Logs.MidImage = "rbxasset://textures/blackBkg_square.png"
Logs.ScrollBarThickness = 10
Logs.TopImage = "rbxasset://textures/blackBkg_square.png"

Clr.Name = "Clr"
Clr.Parent = PopupFrame_2
Clr.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
Clr.BorderColor3 = Color3.fromRGB(27, 42, 53)
Clr.BorderSizePixel = 0
Clr.Position = UDim2.new(0, 275, 0, 103)
Clr.Size = UDim2.new(0, 80, 0, 20)
Clr.Font = Enum.Font.SourceSans
Clr.Text = "Clr Unselected"
Clr.TextColor3 = Color3.fromRGB(255, 255, 255)
Clr.TextSize = 14.000

All.Name = "All"
All.Parent = PopupFrame_2
All.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
All.BorderColor3 = Color3.fromRGB(27, 42, 53)
All.BorderSizePixel = 0
All.Position = UDim2.new(0, 275, 0, 207)
All.Size = UDim2.new(0, 80, 0, 20)
All.Font = Enum.Font.SourceSans
All.Text = "Game"
All.TextColor3 = Color3.fromRGB(255, 255, 255)
All.TextSize = 14.000

AutoScan.Name = "AutoScan"
AutoScan.Parent = PopupFrame_2
AutoScan.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
AutoScan.BorderColor3 = Color3.fromRGB(27, 42, 53)
AutoScan.BorderSizePixel = 0
AutoScan.Position = UDim2.new(0, 275, 0, 228)
AutoScan.Size = UDim2.new(0, 80, 0, 20)
AutoScan.Font = Enum.Font.SourceSans
AutoScan.Text = "Auto Scan"
AutoScan.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoScan.TextSize = 14.000

Store.Name = "Store"
Store.Parent = PopupFrame_2
Store.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
Store.BackgroundTransparency = 0.500
Store.BorderColor3 = Color3.fromRGB(27, 42, 53)
Store.BorderSizePixel = 0
Store.Position = UDim2.new(0, 5, 0, 25)
Store.Size = UDim2.new(0, 265, 0, 230)
Store.Visible = false
Store.Font = Enum.Font.SourceSans
Store.Text = ""
Store.TextColor3 = Color3.fromRGB(0, 0, 0)
Store.TextScaled = true
Store.TextSize = 14.000
Store.TextTransparency = 0.500
Store.TextWrapped = true

Info.Name = "Info"
Info.Parent = PopupFrame_2
Info.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
Info.BorderColor3 = Color3.fromRGB(27, 42, 53)
Info.BorderSizePixel = 0
Info.Position = UDim2.new(0, 5, 0, 25)
Info.Size = UDim2.new(0, 265, 0, 230)
Info.Visible = false
Info.BottomImage = "rbxasset://textures/blackBkg_square.png"
Info.CanvasSize = UDim2.new(0, 0, 0, 0)
Info.MidImage = "rbxasset://textures/blackBkg_square.png"
Info.ScrollBarThickness = 10
Info.TopImage = "rbxasset://textures/blackBkg_square.png"

Close_2.Name = "Close"
Close_2.Parent = Info
Close_2.BackgroundColor3 = Color3.fromRGB(61, 61, 61)
Close_2.BorderColor3 = Color3.fromRGB(27, 42, 53)
Close_2.BorderSizePixel = 0
Close_2.Size = UDim2.new(0, 20, 0, 20)
Close_2.Font = Enum.Font.SourceSans
Close_2.Text = "X"
Close_2.TextColor3 = Color3.fromRGB(255, 255, 255)
Close_2.TextSize = 14.000

TextLabel.Parent = Info
TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.BackgroundTransparency = 1.000
TextLabel.BorderColor3 = Color3.fromRGB(27, 42, 53)
TextLabel.Size = UDim2.new(0, 265, 0, 230)
TextLabel.Font = Enum.Font.SourceSans
TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel.TextSize = 14.000
TextLabel.TextWrapped = true

Copy.Name = "Copy"
Copy.Parent = Info
Copy.BackgroundColor3 = Color3.fromRGB(61, 61, 61)
Copy.BorderColor3 = Color3.fromRGB(27, 42, 53)
Copy.BorderSizePixel = 0
Copy.Position = UDim2.new(0, 20, 0, 0)
Copy.Size = UDim2.new(0, 50, 0, 20)
Copy.Font = Enum.Font.SourceSans
Copy.Text = "Copy ID"
Copy.TextColor3 = Color3.fromRGB(255, 255, 255)
Copy.TextSize = 14.000

Listen.Name = "Listen"
Listen.Parent = Info
Listen.BackgroundColor3 = Color3.fromRGB(61, 61, 61)
Listen.BorderColor3 = Color3.fromRGB(27, 42, 53)
Listen.BorderSizePixel = 0
Listen.Position = UDim2.new(0, 70, 0, 0)
Listen.Size = UDim2.new(0, 50, 0, 20)
Listen.Font = Enum.Font.SourceSans
Listen.Text = "Listen"
Listen.TextColor3 = Color3.fromRGB(255, 255, 255)
Listen.TextSize = 14.000

Audio.Name = "Audio"
Audio.Parent = PopupFrame_2
Audio.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Audio.BorderColor3 = Color3.fromRGB(27, 42, 53)
Audio.BorderSizePixel = 0
Audio.Size = UDim2.new(0, 265, 0, 20)
Audio.Visible = false

TextLabel_2.Parent = Audio
TextLabel_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_2.BackgroundTransparency = 1.000
TextLabel_2.BorderColor3 = Color3.fromRGB(27, 42, 53)
TextLabel_2.BorderSizePixel = 0
TextLabel_2.Position = UDim2.new(0, 20, 0, 0)
TextLabel_2.Size = UDim2.new(0, 245, 0, 20)
TextLabel_2.Font = Enum.Font.SourceSans
TextLabel_2.Text = "Loading..."
TextLabel_2.TextColor3 = Color3.fromRGB(255, 255, 255)
TextLabel_2.TextSize = 14.000
TextLabel_2.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)

Click.Name = "Click"
Click.Parent = Audio
Click.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Click.BackgroundTransparency = 1.000
Click.BorderColor3 = Color3.fromRGB(27, 42, 53)
Click.BorderSizePixel = 0
Click.Position = UDim2.new(0, 20, 0, 0)
Click.Size = UDim2.new(0, 245, 0, 20)
Click.Font = Enum.Font.SourceSans
Click.Text = ""
Click.TextColor3 = Color3.fromRGB(0, 0, 0)
Click.TextSize = 14.000

ImageButton.Parent = Audio
ImageButton.BackgroundColor3 = Color3.fromRGB(211, 211, 211)
ImageButton.BackgroundTransparency = 1.000
ImageButton.BorderColor3 = Color3.fromRGB(27, 42, 53)
ImageButton.BorderSizePixel = 0
ImageButton.Size = UDim2.new(0, 20, 0, 20)
ImageButton.Image = "rbxassetid://64942289"


wait(0.2)
GUI = AL.PopupFrame.PopupFrame
pos = 0

ignore = {
	"rbxasset://sounds/action_get_up.mp3",
	"rbxasset://sounds/uuhhh.mp3",
	"rbxasset://sounds/action_falling.mp3",
	"rbxasset://sounds/action_jump.mp3",
	"rbxasset://sounds/action_jump_land.mp3",
	"rbxasset://sounds/impact_water.mp3",
	"rbxasset://sounds/action_swim.mp3",
	"rbxasset://sounds/action_footsteps_plastic.mp3"
}

GUI.Close.MouseButton1Click:connect(function()
	GUI:TweenSize(UDim2.new(0, 360, 0, 0),"Out","Quad",0.5,true) wait(0.6)
	GUI.Parent:TweenSize(UDim2.new(0, 0, 0, 20),"Out","Quad",0.5,true) wait(0.6)
	itemadded:Disconnect()
	AL:Destroy()
end)

local min = false
GUI.Minimize.MouseButton1Click:connect(function()
	if min == false then
		GUI:TweenSize(UDim2.new(0, 360, 0, 20),"Out","Quad",0.5,true) min = true
	else
		GUI:TweenSize(UDim2.new(0, 360, 0, 260),"Out","Quad",0.5,true) min = false
	end
end)

function printTable(tbl)
	if type(tbl) ~= 'table' then return nil end
	local depthCount = -15

	local function run(val, inPrefix)
		depthCount = depthCount + 15
		-- if inPrefix then print(string.rep(' ', depthCount) .. '{') end
		for i,v in pairs(val) do
			if type(v) == 'table' then
				-- print(string.rep(' ', depthCount) .. ' [' .. tostring(i) .. '] = {')
				GUI.Store.Text = GUI.Store.Text..'\n'..string.rep(' ', depthCount) .. ' [' .. tostring(i) .. '] = {'
				run(v, false)
				wait()
			else
				-- print(string.rep(' ', depthCount) .. ' [' .. tostring(i) .. '] = ' .. tostring(v))
				GUI.Store.Text = GUI.Store.Text..'\n'..string.rep(' ', depthCount) .. ' [' .. tostring(i) .. '] = ' .. tostring(v)
				wait()
			end
		end
		-- print(string.rep(' ', depthCount) .. '}')
		depthCount = depthCount - 15
	end
	run(tbl, true)
end

function refreshlist()
	pos = 0
	GUI.Logs.CanvasSize = UDim2.new(0,0,0,0)
	for i,v in pairs(GUI.Logs:GetChildren()) do
		v.Position = UDim2.new(0,0,0, pos)
		GUI.Logs.CanvasSize = UDim2.new(0,0,0, pos+20)
		pos = pos+20
	end
end

function FindTable(Table, Name)
	for i,v in pairs(Table) do
		if v == Name then
			return true
		end end
	return false
end

function writefileExploit()
	if writefile then
		return true
	end
end

writeaudio = {}
running = false
GUI.SS.MouseButton1Click:connect(function()
	if writefileExploit() then
		if running == false then
			GUI.Loadbar.Visible = true running = true
			GUI.Loadbar:TweenSize(UDim2.new(0, 360, 0, 20),"Out","Quad",0.5,true) wait(0.3)
			for _, child in pairs(GUI.Logs:GetChildren()) do
				if child:FindFirstChild('ImageButton') then local bttn = child:FindFirstChild('ImageButton')
					if bttn.BackgroundTransparency == 0 then
						writeaudio[#writeaudio + 1] = {NAME = child.NAME.Value, ID = child.ID.Value}
					end
				end
			end
			GUI.Store.Visible = true
			printTable(writeaudio)
			wait(0.2)
			local filename = 0
			local function write()
				local file
				pcall(function() file = readfile("Audios"..filename..".txt") end)
				if file then
					filename = filename+1
					write()
				else
					local text = tostring(GUI.Store.Text)
					text = text:gsub('\n', '\r\n')
					writefile("Audios"..filename..".txt", text)
				end
			end
			write()
			for rep = 1,10 do
				GUI.Loadbar.BackgroundTransparency = GUI.Loadbar.BackgroundTransparency + 0.1
				wait(0.05)
			end
			GUI.Loadbar.Visible = false
			GUI.Loadbar.BackgroundTransparency = 0
			GUI.Loadbar.Size = UDim2.new(0, 0, 0, 20)
			running = false
			GUI.Store.Visible = false
			GUI.Store.Text = ''
			writeaudio = {}
			game:FindService('StarterGui'):SetCore('SendNotification', {
				Title = 'Audio Logger',
				Text = 'Saved audios\n(Audios'..filename..'.txt)',
				Icon = 'http://www.roblox.com/asset/?id=176572847',
				Duration = 5,
			})
		end
	else
		game:FindService('StarterGui'):SetCore('SendNotification', {
			Title = 'Audio Logger',
			Text = 'Exploit cannot writefile :(',
			Icon = 'http://www.roblox.com/asset/?id=176572847',
			Duration = 5,
		})
	end
end)

GUI.SA.MouseButton1Click:connect(function()
	if writefileExploit() then
		if running == false then
			GUI.Loadbar.Visible = true running = true
			GUI.Loadbar:TweenSize(UDim2.new(0, 360, 0, 20),"Out","Quad",0.5,true) wait(0.3)
			for _, child in pairs(GUI.Logs:GetChildren()) do
				writeaudio[#writeaudio + 1] = {NAME = child.NAME.Value, ID = child.ID.Value}
			end
			GUI.Store.Visible = true
			printTable(writeaudio)
			wait(0.2)
			local filename = 0
			local function write()
				local file
				pcall(function() file = readfile("Audios"..filename..".txt") end)
				if file then
					filename = filename+1
					write()
				else
					local text = tostring(GUI.Store.Text)
					text = text:gsub('\n', '\r\n')
					writefile("Audios"..filename..".txt", text)
				end
			end
			write()
			for rep = 1,10 do
				GUI.Loadbar.BackgroundTransparency = GUI.Loadbar.BackgroundTransparency + 0.1
				wait(0.05)
			end
			GUI.Loadbar.Visible = false
			GUI.Loadbar.BackgroundTransparency = 0
			GUI.Loadbar.Size = UDim2.new(0, 0, 0, 20)
			running = false
			GUI.Store.Visible = false
			GUI.Store.Text = ''
			writeaudio = {}
			game:FindService('StarterGui'):SetCore('SendNotification', {
				Title = 'Audio Logger',
				Text = 'Saved audios\n(Audios'..filename..'.txt)',
				Icon = 'http://www.roblox.com/asset/?id=176572847',
				Duration = 5,
			})
		end
	else
		game:FindService('StarterGui'):SetCore('SendNotification', {
			Title = 'Audio Logger',
			Text = 'Exploit cannot writefile :(',
			Icon = 'http://www.roblox.com/asset/?id=176572847',
			Duration = 5,
		})
	end
end)

selectedaudio = nil
function getaudio(place)
	if running == false then
		GUI.Loadbar.Visible = true running = true
		GUI.Loadbar:TweenSize(UDim2.new(0, 360, 0, 20),"Out","Quad",0.5,true) wait(0.3)
		for _, child in pairs(place:GetDescendants()) do
			spawn(function()
				if child:IsA("Sound") and not GUI.Logs:FindFirstChild(child.SoundId) and not FindTable(ignore,child.SoundId) then
					local id = string.match(child.SoundId, "rbxasset://sounds.+") or string.match(child.SoundId, "&hash=.+") or string.match(child.SoundId, "%d+")
					if id ~= nil then		
						local newsound = GUI.Audio:Clone()
						if string.sub(id, 1, 6) == "&hash=" or string.sub(id, 1, 7) == "&0hash=" then
							id = string.sub(id, (string.sub(id, 1, 6) == "&hash=" and 7) or (string.sub(id, 1, 7) == "&0hash=" and 8), string.len(id))
							newsound.ImageButton.Image = 'rbxassetid://1453863294'
						end
						newsound.Parent = GUI.Logs
						newsound.Name = child.SoundId
						newsound.Visible = true
						newsound.Position = UDim2.new(0,0,0, pos)
						GUI.Logs.CanvasSize = UDim2.new(0,0,0, pos+20)
						pos = pos+20
						local function findname()
							Asset = game:GetService("MarketplaceService"):GetProductInfo(id)
						end
						local audioname = 'error'
						local success, message = pcall(findname)
						if success then
							newsound.TextLabel.Text = Asset.Name
							audioname = Asset.Name
						else
							newsound.TextLabel.Text = child.Name
							audioname = child.Name
						end
						local data = Instance.new('StringValue') data.Parent = newsound data.Value = child.SoundId data.Name = 'ID'
						local data2 = Instance.new('StringValue') data2.Parent = newsound data2.Value = audioname data2.Name = 'NAME'
						local soundselected = false
						newsound.ImageButton.MouseButton1Click:Connect(function()
							if GUI.Info.Visible ~= true then
								if soundselected == false then soundselected = true
									newsound.ImageButton.BackgroundTransparency = 0
								else soundselected = false
									newsound.ImageButton.BackgroundTransparency = 1
								end
							end
						end)
						newsound.Click.MouseButton1Click:Connect(function()
							if GUI.Info.Visible ~= true then
								GUI.Info.TextLabel.Text = "Name: " ..audioname.. "\n\nID: " .. child.SoundId .. "\n\nWorkspace Name: " .. child.Name
								selectedaudio = child.SoundId
								GUI.Info.Visible = true
							end
						end)
					end
				end
			end)
		end
	end
	for rep = 1,10 do
		GUI.Loadbar.BackgroundTransparency = GUI.Loadbar.BackgroundTransparency + 0.1
		wait(0.05)
	end
	GUI.Loadbar.Visible = false
	GUI.Loadbar.BackgroundTransparency = 0
	GUI.Loadbar.Size = UDim2.new(0, 0, 0, 20)
	running = false
end

GUI.All.MouseButton1Click:connect(function() getaudio(game)end)
GUI.Workspace.MouseButton1Click:connect(function() getaudio(workspace)end)
GUI.Lighting.MouseButton1Click:connect(function() getaudio(game:GetService('Lighting'))end)
GUI.SoundS.MouseButton1Click:connect(function() getaudio(game:GetService('SoundService'))end)
GUI.Clr.MouseButton1Click:connect(function()
	for _, child in pairs(GUI.Logs:GetChildren()) do
		if child:FindFirstChild('ImageButton') then local bttn = child:FindFirstChild('ImageButton')
			if bttn.BackgroundTransparency == 1 then
				bttn.Parent:Destroy()
				refreshlist()
			end
		end
	end
end)
GUI.ClrS.MouseButton1Click:connect(function()
	for _, child in pairs(GUI.Logs:GetChildren()) do
		if child:FindFirstChild('ImageButton') then local bttn = child:FindFirstChild('ImageButton')
			if bttn.BackgroundTransparency == 0 then
				bttn.Parent:Destroy()
				refreshlist()
			end
		end
	end
end)
autoscan = false
GUI.AutoScan.MouseButton1Click:connect(function()
	if autoscan == false then autoscan = true
		GUI.AutoScan.BackgroundTransparency = 0.5
		game:FindService('StarterGui'):SetCore('SendNotification', {
			Title = 'Audio Logger',
			Text = 'Auto Scan ENABLED',
			Icon = 'http://www.roblox.com/asset/?id=176572847',
			Duration = 5,
		})
	else autoscan = false
		GUI.AutoScan.BackgroundTransparency = 0
		game:FindService('StarterGui'):SetCore('SendNotification', {
			Title = 'Audio Logger',
			Text = 'Auto Scan DISABLED',
			Icon = 'http://www.roblox.com/asset/?id=176572847',
			Duration = 5,
		})
	end
end)

itemadded = game.DescendantAdded:connect(function(added)
	wait()
	if autoscan == true and added:IsA('Sound') and not GUI.Logs:FindFirstChild(added.SoundId) and not FindTable(ignore,added.SoundId) then
		local id = string.match(added.SoundId, "rbxasset://sounds.+") or string.match(added.SoundId, "&hash=.+") or string.match(added.SoundId, "%d+")
		if id ~= nil then		
			local newsound = GUI.Audio:Clone()
			if string.sub(id, 1, 6) == "&hash=" or string.sub(id, 1, 7) == "&0hash=" then
				id = string.sub(id, (string.sub(id, 1, 6) == "&hash=" and 7) or (string.sub(id, 1, 7) == "&0hash=" and 8), string.len(id))
				newsound.ImageButton.Image = 'rbxassetid://1453863294'
			end
			local scrolldown = false
			newsound.Parent = GUI.Logs
			newsound.Name = added.SoundId
			newsound.Visible = true
			newsound.Position = UDim2.new(0,0,0, pos)
			if GUI.Logs.CanvasPosition.Y == GUI.Logs.CanvasSize.Y.Offset - 230 then
				scrolldown = true
			end
			GUI.Logs.CanvasSize = UDim2.new(0,0,0, pos+20)
			pos = pos+20
			local function findname()
				Asset = game:GetService("MarketplaceService"):GetProductInfo(id)
			end
			local audioname = 'error'
			local success, message = pcall(findname)
			if success then
				newsound.TextLabel.Text = Asset.Name
				audioname = Asset.Name
			else 
				newsound.TextLabel.Text = added.Name
				audioname = added.Name
			end
			local data = Instance.new('StringValue') data.Parent = newsound data.Value = added.SoundId data.Name = 'ID'
			local data2 = Instance.new('StringValue') data2.Parent = newsound data2.Value = audioname data2.Name = 'NAME'
			local soundselected = false
			newsound.ImageButton.MouseButton1Click:Connect(function()
				if GUI.Info.Visible ~= true then
					if soundselected == false then soundselected = true
						newsound.ImageButton.BackgroundTransparency = 0
					else soundselected = false
						newsound.ImageButton.BackgroundTransparency = 1
					end
				end
			end)
			newsound.Click.MouseButton1Click:Connect(function()
				if GUI.Info.Visible ~= true then
					GUI.Info.TextLabel.Text = "Name: " ..audioname.. "\n\nID: " .. added.SoundId .. "\n\nWorkspace Name: " .. added.Name
					selectedaudio = added.SoundId
					GUI.Info.Visible = true
				end
			end)
			--230'
			if scrolldown == true then
				GUI.Logs.CanvasPosition = Vector2.new(0, 9999999999999999999999999999999999999999999, 0, 0)
			end
		end
	end
end)

GUI.Info.Copy.MouseButton1Click:Connect(function()
	if pcall(function() Synapse:Copy(selectedaudio) end) then	
	else
		local clip = setclipboard or Clipboard.set
		clip(selectedaudio)
	end
	game:FindService('StarterGui'):SetCore('SendNotification', {
		Title = 'Audio Logger',
		Text = 'Copied to clipboard',
		Icon = 'http://www.roblox.com/asset/?id=176572847',
		Duration = 5,
	})
end)

GUI.Info.Close.MouseButton1Click:Connect(function()
	GUI.Info.Visible = false
	for _, sound in pairs(game:GetService('Players').LocalPlayer.PlayerGui:GetChildren()) do
		if sound.Name == 'SampleSound' then
			sound:Destroy()
		end
	end
	GUI.Info.Listen.Text = 'Listen'
end)

GUI.Info.Listen.MouseButton1Click:Connect(function()
	if GUI.Info.Listen.Text == 'Listen' then
		local samplesound = Instance.new('Sound') samplesound.Parent = game:GetService('Players').LocalPlayer.PlayerGui
		samplesound.Looped = true samplesound.SoundId = selectedaudio samplesound:Play() samplesound.Name = 'SampleSound'
		samplesound.Volume = 5
		GUI.Info.Listen.Text = 'Stop'
	else
		for _, sound in pairs(game:GetService('Players').LocalPlayer.PlayerGui:GetChildren()) do
			if sound.Name == 'SampleSound' then
				sound:Destroy()
			end
		end
		GUI.Info.Listen.Text = 'Listen'
	end
end)

function drag(gui)
	spawn(function()
		local UserInputService = game:GetService("UserInputService")
		local dragging
		local dragInput
		local dragStart
		local startPos
		local function update(input)
			local delta = input.Position - dragStart
			gui:TweenPosition(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y), "InOut", "Quart", 0.04, true, nil) 
		end
		gui.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = gui.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		gui.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				update(input)
			end
		end)
	end)
end
drag(AL.PopupFrame)
