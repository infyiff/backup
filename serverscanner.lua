-- https://github.com/sajicooltoday/sajis-scripts
local cloneref = cloneref or function(o) return o end
local gethui = gethui or get_hidden_gui

-- author: saji
-- https://discord.gg/5SszD6fWC8

local uis = cloneref(game:GetService("UserInputService"))
local tween_service = cloneref(game:GetService("TweenService"))
local run_service = cloneref(game:GetService("RunService"))
local players = cloneref(game:GetService("Players"))
local core_gui = cloneref(game:GetService("CoreGui"))

local prefix = "[SERVER SCANNER]: "
local roots = { server_storage = true, server_script_service = true }
local root_map = { server_storage = "ServerStorage", server_script_service = "ServerScriptService" }
local skip = { CorePackages = true, RobloxReplicatedStorage = true, Players = true, CoreGui = true }

local stats = { total = 0, decompiled = 0, matched = 0 }
local log_count = 0
local max_line_width = 0
local log_queue = {}
local scan_delay = 2

local status_label: TextLabel
local gui_frame: Frame
local log_container: ScrollingFrame

local function get_parent()
	local ok, hui = pcall(gethui)
	return (ok and hui) or core_gui or cloneref(players.LocalPlayer:WaitForChild("PlayerGui"))
end

local function build_gui()
	local gui = Instance.new("GuiMain")
	gui.Name = "sajiwasherelmao"
	gui.ResetOnSpawn = false
	gui.Parent = get_parent()

	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.45
	frame.BorderSizePixel = 0
	frame.Position = UDim2.new(0.5, -300, 0.5, -200)
	frame.Size = UDim2.new(0, 600, 0, 420)
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.Parent = frame

	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.BorderSizePixel = 0
	status.Position = UDim2.new(0, 5, 0, 5)
	status.Size = UDim2.new(1, -10, 0, 18)
	status.Text = ""
	status.TextColor3 = Color3.fromRGB(255, 200, 60)
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.Parent = frame

	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Position = UDim2.new(0, 5, 0, 28)
	scroll.ScrollBarImageColor3 = Color3.new(1, 1, 1)
	scroll.Size = UDim2.new(1, -10, 1, -58)
	scroll.CanvasPosition = Vector2.zero
	scroll.Parent = frame

	task.defer(function()
		scroll.CanvasPosition = Vector2.zero
	end)

	return frame, scroll, status, gui
end

gui_frame, log_container, status_label, guibro = build_gui()

local drag_toggle = false
local drag_start = nil
local drag_origin = nil

local function update_drag(input)
	local delta = input.Position - drag_start
	local position = UDim2.new(drag_origin.X.Scale, drag_origin.X.Offset + delta.X, drag_origin.Y.Scale, drag_origin.Y.Offset + delta.Y)
	tween_service:Create(gui_frame, TweenInfo.new(0.25), { Position = position }):Play()
end

gui_frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		drag_toggle = true
		drag_start = input.Position
		drag_origin = gui_frame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				drag_toggle = false
			end
		end)
	end
end)

uis.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		if drag_toggle then
			update_drag(input)
		end
	end
end)

local flush_connection
flush_connection = run_service.Heartbeat:Connect(function()
	if #log_queue == 0 then return end

	local batch = log_queue
	log_queue = {}

	for _, msg in ipairs(batch) do
		local text_width = #msg * 7

		local lbl = Instance.new("TextLabel")
		lbl.BackgroundTransparency = 1
		lbl.Position = UDim2.new(0, 0, 0, log_count * 20)
		lbl.Size = UDim2.new(0, text_width, 0, 20)
		lbl.Text = msg
		lbl.TextColor3 = Color3.new(1, 1, 1)
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = log_container

		log_count += 1
		if text_width > max_line_width then
			max_line_width = text_width
		end
	end

	log_container.CanvasSize = UDim2.new(0, max_line_width, 0, log_count * 20)
	log_container.CanvasPosition = Vector2.new(log_container.CanvasPosition.X, log_count * 20)
end)

local function log(msg: string)
	print(prefix .. msg)
	table.insert(log_queue, prefix .. msg)
end

local function build_speed_menu()
	local overlay = Instance.new("Frame")
	overlay.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	overlay.BackgroundTransparency = 0.15
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.ZIndex = 10
	overlay.Parent = gui_frame

	local corner = Instance.new("UICorner")
	corner.Parent = overlay

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 0, 0, 65)
	title.Size = UDim2.new(1, 0, 0, 30)
	title.Text = "discord.gg/5SszD6fWC8\nselect scan speed"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 15
	title.ZIndex = 11
	title.Parent = overlay

	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.new(0, 0, 0, 115)
	sub.Size = UDim2.new(1, 0, 0, 20)
	sub.Text = "faster = higher risk of breaking the game"
	sub.TextColor3 = Color3.fromRGB(180, 180, 180)
	sub.TextSize = 13
	sub.ZIndex = 11
	sub.Parent = overlay

	local btn_data = {
		{ label = "safe (2s delay)",   color = Color3.fromRGB(40, 140, 60),  delay = 2   },
		{ label = "normal (1s delay)", color = Color3.fromRGB(180, 140, 20), delay = 1   },
		{ label = "fast (0.5s delay)", color = Color3.fromRGB(180, 80, 20),  delay = 0.5 },
        { label = "no delay (high end pc)", color = Color3.fromRGB(180, 30, 20),  delay = 0 },
	}

	local chosen = Instance.new("BindableEvent")

	for i, data in ipairs(btn_data) do
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = data.color
		btn.BorderSizePixel = 0
		btn.Position = UDim2.new(0.5, -120, 0, 155 + (i - 1) * 45)
		btn.Size = UDim2.new(0, 240, 0, 34)
		btn.Text = data.label
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextSize = 14
		btn.ZIndex = 11
		btn.Parent = overlay

		btn.MouseButton1Click:Connect(function()
			chosen:Fire(data.delay)
		end)
	end

	local picked_delay = chosen.Event:Wait()
	chosen:Destroy()
	overlay:Destroy()
	return picked_delay
end

local function ends_with_s(name: string): boolean
	return name:sub(-1):lower() == "s"
end

local function looks_like_module(name: string): boolean
	local lower = name:lower()
	return (lower:find("service") or lower:find("module")) and not ends_with_s(name)
end

local function resolve_type(name: string, i: number, total: number): string
	if ends_with_s(name) then return "Folder" end
	if i == total then
		return looks_like_module(name) and "ModuleScript" or "Script"
	end
	return "Folder"
end

local rebuilt_paths = {}

local function rebuild_path(path: string, from: string): boolean
	local parts = string.split(path, ".")
	if #parts < 2 then return false end

	local root_key = parts[1]
	if not roots[root_key] then return false end

	if rebuilt_paths[path] then return true end
	rebuilt_paths[path] = true

	local root = cloneref(game:GetService(root_map[root_key]))
	if not root then return false end

	local cur = root
	local built = {}

	for i = 2, #parts do
		local part = parts[i]
		local kind = resolve_type(part, i, #parts)
		local existing = cur:FindFirstChild(part)

		if existing then
			cur = existing
		else
			local inst = Instance.new(kind)
			inst.Name = part
			inst.Parent = cur
			table.insert(built, part .. " [" .. kind .. "]")
			cur = inst
		end
	end

	if #built > 0 then
		log("created: " .. table.concat(built, " → "))
		log("   ↳ from: " .. from)
	end

	return true
end

local var_patterns = {
	{ "local%s+([%w_]+)%s*=%s*game%.ServerStorage",                      "server_storage"        },
	{ "local%s+([%w_]+)%s*=%s*game%.ServerScriptService",                "server_script_service" },
	{ 'local%s+([%w_]+)%s*=%s*game:GetService%("ServerStorage"%)',       "server_storage"        },
	{ 'local%s+([%w_]+)%s*=%s*game:GetService%("ServerScriptService"%)', "server_script_service" },
    { 'local%s+([%w_]+)%s*=%s*game:FindService%("ServerStorage"%)',       "server_storage"        },
	{ 'local%s+([%w_]+)%s*=%s*game:FindService%("ServerScriptService"%)', "server_script_service" },
}

local direct_patterns = {
	{ "ServerStorage%.([%w_%.]+)",             "server_storage"        },
	{ "ServerScriptService%.([%w_%.]+)",       "server_script_service" },
	{ "game%.ServerStorage%.([%w_%.]+)",       "server_storage"        },
	{ "game%.ServerScriptService%.([%w_%.]+)", "server_script_service" },
}

local function scan(source: string, name: string): boolean
	local vars = {}
	local hit = false

	for _, def in ipairs(var_patterns) do
		for var in string.gmatch(source, def[1]) do
			vars[var] = def[2]
			log("✅ found assignment: " .. var .. " → " .. def[2])
			hit = true
		end
	end

	for var, svc in string.gmatch(source, 'local%s+([%w_]+)%s*=%s*game:GetService%("([%w_]+)"%)') do
		local key = svc == "ServerStorage" and "server_storage"
			or svc == "ServerScriptService" and "server_script_service"
			or nil
		if key and roots[key] and not vars[var] then
			vars[var] = key
			log("✅ found assignment: " .. var .. " → " .. key)
			hit = true
		end
	end

	for var, svc in pairs(vars) do
		for path in string.gmatch(source, var .. "%.([%w_%.]+)") do
			rebuild_path(svc .. "." .. path, name)
			log("✅ found path via " .. var .. ": " .. path)
			hit = true
		end
	end

	for _, def in ipairs(direct_patterns) do
		for path in string.gmatch(source, def[1]) do
			rebuild_path(def[2] .. "." .. path, name)
			hit = true
		end
	end

	for key in pairs(roots) do
		for path in string.gmatch(source, 'GetService%("' .. root_map[key] .. '"%)%.([%w_%.]+)') do
			rebuild_path(key .. "." .. path, name)
			hit = true
		end
	end

	log(hit and ("✅ references found in: " .. name) or ("❌ nothing found in: " .. name))
	return hit
end

local function scan_container(container: Instance)
	if skip[container.Name] then return end

	for _, obj in ipairs(container:GetDescendants()) do
		if not (obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")) then continue end

		local full_name = obj:GetFullName()
		stats.total += 1
		status_label.Text = "scanning... (" .. stats.total .. " scripts found)"
		log("decompiling: " .. full_name)

		local done = false
		local ok, src

		task.delay(10, function()
			if not done then
				log("❌ timed out: " .. full_name)
				done = true
			end
		end)

		ok, src = pcall(decompile, obj)
		task.wait(scan_delay)

		if done then continue end
		done = true

		if ok and type(src) == "string" and #src > 0 then
			stats.decompiled += 1
			if scan(src, full_name) then
				stats.matched += 1
			end
		else
			log("❌ failed to decompile: " .. full_name)
		end
	end
end

scan_delay = build_speed_menu()

log("starting scan...")
status_label.Text = "scanning..."

local replicated = cloneref(game:GetService("ReplicatedStorage"))
if replicated then
	scan_container(replicated)
end

for _, child in ipairs(game:GetChildren()) do
	if child.Name ~= "ReplicatedStorage" and not skip[child.Name] then
		scan_container(child)
	end
end

log("scan complete ✅")
log("scripts scanned: " .. stats.total)
log("successfully decompiled: " .. stats.decompiled)
log("scripts with references: " .. stats.matched)
log("if scripts were found, open up dex or any explorer")

status_label.Text = "done — " .. stats.matched .. " matches in " .. stats.total .. " scripts (discord.gg/5SszD6fWC8)"
status_label.TextColor3 = Color3.fromRGB(100, 220, 100)

local close_btn = Instance.new("TextButton")
close_btn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
close_btn.BorderSizePixel = 0
close_btn.Position = UDim2.new(0, 5, 1, -25)
close_btn.Size = UDim2.new(1, -10, 0, 20)
close_btn.Text = "close"
close_btn.TextColor3 = Color3.new(1, 1, 1)
close_btn.Parent = gui_frame

close_btn.MouseButton1Click:Connect(function()
	guibro:Destroy()
end)
