assert(getscriptbytecode, "Exploit not supported.")

local API = "http://api.plusgiant5.com"
local MAX_RETRIES = 5
local RETRY_DELAY = 1
local REQUEST_DELAY = 0.5

local last_call = 0
local queue = {}

local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local function addToQueue(konstantType, scriptPath, callback, retryCount)
	table.insert(queue, {
		konstantType = konstantType,
		scriptPath = scriptPath,
		callback = callback,
		retryCount = retryCount
	})

	task.defer(function() callback(konstantType, scriptPath, retryCount) end)
end

local function call(konstantType, scriptPath, retryCount)
	retryCount = retryCount or 0

	local success, bytecode = pcall(getscriptbytecode, scriptPath)
	if not success then return `-- Failed to get script bytecode, error:\n\n--[[\n{bytecode}\n--]]` end

	local time_elapsed = os.clock() - last_call
	if time_elapsed <= REQUEST_DELAY then task.wait(REQUEST_DELAY - time_elapsed) end

	local httpResult = request({
		Url = API .. konstantType,
		Body = bytecode,
		Method = "POST",
		Headers = {
			["Content-Type"] = "text/plain"
		}
	})

	last_call = os.clock()

	if httpResult.StatusCode ~= 200 or httpResult.Body:find("-- BAD error") then
		if retryCount < MAX_RETRIES then
			task.wait(RETRY_DELAY)
			-- print("retrying")
			addToQueue(konstantType, scriptPath, call, retryCount + 1)
		else
			return `-- Retrying... Attempt {retryCount + 1}\n`
		end

		return `-- Error occurred after {MAX_RETRIES} retries, final error:\n\n--[[\n{httpResult.Body}\n--]]`
	else
		return httpResult.Body
	end
end

local function decompile(scriptPath)
	addToQueue("/konstant/decompile", scriptPath, call)
end

local function disassemble(scriptPath)
	addToQueue("/konstant/disassemble", scriptPath, call)
end

getgenv().decompile = decompile
getgenv().disassemble = disassemble
