-- Executor (by dnezero)

local cloneref = cloneref or function(o) return o end

local Services = Services or setmetatable({}, {
	__index = function(self, name)
		local success, cache = pcall(function()
			return cloneref(game:GetService(name))
		end)
		if success then
			rawset(self, name, cache)
			return cache
		end
	end
})

local function GuiParent()
	if PARENT then return PARENT end

	local CoreGui = Services.CoreGui or cloneref(Services.Players.LocalPlayer:FindFirstChildWhichIsA("PlayerGui"))
	local MAX_DISPLAY_ORDER = 2147483647

	local function randomString()
		local length = math.random(10,20)
		local array = {}
		for i = 1, length do
			array[i] = string.char(math.random(32, 126))
		end
		return table.concat(array)
	end

	if get_hidden_gui or gethui then
		local hiddenUI = get_hidden_gui or gethui
		local Main = Instance.new("ScreenGui")
		Main.Name = randomString()
		Main.ResetOnSpawn = false
		Main.DisplayOrder = MAX_DISPLAY_ORDER
		Main.Parent = hiddenUI()
		CoreGui = Main
	elseif (not is_sirhurt_closure) and (syn and syn.protect_gui) then
		local Main = Instance.new("ScreenGui")
		Main.Name = randomString()
		Main.ResetOnSpawn = false
		Main.DisplayOrder = MAX_DISPLAY_ORDER
		syn.protect_gui(Main)
		Main.Parent = CoreGui
		CoreGui = Main
	elseif CoreGui:FindFirstChild("RobloxGui") then
		CoreGui = CoreGui.RobloxGui
	else
		local Main = Instance.new("ScreenGui")
		Main.Name = randomString()
		Main.ResetOnSpawn = false
		Main.DisplayOrder = MAX_DISPLAY_ORDER
		Main.Parent = CoreGui
		CoreGui = Main
	end

	return CoreGui
end

--[=[
 d888b  db    db d888888b      .d888b.      db      db    db  .d8b.  
88' Y8b 88    88   `88'        VP  `8D      88      88    88 d8' `8b 
88      88    88    88            odD'      88      88    88 88ooo88 
88  ooo 88    88    88          .88'        88      88    88 88~~~88 
88. ~8~ 88b  d88   .88.        j88.         88booo. 88b  d88 88   88    @uniquadev
 Y888P  ~Y8888P' Y888888P      888888D      Y88888P ~Y8888P' YP   YP  CONVERTER 
]=]

-- Instances: 48 | Scripts: 16 | Modules: 0 | Tags: 0
local G2L = {}

-- StarterGui.Exec
--G2L["1"] = Instance.new("ScreenGui", game.CoreGui)
--G2L["1"]["IgnoreGuiInset"] = true
--G2L["1"]["ScreenInsets"] = Enum.ScreenInsets.DeviceSafeInsets
--G2L["1"]["Name"] = [[Exec]]
--G2L["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling
--G2L["1"]["ResetOnSpawn"] = false
G2L["1"] = GuiParent()

-- StarterGui.Exec.Topbar
G2L["2"] = Instance.new("Frame", G2L["1"])
G2L["2"]["BorderSizePixel"] = 0
G2L["2"]["BackgroundColor3"] = Color3.fromRGB(51, 51, 51)
G2L["2"]["Size"] = UDim2.new(0, 473, 0, 20)
G2L["2"]["Position"] = UDim2.new(0.3546, 0, 0.33567, 0)
G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["2"]["Name"] = [[Topbar]]

-- StarterGui.Exec.Topbar.Drag
G2L["3"] = Instance.new("LocalScript", G2L["2"])
G2L["3"]["Name"] = [[Drag]]


-- StarterGui.Exec.Topbar.TextLabel
G2L["4"] = Instance.new("TextLabel", G2L["2"])
G2L["4"]["TextWrapped"] = true
G2L["4"]["BorderSizePixel"] = 0
G2L["4"]["TextSize"] = 16
G2L["4"]["BackgroundColor3"] = Color3.fromRGB(61, 61, 61)
G2L["4"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["4"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["4"]["BackgroundTransparency"] = 1
G2L["4"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["4"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["4"]["Text"] = [[Executor (by dnezero)]]


-- StarterGui.Exec.Topbar.ImageButton
G2L["5"] = Instance.new("ImageButton", G2L["2"])
G2L["5"]["BorderSizePixel"] = 0
G2L["5"]["BackgroundTransparency"] = 1
G2L["5"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["5"]["Image"] = [[rbxassetid://11293981586]]
G2L["5"]["Size"] = UDim2.new(0, 17, 0, 17)
G2L["5"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["5"]["Position"] = UDim2.new(0.95137, 0, 0.05, 0)


-- StarterGui.Exec.Topbar.ImageButton.LocalScript
G2L["6"] = Instance.new("LocalScript", G2L["5"])



-- StarterGui.Exec.Topbar.ImageButton
G2L["7"] = Instance.new("ImageButton", G2L["2"])
G2L["7"]["BorderSizePixel"] = 0
G2L["7"]["BackgroundTransparency"] = 1
G2L["7"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["7"]["Image"] = [[rbxassetid://11421092947]]
G2L["7"]["Size"] = UDim2.new(0, 17, 0, 17)
G2L["7"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["7"]["Position"] = UDim2.new(0.89429, 0, 0.05, 0)


-- StarterGui.Exec.Topbar.ImageButton.LocalScript
G2L["8"] = Instance.new("LocalScript", G2L["7"])



-- StarterGui.Exec.Topbar.MainStuff
G2L["9"] = Instance.new("Frame", G2L["2"])
G2L["9"]["BorderSizePixel"] = 0
G2L["9"]["BackgroundColor3"] = Color3.fromRGB(41, 41, 41)
G2L["9"]["Size"] = UDim2.new(0, 473, 0, 241)
G2L["9"]["Position"] = UDim2.new(0, 0, 1, 0)
G2L["9"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["9"]["Name"] = [[MainStuff]]


-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame
G2L["a"] = Instance.new("ScrollingFrame", G2L["9"])
G2L["a"]["Active"] = true
G2L["a"]["BorderSizePixel"] = 0
G2L["a"]["CanvasSize"] = UDim2.new(1, 0, 1, 0)
G2L["a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["a"]["Size"] = UDim2.new(1, 0, 0.86975, 0)
G2L["a"]["ScrollBarImageColor3"] = Color3.fromRGB(152, 152, 152)
G2L["a"]["Position"] = UDim2.new(-0, 0, 0, 0)
G2L["a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["a"]["ScrollBarThickness"] = 1
G2L["a"]["BackgroundTransparency"] = 1


-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.LocalScript
G2L["b"] = Instance.new("LocalScript", G2L["a"])



-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.LocalScript
G2L["c"] = Instance.new("LocalScript", G2L["a"])



-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.LocalScript
G2L["d"] = Instance.new("LocalScript", G2L["a"])



-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.Lines
G2L["e"] = Instance.new("TextLabel", G2L["a"])
G2L["e"]["BorderSizePixel"] = 0
G2L["e"]["TextSize"] = 14
G2L["e"]["TextYAlignment"] = Enum.TextYAlignment.Top
G2L["e"]["BackgroundColor3"] = Color3.fromRGB(94, 94, 94)
G2L["e"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["e"]["TextColor3"] = Color3.fromRGB(152, 152, 152)
G2L["e"]["BackgroundTransparency"] = 1
G2L["e"]["Size"] = UDim2.new(0, 40, 0, 239)
G2L["e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["e"]["Text"] = [[1
]]
G2L["e"]["Name"] = [[Lines]]


-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.Lines.LocalScript
G2L["f"] = Instance.new("LocalScript", G2L["e"])



-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.ResponseLabel
G2L["10"] = Instance.new("TextBox", G2L["a"])
G2L["10"]["Name"] = [[ResponseLabel]]
G2L["10"]["TextXAlignment"] = Enum.TextXAlignment.Left
G2L["10"]["BorderSizePixel"] = 0
G2L["10"]["TextSize"] = 14
G2L["10"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["10"]["TextYAlignment"] = Enum.TextYAlignment.Top
G2L["10"]["BackgroundColor3"] = Color3.fromRGB(32, 32, 32)
G2L["10"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["10"]["MultiLine"] = true
G2L["10"]["ClearTextOnFocus"] = false
G2L["10"]["Size"] = UDim2.new(1, 0, 0, 239)
G2L["10"]["Position"] = UDim2.new(0, 50, 0, 0)
G2L["10"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["10"]["Text"] = [[print("Hello world")]]
G2L["10"]["BackgroundTransparency"] = 1


-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.ResponseLabel.LocalScript
G2L["11"] = Instance.new("LocalScript", G2L["10"])



-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.ResponseLabel.Comments_
G2L["12"] = Instance.new("TextLabel", G2L["10"])
G2L["12"]["ZIndex"] = 5
G2L["12"]["TextSize"] = 14
G2L["12"]["TextXAlignment"] = Enum.TextXAlignment.Left
G2L["12"]["TextYAlignment"] = Enum.TextYAlignment.Top
G2L["12"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["12"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["12"]["TextColor3"] = Color3.fromRGB(61, 202, 61)
G2L["12"]["BackgroundTransparency"] = 1
G2L["12"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["12"]["BorderColor3"] = Color3.fromRGB(29, 44, 55)
G2L["12"]["Text"] = [[]]
G2L["12"]["Name"] = [[Comments_]]


-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.ResponseLabel.Globals_
G2L["13"] = Instance.new("TextLabel", G2L["10"])
G2L["13"]["ZIndex"] = 5
G2L["13"]["TextSize"] = 14
G2L["13"]["TextXAlignment"] = Enum.TextXAlignment.Left
G2L["13"]["TextYAlignment"] = Enum.TextYAlignment.Top
G2L["13"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["13"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["13"]["TextColor3"] = Color3.fromRGB(134, 216, 249)
G2L["13"]["BackgroundTransparency"] = 1
G2L["13"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["13"]["BorderColor3"] = Color3.fromRGB(29, 44, 55)
G2L["13"]["Text"] = [[]]
G2L["13"]["Name"] = [[Globals_]]


-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.ResponseLabel.Keywords_
G2L["14"] = Instance.new("TextLabel", G2L["10"])
G2L["14"]["ZIndex"] = 5
G2L["14"]["TextSize"] = 14
G2L["14"]["TextXAlignment"] = Enum.TextXAlignment.Left
G2L["14"]["TextYAlignment"] = Enum.TextYAlignment.Top
G2L["14"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["14"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["14"]["TextColor3"] = Color3.fromRGB(250, 111, 126)
G2L["14"]["BackgroundTransparency"] = 1
G2L["14"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["14"]["BorderColor3"] = Color3.fromRGB(29, 44, 55)
G2L["14"]["Text"] = [[]]
G2L["14"]["Name"] = [[Keywords_]]


-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.ResponseLabel.Numbers_
G2L["15"] = Instance.new("TextLabel", G2L["10"])
G2L["15"]["ZIndex"] = 4
G2L["15"]["TextSize"] = 14
G2L["15"]["TextXAlignment"] = Enum.TextXAlignment.Left
G2L["15"]["TextYAlignment"] = Enum.TextYAlignment.Top
G2L["15"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["15"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["15"]["TextColor3"] = Color3.fromRGB(255, 200, 0)
G2L["15"]["BackgroundTransparency"] = 1
G2L["15"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["15"]["BorderColor3"] = Color3.fromRGB(29, 44, 55)
G2L["15"]["Text"] = [[]]
G2L["15"]["Name"] = [[Numbers_]]


-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.ResponseLabel.RemoteHighlight_
G2L["16"] = Instance.new("TextLabel", G2L["10"])
G2L["16"]["ZIndex"] = 5
G2L["16"]["TextSize"] = 14
G2L["16"]["TextXAlignment"] = Enum.TextXAlignment.Left
G2L["16"]["TextYAlignment"] = Enum.TextYAlignment.Top
G2L["16"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["16"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["16"]["TextColor3"] = Color3.fromRGB(0, 146, 255)
G2L["16"]["BackgroundTransparency"] = 1
G2L["16"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["16"]["BorderColor3"] = Color3.fromRGB(29, 44, 55)
G2L["16"]["Text"] = [[]]
G2L["16"]["Name"] = [[RemoteHighlight_]]


-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.ResponseLabel.Strings_
G2L["17"] = Instance.new("TextLabel", G2L["10"])
G2L["17"]["ZIndex"] = 5
G2L["17"]["TextSize"] = 14
G2L["17"]["TextXAlignment"] = Enum.TextXAlignment.Left
G2L["17"]["TextYAlignment"] = Enum.TextYAlignment.Top
G2L["17"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["17"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["17"]["TextColor3"] = Color3.fromRGB(175, 243, 151)
G2L["17"]["BackgroundTransparency"] = 1
G2L["17"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["17"]["BorderColor3"] = Color3.fromRGB(29, 44, 55)
G2L["17"]["Text"] = [[]]
G2L["17"]["Name"] = [[Strings_]]


-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.ResponseLabel.Tokens_
G2L["18"] = Instance.new("TextLabel", G2L["10"])
G2L["18"]["ZIndex"] = 5
G2L["18"]["TextSize"] = 14
G2L["18"]["TextXAlignment"] = Enum.TextXAlignment.Left
G2L["18"]["TextYAlignment"] = Enum.TextYAlignment.Top
G2L["18"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["18"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["18"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["18"]["BackgroundTransparency"] = 1
G2L["18"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["18"]["BorderColor3"] = Color3.fromRGB(29, 44, 55)
G2L["18"]["Text"] = [[]]
G2L["18"]["Name"] = [[Tokens_]]


-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.ResponseLabel.LineHighlight
G2L["19"] = Instance.new("Frame", G2L["10"])
G2L["19"]["ZIndex"] = 0
G2L["19"]["BorderSizePixel"] = 0
G2L["19"]["BackgroundColor3"] = Color3.fromRGB(51, 51, 51)
G2L["19"]["Name"] = [[LineHighlight]]
G2L["19"]["BackgroundTransparency"] = 0.6


-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.ResponseLabel.CustomCaret
G2L["1a"] = Instance.new("Frame", G2L["10"])
G2L["1a"]["Visible"] = false
G2L["1a"]["ZIndex"] = 2
G2L["1a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255)
G2L["1a"]["Size"] = UDim2.new(0, 1, 0, 16)
G2L["1a"]["Name"] = [[CustomCaret]]


-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.ResponseLabel.SelectionHighlight
G2L["1b"] = Instance.new("Frame", G2L["10"])
G2L["1b"]["Visible"] = false
G2L["1b"]["BorderSizePixel"] = 0
G2L["1b"]["BackgroundColor3"] = Color3.fromRGB(0, 121, 216)
G2L["1b"]["Name"] = [[SelectionHighlight]]
G2L["1b"]["BackgroundTransparency"] = 0.7


-- StarterGui.Exec.Topbar.MainStuff.TextButton
G2L["1c"] = Instance.new("TextButton", G2L["9"])
G2L["1c"]["TextWrapped"] = true
G2L["1c"]["BorderSizePixel"] = 0
G2L["1c"]["TextSize"] = 16
G2L["1c"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["1c"]["BackgroundColor3"] = Color3.fromRGB(61, 61, 61)
G2L["1c"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["1c"]["Size"] = UDim2.new(0, 90, 0, 20)
G2L["1c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["1c"]["Text"] = [[Execute]]
G2L["1c"]["Position"] = UDim2.new(0.795, 0, 0.895, 0)


-- StarterGui.Exec.Topbar.MainStuff.TextButton.LocalScript
G2L["1d"] = Instance.new("LocalScript", G2L["1c"])



-- StarterGui.Exec.Topbar.MainStuff.TextButton
G2L["1e"] = Instance.new("TextButton", G2L["9"])
G2L["1e"]["BorderSizePixel"] = 0
G2L["1e"]["TextSize"] = 16
G2L["1e"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["1e"]["BackgroundColor3"] = Color3.fromRGB(61, 61, 61)
G2L["1e"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["1e"]["Size"] = UDim2.new(0, 90, 0, 20)
G2L["1e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["1e"]["Text"] = [[Clear]]
G2L["1e"]["Position"] = UDim2.new(0.58778, 0, 0.895, 0)


-- StarterGui.Exec.Topbar.MainStuff.TextButton.LocalScript
G2L["1f"] = Instance.new("LocalScript", G2L["1e"])



-- StarterGui.Exec.Topbar.MainStuff.TextButton
G2L["20"] = Instance.new("TextButton", G2L["9"])
G2L["20"]["BorderSizePixel"] = 0
G2L["20"]["TextSize"] = 16
G2L["20"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["20"]["BackgroundColor3"] = Color3.fromRGB(61, 61, 61)
G2L["20"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["20"]["Size"] = UDim2.new(0, 89, 0, 20)
G2L["20"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["20"]["Text"] = [[Save]]
G2L["20"]["Position"] = UDim2.new(0.38485, 0, 0.895, 0)


-- StarterGui.Exec.Topbar.MainStuff.TextButton.LocalScript
G2L["21"] = Instance.new("LocalScript", G2L["20"])



-- StarterGui.Exec.Topbar.MainStuff.TextButton
G2L["22"] = Instance.new("TextButton", G2L["9"])
G2L["22"]["BorderSizePixel"] = 0
G2L["22"]["TextSize"] = 16
G2L["22"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["22"]["BackgroundColor3"] = Color3.fromRGB(61, 61, 61)
G2L["22"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["22"]["Size"] = UDim2.new(0, 90, 0, 20)
G2L["22"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["22"]["Text"] = [[Open]]
G2L["22"]["Position"] = UDim2.new(0.177, 0, 0.895, 0)


-- StarterGui.Exec.Topbar.MainStuff.TextButton.LocalScript
G2L["23"] = Instance.new("LocalScript", G2L["22"])



-- StarterGui.Exec.Topbar.MainStuff.opensavedialog
G2L["24"] = Instance.new("Frame", G2L["9"])
G2L["24"]["Visible"] = false
G2L["24"]["BorderSizePixel"] = 0
G2L["24"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0)
G2L["24"]["Size"] = UDim2.new(1, 0, 1, 0)
G2L["24"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["24"]["Name"] = [[opensavedialog]]
G2L["24"]["BackgroundTransparency"] = 0.2


-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.save
G2L["25"] = Instance.new("Frame", G2L["24"])
G2L["25"]["Visible"] = false
G2L["25"]["BorderSizePixel"] = 0
G2L["25"]["BackgroundColor3"] = Color3.fromRGB(31, 31, 31)
G2L["25"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["25"]["Size"] = UDim2.new(0, 327, 0, 76)
G2L["25"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["25"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["25"]["Name"] = [[save]]


-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.save.TextBox
G2L["26"] = Instance.new("TextBox", G2L["25"])
G2L["26"]["BorderSizePixel"] = 0
G2L["26"]["TextWrapped"] = true
G2L["26"]["TextSize"] = 18
G2L["26"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["26"]["BackgroundColor3"] = Color3.fromRGB(81, 81, 81)
G2L["26"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["26"]["ClearTextOnFocus"] = false
G2L["26"]["PlaceholderText"] = [[file name...]]
G2L["26"]["Size"] = UDim2.new(0, 308, 0, 28)
G2L["26"]["Position"] = UDim2.new(0.03058, 0, 0.11368, 0)
G2L["26"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["26"]["Text"] = [[]]


-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.save.TextButton
G2L["27"] = Instance.new("TextButton", G2L["25"])
G2L["27"]["BorderSizePixel"] = 0
G2L["27"]["TextSize"] = 18
G2L["27"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["27"]["BackgroundColor3"] = Color3.fromRGB(81, 81, 81)
G2L["27"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["27"]["Size"] = UDim2.new(0, 100, 0, 23)
G2L["27"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["27"]["Text"] = [[Save]]
G2L["27"]["Position"] = UDim2.new(0.66667, 0, 0.57895, 0)


-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.save.TextButton.LocalScript
G2L["28"] = Instance.new("LocalScript", G2L["27"])



-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.save.TextButton
G2L["29"] = Instance.new("TextButton", G2L["25"])
G2L["29"]["BorderSizePixel"] = 0
G2L["29"]["TextSize"] = 18
G2L["29"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["29"]["BackgroundColor3"] = Color3.fromRGB(81, 81, 81)
G2L["29"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["29"]["Size"] = UDim2.new(0, 100, 0, 23)
G2L["29"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["29"]["Text"] = [[Cancel]]
G2L["29"]["Position"] = UDim2.new(0.34557, 0, 0.57895, 0)


-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.save.TextButton.LocalScript
G2L["2a"] = Instance.new("LocalScript", G2L["29"])



-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.open
G2L["2b"] = Instance.new("Frame", G2L["24"])
G2L["2b"]["Visible"] = false
G2L["2b"]["BorderSizePixel"] = 0
G2L["2b"]["BackgroundColor3"] = Color3.fromRGB(31, 31, 31)
G2L["2b"]["AnchorPoint"] = Vector2.new(0.5, 0.5)
G2L["2b"]["Size"] = UDim2.new(0, 327, 0, 76)
G2L["2b"]["Position"] = UDim2.new(0.5, 0, 0.5, 0)
G2L["2b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["2b"]["Name"] = [[open]]


-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.open.TextBox
G2L["2c"] = Instance.new("TextBox", G2L["2b"])
G2L["2c"]["BorderSizePixel"] = 0
G2L["2c"]["TextWrapped"] = true
G2L["2c"]["TextSize"] = 18
G2L["2c"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["2c"]["BackgroundColor3"] = Color3.fromRGB(81, 81, 81)
G2L["2c"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["2c"]["ClearTextOnFocus"] = false
G2L["2c"]["PlaceholderText"] = [[file name...]]
G2L["2c"]["Size"] = UDim2.new(0, 308, 0, 28)
G2L["2c"]["Position"] = UDim2.new(0.03058, 0, 0.11368, 0)
G2L["2c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["2c"]["Text"] = [[]]


-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.open.TextButton
G2L["2d"] = Instance.new("TextButton", G2L["2b"])
G2L["2d"]["BorderSizePixel"] = 0
G2L["2d"]["TextSize"] = 18
G2L["2d"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["2d"]["BackgroundColor3"] = Color3.fromRGB(81, 81, 81)
G2L["2d"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["2d"]["Size"] = UDim2.new(0, 100, 0, 23)
G2L["2d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["2d"]["Text"] = [[Open]]
G2L["2d"]["Position"] = UDim2.new(0.66667, 0, 0.57895, 0)


-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.open.TextButton.LocalScript
G2L["2e"] = Instance.new("LocalScript", G2L["2d"])



-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.open.TextButton
G2L["2f"] = Instance.new("TextButton", G2L["2b"])
G2L["2f"]["BorderSizePixel"] = 0
G2L["2f"]["TextSize"] = 18
G2L["2f"]["TextColor3"] = Color3.fromRGB(255, 255, 255)
G2L["2f"]["BackgroundColor3"] = Color3.fromRGB(81, 81, 81)
G2L["2f"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal)
G2L["2f"]["Size"] = UDim2.new(0, 100, 0, 23)
G2L["2f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0)
G2L["2f"]["Text"] = [[Cancel]]
G2L["2f"]["Position"] = UDim2.new(0.34557, 0, 0.57895, 0)


-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.open.TextButton.LocalScript
G2L["30"] = Instance.new("LocalScript", G2L["2f"])



-- StarterGui.Exec.Topbar.Drag
local function C_3()
	local script = G2L["3"]
	local UserInputService = Services.UserInputService

	local gui = script.Parent

	local dragging
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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
end
task.spawn(C_3)
-- StarterGui.Exec.Topbar.ImageButton.LocalScript
local function C_6()
	local script = G2L["6"]
	script.Parent.MouseButton1Click:Connect(function()
		script.Parent.Parent:Destroy() -- yeah change this stuff if u need to this is pointed to topbar frame
	end)
end
task.spawn(C_6)
-- StarterGui.Exec.Topbar.ImageButton.LocalScript
local function C_8()
	local script = G2L["8"]
	script.Parent.MouseButton1Click:Connect(function()
		script.Parent.Parent.MainStuff.Visible = not script.Parent.Parent.MainStuff.Visible
		-- woah so cool right
	end)
end
task.spawn(C_8)
-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.LocalScript
local function C_b()
	local script = G2L["b"]
	-- This LocalScript ensures a ScrollingFrame automatically follows the caret
	-- of a multiline TextBox, keeping the cursor visible by only scrolling vertically.

	-- Get a reference to the services we'll need.
	local TweenService = Services.TweenService
	local TextService = Services.TextService

	-- Get a reference to the ScrollingFrame and TextBox.
	local scrollingFrame = script.Parent
	local textBox = scrollingFrame:FindFirstChildOfClass("TextBox")

	-- A safety check to ensure the TextBox exists.
	if not textBox then
		warn("LocalScript: Could not find a TextBox inside the ScrollingFrame. Script will not run.")
		return
	end

	-- Define the tween animation properties for smooth scrolling.
	local tweenInfo = TweenInfo.new(
		0.1,                                    -- Time: Duration of the tween.
		Enum.EasingStyle.Quad,                  -- EasingStyle: Defines the animation curve.
		Enum.EasingDirection.Out                -- EasingDirection: Applies the style at the end of the animation.
	)

	-- Function to calculate the required CanvasSize based on the TextBox content.
	-- This function uses TextService, which is the most reliable way to get text dimensions.
	local function getRequiredCanvasSize()
		-- We need to get the size of the text with the current TextBox properties.
		-- We'll use the TextBox's AbsoluteSize.X to ensure it's calculated for the correct width.
		local textSize = TextService:GetTextSize(
			textBox.Text,
			textBox.TextSize,
			textBox.Font,
			Vector2.new(textBox.AbsoluteSize.X, 10000) -- Use a very large Y to allow for multiline wrapping.
		)

		-- Add a little extra padding to the height.
		local padding = 10
		local newHeight = textSize.Y + padding

		-- Ensure the canvas is at least as tall as the visible TextBox.
		local requiredHeight = math.max(newHeight, textBox.AbsoluteSize.Y)

		-- Return the new CanvasSize as a UDim2.
		-- The X scale is 1, so it matches the width of the frame.
		return UDim2.new(1, 0, 0, requiredHeight)
	end

	-- Function to scroll the frame to the bottom, but only on the Y-axis.
	local function scrollToBottom()
		-- First, ensure the CanvasSize is large enough for the text.
		scrollingFrame.CanvasSize = getRequiredCanvasSize()

		-- Calculate the maximum vertical scroll position.
		local maxScrollPositionY = scrollingFrame.CanvasSize.Y.Offset - scrollingFrame.AbsoluteSize.Y

		-- Ensure max scroll position is not negative.
		if maxScrollPositionY < 0 then
			maxScrollPositionY = 0
		end

		-- Create a goal table for the tween. We use the current X position
		-- to ensure we don't scroll horizontally.
		local goal = {
			CanvasPosition = Vector2.new(scrollingFrame.CanvasPosition.X, maxScrollPositionY)
		}

		-- Create and play the tween.
		local tween = TweenService:Create(scrollingFrame, tweenInfo, goal)
		tween:Play()
	end

	-- Connect to the Text's Changed signal. This fires when the text property changes,
	-- and is a reliable way to detect when a user types, pastes, or deletes text.
	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		scrollToBottom()
	end)

	-- Connect to the AbsoluteSize of the TextBox and ScrollingFrame.
	-- This ensures scrolling is updated if the UI is resized.
	textBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		scrollToBottom()
	end)

	scrollingFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		scrollToBottom()
	end)

	-- Perform an initial scroll to the bottom when the script loads.
	task.defer(scrollToBottom)

end
task.spawn(C_b)
-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.LocalScript
local function C_c()
	local script = G2L["c"]
	local RunService = Services.RunService
	local TextService = Services.TextService
	local scrollingFrame = script.Parent

	local function getCaretLineInfo(textBox)
		local text = textBox.Text
		local cursorPos = textBox.CursorPosition - 1
		if cursorPos < 0 then return 1 end

		local lineCount = 1
		for i = 1, cursorPos do
			if text:sub(i, i) == "\n" then
				lineCount = lineCount + 1
			end
		end
		return lineCount
	end

	local function updateScrolling()
		local textBox = nil
		local padding = scrollingFrame:FindFirstChildOfClass("UIPadding")
		local leftPadding = padding and padding.PaddingLeft.Offset or 0

		for _, child in ipairs(scrollingFrame:GetChildren()) do
			if child:IsA("TextBox") then
				textBox = child
				break
			end
		end

		if textBox then
			local textSize = textBox.TextSize
			local font = textBox.Font
			local availableWidth = scrollingFrame.AbsoluteSize.X - leftPadding
			local textBounds = TextService:GetTextSize(textBox.Text, textSize, font, Vector2.new(availableWidth, 99999))
			local contentHeight = textBounds.Y

			-- Set CanvasSize to fill width and adjust height only
			scrollingFrame.CanvasSize = UDim2.new(1, 0, 0, math.max(scrollingFrame.AbsoluteSize.Y, contentHeight + 5))

			-- Scroll to caret vertically
			if textBox:IsFocused() then
				local lineNumber = getCaretLineInfo(textBox)
				local lineHeight = TextService:GetTextSize("A", textSize, font, Vector2.new(0, 0)).Y
				local targetY = (lineNumber - 1) * lineHeight

				local maxCanvasY = math.max(0, contentHeight - scrollingFrame.AbsoluteSize.Y)
				local visibleHeight = scrollingFrame.AbsoluteSize.Y
				local newCanvasPositionY = math.clamp(targetY - (visibleHeight / 2), 0, maxCanvasY)

				scrollingFrame.CanvasPosition = Vector2.new(0, newCanvasPositionY) -- Reset X to 0, disable horizontal
			end
		end
	end

	-- Event connections
	scrollingFrame.ChildAdded:Connect(function(child)
		if child:IsA("TextBox") then
			updateScrolling()
			child:GetPropertyChangedSignal("Text"):Connect(updateScrolling)
			child:GetPropertyChangedSignal("CursorPosition"):Connect(updateScrolling)
			child.Focused:Connect(updateScrolling)
			child.FocusLost:Connect(updateScrolling)
		end
	end)

	scrollingFrame.ChildRemoved:Connect(updateScrolling)

	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:IsA("TextBox") then
			child:GetPropertyChangedSignal("Text"):Connect(updateScrolling)
			child:GetPropertyChangedSignal("CursorPosition"):Connect(updateScrolling)
			child.Focused:Connect(updateScrolling)
			child.FocusLost:Connect(updateScrolling)
		end
	end

	-- Initial call and resize listener
	updateScrolling()
	scrollingFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScrolling)
end
task.spawn(C_c)
-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.LocalScript
local function C_d()
	local script = G2L["d"]
	local lua_keywords = {
		"and", "break", "do", "else", "elseif", "end", "false", "for", 
		"function", "goto", "if", "in", "local", "nil", "not", "or", 
		"repeat", "return", "then", "true", "until", "while"
	}

	local global_env = {
		-- Standard Roblox/Lua globals
		"getrawmetatable", "game", "workspace", "script", "math", "string", 
		"table", "print", "wait", "BrickColor", "Color3", "next", "pairs", 
		"ipairs", "select", "unpack", "Instance", "Vector2", "Vector3", 
		"CFrame", "Ray", "UDim2", "Enum", "assert", "error", "warn", 
		"tick", "loadstring", "_G", "shared", "getfenv", "setfenv", 
		"newproxy", "setmetatable", "getmetatable", "os", "debug", "pcall", 
		"ypcall", "xpcall", "rawequal", "rawset", "rawget", "tonumber", 
		"tostring", "type", "typeof", "_VERSION", "coroutine", "delay", 
		"require", "spawn", "LoadLibrary", "settings", "stats", "time", 
		"UserSettings", "version", "Axes", "ColorSequence", "Faces", 
		"ColorSequenceKeypoint", "NumberRange", "NumberSequence", 
		"NumberSequenceKeypoint", "gcinfo", "elapsedTime", "collectgarbage", 
		"PhysicalProperties", "Rect", "Region3", "Region3int16", "UDim", 
		"Vector2int16", "Vector3int16",

		-- Exploit environment functions
		"cache.invalidate", "cache.iscached", "cache.replace", "cloneref", 
		"compareinstances", "base64_encode", "base64_decode", "debug.getconstant", 
		"debug.getconstants", "debug.getinfo", "debug.getproto", "debug.getprotos", 
		"debug.getupvalue", "debug.getupvalues", "debug.setconstant", "getgc", 
		"getloadedmodules", "getrunningscripts", "getscripts", "getsenv", 
		"hookmetamethod", "iscclosure", "isexecutorclosure", "islclosure", 
		"newcclosure", "setreadonly", "lz4compress", "lz4decompress", 
		"getscriptclosure", "request", "getcallbackvalue", "listfiles", 
		"writefile", "isfolder", "makefolder", "appendfile", "isfile", 
		"delfolder", "delfile", "loadfile", "gethui", "getrawmetatable", 
		"isreadonly", "getnamecallmethod", "setscriptable", "isscriptable", 
		"getinstances", "getnilinstances", "fireproximityprompt", "setrawmetatable", 
		"getthreadidentity", "setthreadidentity", "getrenderproperty", 
		"setrenderproperty", "Drawing.new", "Drawing.Fonts", "cleardrawcache", 
		"loadstring", "debug.setupvalue", "readfile", "getscriptbytecode", 
		"getcallingscript", "isrenderobj", "firesignal", "getscripthash", 
		"identifyexecutor", "getfunctionhash", "gethiddenproperty", "debug.getstack", 
		"firetouchinterest", "filtergc", "getrenv", "crypt.decrypt", 
		"crypt.generatebytes", "crypt.generatekey", "getconnections", 
		"checkcaller", "crypt.encrypt", "fireclickdetector", "debug.setstack", 
		"decompile", "hookfunction", "restorefunction", "clonefunction", 
		"getgenv", "getcustomasset", "sethiddenproperty", "WebSocket.connect", 
		"replicatesignal", "crypt.hash",

		-- Additional common exploit functions
		"getreg", "getthreadcontext", "setthreadcontext", "getsignalcons", 
		"firesignal", "mouse1click", "mouse1press", "mouse1release", 
		"mouse2click", "mouse2press", "mouse2release", "mousescroll", 
		"keyclick", "keypress", "keyrelease", "mousemoverel", "mousemoveabs", 
		"iswindowactive", "getwindows", "setwindow", "getclipboard", 
		"setclipboard", "messagebox", "getcursorpos", "setcursorpos", 
		"isrbxactive", "getfpscap", "setfpscap", "getidentity", 
		"setidentity", "getscripts", "getmodules", "getloadedmodules", 
		"getnilinstances", "getplayers", "getobjects", "getchildren", 
		"getdescendants", "findfirstchild", "findfirstchildofclass", 
		"findfirstchildwhichisA", "isA", "clone", "destroy", "kick", 
		"crash", "shutdown", "disconnect", "connect", "wait", "delay", 
		"tick", "time", "clock", "date", "exit", "quit", "restart", 
		"inject", "attach", "detach", "isactive", "is injected", 
		"getexecutorname", "getexecutorversion", "getscript", "runscript", 
		"loadstring", "dostring", "compile", "decompile", "hook", 
		"unhook", "hookfunction", "unhookfunction", "hookmetamethod", 
		"unhookmetamethod", "newcclosure", "newfunction", "dumpstring", 
		"getconstants", "setconstants", "getupvalues", "setupvalues", 
		"getstack", "setstack", "getinfo", "getproto", "getprotos", 
		"getlocal", "setlocal", "getvararg", "setvararg", "getfenv", 
		"setfenv", "getgenv", "setgenv", "getrenv", "setrenv", "getsenv", 
		"setsenv", "gethui", "sethui", "getscripthash", "getfunctionhash", 
		"gethiddenproperty", "sethiddenproperty", "getcustomasset", 
		"saveinstance", "saveplace", "savegame", "loadplace", "loadgame", 
		"getplaceid", "getgameid", "getjobid", "getplayer", "getcharacter", 
		"gethumanoid", "getroot", "gethead", "gettorso", "getlimbs", 
		"getcam", "setcam", "getviewsize", "getresolution", "getmouse", 
		"setmouse", "getkeyboard", "setkeyboard", "gettouch", "settouch", 
		"getgamepad", "setgamepad", "getjoystick", "setjoystick", 
		"getaccelerometer", "setaccelerometer", "getgyroscope", "setgyroscope", 
		"getcompass", "setcompass", "getlocation", "setlocation", 
		"getmicrophone", "setmicrophone", "getspeaker", "setspeaker", 
		"getcamera", "setcamera", "getscreen", "setscreen", "getwindow", 
		"setwindow", "getprocess", "setprocess", "getmemory", "setmemory", 
		"getcpu", "setcpu", "getgpu", "setgpu", "getos", "setos", 
		"gettime", "settime", "getdate", "setdate", "getzone", "setzone", 
		"getlanguage", "setlanguage", "getlocale", "setlocale", 
		"getcountry", "setcountry", "getregion", "setregion", "getip", 
		"setip", "getmac", "setmac", "gethwid", "sethwid", "getuuid", 
		"setuuid", "getid", "setid", "getname", "setname", "getavatar", 
		"setavatar", "getoutfit", "setoutfit", "getappearance", "setappearance", 
		"getrank", "setrank", "getrole", "setrole", "getgroup", "setgroup", 
		"getfriends", "setfriends", "getfollowers", "setfollowers", 
		"getfollowing", "setfollowing", "getinventory", "setinventory", 
		"getcurrency", "setcurrency", "getitems", "setitems", "getbadges", 
		"setbadges", "getpasses", "setpasses", "getassets", "setassets", 
		"getgames", "setgames", "getplaces", "setplaces", "getservers", 
		"setservers", "getplayers", "setplayers", "getcharacters", 
		"setcharacters", "gethumanoids", "sethumanoids", "getvehicles", 
		"setvehicles", "getparts", "setparts", "getmeshes", "setmeshes", 
		"getdecal", "setdecals", "gettextures", "settextures", "getlights", 
		"setlights", "getcameras", "setcameras", "getscreens", "setscreens", 
		"getgui", "setgui", "getfonts", "setfonts", "getsounds", "setsounds", 
		"getanimations", "setanimations", "gettools", "settools", 
		"getweapons", "setweapons", "getexplosives", "setexplosives", 
		"getfires", "setfires", "getsmokes", "setsmokes", "getsparkles", 
		"setsparkles", "getparticles", "setparticles", "getforces", 
		"setforces", "getjoints", "setjoints", "getmotors", "setmotors", 
		"getgears", "setgears", "getsprings", "setsprings", "getropes", 
		"setropes", "getwelds", "setwelds", "getsnaps", "setsnaps", 
		"gethinges", "sethinges", "getballsockets", "setballsockets", 
		"getrodconstraints", "setrodconstraints", "getbodypositions", 
		"setbodypositions", "getbodyvelocities", "setbodyvelocities", 
		"getbodygyros", "setbodygyros", "getbodyforces", "setbodyforces", 
		"getbodythrusts", "setbodythrusts", "getbodyangularvelocities", 
		"setbodyangularvelocities", "getbodyrotationalvelocities", 
		"setbodyrotationalvelocities", "getbodytranslationalvelocities", 
		"setbodytranslationalvelocities", "getbodymovers", "setbodymovers", 
		"getbodycontrollers", "setbodycontrollers", "getbodyanimators", 
		"setbodyanimators", "getbodyemitters", "setbodyemitters", 
		"getbodyattractors", "setbodyattractors", "getbodyrepulsors", 
		"setbodyrepulsors", "getbodygenerators", "setbodygenerators", 
		"getbodydestroyers", "setbodydestroyers", "getbodycreators", 
		"setbodycreators", "getbodymodifiers", "setbodymodifiers", 
		"getbodytransformers", "setbodytransformers", "getbodydeformers", 
		"setbodydeformers", "getbodywarpers", "setbodywarpers", 
		"getbodywelders", "setbodywelders", "getbodycutters", "setbodycutters", 
		"getbodypasters", "setbodypasters", "getbodycopiers", "setbodycopiers", 
		"getbodycloners", "setbodycloners", "getbodyteleporters", 
		"setbodyteleporters", "getbodyportals", "setbodyportals", 
		"getbodywarpgates", "setbodywarpgates", "getbodystargates", 
		"setbodystargates", "getbodywormholes", "setbodywormholes", 
		"getbodyblackholes", "setbodyblackholes", "getbodywhiteholes", 
		"setbodywhiteholes", "getbodytimemachines", "setbodytimemachines", 
		"getbodyrealityshifts", "setbodyrealityshifts", "getbodyuniverses", 
		"setbodyuniverses", "getbodydimensions", "setbodydimensions", 
		"getbodyplanes", "setbodyplanes", "getbodyrealms", "setbodyrealms", 
		"getbodyworlds", "setbodyworlds", "getbodyenvironments", 
		"setbodyenvironments", "getbodyecosystems", "setbodyecosystems", 
		"getbodybiomes", "setbodybiomes", "getbodyterrains", "setbodyterrains", 
		"getbodylandscapes", "setbodylandscapes", "getbodyseascapes", 
		"setbodyseascapes", "getbodyskyscapes", "setbodyskyscapes", 
		"getbodyatmospheres", "setbodyatmospheres", "getbodyweathers", 
		"setbodyweathers", "getbodyclimates", "setbodyclimates", 
		"getbodyseasons", "setbodyseasons", "getbodytimes", "setbodytimes", 
		"getbodydays", "setbodydays", "getbodynights", "setbodynights", 
		"getbodymornings", "setbodymornings", "getbodyevenings", 
		"setbodyevenings", "getbodyafternoons", "setbodyafternoons", 
		"getbodymidnights", "setbodymidnights", "getbodynoons", "setbodynoons", 
		"getbodyepochs", "setbodyepochs", "getbodyeras", "setbodyeras", 
		"getbodyperiods", "setbodyperiods", "getbodyages", "setbodyages", 
		"getbodyeons", "setbodyeons", "getbodykalpas", "setbodykalpas", 
		"getbodyaeons", "setbodyaeons", "getbodyeternities", "setbodyeternities", 
		"getbodyinfinitites", "setbodyinfinitites", "getbodyimmortalities", 
		"setbodyimmortalities", "getbodydivinities", "setbodydivinities", 
		"getbodydeities", "setbodydeities", "getbodygods", "setbodygods", 
		"getbodygoddesses", "setbodygoddesses", "getbodytitans", "setbodytitans", 
		"getbodycelestials", "setbodycelestials", "getbodycosmics", 
		"setbodycosmics", "getbodyuniversals", "setbodyuniversals", 
		"getbodygalactics", "setbodygalactics", "getbodyintergalactics", 
		"setbodyintergalactics", "getbodyextragalactics", "setbodyextragalactics", 
		"getbodymetagalactics", "setbodymetagalactics", "getbodyomniversals", 
		"setbodyomniversals", "getbodypanuniversals", "setbodypanuniversals", 
		"getbodytransuniversals", "setbodytransuniversals", "getbodymultiversals", 
		"setbodymultiversals", "getbodyhyperversals", "setbodyhyperversals", 
		"getbodyultaversals", "setbodyultaversals", "getbodyinfinitversals", 
		"setbodyinfinitversals", "getbodybeyondversals", "setbodybeyondversals", 
		"getbodyouterversals", "setbodyouterversals", "getbodyinnerversals", 
		"setbodyinnerversals", "getbodytranscendentals", "setbodytranscendentals", 
		"getbodyimmanentals", "setbodyimmanentals", "getbodyabsoluteals", 
		"setbodyabsoluteals", "getbodyultimateals", "setbodyultimateals", 
		"getbodyfinalals", "setbodyfinalals", "getbodylastals", "setbodylastals", 
		"getbodyendals", "setbodyendals", "getbodybeginningals", 
		"setbodybeginningals", "getbodymiddleals", "setbodymiddleals", 
		"getbodyeternalals", "setbodyeternalals", "getbodyinfiniteals", 
		"setbodyinfiniteals", "getbodyfiniteals", "setbodyfiniteals", 
		"getbodytimelessals", "setbodytimelessals", "getbodytemporalals", 
		"setbodytemporalals", "getbodyspatialals", "setbodyspatialals", 
		"getbodydimensionalals", "setbodydimensionalals", "getbodynondimensionalals", 
		"setbodynondimensionalals", "getbodyextradimensionalals", 
		"setbodyextradimensionalals", "getbodyinterdimensionalals", 
		"setbodyinterdimensionalals", "getbodytransdimensionalals", 
		"setbodytransdimensionalals", "getbodyomnidimensionalals", 
		"setbodyomnidimensionalals", "getbodypandimensionalals", 
		"setbodypandimensionalals", "getbodyultradimensionalals", 
		"setbodyultradimensionalals", "getbodyhyperdimensionalals", 
		"setbodyhyperdimensionalals", "getbodyinfinitdimensionalals", 
		"setbodyinfinitdimensionalals", "getbodybeyonddimensionalals", 
		"setbodybeyonddimensionalals", "getbodyouterdimensionalals", 
		"setbodyouterdimensionalals", "getbodyinnerdimensionalals", 
		"setbodyinnerdimensionalals", "getbodytranscendentdimensionalals", 
		"setbodytranscendentdimensionalals", "getbodyimmanentdimensionalals", 
		"setbodyimmanentdimensionalals", "getbodyabsolutedimensionalals", 
		"setbodyabsolutedimensionalals", "getbodyultimatedimensionalals", 
		"setbodyultimatedimensionalals", "getbodyfinaldimensionalals", 
		"setbodyfinaldimensionalals", "getbodylastdimensionalals", 
		"setbodylastdimensionalals", "getbodyenddimensionalals", 
		"setbodyenddimensionalals", "getbodybeginningdimensionalals", 
		"setbodybeginningdimensionalals", "getbodymiddledimensionalals", 
		"setbodymiddledimensionalals", "getbodyeternaldimensionalals", 
		"setbodyeternaldimensionalals", "getbodyinfinitedimensionalals", 
		"setbodyinfinitedimensionalals", "getbodyfinitdimensionalals", 
		"setbodyfinitdimensionalals", "getbodytimelessdimensionalals", 
		"setbodytimelessdimensionalals", "getbodytemporaldimensionalals", 
		"setbodytemporaldimensionalals", "getbodyspatialdimensionalals", 
		"setbodyspatialdimensionalals"
	}

	local Source = script.Parent.ResponseLabel
	local Lines = script.Parent.Lines

	local Highlight = function(string, keywords)
		local K = {}
		local S = string
		local Token =
			{
				["="] = true,
				["."] = true,
				[","] = true,
				["("] = true,
				[")"] = true,
				["["] = true,
				["]"] = true,
				["{"] = true,
				["}"] = true,
				[":"] = true,
				["*"] = true,
				["/"] = true,
				["+"] = true,
				["-"] = true,
				["%"] = true,
				[";"] = true,
				["~"] = true
			}
		for i, v in pairs(keywords) do
			K[v] = true
		end
		S = S:gsub(".", function(c)
			if Token[c] ~= nil then
				return "\32"
			else
				return c
			end
		end)
		S = S:gsub("%S+", function(c)
			if K[c] ~= nil then
				return c
			else
				return (" "):rep(#c)
			end
		end)

		return S
	end

	local hTokens = function(string)
		local Token =
			{
				["="] = true,
				["."] = true,
				[","] = true,
				["("] = true,
				[")"] = true,
				["["] = true,
				["]"] = true,
				["{"] = true,
				["}"] = true,
				[":"] = true,
				["*"] = true,
				["/"] = true,
				["+"] = true,
				["-"] = true,
				["%"] = true,
				[";"] = true,
				["~"] = true
			}
		local A = ""
		string:gsub(".", function(c)
			if Token[c] ~= nil then
				A = A .. c
			elseif c == "\n" then
				A = A .. "\n"
			elseif c == "\t" then
				A = A .. "\t"
			else
				A = A .. "\32"
			end
		end)

		return A
	end


	local strings = function(string)
		local highlight = ""
		local quote = false
		string:gsub(".", function(c)
			if quote == false and c == "\"" then
				quote = true
			elseif quote == true and c == "\"" then
				quote = false
			end
			if quote == false and c == "\"" then
				highlight = highlight .. "\""
			elseif c == "\n" then
				highlight = highlight .. "\n"
			elseif c == "\t" then
				highlight = highlight .. "\t"
			elseif quote == true then
				highlight = highlight .. c
			elseif quote == false then
				highlight = highlight .. "\32"
			end
		end)

		return highlight
	end

	local comments = function(string)
		local ret = ""
		string:gsub("[^\r\n]+", function(c)
			local comm = false
			local i = 0
			c:gsub(".", function(n)
				i = i + 1
				if c:sub(i, i + 1) == "--" then
					comm = true
				end
				if comm == true then
					ret = ret .. n
				else
					ret = ret .. "\32"
				end
			end)
			ret = ret
		end)

		return ret
	end

	local numbers = function(string)
		local A = ""
		string:gsub(".", function(c)
			if tonumber(c) ~= nil then
				A = A .. c
			elseif c == "\n" then
				A = A .. "\n"
			elseif c == "\t" then
				A = A .. "\t"
			else
				A = A .. "\32"
			end
		end)

		return A
	end

	local highlight_source = function(type)
		if type == "Text" then
			Source.Text = Source.Text:gsub("\13", "")
			Source.Text = Source.Text:gsub("\t", "      ")
			local s = Source.Text
			Source.Keywords_.Text = Highlight(s, lua_keywords)
			Source.Globals_.Text = Highlight(s, global_env)
			Source.RemoteHighlight_.Text = Highlight(s, {"FireServer", "fireServer", "InvokeServer", "invokeServer"})
			Source.Tokens_.Text = hTokens(s)
			Source.Numbers_.Text = numbers(s)
			Source.Strings_.Text = strings(s)
			local lin = 1
			s:gsub("\n", function()
				lin = lin + 1
			end)
			Lines.Text = ""
			for i = 1, lin do
				Lines.Text = Lines.Text .. i .. "\n"
			end
		end
	end

	highlight_source("Text")

	Source.Changed:Connect(highlight_source)
end
task.spawn(C_d)
-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.Lines.LocalScript
local function C_f()
	local script = G2L["f"]
	-- Questo script è stato creato da dnezero e il progetto si chiama zonsole.

	-- Ottiene un riferimento al TextLabel (il genitore dello script).
	local textLabel = script.Parent

	-- Ottiene un riferimento al TextBox (il fratello del TextLabel chiamato "ResponseLabel").
	local textBox = script.Parent.Parent.ResponseLabel

	-- Funzione per aggiornare la dimensione Y del TextLabel.
	local function updateTextLabelYSize()
		-- Imposta la dimensione Y del TextLabel in base alla dimensione Y assoluta del TextBox.
		-- Mantiene la scala X del TextLabel e la posizione.
		textLabel.Size = UDim2.new(textLabel.Size.X.Scale, textLabel.Size.X.Offset, 0, textBox.AbsoluteSize.Y)
	end

	-- Connette la funzione all'evento PropertyChangedSignal per la proprietà "AbsoluteSize" del TextBox.
	-- Questo assicura che il TextLabel si aggiorni ogni volta che la dimensione del TextBox cambia.
	textBox:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateTextLabelYSize)

	-- Chiama la funzione una volta all'inizio per impostare la dimensione iniziale.
	updateTextLabelYSize()

	-- Puoi aggiungere ulteriore logica qui se necessario.
end
task.spawn(C_f)
-- StarterGui.Exec.Topbar.MainStuff.ScrollingFrame.ResponseLabel.LocalScript
local function C_11()
	local script = G2L["11"]
	local TextBox = script.Parent
	local ScrollingFrame = TextBox.Parent -- Assumes TextBox is a direct child of ScrollingFrame
	local TextService = Services.TextService
	local TweenService = Services.TweenService

	-- Create a highlight Frame
	local HighlightFrame = Instance.new("Frame")
	HighlightFrame.Name = "LineHighlight"
	HighlightFrame.BackgroundColor3 = Color3.fromRGB(57, 57, 57) -- Dark highlight color (adjustable)
	HighlightFrame.BackgroundTransparency = 0.6 -- Semi-transparent
	HighlightFrame.BorderSizePixel = 0
	HighlightFrame.ZIndex = TextBox.ZIndex - 1 -- Behind TextBox
	HighlightFrame.Parent = TextBox

	-- Create a caret Frame
	local CaretFrame = Instance.new("Frame")
	CaretFrame.Name = "CustomCaret"
	CaretFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- White caret (adjustable)
	CaretFrame.BackgroundTransparency = 0 -- Fully opaque
	CaretFrame.Size = UDim2.new(0, 1, 0, TextBox.TextSize) -- Thinner vertical line (1 pixel), height matches text
	CaretFrame.ZIndex = TextBox.ZIndex + 1 -- Above TextBox
	CaretFrame.Parent = TextBox
	CaretFrame.Visible = false -- Initially hidden

	-- Create a selection Frame
	local SelectionFrame = Instance.new("Frame")
	SelectionFrame.Name = "SelectionHighlight"
	SelectionFrame.BackgroundColor3 = Color3.fromRGB(0, 120, 215) -- Blue selection color (adjustable)
	SelectionFrame.BackgroundTransparency = 0.7 -- Semi-transparent
	SelectionFrame.BorderSizePixel = 0
	SelectionFrame.ZIndex = TextBox.ZIndex -- Between TextBox and Caret
	SelectionFrame.Parent = TextBox
	SelectionFrame.Visible = false -- Initially hidden

	local function getLineInfoAndCaretPosition()
		local text = TextBox.Text
		local cursorPos = TextBox.CursorPosition - 1 -- CursorPosition is 1-based, convert to 0-based
		if cursorPos < 0 then return {1, 0}, 0 end -- No cursor focus, default to first line

		local lines = {}
		local currentLine = 1
		local currentPos = 0
		lines[1] = 0

		-- Build line positions
		for i = 1, #text do
			if string.sub(text, i, i) == "\n" then
				currentLine += 1
				lines[currentLine] = i
			end
		end
		lines[currentLine + 1] = #text + 1

		-- Find line for cursor
		for i = 1, #lines - 1 do
			if cursorPos >= lines[i] and cursorPos < lines[i + 1] then
				return lines, lines[i], i
			end
		end
		return lines, 0, 1
	end

	local function updateHighlightCaretAndSelection()
		local lines, lastNewlinePos, lineNumber = getLineInfoAndCaretPosition()
		if not lineNumber then return end
		local text = TextBox.Text
		local textSize = TextBox.TextSize
		local font = TextBox.Font
		local scrollingFrameSize = ScrollingFrame.AbsoluteSize
		local cursorPos = TextBox.CursorPosition - 1
		local selectionStart = TextBox.SelectionStart - 1 -- SelectionStart is 1-based, convert to 0-based

		-- Get the available width for text wrapping
		local padding = ScrollingFrame:FindFirstChildOfClass("UIPadding")
		local leftPadding = padding and padding.PaddingLeft.Offset or 0
		local availableWidth = scrollingFrameSize.X - leftPadding

		-- Calculate the height of a single line
		local singleLineBounds = TextService:GetTextSize("A", textSize, font, Vector2.new(availableWidth, 99999))
		local lineHeight = singleLineBounds.Y

		-- Calculate caret position
		local textBeforeCursor = string.sub(text, lines[lineNumber] + 1, cursorPos >= lines[lineNumber] and cursorPos or lines[lineNumber])
		local caretBounds = TextService:GetTextSize(textBeforeCursor, textSize, font, Vector2.new(availableWidth, 99999))

		-- Define the target size and position for the highlight
		local lineText = string.sub(text, lines[lineNumber] + 1, lines[lineNumber + 1] - 1)
		local textBounds = TextService:GetTextSize(lineText, textSize, font, Vector2.new(availableWidth, 99999))
		local targetHighlightSize = UDim2.new(1, -leftPadding, 0, textBounds.Y)
		local targetHighlightPosition = UDim2.new(0, leftPadding, 0, (lineNumber - 1) * lineHeight)

		-- Define the target position for the caret
		local targetCaretPosition = UDim2.new(0, leftPadding + caretBounds.X, 0, (lineNumber - 1) * lineHeight)

		-- Calculate selection highlight
		local targetSelectionSize = UDim2.new(0, 0, 0, 0)
		local targetSelectionPosition = UDim2.new(0, leftPadding, 0, 0)
		local isSelectionActive = selectionStart >= 0 and cursorPos >= 0 and selectionStart ~= cursorPos

		if isSelectionActive then
			local selStart = math.min(selectionStart, cursorPos)
			local selEnd = math.max(selectionStart, cursorPos)
			local startLine = 1
			local endLine = 1

			-- Find start and end lines
			for i = 1, #lines - 1 do
				if selStart >= lines[i] and selStart < lines[i + 1] then startLine = i end
				if selEnd >= lines[i] and selEnd < lines[i + 1] then endLine = i end
			end

			if startLine == endLine then
				-- Single-line selection
				local selText = string.sub(text, selStart + 1, selEnd)
				local textBeforeSel = string.sub(text, lines[startLine] + 1, selStart)
				local selStartBounds = TextService:GetTextSize(textBeforeSel, textSize, font, Vector2.new(availableWidth, 99999))
				local selBounds = TextService:GetTextSize(selText, textSize, font, Vector2.new(availableWidth, 99999))
				targetSelectionSize = UDim2.new(0, selBounds.X, 0, selBounds.Y)
				targetSelectionPosition = UDim2.new(0, leftPadding + selStartBounds.X, 0, (startLine - 1) * lineHeight)
			else
				-- Multi-line selection
				local totalHeight = (endLine - startLine + 1) * lineHeight
				local firstLineText = string.sub(text, lines[startLine] + 1, selStart)
				local lastLineText = string.sub(text, selEnd + 1, lines[endLine + 1] - 1)
				local firstLineBounds = TextService:GetTextSize(firstLineText, textSize, font, Vector2.new(availableWidth, 99999))
				local lastLineBounds = TextService:GetTextSize(lastLineText, textSize, font, Vector2.new(availableWidth, 99999))
				local selStartBounds = TextService:GetTextSize(string.sub(text, lines[startLine] + 1, selStart), textSize, font, Vector2.new(availableWidth, 99999))
				local selEndBounds = TextService:GetTextSize(string.sub(text, lines[endLine] + 1, selEnd), textSize, font, Vector2.new(availableWidth, 99999))

				targetSelectionSize = UDim2.new(1, -leftPadding, 0, totalHeight)
				targetSelectionPosition = UDim2.new(0, leftPadding, 0, (startLine - 1) * lineHeight)
				-- Adjust for partial lines (simplified for now, can be refined)
			end
		end

		-- Create tweens for smooth transitions
		local tweenInfo = TweenInfo.new(
			0.1, -- Faster duration of the animation (100ms)
			Enum.EasingStyle.Quad, -- Easing style for smooth movement
			Enum.EasingDirection.Out -- Easing direction
		)

		-- Tween the highlight
		local highlightTween = TweenService:Create(HighlightFrame, tweenInfo, {
			Size = targetHighlightSize,
			Position = targetHighlightPosition
		})

		-- Tween the caret
		local caretTween = TweenService:Create(CaretFrame, tweenInfo, {
			Position = targetCaretPosition
		})

		-- Tween the selection
		local selectionTween = TweenService:Create(SelectionFrame, tweenInfo, {
			Size = targetSelectionSize,
			Position = targetSelectionPosition
		})

		-- Play tweens and set visibility only if TextBox is focused
		HighlightFrame.Visible = TextBox:IsFocused()
		CaretFrame.Visible = TextBox:IsFocused() and not (TextBox.SelectionStart >= 0 and TextBox.CursorPosition >= 0 and TextBox.SelectionStart ~= TextBox.CursorPosition)
		SelectionFrame.Visible = TextBox:IsFocused() and isSelectionActive
		if TextBox:IsFocused() then
			highlightTween:Play()
			caretTween:Play()
			selectionTween:Play()
		end
	end

	local function updateSize()
		local text = TextBox.Text
		local textSize = TextBox.TextSize
		local font = TextBox.Font
		local scrollingFrameSize = ScrollingFrame.AbsoluteSize

		-- Calculate text bounds with the ScrollingFrame's width (minus left padding) as the constraint
		local padding = ScrollingFrame:FindFirstChildOfClass("UIPadding")
		local leftPadding = padding and padding.PaddingLeft.Offset or 0
		local availableWidth = scrollingFrameSize.X - leftPadding

		-- Use availableWidth as the max width for text wrapping
		local textBounds = TextService:GetTextSize(text, textSize, font, Vector2.new(availableWidth, 99999))

		-- Set TextBox X size to fill the available width of the ScrollingFrame
		-- Set Y size to at least 1 (scale) of ScrollingFrame height, but grow if textBounds.Y is larger
		local minHeight = scrollingFrameSize.Y -- Minimum height is ScrollingFrame's absolute height
		local newHeight = math.max(minHeight, textBounds.Y + 5) -- Add padding for Y, allow growth

		TextBox.Size = UDim2.new(1, -leftPadding, 0, newHeight)

		-- Update ScrollingFrame's CanvasSize to accommodate the TextBox height
		ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, newHeight)

		-- Update highlight, caret, and selection
		updateHighlightCaretAndSelection()
	end

	-- Connect updateSize to Text changes
	TextBox:GetPropertyChangedSignal("Text"):Connect(updateSize)

	-- Connect updateHighlightCaretAndSelection to CursorPosition and SelectionStart changes
	TextBox:GetPropertyChangedSignal("CursorPosition"):Connect(updateHighlightCaretAndSelection)
	TextBox:GetPropertyChangedSignal("SelectionStart"):Connect(updateHighlightCaretAndSelection)

	-- Connect updateHighlightCaretAndSelection to focus changes
	TextBox.Focused:Connect(function()
		updateHighlightCaretAndSelection()
		-- Ensure caret is visible when focused, unless there's a selection
		CaretFrame.Visible = true
	end)
	TextBox.FocusLost:Connect(function()
		HighlightFrame.Visible = false -- Hide highlight when TextBox loses focus
		CaretFrame.Visible = false -- Hide caret when TextBox loses focus
		SelectionFrame.Visible = false -- Hide selection when TextBox loses focus
	end)

	-- Call once initially to set the size, highlight, caret, and selection
	updateSize()
end
task.spawn(C_11)
-- StarterGui.Exec.Topbar.MainStuff.TextButton.LocalScript
local function C_1d()
	local script = G2L["1d"]
	local button = script.Parent
	local responseLabel = button.Parent.ScrollingFrame.ResponseLabel
	button.MouseButton1Click:Connect(function()
		loadstring(responseLabel.Text)()
	end)
end
task.spawn(C_1d)
-- StarterGui.Exec.Topbar.MainStuff.TextButton.LocalScript
local function C_1f()
	local script = G2L["1f"]
	script.Parent.MouseButton1Click:Connect(function()
		script.Parent.Parent.ScrollingFrame.ResponseLabel.Text = ""
	end)
end
task.spawn(C_1f)
-- StarterGui.Exec.Topbar.MainStuff.TextButton.LocalScript
local function C_21()
	local script = G2L["21"]
	script.Parent.MouseButton1Click:Connect(function()
		script.Parent.Parent.opensavedialog.Visible = true
		script.Parent.Parent.opensavedialog.save.Visible = true
	end)
end
task.spawn(C_21)
-- StarterGui.Exec.Topbar.MainStuff.TextButton.LocalScript
local function C_23()
	local script = G2L["23"]
	script.Parent.MouseButton1Click:Connect(function()
		script.Parent.Parent.opensavedialog.Visible = true
		script.Parent.Parent.opensavedialog.open.Visible = true
	end)
end
task.spawn(C_23)
-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.save.TextButton.LocalScript
local function C_28()
	local script = G2L["28"]
	--[[
	made by dnezero cuh (mom im famous yuhh) also dont mind the skiddish print()s i felt like it
	]]
	local button = script.Parent
	local textbox = button.Parent.TextBox
	local responseLabel = button.Parent.Parent.Parent.ScrollingFrame.ResponseLabel

	button.MouseButton1Click:Connect(function()
		local filename = textbox.Text
		local content = responseLabel.Text

		if not filename or filename:match("^%s*$") then
			print("[System] Filename cannot be empty.")
			return
		end

		local safeFilename = (filename:gsub("[/\\|%*:?\"<>]", "_"))

		local success, err = pcall(function()
			writefile(safeFilename, content)
		end)

		if success then
			print(string.format("[System] Successfully saved to: %s", safeFilename))
		else
			print(string.format("[System] Failed to save file. Error: %s", tostring(err)))
		end
	end)
end
task.spawn(C_28)
-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.save.TextButton.LocalScript
local function C_2a()
	local script = G2L["2a"]
	script.Parent.MouseButton1Click:Connect(function()
		script.Parent.Parent.Parent.Visible = false
		script.Parent.Parent.Visible = false
	end)
end
task.spawn(C_2a)
-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.open.TextButton.LocalScript
local function C_2e()
	local script = G2L["2e"]
	--[[
	made by dnezero cuh (yes its me again)
	]]
	local openFileButton = script.Parent
	local fileNameInput = openFileButton.Parent.TextBox
	local outputDisplay = openFileButton.Parent.Parent.Parent.ScrollingFrame.ResponseLabel

	local function attemptReadFile(filename)
		local success, content = pcall(function()
			return readfile(filename)
		end)

		if success then
			return success, content
		end

		success, content = pcall(function()
			if getfile then
				return getfile(filename)
			elseif isfile and isfile(filename) then
				return readfile(filename)
			end
			error("File access function (readfile/getfile) not available or file not found.")
		end)

		return success, content
	end

	openFileButton.MouseButton1Click:Connect(function()
		local filename = fileNameInput.Text

		if not filename or filename:match("^%s*$") then
			print("[File Loader] Please enter a file name to load.")
			return
		end

		local safeFilename = (filename:gsub("[/\\|%*:?\"<>]", "_"))

		print(string.format("[File Loader] Attempting to load: %s", safeFilename))

		local success, content = attemptReadFile(safeFilename)

		if success and type(content) == "string" then
			outputDisplay.Text = content
			print(string.format("[File Loader] Successfully loaded '%s'. Content displayed.", safeFilename))
		else
			local errorMessage = content or "An unknown error occurred during file reading."
			outputDisplay.Text = "Error: Could not load file."
			print(string.format("[File Loader Error] Failed to read file '%s'. Details: %s", safeFilename, errorMessage))
		end
	end)
end
task.spawn(C_2e)
-- StarterGui.Exec.Topbar.MainStuff.opensavedialog.open.TextButton.LocalScript
local function C_30()
	local script = G2L["30"]
	script.Parent.MouseButton1Click:Connect(function()
		script.Parent.Parent.Parent.Visible = false
		script.Parent.Parent.Visible = false
	end)
end
task.spawn(C_30)
