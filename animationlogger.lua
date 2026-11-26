-- https://github.com/luarsky/animationlogger

-- https://github.com/luarsky
-- Credits to Tiffblocks for drag system
-- Inspired by https://www.youtube.com/watch?v=07Zhq5VR5dk

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Plrs = game:GetService("Players")
local Plr = Plrs.LocalPlayer
local RunService = game:GetService("RunService")
local CoreGui
if RunService:IsStudio() then
	CoreGui = Plr.PlayerGui
else
	CoreGui = game:GetService("CoreGui")
end
local Camera = workspace.CurrentCamera

if Camera.ViewportSize == Vector2.new(1,1) then
	Camera:GetPropertyChangedSignal("ViewportSize"):Wait()
end

if CoreGui:FindFirstChild("AnimationLogger") then
	local CurrentAnimLogger: ScreenGui = CoreGui.AnimationLogger
	CurrentAnimLogger:Destroy()
end

local function CreateInstance(InstanceClass: string, Properties)
	local NewInstance = Instance.new(InstanceClass)
	for PropertyName: string, PropertyValue in pairs(Properties) do
		NewInstance[PropertyName] = PropertyValue
	end
	return NewInstance
end

local AnimLogger: ScreenGui = CreateInstance("ScreenGui",{Name="AnimationLogger",ClipToDeviceSafeArea=false,DisplayOrder=999999999,IgnoreGuiInset=true,ResetOnSpawn=false,ZIndexBehavior="Sibling",Parent=CoreGui})
local BaseXPosOffset = Camera.ViewportSize.X/2-425/2
local BaseYPosOffset = Camera.ViewportSize.Y/2-275/2
local Base: Frame = CreateInstance("Frame",{Name="Base",BackgroundTransparency=1,Size=UDim2.fromOffset(425,20),ClipsDescendants=true,Position=UDim2.fromOffset(BaseXPosOffset, BaseYPosOffset),Parent=AnimLogger})
local TitleHolder: Frame = CreateInstance("Frame",{Name="TitleHolder",BackgroundColor3=Color3.fromRGB(40,40,40),BorderSizePixel=0,Size=UDim2.fromOffset(425,20),Parent=Base})
local CloseAnimLogger: TextButton = CreateInstance("TextButton",{Name="Close",BackgroundColor3=Color3.fromRGB(40,40,40),BorderSizePixel=0,Position=UDim2.fromOffset(405,0),Size=UDim2.fromOffset(20,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Italic),Text="x",TextColor3=Color3.fromRGB(255,0,0),TextSize=17,Parent=TitleHolder})
local CollapseAnimLogger: TextButton = CreateInstance("TextButton",{Name="Collapse",BackgroundColor3=Color3.fromRGB(40,40,40),BorderSizePixel=0,Position=UDim2.fromOffset(385,0),Size=UDim2.fromOffset(20,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Italic),Text="_",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=TitleHolder})
local MainTitle: TextLabel = CreateInstance("TextLabel",{Name="Title",BackgroundTransparency=1,Size=UDim2.fromOffset(385,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Italic),Text="Animation Logger",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=TitleHolder})
local ContentHolder: Frame = CreateInstance("Frame",{Name="ContentHolder",BackgroundColor3=Color3.fromRGB(61,61,61),BorderSizePixel=0,Position=UDim2.fromOffset(0,20),Size=UDim2.fromOffset(425,255),Parent=Base})
local GrabOptions: Frame = CreateInstance("Frame",{Name="Options",BackgroundTransparency=1,Position=UDim2.fromOffset(5,5),Size=UDim2.fromOffset(115,245),Parent=ContentHolder})
local GrabOptionsSettings: Frame = CreateInstance("Frame",{Name="Settings",BackgroundTransparency=1,Size=UDim2.fromOffset(115,112),Parent=GrabOptions})
local GrabOptionsSettingsUIListLayout: UIListLayout = CreateInstance("UIListLayout",{Padding=UDim.new(0,3),SortOrder="LayoutOrder",HorizontalAlignment="Center",Parent=GrabOptionsSettings})
local GrabOptionsSettingsTitle: TextLabel = CreateInstance("TextLabel",{Name="Title",BackgroundTransparency=1,Size=UDim2.fromOffset(115,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Italic),Text="settings:",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=GrabOptionsSettings})
local GrabOptionsSettingsSaveSelected: TextButton = CreateInstance("TextButton",{Name="SaveSelected",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Size=UDim2.fromOffset(115,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Normal),Text="save selected",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=GrabOptionsSettings})
local GrabOptionsSettingsSaveAll: TextButton = CreateInstance("TextButton",{Name="SaveAll",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Size=UDim2.fromOffset(115,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Normal),Text="save all",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=GrabOptionsSettings})
local GrabOptionsSettingsClearSelected: TextButton = CreateInstance("TextButton",{Name="ClearSelected",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Size=UDim2.fromOffset(115,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Normal),Text="clear selected",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=GrabOptionsSettings})
local GrabOptionsSettingsClearAll: TextButton = CreateInstance("TextButton",{Name="ClearAll",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Size=UDim2.fromOffset(115,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Normal),Text="clear all",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=GrabOptionsSettings})
local GrabOptionsScan: Frame = CreateInstance("Frame",{Name="Scan",BackgroundTransparency=1,Position=UDim2.fromOffset(0,115),Size=UDim2.fromOffset(115,112),Parent=GrabOptions})
local GrabOptionsScanUIListLayout: UIListLayout = CreateInstance("UIListLayout",{Padding=UDim.new(0,3),SortOrder="LayoutOrder",HorizontalAlignment="Center",Parent=GrabOptionsScan})
local GrabOptionsScanTitle: TextLabel = CreateInstance("TextLabel",{Name="Title",BackgroundTransparency=1,Size=UDim2.fromOffset(115,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Italic),Text="scan:",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=GrabOptionsScan})
local GrabOptionsScanYourself: TextButton = CreateInstance("TextButton",{Name="Yourself",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Size=UDim2.fromOffset(115,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Normal),Text="yourself",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=GrabOptionsScan})
local GrabOptionsScanPlayers: TextButton = CreateInstance("TextButton",{Name="Players",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Size=UDim2.fromOffset(115,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Normal),Text="players",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=GrabOptionsScan})
local GrabOptionsScanSelected: TextButton = CreateInstance("TextButton",{Name="Selected",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Size=UDim2.fromOffset(115,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Normal),Text="selected",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=GrabOptionsScan})
local GrabOptionsScanAll: TextButton = CreateInstance("TextButton",{Name="All",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Size=UDim2.fromOffset(115,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Normal),Text="all",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=GrabOptionsScan})
local GrabResults: Frame = CreateInstance("Frame",{Name="Results",BackgroundColor3=Color3.fromRGB(50,50,50),BorderSizePixel=0,Position=UDim2.fromOffset(125,5),Size=UDim2.fromOffset(295,245),ClipsDescendants=true,Parent=ContentHolder})
local ScrollBarVisualHolder: Frame = CreateInstance("Frame",{Name="ScrollBarVisualHolder",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Position=UDim2.fromOffset(5,5),Size=UDim2.fromOffset(10,235),Parent=GrabResults})
local ResultsList: ScrollingFrame = CreateInstance("ScrollingFrame",{Name="List",BackgroundTransparency=1,Position=UDim2.fromOffset(5,5),Size=UDim2.fromOffset(285,235),ClipsDescendants=false,AutomaticCanvasSize="Y",BottomImage="rbxasset://textures/ui/Scroll/scroll-middle.png",CanvasSize=UDim2.fromOffset(0,0),ElasticBehavior="Never",ScrollBarThickness=10,ScrollingDirection="Y",TopImage="rbxasset://textures/ui/Scroll/scroll-middle.png",VerticalScrollBarPosition="Left",Parent=GrabResults})
local ResultsListUIListLayout: UIListLayout = CreateInstance("UIListLayout",{SortOrder="LayoutOrder",HorizontalAlignment="Right",Parent=ResultsList})
local AnimationInfoDisplay: Frame = CreateInstance("Frame",{Visible=false,Name="InfoDisplay",BackgroundTransparency=1,Position=UDim2.fromOffset(5,5),Size=UDim2.fromOffset(285,235),Parent=GrabResults})
local CloseAnimationInfoDisplay: TextButton = CreateInstance("TextButton",{Name="Close",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Position=UDim2.fromOffset(265,0),Size=UDim2.fromOffset(20,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Italic),Text="x",TextColor3=Color3.fromRGB(255,0,0),TextSize=17,Parent=AnimationInfoDisplay})
local CopyAnimationID: TextButton = CreateInstance("TextButton",{Name="CopyID",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Position=UDim2.fromOffset(190,0),Size=UDim2.fromOffset(75,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Italic),Text="copy ID",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=AnimationInfoDisplay})
local AnimationDescription: Frame = CreateInstance("Frame",{Name="AnimationDescription",BackgroundTransparency=1,Position=UDim2.fromOffset(0,25),Size=UDim2.fromOffset(285,60),ClipsDescendants=true,Parent=AnimationInfoDisplay})
local AnimationDescriptionUIListLayout: UIListLayout = CreateInstance("UIListLayout",{SortOrder="LayoutOrder",Parent=AnimationDescription})
local AnimMarketplaceName: TextLabel = CreateInstance("TextLabel",{Name="MarketplaceName",BackgroundTransparency=1,Size=UDim2.fromOffset(285,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Normal),Text="Marketplace Name: ?",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,TextXAlignment="Left",Parent=AnimationDescription})
local AnimGameName: TextLabel = CreateInstance("TextLabel",{Name="GameName",BackgroundTransparency=1,Size=UDim2.fromOffset(285,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Normal),Text="Game Name: ?",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,TextXAlignment="Left",Parent=AnimationDescription})
local AnimID: TextLabel = CreateInstance("TextLabel",{Name="ID",BackgroundTransparency=1,Size=UDim2.fromOffset(285,20),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Normal),Text="ID: ?",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,TextXAlignment="Left",Parent=AnimationDescription})
local RunAnimTrackOptions: Frame = CreateInstance("Frame",{Name="RunOptions",BackgroundTransparency=1,Position=UDim2.fromOffset(0,90),Size=UDim2.fromOffset(285,145),Parent=AnimationInfoDisplay})
local AnimTrackFunctions: Frame = CreateInstance("Frame",{Name="AnimationTrackFunctions",BackgroundTransparency=1,Size=UDim2.fromOffset(285,30),Parent=RunAnimTrackOptions})
local AnimTrackFunctionsUIListLayout: UIListLayout = CreateInstance("UIListLayout",{Padding=UDim.new(0,10),FillDirection="Horizontal",SortOrder="LayoutOrder",HorizontalAlignment="Center",VerticalAlignment="Center",Parent=AnimTrackFunctions})
local PlayAnimTrack: TextButton = CreateInstance("TextButton",{Name="Play",BackgroundColor3=Color3.fromRGB(0,242,0),BorderSizePixel=0,Size=UDim2.fromOffset(80,30),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Bold,Enum.FontStyle.Italic),Text="play",TextColor3=Color3.fromRGB(0,0,0),TextSize=20,Parent=AnimTrackFunctions})
local PauseAndResumeAnimTrack: TextButton = CreateInstance("TextButton",{Name="Pause&Resume",BackgroundColor3=Color3.fromRGB(243,243,2),BorderSizePixel=0,Size=UDim2.fromOffset(80,30),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Bold,Enum.FontStyle.Italic),Text="pause",TextColor3=Color3.fromRGB(0,0,0),TextSize=20,Parent=AnimTrackFunctions})
local StopAnimTrack: TextButton = CreateInstance("TextButton",{Name="Stop",BackgroundColor3=Color3.fromRGB(241,0,0),BorderSizePixel=0,Size=UDim2.fromOffset(80,30),FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Bold,Enum.FontStyle.Italic),Text="stop",TextColor3=Color3.fromRGB(0,0,0),TextSize=20,Parent=AnimTrackFunctions})
local Sliders: Frame = CreateInstance("Frame",{Name="Sliders",BackgroundTransparency=1,Position=UDim2.fromOffset(0,40),Size=UDim2.fromOffset(285,105),Parent=RunAnimTrackOptions})
local SlidersUIListLayout: UIListLayout = CreateInstance("UIListLayout",{Padding=UDim.new(0,20),SortOrder="LayoutOrder",HorizontalAlignment="Center",VerticalAlignment="Center",Parent=Sliders})
local SpeedSlider: Frame = CreateInstance("Frame",{Name="SpeedSlider",BackgroundTransparency=1,Size=UDim2.fromOffset(285,30),Parent=Sliders})
local SpeedSliderBar: Frame = CreateInstance("Frame",{Name="SliderBar",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Position=UDim2.fromOffset(0,10),Size=UDim2.fromOffset(200,10),Parent=SpeedSlider})
local SpeedSliderButton: TextButton = CreateInstance("TextButton",{Name="Slider",BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Position=UDim2.fromOffset(0,-10),Size=UDim2.fromOffset(5,30),Text="",Parent=SpeedSliderBar})
local SpeedBox: TextBox = CreateInstance("TextBox",{Name="SpeedBox",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Position=UDim2.fromOffset(205,0),Size=UDim2.fromOffset(80,30),ClipsDescendants=true,FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Normal),PlaceholderText="0x",Text="",TextColor3=Color3.fromRGB(255,255,255),TextSize=20,Parent=SpeedSlider})
local TimePosSlider: Frame = CreateInstance("Frame",{Name="TimePosSlider",BackgroundTransparency=1,Size=UDim2.fromOffset(285,30),Parent=Sliders})
local TimePosSliderBar: Frame = CreateInstance("Frame",{Name="SliderBar",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Position=UDim2.fromOffset(0,10),Size=UDim2.fromOffset(200,10),Parent=TimePosSlider})
local TimePosSliderButton: TextButton = CreateInstance("TextButton",{Name="Slider",BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0,Position=UDim2.fromOffset(0,-10),Size=UDim2.fromOffset(5,30),Text="",Parent=TimePosSliderBar})
local TimePosBox: TextBox = CreateInstance("TextBox",{Name="TimePosBox",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Position=UDim2.fromOffset(205,0),Size=UDim2.fromOffset(80,30),ClipsDescendants=true,FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Normal),PlaceholderText="0s",Text="",TextColor3=Color3.fromRGB(255,255,255),TextSize=20,Parent=TimePosSlider})

local TweenService = game:GetService("TweenService")
TweenService:Create(Base, TweenInfo.new(.5, Enum.EasingStyle.Linear), {Size=UDim2.fromOffset(425,275)}):Play()
task.wait(.5)

local StarterGui = game:FindService("StarterGui")
local function MakeNotify(NotifyTitle: string, NotifyText: string, NotifyIcon: string, NotifyDuration: number)
	StarterGui:SetCore("SendNotification", {
		Title = NotifyTitle,
		Text = NotifyText,
		Icon = NotifyIcon,
		Duration = NotifyDuration
	})
end
MakeNotify("Animation Logger", "Loaded!", "http://www.roblox.com/asset/?id=131006790482868", 3)

local UIS = game:GetService("UserInputService")
local dragging
local dragInput
local dragStart
local startPos

local function updateMainGui(input)
	local delta = input.Position - dragStart
	Base.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

MainTitle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Base.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

MainTitle.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		updateMainGui(input)
	end
end)

local CollapseHideTween
local CollapseShowTween
local Collapsed = false
local InCollapsing = false
local Closing = false

CollapseAnimLogger.MouseButton1Click:Connect(function()
	if Closing then return end
	InCollapsing = true
	if not Collapsed then
		Collapsed = true
		if CollapseShowTween then
			CollapseShowTween:Pause()
		end
		if CollapseHideTween then
			CollapseHideTween:Cancel()
		end
		CollapseHideTween = TweenService:Create(Base, TweenInfo.new(.5, Enum.EasingStyle.Linear), {Size=UDim2.fromOffset(425,20)})
		CollapseHideTween:Play()
		CollapseHideTween.Completed:Wait()
	else
		Collapsed = false
		if CollapseHideTween then
			CollapseHideTween:Pause()
		end
		if CollapseShowTween then
			CollapseShowTween:Cancel()
		end
		CollapseShowTween = TweenService:Create(Base, TweenInfo.new(.5, Enum.EasingStyle.Linear), {Size=UDim2.fromOffset(425,275)})
		CollapseShowTween:Play()
		CollapseShowTween.Completed:Wait()
	end
	InCollapsing = false
end)

local ScanMode = "None"
local MarketplaceService = game:GetService("MarketplaceService")
local IgnoreIDs = {}
local ScanningAnimators = {}
local Mouse = Plr:GetMouse()
local AnimSelectionConnection
local AnimChoosingConnection
local AnimObjectSelectionHighlightTween
local AnimSelectedRig
local AnimSelectedRigRemovingConnection
local AnimObjectSelectionHighlight: Highlight?

local function GetCharFromMouseTarget(MouseTarget: BasePart?)
	if not MouseTarget then return end
	local CharFromMouseTarget: Model? = MouseTarget.Parent
	if not CharFromMouseTarget:FindFirstChildWhichIsA("Humanoid") and not CharFromMouseTarget:FindFirstChildWhichIsA("Animator") and CharFromMouseTarget ~= game then
		repeat
			CharFromMouseTarget = CharFromMouseTarget.Parent
		until CharFromMouseTarget:FindFirstChildWhichIsA("Humanoid") or CharFromMouseTarget:FindFirstChildWhichIsA("Animator") or CharFromMouseTarget == game
	end
	return CharFromMouseTarget
end

local function StopAnimSelection()
	if AnimObjectSelectionHighlightTween then
		AnimObjectSelectionHighlightTween:Cancel()
	end
	if AnimSelectionConnection then
		AnimSelectionConnection:Disconnect()
	end
	if AnimChoosingConnection then
		AnimChoosingConnection:Disconnect()
	end
	if AnimSelectedRigRemovingConnection then
		AnimSelectedRigRemovingConnection:Disconnect()
	end
	if AnimObjectSelectionHighlight then
		AnimObjectSelectionHighlight:Destroy()
	end
end

for _, Kid in pairs(GrabOptionsScan:GetChildren()) do
	if not Kid:IsA("TextButton") then continue end
	Kid.MouseButton1Click:Connect(function()
		for _, OtherButton in pairs(GrabOptionsScan:GetChildren()) do
			if not OtherButton:IsA("TextButton") then continue end
			OtherButton.TextColor3 = Color3.fromRGB(255,255,255)
		end
		if Kid == GrabOptionsScanYourself then
			if ScanMode ~= "Yourself" then
				ScanMode = "Yourself"
				Kid.TextColor3 = Color3.fromRGB(0,255,127)
			else
				ScanMode = "None"
			end
		elseif Kid == GrabOptionsScanPlayers then
			if ScanMode ~= "Players" then
				ScanMode = "Players"
				Kid.TextColor3 = Color3.fromRGB(0,255,127)
			else
				ScanMode = "None"
			end
		elseif Kid == GrabOptionsScanSelected then
			if ScanMode ~= "Selected" then
				ScanMode = "Selected"
				Kid.TextColor3 = Color3.fromRGB(0,255,127)
				MakeNotify("Animation Logger", "Select rig!", "http://www.roblox.com/asset/?id=88461527259893", 5)
				StopAnimSelection()
				AnimObjectSelectionHighlight = CreateInstance("Highlight",{Name="AnimObjectSelection",FillColor=Color3.fromRGB(48,180,252)})
				AnimObjectSelectionHighlightTween = TweenService:Create(AnimObjectSelectionHighlight, TweenInfo.new(.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {FillTransparency=.75,OutlineTransparency=.5})
				AnimObjectSelectionHighlightTween:Play()
				local CharFromMouseTarget: Model?
				AnimSelectionConnection = RunService.RenderStepped:Connect(function()
					Mouse.TargetFilter = Plr.Character
					CharFromMouseTarget = GetCharFromMouseTarget(Mouse.Target)
					if not CharFromMouseTarget or CharFromMouseTarget == game then
						AnimObjectSelectionHighlight.Parent = nil
						return
					end
					AnimObjectSelectionHighlight.Parent = CharFromMouseTarget
				end)
				AnimChoosingConnection = Mouse.Button1Down:Connect(function()
					if not CharFromMouseTarget or CharFromMouseTarget == game then return end
					AnimChoosingConnection:Disconnect()
					AnimSelectionConnection:Disconnect()
					AnimObjectSelectionHighlightTween:Cancel()
					AnimObjectSelectionHighlight.FillTransparency = .5
					AnimObjectSelectionHighlight.OutlineTransparency = 0
					AnimSelectedRig = CharFromMouseTarget
					MakeNotify("Animation Logger", "Rig selected - " .. AnimSelectedRig.Name .. "!", "http://www.roblox.com/asset/?id=88461527259893", 5)
					AnimSelectedRigRemovingConnection = AnimSelectedRig.Destroying:Once(function()
						AnimSelectedRig = nil
					end)
				end)
			else
				StopAnimSelection()
				ScanMode = "None"
			end
		elseif Kid == GrabOptionsScanAll then
			if ScanMode ~= "All" then
				ScanMode = "All"
				Kid.TextColor3 = Color3.fromRGB(0,255,127)
			else
				ScanMode = "None"
			end
		end
	end)
end

local function CheckAnimationMatching(CheckID: number)
	local MatchedAnimStatus = false
	if table.find(IgnoreIDs, CheckID) then
		MatchedAnimStatus = true
	end
	for _, TakenAnim in pairs(ResultsList:GetChildren()) do
		if TakenAnim.Name ~= "Animation_" .. tostring(CheckID) then continue end
		MatchedAnimStatus = true
		break
	end
	return MatchedAnimStatus
end

local function GetAnimators(instance: Instance)
	if not instance then return end
	if instance:IsA("Animator") then
		table.insert(ScanningAnimators, instance)
		return
	end
	local instanceAnimator
	for _, Kid in pairs(instance:GetDescendants()) do
		if not Kid:IsA("Animator") then continue end
		instanceAnimator = Kid
		break
	end
	table.insert(ScanningAnimators, instanceAnimator)
end

RunService.RenderStepped:Connect(function()
	table.clear(ScanningAnimators)
	if ScanMode == "Yourself" then
		GetAnimators(Plr.Character)
	elseif ScanMode == "Players" then
		for _, ScanningPlr in pairs(Plrs:GetPlayers()) do
			if ScanningPlr == Plr then continue end
			GetAnimators(ScanningPlr.Character)
		end
	elseif ScanMode == "Selected" then
		GetAnimators(AnimSelectedRig)
	elseif ScanMode == "All" then
		for _, Kid in pairs(workspace:GetDescendants()) do
			if not Kid:IsA("Animator") then continue end
			GetAnimators(Kid)
		end
	end
	for _, ScanningAnimator in pairs(ScanningAnimators) do
		local PlayingAnimTracks = ScanningAnimator:GetPlayingAnimationTracks()
		for _, PlayingAnimTrack: AnimationTrack in pairs(PlayingAnimTracks) do
			local PlayingAnimTrackAnimationObject = PlayingAnimTrack.Animation
			local PlayingAnimTrackAnimationID, i = PlayingAnimTrackAnimationObject.AnimationId:gsub("%D", "")
			PlayingAnimTrackAnimationID = tonumber(PlayingAnimTrackAnimationID)
			--[[if not string.match(PlayingAnimTrackAnimationObject.AnimationId, "rbxassetid://") then
				if not table.find(IgnoreIDs, PlayingAnimTrackAnimationID) then
					table.insert(IgnoreIDs, PlayingAnimTrackAnimationID)
				end
			end]]
			local HasMatchedTakenAnim = CheckAnimationMatching(PlayingAnimTrackAnimationID)
			if HasMatchedTakenAnim then continue end
			local NewTakenAnim: Frame = CreateInstance("Frame",{Name="Animation_"..tostring(PlayingAnimTrackAnimationID),BackgroundTransparency=1,Size=UDim2.fromOffset(270,20),Parent=ResultsList})
			local SelectTakenAnim: TextButton = CreateInstance("TextButton",{Name="Select",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Position=UDim2.fromOffset(250,0),Size=UDim2.fromOffset(20,20),Text="",Parent=NewTakenAnim})
			local SelectTakenAnimIcon: ImageLabel = CreateInstance("ImageLabel",{Name="Icon",BackgroundTransparency=1,Position=UDim2.fromOffset(2,2),Size=UDim2.fromOffset(16,16),Image="http://www.roblox.com/asset/?id=131006790482868",Parent=SelectTakenAnim})
			local TakenAnimInfo: TextButton = CreateInstance("TextButton",{Name="Info",BackgroundColor3=Color3.fromRGB(113,113,113),BorderSizePixel=0,Size=UDim2.fromOffset(250,20),Text="",Parent=NewTakenAnim})
			local TakenAnimInfoTitle: TextLabel = CreateInstance("TextLabel",{Name="Title",BackgroundTransparency=1,Position=UDim2.fromOffset(5,2),Size=UDim2.fromOffset(240,16),ClipsDescendants=true,FontFace=Font.fromName("ComicNeueAngular",Enum.FontWeight.Regular,Enum.FontStyle.Italic),Text="Loading...",TextXAlignment="Left",TextColor3=Color3.fromRGB(255,255,255),TextSize=17,Parent=TakenAnimInfo})
			local AnimNameFromMarketplace = "Error loading name!"
			local AnimMarketplaceInfo
			pcall(function()
				AnimMarketplaceInfo = MarketplaceService:GetProductInfo(PlayingAnimTrackAnimationID, "Asset")
			end)
			AnimNameFromMarketplace = AnimMarketplaceInfo["Name"]
			TakenAnimInfoTitle.Text = AnimNameFromMarketplace
			SelectTakenAnim.MouseButton1Click:Connect(function()
				if SelectTakenAnimIcon.ImageColor3 == Color3.fromRGB(255,255,255) then
					SelectTakenAnimIcon.ImageColor3 = Color3.fromRGB(48,180,252)
				else
					SelectTakenAnimIcon.ImageColor3 = Color3.fromRGB(255,255,255)
				end
			end)
			TakenAnimInfo.MouseButton1Click:Connect(function()
				ResultsList.Visible = false
				ScrollBarVisualHolder.Visible = false
				AnimationInfoDisplay.Visible = true
				AnimGameName.Text = "Game Name: " .. PlayingAnimTrackAnimationObject.Name
				AnimID.Text = "ID: " .. tostring(PlayingAnimTrackAnimationID)
				AnimMarketplaceName.Text = "Marketplace Name: " .. AnimNameFromMarketplace
			end)
		end
	end
end)

local function GetTakenAnimations(Mode: string)
	local TakenAnimations = {}
	for _, Kid in pairs(ResultsList:GetChildren()) do
		if not Kid:IsA("Frame") then continue end
		if Mode == "Selected" then
			local SelectIcon: ImageLabel = Kid.Select.Icon
			if SelectIcon.ImageColor3 ~= Color3.fromRGB(48,180,252) then continue end
			table.insert(TakenAnimations, Kid)
		elseif Mode == "All" then
			table.insert(TakenAnimations, Kid)
		end
	end
	return TakenAnimations
end

local function SaveAnimation(TakenAnimID: number)
	local filename = tostring(TakenAnimID)
	local function write()
		local file
		pcall(function() file = readfile("Animation_"..filename..".txt") end)
		if file then
			write()
		else
			local text = "Animation ID: " .. tostring(TakenAnimID)
			text = text:gsub('\n', '\r\n')
			writefile("Animation_"..filename..".txt", text)
		end
	end
	write()
end

GrabOptionsSettingsSaveSelected.MouseButton1Click:Connect(function()
	if RunService:IsStudio() then return end
	local TakenAnimations = GetTakenAnimations("Selected")
	for _, TakenAnimation in pairs(TakenAnimations) do
		local TakenAnimID, i = TakenAnimation.Name:gsub("Animation_", "")
		TakenAnimID = tonumber(TakenAnimID)
		if not TakenAnimID then continue end
		SaveAnimation(TakenAnimID)
	end
	MakeNotify("Animation Logger", "Saved selected animations!", "http://www.roblox.com/asset/?id=131006790482868", 3)
end)

GrabOptionsSettingsSaveAll.MouseButton1Click:Connect(function()
	if RunService:IsStudio() then return end
	local TakenAnimations = GetTakenAnimations("All")
	for _, TakenAnimation in pairs(TakenAnimations) do
		local TakenAnimID, i = TakenAnimation.Name:gsub("Animation_", "")
		TakenAnimID = tonumber(TakenAnimID)
		if not TakenAnimID then continue end
		SaveAnimation(TakenAnimID)
	end
	MakeNotify("Animation Logger", "Saved all animations!", "http://www.roblox.com/asset/?id=131006790482868", 3)
end)

GrabOptionsSettingsClearSelected.MouseButton1Click:Connect(function()
	local TakenAnimations = GetTakenAnimations("Selected")
	for _, TakenAnimation in pairs(TakenAnimations) do
		TakenAnimation:Destroy()
	end
	MakeNotify("Animation Logger", "Cleared selected animations!", "http://www.roblox.com/asset/?id=131006790482868", 3)
end)

GrabOptionsSettingsClearAll.MouseButton1Click:Connect(function()
	local TakenAnimations = GetTakenAnimations("All")
	for _, TakenAnimation in pairs(TakenAnimations) do
		TakenAnimation:Destroy()
	end
	MakeNotify("Animation Logger", "Cleared all animations!", "http://www.roblox.com/asset/?id=131006790482868", 3)
end)

local CurrentAnimTrack: AnimationTrack?
local CurrentAnimTrackTimePos = 0
local NormalSpeed = 0

RunService.RenderStepped:Connect(function()
	if not CurrentAnimTrack then return end
	if not CurrentAnimTrack.IsPlaying then return end
	if PauseAndResumeAnimTrack.Text == "resume" then return end
	CurrentAnimTrackTimePos = CurrentAnimTrack.TimePosition
	local AdjustingSpeed, i = SpeedBox.Text:gsub("x", "")
	AdjustingSpeed = tonumber(AdjustingSpeed)
	if AdjustingSpeed then
		CurrentAnimTrack:AdjustSpeed(AdjustingSpeed)
	end
	if CurrentAnimTrack.Speed == 0 then return end
	local TimePosProgress = CurrentAnimTrackTimePos/CurrentAnimTrack.Length*TimePosSliderBar.AbsoluteSize.X
	TimePosSliderButton.Position = UDim2.fromOffset(TimePosProgress,-10)
	local TextTimePos = tostring(math.floor(CurrentAnimTrackTimePos*10)/10)
	TimePosBox.Text = TextTimePos .. "s"
end)

CloseAnimationInfoDisplay.MouseButton1Click:Connect(function()
	if CurrentAnimTrack then
		CurrentAnimTrack:Stop()
		CurrentAnimTrack = nil
	end	
	AnimationInfoDisplay.Visible = false
	ResultsList.Visible = true
	ScrollBarVisualHolder.Visible = true
	AnimGameName.Text = "Game Name: ?"
	AnimID.Text = "ID: ?"
	AnimMarketplaceName.Text = "Marketplace Name: ?"
	SpeedSliderButton.Position = UDim2.fromOffset(0,-10)
	TimePosSliderButton.Position = UDim2.fromOffset(0,-10)
	SpeedBox.Text = ""
	TimePosBox.Text = ""
	PauseAndResumeAnimTrack.Text = "pause"
	CurrentAnimTrackTimePos = 0
	NormalSpeed = 0
end)

CopyAnimationID.MouseButton1Click:Connect(function()
	if RunService:IsStudio() then return end
	local ViewingAnimTrackID = AnimID.Text:gsub("ID: ", "")
	if not tonumber(ViewingAnimTrackID) then return end
	local clipBoard = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
	if clipBoard then
		clipBoard(ViewingAnimTrackID)
		MakeNotify("Animation Logger", "Copied to clipboard - " .. ViewingAnimTrackID, "http://www.roblox.com/asset/?id=131006790482868", 3)
	else
		MakeNotify("Animation Logger", "Your exploit doesn't have the ability to use the clipboard", "http://www.roblox.com/asset/?id=131006790482868", 3)
	end
end)

PlayAnimTrack.MouseButton1Click:Connect(function()
	local PlrChar = Plr.Character
	if not PlrChar then return end
	local PlrCharHum = PlrChar:FindFirstChildWhichIsA("Humanoid")
	if not PlrCharHum then return end
	local PlrCharAnimator = PlrCharHum:FindFirstChildWhichIsA("Animator")
	if not PlrCharAnimator then return end
	local ViewingAnimTrackID = AnimID.Text:gsub("ID: ", "")
	ViewingAnimTrackID = tonumber(ViewingAnimTrackID)
	if not ViewingAnimTrackID then return end
	if CurrentAnimTrack then
		local CurrentAnimTrackAnimationObject = CurrentAnimTrack.Animation
		local CurrentAnimTrackID, i = CurrentAnimTrackAnimationObject.AnimationId:gsub("%D", "")
		CurrentAnimTrackID = tonumber(CurrentAnimTrackID)
		if ViewingAnimTrackID == CurrentAnimTrackID then return end
	end
	local ViewingAnimation: Animation = CreateInstance("Animation",{AnimationId="rbxassetid://"..tostring(ViewingAnimTrackID)})
	CurrentAnimTrack = PlrCharAnimator:LoadAnimation(ViewingAnimation)
	CurrentAnimTrack.Looped = true
	CurrentAnimTrack.Priority = "Action4"
	CurrentAnimTrack:Play()
	NormalSpeed = CurrentAnimTrack.Speed
	local SpeedProgress = .5*SpeedSliderBar.AbsoluteSize.X
	SpeedSliderButton.Position = UDim2.fromOffset(SpeedProgress,-10)
	local TextSpeed = tostring(math.floor(NormalSpeed*10)/10)
	SpeedBox.Text = TextSpeed .. "x"
end)

PauseAndResumeAnimTrack.MouseButton1Click:Connect(function()
	if PauseAndResumeAnimTrack.Text == "pause" then
		if not CurrentAnimTrack then return end
		CurrentAnimTrack:AdjustSpeed(0)
		PauseAndResumeAnimTrack.Text = "resume"
	elseif PauseAndResumeAnimTrack.Text == "resume" then
		if not CurrentAnimTrack then return end
		CurrentAnimTrack:AdjustSpeed(NormalSpeed)
		PauseAndResumeAnimTrack.Text = "pause"
	end
end)

StopAnimTrack.MouseButton1Click:Connect(function()
	if not CurrentAnimTrack then return end
	CurrentAnimTrack:Stop()
	CurrentAnimTrack = nil
	CurrentAnimTrackTimePos = 0
	NormalSpeed = 0
	SpeedSliderButton.Position = UDim2.fromOffset(0,-10)
	TimePosSliderButton.Position = UDim2.fromOffset(0,-10)
	SpeedBox.Text = ""
	TimePosBox.Text = ""
	PauseAndResumeAnimTrack.Text = "pause"
end)

SpeedBox.FocusLost:Connect(function()
	local EnteredSpeed = SpeedBox.Text
	EnteredSpeed = tonumber(EnteredSpeed)
	if not EnteredSpeed then
		EnteredSpeed = NormalSpeed
	end
	if EnteredSpeed < 0 then
		EnteredSpeed = 0
	end
	SpeedBox.Text = tostring(EnteredSpeed) .. "x"
	local SpeedProgress = SpeedSliderBar.AbsoluteSize.X/2*tonumber(EnteredSpeed)
	if SpeedProgress > SpeedSliderBar.AbsoluteSize.X then
		SpeedProgress = SpeedSliderBar.AbsoluteSize.X
	end
	SpeedSliderButton.Position = UDim2.fromOffset(SpeedProgress,-10)
end)

local draggingSpeed
local dragInputSpeed
local dragStartSpeed
local startPosSpeed
local draggingTimePos
local dragInputTimePos
local dragStartTimePos
local startPosTimePos

local function updateSpeed(input)
	local delta = input.Position - dragStartSpeed
	local SliderGoal = UDim2.fromOffset(startPosSpeed.X.Offset + delta.X,-10)
	if SliderGoal.X.Offset < 0 then
		SliderGoal = UDim2.fromOffset(0,-10)
	elseif SliderGoal.X.Offset > SpeedSliderBar.AbsoluteSize.X then
		SliderGoal = UDim2.fromOffset(SpeedSliderBar.AbsoluteSize.X,-10)
	end
	SpeedSliderButton.Position = SliderGoal
	local TextPartOfSlider = tostring(math.floor(SpeedSliderButton.Position.X.Offset/(SpeedSliderBar.AbsoluteSize.X/2)*10)/10)
	SpeedBox.Text = TextPartOfSlider .. "x"
end

local function updateTimePos(input)
	local delta = input.Position - dragStartTimePos
	local SliderGoal = UDim2.fromOffset(startPosTimePos.X.Offset + delta.X,-10)
	if SliderGoal.X.Offset < 0 then
		SliderGoal = UDim2.fromOffset(0,-10)
	elseif SliderGoal.X.Offset > TimePosSliderBar.AbsoluteSize.X then
		SliderGoal = UDim2.fromOffset(TimePosSliderBar.AbsoluteSize.X,-10)
	end
	TimePosSliderButton.Position = SliderGoal
	local PartOfSlider = TimePosSliderButton.Position.X.Offset/TimePosSliderBar.AbsoluteSize.X
	local TextPartInSlider = tostring(math.floor(PartOfSlider*10)/10)
	TimePosBox.Text = TextPartInSlider .. "s"
	if CurrentAnimTrack.Speed == 0 then
		CurrentAnimTrack.TimePosition = PartOfSlider
	end
end

SpeedSliderButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingSpeed = true
		dragStartSpeed = input.Position
		startPosSpeed = SpeedSliderButton.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingSpeed = false
			end
		end)
	end
end)

SpeedSliderButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInputSpeed = input
	end
end)

TimePosSliderButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingTimePos = true
		dragStartTimePos = input.Position
		startPosTimePos = TimePosSliderButton.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				draggingTimePos = false
			end
		end)
	end
end)

TimePosSliderButton.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInputTimePos = input
	end
end)

UIS.InputChanged:Connect(function(input)
	if input == dragInputSpeed and draggingSpeed then
		updateSpeed(input)
	elseif input == dragInputTimePos and draggingTimePos then
		updateTimePos(input)
	end
end)

CloseAnimLogger.MouseButton1Click:Connect(function()
	if Closing then return end
	if InCollapsing then return end
	Closing = true
	Collapsed = true
	if CollapseShowTween then
		CollapseHideTween:Pause()
	end
	if CollapseHideTween then
		CollapseHideTween:Cancel()
	end
	if Base.Size ~= UDim2.fromOffset(425,20) then
		CollapseHideTween = TweenService:Create(Base, TweenInfo.new(.5, Enum.EasingStyle.Linear), {Size=UDim2.fromOffset(425,20)})
		CollapseHideTween:Play()
		CollapseHideTween.Completed:Wait()
	end
	TweenService:Create(Base, TweenInfo.new(.5, Enum.EasingStyle.Linear), {Size=UDim2.fromOffset(0,20)}):Play()
	task.wait(.5)
	AnimLogger:Destroy()
	MakeNotify("Animation Logger", "Closed!", "http://www.roblox.com/asset/?id=131006790482868", 3)
	if CurrentAnimTrack then
		CurrentAnimTrack:Stop()
	end
	if AnimObjectSelectionHighlight then
		AnimObjectSelectionHighlight:Destroy()
	end
	script:Destroy()
end)
