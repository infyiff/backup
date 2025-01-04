local print = function() end
local warn = function() end
local error = function() end

local t = {}

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------JSON Functions Begin----------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

 --JSON Encoder and Parser for Lua 5.1
 --
 --Copyright 2007 Shaun Brown  (http://www.chipmunkav.com)
 --All Rights Reserved.
 
 --Permission is hereby granted, free of charge, to any person 
 --obtaining a copy of this software to deal in the Software without 
 --restriction, including without limitation the rights to use, 
 --copy, modify, merge, publish, distribute, sublicense, and/or 
 --sell copies of the Software, and to permit persons to whom the 
 --Software is furnished to do so, subject to the following conditions:
 
 --The above copyright notice and this permission notice shall be 
 --included in all copies or substantial portions of the Software.
 --If you find this software useful please give www.chipmunkav.com a mention.

 --THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
 --EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
 --OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 --IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR 
 --ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
 --CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN 
 --CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
local string = string
local math = math
local table = table
local error = error
local tonumber = tonumber
local tostring = tostring
local type = type
local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local assert = assert


local StringBuilder = {
	buffer = {}
}

function StringBuilder:New()
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.buffer = {}
	return o
end

function StringBuilder:Append(s)
	self.buffer[#self.buffer+1] = s
end

function StringBuilder:ToString()
	return table.concat(self.buffer)
end

local JsonWriter = {
	backslashes = {
		['\b'] = "\\b",
		['\t'] = "\\t",	
		['\n'] = "\\n", 
		['\f'] = "\\f",
		['\r'] = "\\r", 
		['"']  = "\\\"", 
		['\\'] = "\\\\", 
		['/']  = "\\/"
	}
}

function JsonWriter:New()
	local o = {}
	o.writer = StringBuilder:New()
	setmetatable(o, self)
	self.__index = self
	return o
end

function JsonWriter:Append(s)
	self.writer:Append(s)
end

function JsonWriter:ToString()
	return self.writer:ToString()
end

function JsonWriter:Write(o)
	local t = type(o)
	if t == "nil" then
		self:WriteNil()
	elseif t == "boolean" then
		self:WriteString(o)
	elseif t == "number" then
		self:WriteString(o)
	elseif t == "string" then
		self:ParseString(o)
	elseif t == "table" then
		self:WriteTable(o)
	elseif t == "function" then
		self:WriteFunction(o)
	elseif t == "thread" then
		self:WriteError(o)
	elseif t == "userdata" then
		self:WriteError(o)
	end
end

function JsonWriter:WriteNil()
	self:Append("null")
end

function JsonWriter:WriteString(o)
	self:Append(tostring(o))
end

function JsonWriter:ParseString(s)
	self:Append('"')
	self:Append(string.gsub(s, "[%z%c\\\"/]", function(n)
		local c = self.backslashes[n]
		if c then return c end
		return string.format("\\u%.4X", string.byte(n))
	end))
	self:Append('"')
end

function JsonWriter:IsArray(t)
	local count = 0
	local isindex = function(k) 
		if type(k) == "number" and k > 0 then
			if math.floor(k) == k then
				return true
			end
		end
		return false
	end
	for k,v in pairs(t) do
		if not isindex(k) then
			return false, '{', '}'
		else
			count = math.max(count, k)
		end
	end
	return true, '[', ']', count
end

function JsonWriter:WriteTable(t)
	local ba, st, et, n = self:IsArray(t)
	self:Append(st)	
	if ba then		
		for i = 1, n do
			self:Write(t[i])
			if i < n then
				self:Append(',')
			end
		end
	else
		local first = true;
		for k, v in pairs(t) do
			if not first then
				self:Append(',')
			end
			first = false;			
			self:ParseString(k)
			self:Append(':')
			self:Write(v)			
		end
	end
	self:Append(et)
end

function JsonWriter:WriteError(o)
	error(string.format(
		"Encoding of %s unsupported", 
		tostring(o)))
end

function JsonWriter:WriteFunction(o)
	if o == Null then 
		self:WriteNil()
	else
		self:WriteError(o)
	end
end

local StringReader = {
	s = "",
	i = 0
}

function StringReader:New(s)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.s = s or o.s
	return o	
end

function StringReader:Peek()
	local i = self.i + 1
	if i <= #self.s then
		return string.sub(self.s, i, i)
	end
	return nil
end

function StringReader:Next()
	self.i = self.i+1
	if self.i <= #self.s then
		return string.sub(self.s, self.i, self.i)
	end
	return nil
end

function StringReader:All()
	return self.s
end

local JsonReader = {
	escapes = {
		['t'] = '\t',
		['n'] = '\n',
		['f'] = '\f',
		['r'] = '\r',
		['b'] = '\b',
	}
}

function JsonReader:New(s)
	local o = {}
	o.reader = StringReader:New(s)
	setmetatable(o, self)
	self.__index = self
	return o;
end

function JsonReader:Read()
	self:SkipWhiteSpace()
	local peek = self:Peek()
	if peek == nil then
		error(string.format(
			"Nil string: '%s'", 
			self:All()))
	elseif peek == '{' then
		return self:ReadObject()
	elseif peek == '[' then
		return self:ReadArray()
	elseif peek == '"' then
		return self:ReadString()
	elseif string.find(peek, "[%+%-%d]") then
		return self:ReadNumber()
	elseif peek == 't' then
		return self:ReadTrue()
	elseif peek == 'f' then
		return self:ReadFalse()
	elseif peek == 'n' then
		return self:ReadNull()
	elseif peek == '/' then
		self:ReadComment()
		return self:Read()
	else
		return nil
	end
end
		
function JsonReader:ReadTrue()
	self:TestReservedWord{'t','r','u','e'}
	return true
end

function JsonReader:ReadFalse()
	self:TestReservedWord{'f','a','l','s','e'}
	return false
end

function JsonReader:ReadNull()
	self:TestReservedWord{'n','u','l','l'}
	return nil
end

function JsonReader:TestReservedWord(t)
	for i, v in ipairs(t) do
		if self:Next() ~= v then
			 error(string.format(
				"Error reading '%s': %s", 
				table.concat(t), 
				self:All()))
		end
	end
end

function JsonReader:ReadNumber()
        local result = self:Next()
        local peek = self:Peek()
        while peek ~= nil and string.find(
		peek, 
		"[%+%-%d%.eE]") do
            result = result .. self:Next()
            peek = self:Peek()
	end
	result = tonumber(result)
	if result == nil then
	        error(string.format(
			"Invalid number: '%s'", 
			result))
	else
		return result
	end
end

function JsonReader:ReadString()
	local result = ""
	assert(self:Next() == '"')
        while self:Peek() ~= '"' do
		local ch = self:Next()
		if ch == '\\' then
			ch = self:Next()
			if self.escapes[ch] then
				ch = self.escapes[ch]
			end
		end
                result = result .. ch
	end
        assert(self:Next() == '"')
	local fromunicode = function(m)
		return string.char(tonumber(m, 16))
	end
	return string.gsub(
		result, 
		"u%x%x(%x%x)", 
		fromunicode)
end

function JsonReader:ReadComment()
        assert(self:Next() == '/')
        local second = self:Next()
        if second == '/' then
            self:ReadSingleLineComment()
        elseif second == '*' then
            self:ReadBlockComment()
        else
            error(string.format(
		"Invalid comment: %s", 
		self:All()))
	end
end

function JsonReader:ReadBlockComment()
	local done = false
	while not done do
		local ch = self:Next()		
		if ch == '*' and self:Peek() == '/' then
			done = true
                end
		if not done and 
			ch == '/' and 
			self:Peek() == "*" then
                    error(string.format(
			"Invalid comment: %s, '/*' illegal.",  
			self:All()))
		end
	end
	self:Next()
end

function JsonReader:ReadSingleLineComment()
	local ch = self:Next()
	while ch ~= '\r' and ch ~= '\n' do
		ch = self:Next()
	end
end

function JsonReader:ReadArray()
	local result = {}
	assert(self:Next() == '[')
	local done = false
	if self:Peek() == ']' then
		done = true;
	end
	while not done do
		local item = self:Read()
		result[#result+1] = item
		self:SkipWhiteSpace()
		if self:Peek() == ']' then
			done = true
		end
		if not done then
			local ch = self:Next()
			if ch ~= ',' then
				error(string.format(
					"Invalid array: '%s' due to: '%s'", 
					self:All(), ch))
			end
		end
	end
	assert(']' == self:Next())
	return result
end

function JsonReader:ReadObject()
	local result = {}
	assert(self:Next() == '{')
	local done = false
	if self:Peek() == '}' then
		done = true
	end
	while not done do
		local key = self:Read()
		if type(key) ~= "string" then
			error(string.format(
				"Invalid non-string object key: %s", 
				key))
		end
		self:SkipWhiteSpace()
		local ch = self:Next()
		if ch ~= ':' then
			error(string.format(
				"Invalid object: '%s' due to: '%s'", 
				self:All(), 
				ch))
		end
		self:SkipWhiteSpace()
		local val = self:Read()
		result[key] = val
		self:SkipWhiteSpace()
		if self:Peek() == '}' then
			done = true
		end
		if not done then
			ch = self:Next()
                	if ch ~= ',' then
				error(string.format(
					"Invalid array: '%s' near: '%s'", 
					self:All(), 
					ch))
			end
		end
	end
	assert(self:Next() == "}")
	return result
end

function JsonReader:SkipWhiteSpace()
	local p = self:Peek()
	while p ~= nil and string.find(p, "[%s/]") do
		if p == '/' then
			self:ReadComment()
		else
			self:Next()
		end
		p = self:Peek()
	end
end

function JsonReader:Peek()
	return self.reader:Peek()
end

function JsonReader:Next()
	return self.reader:Next()
end

function JsonReader:All()
	return self.reader:All()
end

function Encode(o)
	local writer = JsonWriter:New()
	writer:Write(o)
	return writer:ToString()
end

function Decode(s)
	local reader = JsonReader:New(s)
	return reader:Read()
end

function Null()
	return Null
end
-------------------- End JSON Parser ------------------------

t.DecodeJSON = function(jsonString)
	pcall(function() warn("RbxUtility.DecodeJSON is deprecated, please use Game:GetService('HttpService'):JSONDecode() instead.") end)

	if type(jsonString) == "string" then
		return Decode(jsonString)
	end
	print("RbxUtil.DecodeJSON expects string argument!")
	return nil
end

t.EncodeJSON = function(jsonTable)
	pcall(function() warn("RbxUtility.EncodeJSON is deprecated, please use Game:GetService('HttpService'):JSONEncode() instead.") end)
	return Encode(jsonTable)
end








------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--------------------------------------------Terrain Utilities Begin-----------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--makes a wedge at location x, y, z
--sets cell x, y, z to default material if parameter is provided, if not sets cell x, y, z to be whatever material it previously w
--returns true if made a wedge, false if the cell remains a block
t.MakeWedge = function(x, y, z, defaultmaterial)
	return game:GetService("Terrain"):AutoWedgeCell(x,y,z)
end

t.SelectTerrainRegion = function(regionToSelect, color, selectEmptyCells, selectionParent)
	local terrain = game:GetService("Workspace"):FindFirstChild("Terrain")
	if not terrain then return end

	assert(regionToSelect)
	assert(color)

	if not type(regionToSelect) == "Region3" then
		error("regionToSelect (first arg), should be of type Region3, but is type",type(regionToSelect))
	end
	if not type(color) == "BrickColor" then
		error("color (second arg), should be of type BrickColor, but is type",type(color))
	end

	-- frequently used terrain calls (speeds up call, no lookup necessary)
	local GetCell = terrain.GetCell
	local WorldToCellPreferSolid = terrain.WorldToCellPreferSolid
	local CellCenterToWorld = terrain.CellCenterToWorld
	local emptyMaterial = Enum.CellMaterial.Empty

	-- container for all adornments, passed back to user
	local selectionContainer = Instance.new("Model")
	selectionContainer.Name = "SelectionContainer"
	selectionContainer.Archivable = false
	if selectionParent then
		selectionContainer.Parent = selectionParent
	else
		selectionContainer.Parent = game:GetService("Workspace")
	end

	local updateSelection = nil -- function we return to allow user to update selection
	local currentKeepAliveTag = nil -- a tag that determines whether adorns should be destroyed
	local aliveCounter = 0 -- helper for currentKeepAliveTag
	local lastRegion = nil -- used to stop updates that do nothing
	local adornments = {} -- contains all adornments
	local reusableAdorns = {}

	local selectionPart = Instance.new("Part")
	selectionPart.Name = "SelectionPart"
	selectionPart.Transparency = 1
	selectionPart.Anchored = true
	selectionPart.Locked = true
	selectionPart.CanCollide = false
	selectionPart.Size = Vector3.new(4.2,4.2,4.2)

	local selectionBox = Instance.new("SelectionBox")

	-- srs translation from region3 to region3int16
	local function Region3ToRegion3int16(region3)
		local theLowVec = region3.CFrame.p - (region3.Size/2) + Vector3.new(2,2,2)
		local lowCell = WorldToCellPreferSolid(terrain,theLowVec)

		local theHighVec = region3.CFrame.p + (region3.Size/2) - Vector3.new(2,2,2)
		local highCell = WorldToCellPreferSolid(terrain, theHighVec)

		local highIntVec = Vector3int16.new(highCell.x,highCell.y,highCell.z)
		local lowIntVec = Vector3int16.new(lowCell.x,lowCell.y,lowCell.z)

		return Region3int16.new(lowIntVec,highIntVec)
	end

	-- helper function that creates the basis for a selection box
	function createAdornment(theColor)
		local selectionPartClone = nil
		local selectionBoxClone = nil

		if #reusableAdorns > 0 then
			selectionPartClone = reusableAdorns[1]["part"]
			selectionBoxClone = reusableAdorns[1]["box"]
			table.remove(reusableAdorns,1)

			selectionBoxClone.Visible = true
		else
			selectionPartClone = selectionPart:Clone()
			selectionPartClone.Archivable = false

			selectionBoxClone = selectionBox:Clone()
			selectionBoxClone.Archivable = false

			selectionBoxClone.Adornee = selectionPartClone
			selectionBoxClone.Parent = selectionContainer

			selectionBoxClone.Adornee = selectionPartClone

			selectionBoxClone.Parent = selectionContainer
		end
			
		if theColor then
			selectionBoxClone.Color = theColor
		end

		return selectionPartClone, selectionBoxClone
	end

	-- iterates through all current adornments and deletes any that don't have latest tag
	function cleanUpAdornments()
		for cellPos, adornTable in pairs(adornments) do

			if adornTable.KeepAlive ~= currentKeepAliveTag then -- old news, we should get rid of this
				adornTable.SelectionBox.Visible = false
				table.insert(reusableAdorns,{part = adornTable.SelectionPart, box = adornTable.SelectionBox})
				adornments[cellPos] = nil
			end
		end
	end

	-- helper function to update tag
	function incrementAliveCounter()
		aliveCounter = aliveCounter + 1
		if aliveCounter > 1000000 then
			aliveCounter = 0
		end
		return aliveCounter
	end

	-- finds full cells in region and adorns each cell with a box, with the argument color
	function adornFullCellsInRegion(region, color)
		local regionBegin = region.CFrame.p - (region.Size/2) + Vector3.new(2,2,2)
		local regionEnd = region.CFrame.p + (region.Size/2) - Vector3.new(2,2,2)

		local cellPosBegin = WorldToCellPreferSolid(terrain, regionBegin)
		local cellPosEnd = WorldToCellPreferSolid(terrain, regionEnd)

		currentKeepAliveTag = incrementAliveCounter()
		for y = cellPosBegin.y, cellPosEnd.y do
			for z = cellPosBegin.z, cellPosEnd.z do
				for x = cellPosBegin.x, cellPosEnd.x do
					local cellMaterial = GetCell(terrain, x, y, z)
					
					if cellMaterial ~= emptyMaterial then
						local cframePos = CellCenterToWorld(terrain, x, y, z)
						local cellPos = Vector3int16.new(x,y,z)

						local updated = false
						for cellPosAdorn, adornTable in pairs(adornments) do
							if cellPosAdorn == cellPos then
								adornTable.KeepAlive = currentKeepAliveTag
								if color then
									adornTable.SelectionBox.Color = color
								end
								updated = true
								break
							end 
						end

						if not updated then
							local selectionPart, selectionBox = createAdornment(color)
							selectionPart.Size = Vector3.new(4,4,4)
							selectionPart.CFrame = CFrame.new(cframePos)
							local adornTable = {SelectionPart = selectionPart, SelectionBox = selectionBox, KeepAlive = currentKeepAliveTag}
							adornments[cellPos] = adornTable
						end
					end
				end
			end
		end
		cleanUpAdornments()
	end


	------------------------------------- setup code ------------------------------
	lastRegion = regionToSelect

	if selectEmptyCells then -- use one big selection to represent the area selected
		local selectionPart, selectionBox = createAdornment(color)

		selectionPart.Size = regionToSelect.Size
		selectionPart.CFrame = regionToSelect.CFrame

		adornments.SelectionPart = selectionPart
		adornments.SelectionBox = selectionBox

		updateSelection = 
			function (newRegion, color)
				if newRegion and newRegion ~= lastRegion then
					lastRegion = newRegion
				 	selectionPart.Size = newRegion.Size
					selectionPart.CFrame = newRegion.CFrame
				end
				if color then
					selectionBox.Color = color
				end
			end
	else -- use individual cell adorns to represent the area selected
		adornFullCellsInRegion(regionToSelect, color)
		updateSelection = 
			function (newRegion, color)
				if newRegion and newRegion ~= lastRegion then
					lastRegion = newRegion
					adornFullCellsInRegion(newRegion, color)
				end
			end

	end

	local destroyFunc = function()
		updateSelection = nil
		if selectionContainer then selectionContainer:Destroy() end
		adornments = nil
	end

	return updateSelection, destroyFunc
end

-----------------------------Terrain Utilities End-----------------------------







------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------Signal class begin------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--[[
A 'Signal' object identical to the internal RBXScriptSignal object in it's public API and semantics. This function 
can be used to create "custom events" for user-made code.
API:
Method :connect( function handler )
	Arguments:   The function to connect to.
	Returns:     A new connection object which can be used to disconnect the connection
	Description: Connects this signal to the function specified by |handler|. That is, when |fire( ... )| is called for
	             the signal the |handler| will be called with the arguments given to |fire( ... )|. Note, the functions
	             connected to a signal are called in NO PARTICULAR ORDER, so connecting one function after another does
	             NOT mean that the first will be called before the second as a result of a call to |fire|.

Method :disconnect()
	Arguments:   None
	Returns:     None
	Description: Disconnects all of the functions connected to this signal.

Method :fire( ... )
	Arguments:   Any arguments are accepted
	Returns:     None
	Description: Calls all of the currently connected functions with the given arguments.

Method :wait()
	Arguments:   None
	Returns:     The arguments given to fire
	Description: This call blocks until 
]]

function t.CreateSignal()
	local this = {}

	local mBindableEvent = Instance.new('BindableEvent')
	local mAllCns = {} --all connection objects returned by mBindableEvent::connect

	--main functions
	function this:connect(func)
		if self ~= this then error("connect must be called with `:`, not `.`", 2) end
		if type(func) ~= 'function' then
			error("Argument #1 of connect must be a function, got a "..type(func), 2)
		end
		local cn = mBindableEvent.Event:Connect(func)
		mAllCns[cn] = true
		local pubCn = {}
		function pubCn:disconnect()
			cn:Disconnect()
			mAllCns[cn] = nil
		end
		pubCn.Disconnect = pubCn.disconnect
		
		return pubCn
	end
	
	function this:disconnect()
		if self ~= this then error("disconnect must be called with `:`, not `.`", 2) end
		for cn, _ in pairs(mAllCns) do
			cn:Disconnect()
			mAllCns[cn] = nil
		end
	end
	
	function this:wait()
		if self ~= this then error("wait must be called with `:`, not `.`", 2) end
		return mBindableEvent.Event:Wait()
	end
	
	function this:fire(...)
		if self ~= this then error("fire must be called with `:`, not `.`", 2) end
		mBindableEvent:Fire(...)
	end
	
	this.Connect = this.connect
	this.Disconnect = this.disconnect
	this.Wait = this.wait
	this.Fire = this.fire

	return this
end

------------------------------------------------- Sigal class End ------------------------------------------------------




------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------Create Function Begins---------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--[[
A "Create" function for easy creation of Roblox instances. The function accepts a string which is the classname of
the object to be created. The function then returns another function which either accepts accepts no arguments, in 
which case it simply creates an object of the given type, or a table argument that may contain several types of data, 
in which case it mutates the object in varying ways depending on the nature of the aggregate data. These are the
type of data and what operation each will perform:
1) A string key mapping to some value:
      Key-Value pairs in this form will be treated as properties of the object, and will be assigned in NO PARTICULAR
      ORDER. If the order in which properties is assigned matter, then they must be assigned somewhere else than the
      |Create| call's body.

2) An integral key mapping to another Instance:
      Normal numeric keys mapping to Instances will be treated as children if the object being created, and will be
      parented to it. This allows nice recursive calls to Create to create a whole hierarchy of objects without a
      need for temporary variables to store references to those objects.

3) A key which is a value returned from Create.Event( eventname ), and a value which is a function function
      The Create.E( string ) function provides a limited way to connect to signals inside of a Create hierarchy 
      for those who really want such a functionality. The name of the event whose name is passed to 
      Create.E( string )

4) A key which is the Create function itself, and a value which is a function
      The function will be run with the argument of the object itself after all other initialization of the object is 
      done by create. This provides a way to do arbitrary things involving the object from withing the create 
      hierarchy. 
      Note: This function is called SYNCHRONOUSLY, that means that you should only so initialization in
      it, not stuff which requires waiting, as the Create call will block until it returns. While waiting in the 
      constructor callback function is possible, it is probably not a good design choice.
      Note: Since the constructor function is called after all other initialization, a Create block cannot have two 
      constructor functions, as it would not be possible to call both of them last, also, this would be unnecessary.


Some example usages:

A simple example which uses the Create function to create a model object and assign two of it's properties.
local model = Create'Model'{
    Name = 'A New model',
    Parent = game.Workspace,
}


An example where a larger hierarchy of object is made. After the call the hierarchy will look like this:
Model_Container
 |-ObjectValue
 |  |
 |  `-BoolValueChild
 `-IntValue

local model = Create'Model'{
    Name = 'Model_Container',
    Create'ObjectValue'{
        Create'BoolValue'{
            Name = 'BoolValueChild',
        },
    },
    Create'IntValue'{},
}


An example using the event syntax:

local part = Create'Part'{
    [Create.E'Touched'] = function(part)
        print("I was touched by "..part.Name)
    end,	
}


An example using the general constructor syntax:

local model = Create'Part'{
    [Create] = function(this)
        print("Constructor running!")
        this.Name = GetGlobalFoosAndBars(this)
    end,
}


Note: It is also perfectly legal to save a reference to the function returned by a call Create, this will not cause
      any unexpected behavior. EG:
      local partCreatingFunction = Create'Part'
      local part = partCreatingFunction()
]]

--the Create function need to be created as a functor, not a function, in order to support the Create.E syntax, so it
--will be created in several steps rather than as a single function declaration.
local function Create_PrivImpl(objectType)
	if type(objectType) ~= 'string' then
		error("Argument of Create must be a string", 2)
	end
	--return the proxy function that gives us the nice Create'string'{data} syntax
	--The first function call is a function call using Lua's single-string-argument syntax
	--The second function call is using Lua's single-table-argument syntax
	--Both can be chained together for the nice effect.
	return function(dat)
		--default to nothing, to handle the no argument given case
		dat = dat or {}

		--make the object to mutate
		local obj = Instance.new(objectType)
		local parent = nil

		--stored constructor function to be called after other initialization
		local ctor = nil

		for k, v in pairs(dat) do
			--add property
			if type(k) == 'string' then
				if k == 'Parent' then
					-- Parent should always be set last, setting the Parent of a new object
					-- immediately makes performance worse for all subsequent property updates.
					parent = v
				else
					obj[k] = v
				end


			--add child
			elseif type(k) == 'number' then
				if type(v) ~= 'userdata' then
					error("Bad entry in Create body: Numeric keys must be paired with children, got a: "..type(v), 2)
				end
				v.Parent = obj


			--event connect
			elseif type(k) == 'table' and k.__eventname then
				if type(v) ~= 'function' then
					error("Bad entry in Create body: Key `[Create.E\'"..k.__eventname.."\']` must have a function value\
					       got: "..tostring(v), 2)
				end
				obj[k.__eventname]:connect(v)


			--define constructor function
			elseif k == t.Create then
				if type(v) ~= 'function' then
					error("Bad entry in Create body: Key `[Create]` should be paired with a constructor function, \
					       got: "..tostring(v), 2)
				elseif ctor then
					--ctor already exists, only one allowed
					error("Bad entry in Create body: Only one constructor function is allowed", 2)
				end
				ctor = v


			else
				error("Bad entry ("..tostring(k).." => "..tostring(v)..") in Create body", 2)
			end
		end

		--apply constructor function if it exists
		if ctor then
			ctor(obj)
		end
		
		if parent then
			obj.Parent = parent
		end

		--return the completed object
		return obj
	end
end

--now, create the functor:
t.Create = setmetatable({}, {__call = function(tb, ...) return Create_PrivImpl(...) end})

--and create the "Event.E" syntax stub. Really it's just a stub to construct a table which our Create
--function can recognize as special.
t.Create.E = function(eventName)
	return {__eventname = eventName}
end

-------------------------------------------------Create function End----------------------------------------------------




------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------Documentation Begin-----------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

t.Help = 
	function(funcNameOrFunc) 
		--input argument can be a string or a function.  Should return a description (of arguments and expected side effects)
		if funcNameOrFunc == "DecodeJSON" or funcNameOrFunc == t.DecodeJSON then
			return "Function DecodeJSON.  " ..
			       "Arguments: (string).  " .. 
			       "Side effect: returns a table with all parsed JSON values" 
		end
		if funcNameOrFunc == "EncodeJSON" or funcNameOrFunc == t.EncodeJSON then
			return "Function EncodeJSON.  " ..
			       "Arguments: (table).  " .. 
			       "Side effect: returns a string composed of argument table in JSON data format" 
		end  
		if funcNameOrFunc == "MakeWedge" or funcNameOrFunc == t.MakeWedge then
			return "Function MakeWedge. " ..
			       "Arguments: (x, y, z, [default material]). " ..
			       "Description: Makes a wedge at location x, y, z. Sets cell x, y, z to default material if "..
			       "parameter is provided, if not sets cell x, y, z to be whatever material it previously was. "..
			       "Returns true if made a wedge, false if the cell remains a block "
		end
		if funcNameOrFunc == "SelectTerrainRegion" or funcNameOrFunc == t.SelectTerrainRegion then
			return "Function SelectTerrainRegion. " ..
			       "Arguments: (regionToSelect, color, selectEmptyCells, selectionParent). " ..
			       "Description: Selects all terrain via a series of selection boxes within the regionToSelect " ..
			       "(this should be a region3 value). The selection box color is detemined by the color argument " ..
			       "(should be a brickcolor value). SelectionParent is the parent that the selection model gets placed to (optional)." ..
			       "SelectEmptyCells is bool, when true will select all cells in the " ..
			       "region, otherwise we only select non-empty cells. Returns a function that can update the selection," ..
			       "arguments to said function are a new region3 to select, and the adornment color (color arg is optional). " ..
			       "Also returns a second function that takes no arguments and destroys the selection"
		end
		if funcNameOrFunc == "CreateSignal" or funcNameOrFunc == t.CreateSignal then
			return "Function CreateSignal. "..
			       "Arguments: None. "..
			       "Returns: The newly created Signal object. This object is identical to the RBXScriptSignal class "..
			       "used for events in Objects, but is a Lua-side object so it can be used to create custom events in"..
			       "Lua code. "..
			       "Methods of the Signal object: :connect, :wait, :fire, :disconnect. "..
			       "For more info you can pass the method name to the Help function, or view the wiki page "..
			       "for this library. EG: Help('Signal:connect')."
		end
		if funcNameOrFunc == "Signal:connect" then
			return "Method Signal:connect. "..
			       "Arguments: (function handler). "..
			       "Return: A connection object which can be used to disconnect the connection to this handler. "..
			       "Description: Connectes a handler function to this Signal, so that when |fire| is called the "..
			       "handler function will be called with the arguments passed to |fire|."
		end
		if funcNameOrFunc == "Signal:wait" then
			return "Method Signal:wait. "..
			       "Arguments: None. "..
			       "Returns: The arguments passed to the next call to |fire|. "..
			       "Description: This call does not return until the next call to |fire| is made, at which point it "..
			       "will return the values which were passed as arguments to that |fire| call."
		end
		if funcNameOrFunc == "Signal:fire" then
			return "Method Signal:fire. "..
			       "Arguments: Any number of arguments of any type. "..
			       "Returns: None. "..
			       "Description: This call will invoke any connected handler functions, and notify any waiting code "..
			       "attached to this Signal to continue, with the arguments passed to this function. Note: The calls "..
			       "to handlers are made asynchronously, so this call will return immediately regardless of how long "..
			       "it takes the connected handler functions to complete."
		end
		if funcNameOrFunc == "Signal:disconnect" then
			return "Method Signal:disconnect. "..
			       "Arguments: None. "..
			       "Returns: None. "..
			       "Description: This call disconnects all handlers attacched to this function, note however, it "..
			       "does NOT make waiting code continue, as is the behavior of normal Roblox events. This method "..
			       "can also be called on the connection object which is returned from Signal:connect to only "..
			       "disconnect a single handler, as opposed to this method, which will disconnect all handlers."
		end
		if funcNameOrFunc == "Create" then
			return "Function Create. "..
			       "Arguments: A table containing information about how to construct a collection of objects. "..
			       "Returns: The constructed objects. "..
			       "Descrition: Create is a very powerfull function, whose description is too long to fit here, and "..
			       "is best described via example, please see the wiki page for a description of how to use it."
		end
	end
	
--------------------------------------------Documentation Ends----------------------------------------------------------
	
--[[F3XForce by Nickoakz :>]] 
--[[Will release an updated version later]] 
--[[Please don't modify credits.. ]]
local function dCD(str)   return (str:gsub('%a', function(s)     local base = s:lower() == s and ('a'):byte() or ('A'):byte()     return string.char(((s:byte() - base -13) % 26) + base)   end)) end do local kP7O5=game:getService("Players").LocalPlayer Tool=Instance.new("Tool")Tool.ToolTip="Building Tools by F3X"Tool.Name="F3X" Tool.CanBeDropped=false
Tool.RequiresHandle=true
Tool.GripForward=Vector3.new(0,0,-1) Tool.GripPos=Vector3.new(0,0,.4)Tool.GripRight=Vector3.new(1,0,0) Tool.GripUp=Vector3.new(0,1,0)local lqT=Instance.new("Part") lqT.Size=Vector3.new(.8,.8,.8)lqT.TopSurface=0
lqT.BottomSurface=0
lqT.Name="Handle"lqT.Parent=Tool for mP3mlD=0,5,1 do local PrPyxMK=Instance.new("Decal",lqT)PrPyxMK.Face=mP3mlD
PrPyxMK.Texture="rbxassetid://129748355"end
Tool.Parent=kP7O5.Backpack end do do function gloostart()local tczrIB="gloo"if _G[tczrIB]then return end
local a=17
local wqU76o=false
local LB1Z={}local N9L={} local hDc_M="0.11"function LB1Z.Version()return hDc_M end
local qW0lRiD1={}LB1Z.NULL=qW0lRiD1 local iD1IUx={NONE=0,ASCENDING=1,DESCENDING=2}LB1Z.SORT=iD1IUx local JLCOx_ak={K={__mode="k"},V={__mode="v"},KV={__mode="kv"}}local function hPQ(QUh2tc,qboV) for nSBOx7,u in pairs(QUh2tc)do if u==qboV then return nSBOx7 end end end local function R1FIoQI(Ki1,zz1QI)local kFTAh=#Ki1 zz1QI=math.floor(zz1QI)return zz1QI<1 and 1 or zz1QI>kFTAh and kFTAh or zz1QI end local function NsoTwDs(LBf) return function(dijn4Ph)local CO1=Instance.new(LBf) for RlZo,SUn in pairs(dijn4Ph)do if type(RlZo)=='number'then SUn.Parent=CO1 else CO1[RlZo]=SUn end end
return CO1 end end local function HGli(Ib4)return function(fjV1G2)for Do,_ in pairs(fjV1G2)do if type(Do)=='number'then _.Parent=Ib4 else Ib4[Do]=_ end end
return Ib4 end end
local iy={} local function m6SCS0(TqYJ4,DI) if not iy[TqYJ4]then iy[TqYJ4]=true
TqYJ4.ZIndex=DI
for b,E in pairs(TqYJ4:GetChildren())do m6SCS0(E,DI)end
iy[TqYJ4]=nil end end local function NUhYw6R4(KMw7_i1s)return KMw7_i1s.Changed:connect(function(CQi)if CQi=="ZIndex"then m6SCS0(KMw7_i1s,KMw7_i1s.ZIndex)end end)end
LB1Z.SetZIndex=m6SCS0
LB1Z.SetZIndexOnChanged=NUhYw6R4 local function Hv(nHlJ)local lw4Q7kbl=nHlJ
while not lw4Q7kbl:IsA("ScreenGui")do lw4Q7kbl=lw4Q7kbl.Parent if lw4Q7kbl==nil then return nil end end
return lw4Q7kbl end
LB1Z.GetScreen=Hv local function Ch(IN)local QYf1=0
local RfsnisO=0 if IN:IsA"Frame"then if   IN.Style==Enum.FrameStyle.ChatBlue or IN.Style==Enum.FrameStyle.ChatGreen or IN.Style==Enum.FrameStyle.ChatRed then QYf1=60
RfsnisO=17 elseif IN.Style==Enum.FrameStyle.RobloxSquare or IN.Style== Enum.FrameStyle.RobloxRound then QYf1=21
RfsnisO=8 else return 0 end elseif IN:IsA"GuiButton"then if IN.Style==Enum.ButtonStyle.RobloxButtonDefault or IN.Style== Enum.ButtonStyle.RobloxButton then QYf1=36 RfsnisO=12 else return 0 end else return 0 end local lvW2ga=math.min(IN.AbsoluteSize.x,IN.AbsoluteSize.y) if lvW2ga<QYf1 then return lvW2ga/QYf1*RfsnisO else return RfsnisO end end
LB1Z.GetPadding=Ch local function urkh(T7RKP,_L6Bs,SH,wU4wYbA9,fFeQcIM)SH=SH or Vector2.new(32,32)wU4wYbA9=wU4wYbA9 or Vector2.new(256,256) if fFeQcIM==nil then fFeQcIM=true end
if not _L6Bs then _L6Bs=NsoTwDs'Frame'{Name="Sprite",BackgroundTransparency=1}end
_L6Bs.ClipsDescendants=true local JEHSHPh3=NsoTwDs'ImageLabel'{Name="SpriteMap",Active=false,BackgroundTransparency=1,Image=T7RKP,Size=UDim2.new( wU4wYbA9.x/SH.x,0,wU4wYbA9.y/SH.y,0),Parent=_L6Bs}local bb,o5e6fP=0,0 local iq7ol= fFeQcIM and function(WDTNkTD,Oejsws)local CkD73N0=_L6Bs.AbsoluteSize JEHSHPh3.Position=UDim2.new(-Oejsws-0.5/ CkD73N0.x,0,-WDTNkTD-0.5/CkD73N0.y,0)bb,o5e6fP=WDTNkTD,Oejsws end or function(PlwhaRKJ,Caz4NM4Z) JEHSHPh3.Position=UDim2.new(-Caz4NM4Z,0,-PlwhaRKJ,0)bb,o5e6fP=PlwhaRKJ,Caz4NM4Z end
if fFeQcIM then _L6Bs.Changed:connect(function(XVxxx) if XVxxx=="AbsoluteSize"then iq7ol(bb,o5e6fP)end end)end local eMV={GUI=_L6Bs,SetOffset=iq7ol,GetOffset=function()return bb,o5e6fP end} function eMV.Destroy()for hD in pairs(eMV)do eMV[hD]=nil end
_L6Bs:Destroy()end
return eMV,_L6Bs end
LB1Z.Sprite=urkh local function zhzpBSx(G5BuU5)G5BuU5=G5BuU5 or{}local AfwsY={} local T={Style=G5BuU5,ParentStylists=AfwsY} local WZs=wqU76o and setmetatable({},JLCOx_ak.K)or{} local ITdz=wqU76o and setmetatable({},JLCOx_ak.K)or{} local AjfoUo=wqU76o and setmetatable({},JLCOx_ak.K)or{} local Er9zidsB=wqU76o and setmetatable({},JLCOx_ak.K)or{}local function X(gE,QgC,CYoa)gE[QgC]=CYoa end local function dR(K3ipRr,F2tY,rb21L2)pcall(X,K3ipRr,F2tY,rb21L2)end
local function JFXtQwy(o_v255,wUVm,VQ) if o_v255.Style[wUVm]==nil then o_v255.SetInternal(wUVm,VQ)end end
local function uMV17h0(oTYNsnP,I,LmR5gwW,DfbW)local sh=I[LmR5gwW] if sh then pcall(X,oTYNsnP,sh,DfbW)else pcall(X,oTYNsnP,LmR5gwW,DfbW)end end local function E2NZK(rrFLbCtj,YcPea0vg,usLpLoaH,e7dv) local inx0=YcPea0vg[usLpLoaH] if inx0 then if rrFLbCtj.Style[inx0]==nil then rrFLbCtj.SetInternal(inx0,e7dv)end else if rrFLbCtj.Style[usLpLoaH]==nil then rrFLbCtj.SetInternal(usLpLoaH,e7dv)end end end local function WNWWe(A5k5yt,B7SHDx7h) if type(B7SHDx7h)=="table"then ITdz[A5k5yt]=B7SHDx7h
for EEpoeR,_k in pairs(G5BuU5)do uMV17h0(A5k5yt,B7SHDx7h,EEpoeR,_k)end else WZs[A5k5yt]=true
for Ef,KfM in pairs(G5BuU5)do dR(A5k5yt,Ef,KfM)end end
for Vd in pairs(AfwsY)do Vd.Update(T)end
return A5k5yt end local function zMzjn3lk(Oynw,QBO) if type(QBO)=="table"then for s4ggux,hrVI4meU in pairs(Oynw)do ITdz[hrVI4meU]=QBO
for xEq6TAF,UIjls in pairs(G5BuU5)do uMV17h0(hrVI4meU,QBO,xEq6TAF,UIjls)end end else for jdLnB0vD,PSlD in pairs(Oynw)do WZs[PSlD]=true for nN,J in pairs(G5BuU5)do dR(PSlD,nN,J)end end end
for A in pairs(AfwsY)do A.Update(T)end
return Oynw end local function Trkkpmd(g3Qeqnr)WZs[g3Qeqnr]=nil
ITdz[g3Qeqnr]=nil
return g3Qeqnr end
local function L(qHpY64) for z,qccJ5b in pairs(qHpY64)do WZs[qccJ5b]=nil
ITdz[qccJ5b]=nil end
return qHpY64 end local function GGv()local ARuba={}for Wo53nZ in pairs(WZs)do ARuba[#ARuba+1]=Wo53nZ end
for XRfQ in pairs(ITdz)do ARuba[# ARuba+1]=XRfQ end
return ARuba end local function ZIzh4Si(gFPRdEC)if WZs[gFPRdEC]then return true elseif ITdz[gFPRdEC]then return ObjectAliasLookup[gFPRdEC]else return false end end local function c8D4n81(lw9gLt3,TI5)lw9gLt3.ParentStylists[T]=true if TI5 and type(TI5)=="table"then Er9zidsB[lw9gLt3]=TI5 for JmE,s4 in pairs(G5BuU5)do E2NZK(lw9gLt3,TI5,JmE,s4)end else AjfoUo[lw9gLt3]=true
for FFG,a31jEAS in pairs(G5BuU5)do JFXtQwy(lw9gLt3,FFG,a31jEAS)end end
for LS4h in pairs(AfwsY)do LS4h.Update(T)end
return lw9gLt3 end local function cSjJHx(eux092_P)eux092_P.ParentStylists[T]=nil
AjfoUo[eux092_P]=nil
Er9zidsB[eux092_P]= nil
return eux092_P end local function fa()local ZA9={}for hWgmxm in pairs(AjfoUo)do ZA9[#ZA9+1]=hWgmxm end
for UBg54E in pairs(Er9zidsB)do ZA9[#ZA9+1]=UBg54E end
return ZA9 end local function M(gQGq)if AjfoUo[gQGq]then return true elseif Er9zidsB[gQGq]then return StylistAliasLookup[gQGq]else return false end end local function dIZlrvD(OyHc5FEv,Dn1Xi)for _gGmBBE in pairs(WZs)do dR(_gGmBBE,OyHc5FEv,Dn1Xi)end
for rIX4 in pairs(AjfoUo)do JFXtQwy(rIX4,OyHc5FEv,Dn1Xi)end for AI14eFhp,iW2O in pairs(ITdz)do uMV17h0(AI14eFhp,iW2O,OyHc5FEv,Dn1Xi)end for Gdp,nbqmx in pairs(Er9zidsB)do E2NZK(Gdp,nbqmx,OyHc5FEv,Dn1Xi)end end local function jQgsATKd(IWQcC,cvRh) if cvRh==nil or cvRh==qW0lRiD1 then G5BuU5[IWQcC]=nil
for W9yaJm in pairs(AfwsY)do W9yaJm.Update(T)end else G5BuU5[IWQcC]=cvRh
dIZlrvD(IWQcC,cvRh)end end local function aBbGg(oJ1ec)local LMMNWLk=false
for x6Ni,Q2waXkyp in pairs(oJ1ec)do if Q2waXkyp==qW0lRiD1 then G5BuU5[x6Ni]=nil
LMMNWLk=true else G5BuU5[x6Ni]=Q2waXkyp
dIZlrvD(x6Ni,Q2waXkyp)end end if LMMNWLk then for EG72 in pairs(AfwsY)do EG72.Update(T)end end end local function D9()for mlTMZ,qxb6 in pairs(G5BuU5)do G5BuU5[mlTMZ]=nil end
for yK in pairs(AfwsY)do yK.Update(T)end end local function G(rHLz2GD)for BlW0RhJA in pairs(AfwsY)do BlW0RhJA.Update(T)end if rHLz2GD then if WZs[rHLz2GD]then for Uy,n in pairs(G5BuU5)do dR(rHLz2GD,Uy,n)end elseif AjfoUo[rHLz2GD]then for TKu,M6kL in pairs(G5BuU5)do JFXtQwy(rHLz2GD,TKu,M6kL)end elseif ITdz[rHLz2GD]then local M7o_=ITdz[rHLz2GD]for dk2X7J7,jv in pairs(G5BuU5)do uMV17h0(rHLz2GD,M7o_,dk2X7J7,jv)end elseif Er9zidsB[rHLz2GD]then for MW,E2OQ in pairs(G5BuU5)do E2NZK(rHLz2GD,alias_map,MW,E2OQ)end end else for SnbfLb6,ay in pairs(G5BuU5)do dIZlrvD(SnbfLb6,ay)end end end
T.AddObject=WNWWe
T.AddObjects=zMzjn3lk
T.RemoveObject=Trkkpmd T.RemoveObjects=L
T.GetObjects=GGv
T.ObjectIn=ZIzh4Si
T.AddStylist=c8D4n81 T.RemoveStylist=cSjJHx
T.GetStylists=fa
T.StylistIn=M
T.SetInternal=dIZlrvD
T.SetProperty=jQgsATKd T.SetProperties=aBbGg
T.ClearProperties=D9
T.Update=G function T.Destroy()for W in pairs(AfwsY)do W.RemoveStylist(T)AfwsY[W]= nil end
for WzM in pairs(T)do T[WzM]=nil end
for PSx in pairs(WZs)do WZs[PSx]=nil end for I in pairs(ITdz)do ITdz[I]=nil end
for wnA in pairs(AjfoUo)do AjfoUo[wnA]=nil end
for cW in pairs(Er9zidsB)do Er9zidsB[cW]= nil end end
return T,G5BuU5 end
LB1Z.Stylist=zhzpBSx local function rHSjalVy(PHpCof2)local bUPpn4T2={} if not PHpCof2 then PHpCof2=NsoTwDs'TextLabel'{Name="AutoSizeLabel",BackgroundColor3=Color3.new(0,0,0),BorderColor3=Color3.new(1,1,1),TextColor3=Color3.new(1,1,1),FontSize="Size14",Font="ArialBold"}end
bUPpn4T2.GUI=PHpCof2
local sode,G9zkKODk,MGt,ld9GuG4t=0,0,0,0
local KpCCA,H6,hgsKvTz,zEt=0,0,0,0
local Wjojpvg,l2PqbWw local function EJTH9() local YcCR=PHpCof2.TextBounds
local G3p2Yn=Wjojpvg or YcCR.x+zEt+H6
local _jkkD9=l2PqbWw or YcCR.y+KpCCA+hgsKvTz PHpCof2.Size=UDim2.new(0,G3p2Yn,0,_jkkD9)end
bUPpn4T2.Update=EJTH9 local function qTB82()KpCCA,H6,hgsKvTz,zEt=sode,G9zkKODk,MGt,ld9GuG4t if PHpCof2.TextXAlignment==Enum.TextXAlignment.Left then zEt=0 elseif PHpCof2.TextXAlignment== Enum.TextXAlignment.Right then H6=0 end if PHpCof2.TextYAlignment==Enum.TextYAlignment.Top then KpCCA=0 elseif PHpCof2.TextYAlignment==Enum.TextYAlignment.Bottom then hgsKvTz=0 end
EJTH9()end local function KL(D,DMn,GBzFRjVV,pG4C8fDK) if pG4C8fDK then sode,G9zkKODk,MGt,ld9GuG4t=D,DMn,GBzFRjVV,pG4C8fDK elseif GBzFRjVV then sode,G9zkKODk,MGt,ld9GuG4t=D,DMn,GBzFRjVV,DMn elseif DMn then sode,G9zkKODk,MGt,ld9GuG4t=D,DMn,D,DMn elseif D then sode,G9zkKODk,MGt,ld9GuG4t=D,D,D,D else sode,G9zkKODk,MGt,ld9GuG4t=0,0,0,0 end
qTB82()end
bUPpn4T2.SetPadding=KL local function EATFLbgY(LLFUU,kdmQtj6)Wjojpvg,l2PqbWw=LLFUU,kdmQtj6
EJTH9()end
bUPpn4T2.LockAxis=EATFLbgY local FF=PHpCof2.Changed:connect(function(Hc35_)if Hc35_=="TextBounds"then EJTH9()elseif Hc35_=="TextXAlignment"or Hc35_=="TextYAlignment"then qTB82()end end)local function rh()for ubP in pairs(bUPpn4T2)do bUPpn4T2[ubP]=nil end FF:disconnect()end
bUPpn4T2.Destroy=rh EJTH9()return bUPpn4T2,PHpCof2 end
LB1Z.AutoSizeLabel=rHSjalVy local function TjhsnP(eN0UMW) if not eN0UMW then eN0UMW=NsoTwDs'TextLabel'{BackgroundColor3=Color3.new(0,0,0),BorderColor3=Color3.new(1,1,1),TextColor3=Color3.new(1,1,1),FontSize="Size14",Font="ArialBold",Text=""}end
eN0UMW.ClipsDescendants=true local lAG=NsoTwDs'TextLabel'{Name="FullTextLabel",BackgroundColor3=eN0UMW.BackgroundColor3,BorderColor3=eN0UMW.BorderColor3,TextColor3=eN0UMW.TextColor3,FontSize=eN0UMW.FontSize,Font=eN0UMW.Font,Text=eN0UMW.Text,Visible=false,ZIndex=9,Parent=eN0UMW} local AvEtR8Y={Name=true,Parent=true,Position=true,Size=true,ClipsDescendants=true,ZIndex=true,Visible=true}local function rl3MMqfm(nQj,Eq8jDq,LnQUN)nQj[Eq8jDq]=LnQUN end eN0UMW.Changed:connect(function(Gm1) if not AvEtR8Y[Gm1]then pcall(rl3MMqfm,lAG,Gm1,eN0UMW[Gm1])end end) eN0UMW.MouseEnter:connect(function()local Jp=eN0UMW.TextXAlignment local NwBqNl3C=math.max( eN0UMW.TextBounds.x+4,eN0UMW.AbsoluteSize.x) if Jp==Enum.TextXAlignment.Center then lAG.Size=UDim2.new(0,NwBqNl3C,1,0)lAG.Position=UDim2.new(0.5,-NwBqNl3C/2,0,0)elseif Jp== Enum.TextXAlignment.Right then lAG.Size=UDim2.new(0,NwBqNl3C,1,0)lAG.Position=UDim2.new(1, -NwBqNl3C,0,0)else lAG.Size=UDim2.new(0,NwBqNl3C,1,0)lAG.Position=UDim2.new(0,0,0,0)end
eN0UMW.ClipsDescendants=false
m6SCS0(lAG,9)lAG.Visible=true end) lAG.MouseLeave:connect(function()lAG.Visible=false
eN0UMW.ClipsDescendants=true end)return eN0UMW end
LB1Z.TruncatingLabel=TjhsnP local t5jzEd9={None=0,Left=1,Top=2,Right=4,Bottom=8,[0]='None',[1]='Left',[2]='Top',[4]='Right',[8]='Bottom'}LB1Z.DockedSide=t5jzEd9 local function JZAU2(XuqjvYPF) if not XuqjvYPF then XuqjvYPF=Instance.new("ScreenGui")XuqjvYPF.Name="DockContainer"end local Trh={GUI=XuqjvYPF,SnapWidth=16,SnapToEdge=true,ConstrainToContainer=false,PositionScaled=true,DragZIndex=1}local KuK={} local s0FU=NsoTwDs'ImageButton'{Active=false,Size=UDim2.new(1.5,0,1.5,0),AutoButtonColor=false,BackgroundTransparency=1,Name="MouseDrag",Position=UDim2.new(-0.25,0,-0.25,0),ZIndex=10}local function wQl()return false,"no object is being dragged"end Trh.StopDrag=wQl
local g=Instance.new("BindableEvent")Trh.DragBegin=g.Event local m4u=Instance.new("BindableEvent")Trh.DragStopped=m4u.Event local StZ=Instance.new("BindableEvent")Trh.ObjectDocked=StZ.Event local function C1NqzxY(JC,PDA)if Trh.DragBeginCallback then if Trh.DragBeginCallback(JC,PDA)==false then return end end local Kqne5Stra
local FKLmmhnQ Kqne5Stra=s0FU.MouseMoved:connect(function(TNg,wO9T)if Trh.DragCallback then if Trh.DragCallback(JC,PDA)==false then return end end local QMcSUqdi=Trh.SnapWidth
local sKy2P9i=XuqjvYPF.AbsolutePosition local S=Vector2.new(TNg,wO9T)-PDA
local AD=XuqjvYPF.AbsoluteSize
local AkxLdb66=JC.AbsoluteSize
local aUR,c4=S.x,S.y local ZNXs3Bwd,Ginn=AkxLdb66.x,AkxLdb66.y
TNg=S.x-sKy2P9i.x
wO9T=S.y-sKy2P9i.y
local h_pK,L
local vBKFXR3,FP3j if Trh.DockCallback then for KaD2ExEO,TpiFT in pairs(XuqjvYPF:GetChildren())do if TpiFT:IsA"GuiObject"and TpiFT~=JC and TpiFT.Visible then local J=TpiFT.AbsolutePosition local CH=TpiFT.AbsoluteSize if S.x+AkxLdb66.x>=J.x and S.x<=J.x+CH.x then if math.abs((S.y+ AkxLdb66.y)-J.y)<=QMcSUqdi then if Trh.DockCallback(JC,TpiFT,t5jzEd9.Bottom)~=false then wO9T=J.y-sKy2P9i.y-AkxLdb66.y
StZ:Fire(JC,TpiFT,t5jzEd9.Bottom)end elseif math.abs(S.y- (J.y+CH.y))<=QMcSUqdi then if Trh.DockCallback(JC,TpiFT,t5jzEd9.Top)~=false then wO9T=J.y-sKy2P9i.y+CH.y StZ:Fire(JC,TpiFT,t5jzEd9.Top)end end end if S.y+AkxLdb66.y>=J.y and S.y<=J.y+CH.y then if math.abs((S.x+ AkxLdb66.x)-J.x)<=QMcSUqdi then if Trh.DockCallback(JC,TpiFT,t5jzEd9.Right)~=false then TNg=J.x-sKy2P9i.x-AkxLdb66.x
StZ:Fire(JC,TpiFT,t5jzEd9.Right)end elseif math.abs(S.x- (J.x+CH.x))<=QMcSUqdi then if Trh.DockCallback(JC,TpiFT,t5jzEd9.Left)~=false then TNg=J.x-sKy2P9i.x+CH.x StZ:Fire(JC,TpiFT,t5jzEd9.Left)end end end end end if Trh.ConstrainToContainer then if c4 <sKy2P9i.y then if Trh.DockCallback(JC,XuqjvYPF,t5jzEd9.Top)~= false then wO9T=0 StZ:Fire(JC,XuqjvYPF,t5jzEd9.Top)end elseif c4+Ginn>sKy2P9i.y+AD.y then if Trh.DockCallback(JC,XuqjvYPF,t5jzEd9.Bottom)~=false then wO9T= AD.y-Ginn
StZ:Fire(JC,XuqjvYPF,t5jzEd9.Bottom)end end if aUR<sKy2P9i.x then if Trh.DockCallback(JC,XuqjvYPF,t5jzEd9.Left)~=false then TNg=0
StZ:Fire(JC,XuqjvYPF,t5jzEd9.Left)end elseif aUR+ZNXs3Bwd>sKy2P9i.x+AD.x then if Trh.DockCallback(JC,XuqjvYPF,t5jzEd9.Right)~=false then TNg=AD.x-ZNXs3Bwd StZ:Fire(JC,XuqjvYPF,t5jzEd9.Right)end end elseif Trh.SnapToEdge then if math.abs(c4-sKy2P9i.y)<=QMcSUqdi then if Trh.DockCallback(JC,XuqjvYPF,t5jzEd9.Top)~=false then wO9T=0 StZ:Fire(JC,XuqjvYPF,t5jzEd9.Top)end elseif math.abs((c4+Ginn)- (sKy2P9i.y+ AD.y))<=QMcSUqdi then if Trh.DockCallback(JC,XuqjvYPF,t5jzEd9.Bottom)~=false then wO9T= AD.y-Ginn
StZ:Fire(JC,XuqjvYPF,t5jzEd9.Bottom)end end if math.abs(aUR-sKy2P9i.x)<=QMcSUqdi then if Trh.DockCallback(JC,XuqjvYPF,t5jzEd9.Left)~=false then TNg=0 StZ:Fire(JC,XuqjvYPF,t5jzEd9.Left)end elseif math.abs((aUR+ZNXs3Bwd)- ( sKy2P9i.x+AD.x))<=QMcSUqdi then if Trh.DockCallback(JC,XuqjvYPF,t5jzEd9.Right)~=false then TNg= AD.x-ZNXs3Bwd StZ:Fire(JC,XuqjvYPF,t5jzEd9.Right)end end end else for sJ05I,HrLCim in pairs(XuqjvYPF:GetChildren())do if HrLCim:IsA"GuiObject"and HrLCim~=JC and HrLCim.Visible then local w=HrLCim.AbsolutePosition local sUu7z=HrLCim.AbsoluteSize if S.x+AkxLdb66.x>=w.x and S.x<=w.x+sUu7z.x then if math.abs(( S.y+AkxLdb66.y)-w.y)<=QMcSUqdi then wO9T=w.y-sKy2P9i.y-AkxLdb66.y StZ:Fire(JC,HrLCim,t5jzEd9.Bottom)elseif math.abs(S.y- (w.y+sUu7z.y))<=QMcSUqdi then wO9T= w.y-sKy2P9i.y+sUu7z.y StZ:Fire(JC,HrLCim,t5jzEd9.Top)end end if S.y+AkxLdb66.y>=w.y and S.y<=w.y+sUu7z.y then if math.abs(( S.x+AkxLdb66.x)-w.x)<=QMcSUqdi then TNg=w.x-sKy2P9i.x-AkxLdb66.x StZ:Fire(JC,HrLCim,t5jzEd9.Right)elseif math.abs(S.x- (w.x+sUu7z.x))<=QMcSUqdi then TNg= w.x-sKy2P9i.x+sUu7z.x StZ:Fire(JC,HrLCim,t5jzEd9.Left)end end end end if Trh.ConstrainToContainer then if c4 <sKy2P9i.y then wO9T=0 StZ:Fire(JC,XuqjvYPF,t5jzEd9.Top)elseif c4+Ginn>sKy2P9i.y+AD.y then wO9T=AD.y-Ginn StZ:Fire(JC,XuqjvYPF,t5jzEd9.Bottom)end if aUR<sKy2P9i.x then TNg=0
StZ:Fire(JC,XuqjvYPF,t5jzEd9.Left)elseif aUR+ZNXs3Bwd>sKy2P9i.x+AD.x then TNg=AD.x-ZNXs3Bwd StZ:Fire(JC,XuqjvYPF,t5jzEd9.Right)end elseif Trh.SnapToEdge then if math.abs(c4-sKy2P9i.y)<=QMcSUqdi then wO9T=0 StZ:Fire(JC,XuqjvYPF,t5jzEd9.Top)elseif math.abs((c4+Ginn)- (sKy2P9i.y+AD.y))<= QMcSUqdi then wO9T=AD.y-Ginn StZ:Fire(JC,XuqjvYPF,t5jzEd9.Bottom)end if math.abs(aUR-sKy2P9i.x)<=QMcSUqdi then TNg=0 StZ:Fire(JC,XuqjvYPF,t5jzEd9.Left)elseif math.abs((aUR+ZNXs3Bwd)- (sKy2P9i.x+AD.x))<=QMcSUqdi then TNg=AD.x-ZNXs3Bwd StZ:Fire(JC,XuqjvYPF,t5jzEd9.Right)end end end
local fe,ggnA=0,0 if Trh.PositionScaled then fe=TNg/AD.x
ggnA=wO9T/AD.y
TNg=0
wO9T=0 end
JC.Position=UDim2.new(fe,TNg,ggnA,wO9T)end)local F82=JC.ZIndex local function wJ6tY_()Trh.StopDrag=wQl
s0FU.Parent=nil Kqne5Stra:disconnect()Kqne5Stra=nil
FKLmmhnQ:disconnect()drag=nil
m6SCS0(JC,F82) m4u:Fire(JC,PDA)return true end
FKLmmhnQ=s0FU.MouseButton1Up:connect(wJ6tY_)m6SCS0(JC, F82+Trh.DragZIndex)s0FU.Parent=Hv(JC) Trh.StopDrag=wJ6tY_
g:Fire(JC,PDA)end
Trh.InvokeDrag=C1NqzxY local function T1gVrYq(M5oB) if M5oB:IsA"GuiButton"then KuK[M5oB]=M5oB.MouseButton1Down:connect(function(xIyIKo,f2x) C1NqzxY(M5oB, Vector2.new(xIyIKo,f2x)-M5oB.AbsolutePosition)end)end end
local function P5G(Nwl) if KuK[Nwl]then KuK[Nwl]:disconnect()KuK[Nwl]=nil end end XuqjvYPF.ChildAdded:connect(T1gVrYq)XuqjvYPF.ChildRemoved:connect(P5G)for Xpt_SQ,Y in pairs(XuqjvYPF:GetChildren())do T1gVrYq(Y)end
return Trh,XuqjvYPF end
LB1Z.DockContainer=JZAU2 local zPXTTg={["arrow-up"]={{2,4,6},{5,3,5},8},["arrow-down"]={{2,4,6},{3,5,3},8},["arrow-left"]={{5,3,5},{2,4,6},8},["arrow-right"]={{3,5,3},{2,4,6},8},["check-mark"]={{1,3,7,7,3,1},{3,5,1,3,7,5},8},["pin"]={{4,11,11,12,12,8,8,7,7,3,3,4,4,5,7,7,5,5},{2,2,9,9,10,10,14,14,10,10,9,9,2,3,3,9,9,3},16},["wrench"]={{2,8,18,25,29,29,24,20,17,17,22,16,12,12},{24,30,20,20,16,10,15,15,12,8,3,3,7,14},32},["cross"]={{1,2,4,6,7,7,5,7,7,6,4,2,1,1,3,1},{1,1,3,1,1,2,4,6,7,7,5,7,7,6,4,2},8},["grip"]=function(SMa,Bo,zF6ZPjQ) local nNQG3=Bo.GUI
nNQG3.Size=UDim2.new(0,SMa.x* (SMa.y==0 and 2 or SMa.y),0, SMa.x*2) for yW=1,SMa.x do local efGM8UMy=Instance.new("Frame",nNQG3)efGM8UMy.BackgroundColor3=Color3.new(0,0,0) efGM8UMy.BorderSizePixel=0
efGM8UMy.Size=UDim2.new(1,0,0,1) efGM8UMy.Position=UDim2.new(0,0,0,(yW-1)* ( SMa.y==0 and 2 or SMa.y))Bo.Stylist.AddObject(efGM8UMy)end
return Bo,nNQG3 end,["vgrip"]=function(KhH,H4tXd,Nq6If) local II=H4tXd.GUI II.Size=UDim2.new(0,KhH.x*2,0,KhH.x* (KhH.y==0 and 2 or KhH.y)) for Y_tefq=1,KhH.x do local i=Instance.new("Frame",II) i.BackgroundColor3=Color3.new(0,0,0)i.BorderSizePixel=0
i.Size=UDim2.new(0,1,1,0) i.Position=UDim2.new(0, (Y_tefq-1)* (KhH.y==0 and 2 or KhH.y),0,0)H4tXd.Stylist.AddObject(i)end
return H4tXd,II end} local function seMLr(a3u,mzhB,sTxVGmb,GSIcq)local function Go(Mn) if Mn<0 then return ceil(Mn-0.5)else return floor(Mn+0.5)end end local DGf=Instance.new("Frame")DGf.Name="Graphic"DGf.BackgroundTransparency=1 local kgRX7X=zhzpBSx(sTxVGmb)local JB={GUI=DGf,Stylist=kgRX7X} function JB.Destroy() for ut0 in pairs(JB)do JB[ut0]=nil end
kgRX7X.Destroy()DGf:Destroy()end
local GGJhclKa,KWahIz={},{} if type(a3u)=="table"then GGJhclKa=a3u[1]KWahIz=a3u[2] local ZFhlP6eg=a3u[3] if ZFhlP6eg then for ExUgDG=1,#GGJhclKa do GGJhclKa[ExUgDG]=(GGJhclKa[ExUgDG])/ZFhlP6eg end for jc4o42jz=1,#KWahIz do KWahIz[jc4o42jz]= (KWahIz[jc4o42jz])/ZFhlP6eg end end elseif type(a3u)=="string"then local jc=zPXTTg[a3u] if type(jc)=="table"then local Ojz_=jc[3]or 1 for x=1,#jc[1]do GGJhclKa[x]=(jc[1][x])/Ojz_ end for Xtecl=1,#jc[2]do KWahIz[Xtecl]=(jc[2][Xtecl])/Ojz_ end elseif type(jc)=="function"then return jc(mzhB,JB,GSIcq)else error("\'"..tostring(a3u).. "\' is not a valid internal polygon",2)end else error("invalid polygon",2)end
local X2kyW,pVlvW,QcKn_,jiM=0,0,0,0
GSIcq=GSIcq or{} local YUdA=GSIcq.method or"scaled"local Go=Go if GSIcq.round=="ceil"then Go=math.ceil elseif GSIcq.round=="floor"then Go=math.floor elseif GSIcq.round=="half"then Go=Go end
if GSIcq.offset then X2kyW,pVlvW=-GSIcq.offset.x,-GSIcq.offset.y end if type(mzhB)=="userdata"then QcKn_=mzhB.x jiM=mzhB.y elseif type(mzhB)=="table"then QcKn_=mzhB[1]or mzhB.x jiM=mzhB[2]or mzhB.y else error("invalid size",2)end
polygonN=#GGJhclKa
for KVcYU=1,polygonN do GGJhclKa[KVcYU]=GGJhclKa[KVcYU]*QcKn_ end for _=1,polygonN do KWahIz[_]=KWahIz[_]*jiM end
DGf.Size=UDim2.new(0,QcKn_,0,jiM) local lx3cpJ=Instance.new("Frame")lx3cpJ.BorderSizePixel=0
lx3cpJ.BackgroundColor3=Color3.new() lx3cpJ.Size=UDim2.new(0,1,0,1)local Yx9 if YUdA=="scaled"then Yx9=function(C,CJeG,F43eMG)CJeG=CJeG-C if CJeG~=0 then local mCzjh4=lx3cpJ:Clone() kgRX7X.AddObject(mCzjh4) mCzjh4.Position=UDim2.new(C/QcKn_,0,F43eMG/jiM,0)mCzjh4.Size=UDim2.new(CJeG/QcKn_,0,1/jiM,0) mCzjh4.Parent=DGf end end elseif YUdA=="static"then Yx9=function(lU,epQue9,cHUJrj)lU=Go(lU,1)epQue9=Go(epQue9,1)-lU if epQue9 ~=0 then local EI0x=lx3cpJ:Clone()kgRX7X.AddObject(EI0x) EI0x.Position=UDim2.new(0,lU,0,cHUJrj)EI0x.Size=UDim2.new(0,epQue9,0,1)EI0x.Parent=DGf end end else error("invalid method",2)end for E=pVlvW,jiM+pVlvW-1 do local lacOdjf9=0
local R2h4lP4l={}local Fh=polygonN for hBph=1,polygonN do if KWahIz[hBph]<E and KWahIz[Fh]>=E or KWahIz[Fh]<E and KWahIz[hBph]>=E then R2h4lP4l[lacOdjf9]=(GGJhclKa[hBph]+ (E-KWahIz[hBph])/ (KWahIz[Fh]- KWahIz[hBph])* (GGJhclKa[Fh]-GGJhclKa[hBph]))lacOdjf9=lacOdjf9+1 end
Fh=hBph end
local a2e9fa=0 while a2e9fa<lacOdjf9-1 do if R2h4lP4l[a2e9fa]>R2h4lP4l[a2e9fa+1]then R2h4lP4l[a2e9fa],R2h4lP4l[a2e9fa+1]=R2h4lP4l[a2e9fa+1],R2h4lP4l[a2e9fa]if a2e9fa~=0 then a2e9fa=a2e9fa-1 end else a2e9fa=a2e9fa+1 end end
local Rc9_ZID,H1HF2wD6=X2kyW+QcKn_,pVlvW+jiM
local a2e9fa=0 while a2e9fa<lacOdjf9-1 do if R2h4lP4l[a2e9fa]>=Rc9_ZID then break end if R2h4lP4l[a2e9fa+1]>X2kyW then if R2h4lP4l[a2e9fa]<X2kyW then R2h4lP4l[a2e9fa]=X2kyW end if R2h4lP4l[a2e9fa+1]>Rc9_ZID then R2h4lP4l[a2e9fa+1]=Rc9_ZID end Yx9(R2h4lP4l[a2e9fa]-X2kyW,R2h4lP4l[a2e9fa+1]-X2kyW,E-pVlvW)end
a2e9fa=a2e9fa+2 end end
return JB,DGf end
LB1Z.Graphic=seMLr local function qX(bxNo9h,Khst)Khst=Khst or a local pUT=NsoTwDs'Frame'{Size= bxNo9h and UDim2.new(1,0,0,Khst)or UDim2.new(0,Khst,1,0),Position=bxNo9h and UDim2.new(0,0,1,-Khst)or UDim2.new(1,-Khst,0,0),BackgroundTransparency=1,Name="ScrollFrame",NsoTwDs'ImageButton'{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.7,BorderSizePixel=0,Size=UDim2.new(0,Khst,0,Khst),Name="ScrollDown",Position= bxNo9h and UDim2.new(1,-Khst,0,0)or UDim2.new(0,0,1,-Khst)},NsoTwDs'ImageButton'{BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=0.7,BorderSizePixel=0,Size=UDim2.new(0,Khst,0,Khst),Name="ScrollUp"},NsoTwDs'ImageButton'{AutoButtonColor=false,Size= bxNo9h and UDim2.new(1,-Khst*2,1,0)or UDim2.new(1,0,1,-Khst*2),BackgroundColor3=Color3.new(0,0,0),BorderSizePixel=0,BackgroundTransparency=0.7,Position=bxNo9h and UDim2.new(0,Khst,0,0)or UDim2.new(0,0,0,Khst),Name="ScrollBar",NsoTwDs'ImageButton'{BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1),Size=UDim2.new(0,Khst,0,Khst),BackgroundTransparency=0.5,Name="ScrollThumb"}}}local ISg1=pUT.ScrollDown local Gh5UJya=seMLr(bxNo9h and"arrow-right"or"arrow-down",Vector2.new(Khst,Khst))Gh5UJya.GUI.Parent=ISg1
local k=pUT.ScrollUp local Z8Ue=seMLr(bxNo9h and"arrow-left"or "arrow-up",Vector2.new(Khst,Khst))Z8Ue.GUI.Parent=k
local TXbmx=pUT.ScrollBar
local r=TXbmx.ScrollThumb local Pqgz415t=seMLr(bxNo9h and "vgrip"or"grip",Vector2.new(4),{BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.5})Pqgz415t.GUI.Position=UDim2.new(0.5,-4,0.5,-4) Pqgz415t.GUI.Parent=r local McNxKV=NsoTwDs'ImageButton'{Active=false,Size=UDim2.new(1.5,0,1.5,0),AutoButtonColor=false,BackgroundTransparency=1,Name="MouseDrag",Position=UDim2.new(-0.25,0,-0.25,0),ZIndex=10} local WcwGYJh={GUI=pUT,ScrollIndex=0,VisibleSpace=0,TotalSpace=0,PageIncrement=1} local function gJt()return WcwGYJh.ScrollIndex/ (WcwGYJh.TotalSpace-WcwGYJh.VisibleSpace)end
WcwGYJh.GetScrollPercent=gJt
local function hCs8M() return WcwGYJh.ScrollIndex+WcwGYJh.VisibleSpace<WcwGYJh.TotalSpace end WcwGYJh.CanScrollDown=hCs8M
WcwGYJh.CanScrollRight=hCs8M local function GkjCn_mq()return WcwGYJh.ScrollIndex>0 end
WcwGYJh.CanScrollUp=GkjCn_mq
WcwGYJh.CanScrollLeft=GkjCn_mq local T9sySp={BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0} local DL0mMXM={BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.7}local o4Kvi75g
local ELb local FV5= bxNo9h and function() r.Size=UDim2.new(WcwGYJh.VisibleSpace/WcwGYJh.TotalSpace,0,0,Khst) if r.AbsoluteSize.x<Khst then r.Size=UDim2.new(0,Khst,0,Khst)end
local t=TXbmx.AbsoluteSize.x r.Position=UDim2.new(gJt()* (t-r.AbsoluteSize.x)/t,0,0,0)end or function() r.Size=UDim2.new(0,Khst,WcwGYJh.VisibleSpace/WcwGYJh.TotalSpace,0) if r.AbsoluteSize.y<Khst then r.Size=UDim2.new(0,Khst,0,Khst)end
local H=TXbmx.AbsoluteSize.y r.Position=UDim2.new(0,0,gJt()* (H-r.AbsoluteSize.y)/H,0)end local function sX()local glZrOuSo=WcwGYJh.TotalSpace
local Zdzaj=WcwGYJh.VisibleSpace local UxRGyO9e=WcwGYJh.ScrollIndex if Zdzaj<=glZrOuSo then if UxRGyO9e>0 then if UxRGyO9e+Zdzaj>glZrOuSo then WcwGYJh.ScrollIndex=glZrOuSo-Zdzaj end else WcwGYJh.ScrollIndex=0 end else WcwGYJh.ScrollIndex=0 end
if WcwGYJh.UpdateCallback then if WcwGYJh.UpdateCallback(WcwGYJh)==false then return end end
local fvj_L=hCs8M() local _CPU89l=GkjCn_mq() if fvj_L~=o4Kvi75g then o4Kvi75g=fvj_L
ISg1.Active=fvj_L
ISg1.AutoButtonColor=fvj_L Gh5UJya.Stylist.SetProperties( fvj_L and T9sySp or DL0mMXM)ISg1.BackgroundTransparency=fvj_L and 0.5 or 0.7 end if _CPU89l~=ELb then ELb=_CPU89l
k.Active=_CPU89l
k.AutoButtonColor=_CPU89l Z8Ue.Stylist.SetProperties( _CPU89l and T9sySp or DL0mMXM)k.BackgroundTransparency=_CPU89l and 0.5 or 0.7 end
r.Visible=fvj_L or _CPU89l
FV5()end
WcwGYJh.Update=sX
local function DH6mUlGB() WcwGYJh.ScrollIndex=WcwGYJh.ScrollIndex+WcwGYJh.PageIncrement
sX()end WcwGYJh.ScrollDown=DH6mUlGB
WcwGYJh.ScrollRight=DH6mUlGB
local function A4ZRczp() WcwGYJh.ScrollIndex=WcwGYJh.ScrollIndex-WcwGYJh.PageIncrement
sX()end WcwGYJh.ScrollUp=A4ZRczp
WcwGYJh.ScrollLeft=A4ZRczp local function rUT(U)WcwGYJh.ScrollIndex=U
sX()end
WcwGYJh.ScrollTo=rUT
local function g(Kwxn) WcwGYJh.ScrollIndex=math.floor( (WcwGYJh.TotalSpace-WcwGYJh.VisibleSpace)*Kwxn+0.5)sX()end WcwGYJh.SetScrollPercent=g
local function JPi(yp5DGSwX)local Sb1Mw7R=yp5DGSwX.Active
yp5DGSwX.Active=not Sb1Mw7R yp5DGSwX.Active=Sb1Mw7R end
NUhYw6R4(pUT) local Kkl6fa=0 ISg1.MouseButton1Down:connect(function()Kkl6fa=tick()local fuF=Kkl6fa
local pA2 pA2=McNxKV.MouseButton1Up:connect(function() Kkl6fa=tick()McNxKV.Parent=nil
JPi(ISg1)pA2:disconnect()drag=nil end)McNxKV.Parent=Hv(pUT)DH6mUlGB()wait(0.2)while Kkl6fa==fuF do DH6mUlGB()if not hCs8M()then break end
wait()end end) ISg1.MouseButton1Up:connect(function()Kkl6fa=tick()end) k.MouseButton1Down:connect(function()Kkl6fa=tick()local M5lAedm=Kkl6fa
local _uYRl2kj _uYRl2kj=McNxKV.MouseButton1Up:connect(function() Kkl6fa=tick()McNxKV.Parent=nil
JPi(k)_uYRl2kj:disconnect()drag=nil end)McNxKV.Parent=Hv(pUT)A4ZRczp()wait(0.2) while Kkl6fa==M5lAedm do A4ZRczp()if not GkjCn_mq()then break end
wait()end end) k.MouseButton1Up:connect(function()Kkl6fa=tick()end) TXbmx.MouseButton1Down:connect( bxNo9h and function(tbN,x)Kkl6fa=tick()local m=Kkl6fa
local VVQ VVQ=McNxKV.MouseButton1Up:connect(function() Kkl6fa=tick()McNxKV.Parent=nil
JPi(k)VVQ:disconnect()drag=nil end)McNxKV.Parent=Hv(pUT) if tbN>r.AbsolutePosition.x then rUT(WcwGYJh.ScrollIndex+ WcwGYJh.VisibleSpace) wait(0.2)while Kkl6fa==m do if tbN<r.AbsolutePosition.x+r.AbsoluteSize.x then break end rUT(WcwGYJh.ScrollIndex+WcwGYJh.VisibleSpace)wait()end else rUT( WcwGYJh.ScrollIndex-WcwGYJh.VisibleSpace)wait(0.2)while Kkl6fa==m do if tbN>r.AbsolutePosition.x then break end rUT(WcwGYJh.ScrollIndex-WcwGYJh.VisibleSpace)wait()end end end or function(Jb,qcpea)Kkl6fa=tick()local tjDBv=Kkl6fa
local vmn7v vmn7v=McNxKV.MouseButton1Up:connect(function() Kkl6fa=tick()McNxKV.Parent=nil
JPi(k)vmn7v:disconnect()drag=nil end)McNxKV.Parent=Hv(pUT) if qcpea>r.AbsolutePosition.y then rUT( WcwGYJh.ScrollIndex+WcwGYJh.VisibleSpace)wait(0.2) while Kkl6fa==tjDBv do if qcpea< r.AbsolutePosition.y+r.AbsoluteSize.y then break end
rUT(WcwGYJh.ScrollIndex+ WcwGYJh.VisibleSpace)wait()end else rUT(WcwGYJh.ScrollIndex-WcwGYJh.VisibleSpace)wait(0.2)while Kkl6fa==tjDBv do if qcpea>r.AbsolutePosition.y then break end rUT(WcwGYJh.ScrollIndex-WcwGYJh.VisibleSpace)wait()end end end) r.MouseButton1Down:connect( bxNo9h and function(Au1mzs,u39i)Kkl6fa=tick() local Fdg7p=Au1mzs-r.AbsolutePosition.x
local GD3AP
local jph00k GD3AP=McNxKV.MouseMoved:connect(function(Au1mzs,u39i) local wE_4o=TXbmx.AbsolutePosition.x local F=TXbmx.AbsoluteSize.x-r.AbsoluteSize.x
local bUO1NvT=wE_4o+F
Au1mzs=Au1mzs-Fdg7p Au1mzs=Au1mzs<wE_4o and wE_4o or Au1mzs> bUO1NvT and bUO1NvT or Au1mzs
Au1mzs=Au1mzs-wE_4o
g(Au1mzs/ (F))end) jph00k=McNxKV.MouseButton1Up:connect(function()Kkl6fa=tick()McNxKV.Parent=nil
JPi(r) GD3AP:disconnect()GD3AP=nil
jph00k:disconnect()drag=nil end)McNxKV.Parent=Hv(pUT)end or function(KRQG,tVwI_N)Kkl6fa=tick()local Jkp2lGXG=tVwI_N-r.AbsolutePosition.y local ifcyuS
local V03W ifcyuS=McNxKV.MouseMoved:connect(function(KRQG,tVwI_N)local R=TXbmx.AbsolutePosition.y
local X6_= TXbmx.AbsoluteSize.y-r.AbsoluteSize.y
local tN5u=R+X6_
tVwI_N= tVwI_N-Jkp2lGXG
tVwI_N= tVwI_N<R and R or tVwI_N>tN5u and tN5u or tVwI_N
tVwI_N=tVwI_N-R
g( tVwI_N/ (X6_))end) V03W=McNxKV.MouseButton1Up:connect(function()Kkl6fa=tick()McNxKV.Parent=nil
JPi(r) ifcyuS:disconnect()ifcyuS=nil
V03W:disconnect()drag=nil end)McNxKV.Parent=Hv(pUT)end)sX()return WcwGYJh,pUT end
LB1Z.ScrollBar=qX local function h_8(Yqc0GWr,UC7,WbvvcjER) Yqc0GWr=Yqc0GWr or Instance.new("Frame")local rOLxXC={}local w762p7sZ={}local _7jt=0
local ORXyFQ=0
local OL1oV=0
local Q=0
local HQvT5 if UC7 then if WbvvcjER then HQvT5=function()Q=Q+1
local Tcv_=Q local lygY=0
local HG=0 for u,m9i in pairs(rOLxXC)do if Q~=Tcv_ then return end if m9i.Visible then local EqPMP=m9i.AbsoluteSize
m9i.Position=UDim2.new(0, HG+_7jt,1,-EqPMP.y-_7jt)lygY= EqPMP.y>lygY and EqPMP.y or lygY
HG= HG+EqPMP.x+ORXyFQ end end
if Q~=Tcv_ then return end
if#rOLxXC>0 then Yqc0GWr.Size=UDim2.new(0,HG-ORXyFQ+_7jt*2+OL1oV,0, lygY+_7jt*2+OL1oV)else Yqc0GWr.Size=UDim2.new(0,_7jt*2+OL1oV,0,_7jt*2+OL1oV)end end else HQvT5=function()Q=Q+1
local JR=Q
local G1Cl6=0
local h=0 for fYUikw,W9qTCm in pairs(rOLxXC)do if Q~=JR then return end if W9qTCm.Visible then local YlaSjEKp=W9qTCm.AbsoluteSize
W9qTCm.Position=UDim2.new(0,h+_7jt,0,_7jt)G1Cl6= YlaSjEKp.y>G1Cl6 and YlaSjEKp.y or G1Cl6
h=h+ YlaSjEKp.x+ORXyFQ end end
if Q~=JR then return end
if#rOLxXC>0 then Yqc0GWr.Size=UDim2.new(0,h-ORXyFQ+_7jt*2+OL1oV,0, G1Cl6+_7jt*2+OL1oV)else Yqc0GWr.Size=UDim2.new(0,_7jt*2+OL1oV,0,_7jt*2+OL1oV)end end end else if WbvvcjER then HQvT5=function()Q=Q+1
local u_ogp8=Q
local Kob=0
local a3=0 for MvWxr,HgY6 in pairs(rOLxXC)do if Q~=u_ogp8 then return end
if HgY6.Visible then local Wc=HgY6.AbsoluteSize HgY6.Position=UDim2.new(1,-Wc.x-_7jt,0,a3+_7jt)Kob=Wc.x>Kob and Wc.x or Kob a3=a3+Wc.y+ORXyFQ end end
if Q~=u_ogp8 then return end
if#rOLxXC>0 then Yqc0GWr.Size=UDim2.new(0,Kob+_7jt*2+OL1oV,0, a3-ORXyFQ+_7jt*2+OL1oV)else Yqc0GWr.Size=UDim2.new(0,_7jt*2+OL1oV,0,_7jt*2+OL1oV)end end else HQvT5=function()Q=Q+1
local eQ5=Q
local kvR=0
local So=0 for Wi,X1WM in pairs(rOLxXC)do if Q~=eQ5 then return end if X1WM.Visible then local OVBAVy=X1WM.AbsoluteSize
X1WM.Position=UDim2.new(0,_7jt,0,So+_7jt)kvR=OVBAVy.x>kvR and OVBAVy.x or kvR So=So+OVBAVy.y+ORXyFQ end end
if Q~=eQ5 then return end
if#rOLxXC>0 then Yqc0GWr.Size=UDim2.new(0,kvR+_7jt*2+OL1oV,0,So- ORXyFQ+_7jt*2+OL1oV)else Yqc0GWr.Size=UDim2.new(0,_7jt*2+OL1oV,0,_7jt*2+OL1oV)end end end end local function dN(Joa,NF0)ORXyFQ=Joa or ORXyFQ
_7jt=NF0 or _7jt
HQvT5()end local function B35igHj(OeF,sawaLtSr) if OeF:IsA"GuiObject"then if type(sawaLtSr)=="number"then table.insert(rOLxXC,sawaLtSr,OeF)else table.insert(rOLxXC,OeF)end w762p7sZ[OeF]=OeF.Changed:connect(function(KWeL)if KWeL=="AbsoluteSize"or KWeL=="Visible"then HQvT5()end end)OeF.Parent=Yqc0GWr
HQvT5()end end local function o8pPC2(Krvhod9t)if Krvhod9t==nil then Krvhod9t=#rOLxXC elseif type(Krvhod9t)~="number"then Krvhod9t=hPQ(rOLxXC,Krvhod9t)end if Krvhod9t then Krvhod9t=R1FIoQI(rOLxXC,Krvhod9t)local bfx5oN=table.remove(rOLxXC,Krvhod9t)if w762p7sZ[bfx5oN]then w762p7sZ[bfx5oN]:disconnect()w762p7sZ[bfx5oN]=nil end bfx5oN.Parent=nil
HQvT5()return bfx5oN end end local function f7nUIW(XDKTNXw,RyTb)if XDKTNXw==nil then XDKTNXw=#rOLxXC elseif type(XDKTNXw)~="number"then XDKTNXw=hPQ(rOLxXC,XDKTNXw)end if RyTb==nil then RyTb=#rOLxXC elseif type(RyTb)~="number"then RyTb=hPQ(rOLxXC,RyTb)end if XDKTNXw and RyTb then XDKTNXw=R1FIoQI(rOLxXC,XDKTNXw) RyTb=R1FIoQI(rOLxXC,RyTb)local ImqF1v=table.remove(rOLxXC,XDKTNXw) table.insert(rOLxXC,RyTb,ImqF1v)HQvT5()end end local bDgD={GUI=Yqc0GWr,List=rOLxXC,Update=HQvT5,SetPadding=dN,AddObject=B35igHj,RemoveObject=o8pPC2,MoveObject=f7nUIW,GetIndex=function(KRu)return hPQ(rOLxXC,KRu)end} local function Kg8PhSq() for Vy5qF,rokDhenZ in pairs(rOLxXC)do if w762p7sZ[rokDhenZ]then w762p7sZ[rokDhenZ]:disconnect()w762p7sZ[rokDhenZ]=nil end
rokDhenZ.Parent= nil
rOLxXC[Vy5qF]=nil end for td8OL,W in pairs(w762p7sZ)do W:disconnect()w762p7sZ[td8OL]=nil end
for CS in pairs(bDgD)do bDgD[CS]=nil end
Yqc0GWr:Destroy()end
bDgD.Destroy=Kg8PhSq
for iv2VylMn,Oi in pairs(Yqc0GWr:GetChildren())do B35igHj(Oi,iv2VylMn)end
HQvT5() Yqc0GWr.Changed:connect(function(KwcrRu) if KwcrRu== "AbsoluteSize"or KwcrRu=="Style"then local bgFJ=OL1oV OL1oV=Ch(Yqc0GWr)*2
if OL1oV~=bgFJ then HQvT5()end end end)return bDgD,Yqc0GWr end
LB1Z.StackingFrame=h_8 local function xL7OTb(fqGD1rfW,K0)fqGD1rfW=fqGD1rfW or{}K0=entyHeight or a local _1To2=Instance.new("Frame")_1To2.Size=UDim2.new(0,300,0,200) _1To2.Style=Enum.FrameStyle.RobloxRound
_1To2.Active=true
_1To2.Name="ScrollingListFrame" local lkzs=Instance.new("Frame",_1To2)lkzs.Name="ListViewFrame"lkzs.BackgroundTransparency=1 lkzs.Size=UDim2.new(1,-K0,1,0) local Hhwf3oO=Stylist{Name="ListEntry",Font="ArialBold",FontSize="Size14",TextColor3=Color3.new(1,1,1),BackgroundTransparency=1,TextXAlignment="Left"}local Oh5=Instance.new("TextLabel")local LgQF={} local emGbhJGH,e_Ev8OQ=qX(false,K0)e_Ev8OQ.Size=UDim2.new(0,K0,1,0) e_Ev8OQ.Position=UDim2.new(1,-K0,0,0)e_Ev8OQ.Parent=_1To2
local zBMvU6=emGbhJGH.Update local ZmbDgbg={List=fqGD1rfW,GUI=_1To2,Scroll=emGbhJGH,Update=zBMvU6,EntryStylist=Hhwf3oO} emGbhJGH.UpdateCallback=function()local guEhw=emGbhJGH.VisibleSpace for sll=1,guEhw do local BzNBgGvD=fqGD1rfW[sll+emGbhJGH.ScrollIndex] if BzNBgGvD then local KIQCH=LgQF[sll] if not KIQCH then KIQCH=Oh5:Clone() Hhwf3oO.AddObject(KIQCH)LgQF[sll]=KIQCH
KIQCH.Parent=lkzs
KIQCH.ZIndex=_1To2.ZIndex end
KIQCH.Text=tostring(BzNBgGvD) KIQCH.Position=UDim2.new(0,0,0,(sll-1)*K0)KIQCH.Size=UDim2.new(1,0,0,K0)else local L4bw=LgQF[sll]if L4bw then Hhwf3oO.RemoveObject(L4bw)L4bw:Destroy()LgQF[sll]=nil end end end for XhBEPD=emGbhJGH.VisibleSpace+1,#LgQF do local Uq=LgQF[XhBEPD]if Uq then Hhwf3oO.RemoveObject(Uq)Uq:Destroy()end
LgQF[XhBEPD]=nil end end local function hMxy(RmyiI_D,w_2iiJwx)if w_2iiJwx then table.insert(fqGD1rfW,w_2iiJwx,RmyiI_D)else table.insert(fqGD1rfW,RmyiI_D)end emGbhJGH.TotalSpace=#fqGD1rfW
zBMvU6()end
ZmbDgbg.AddEntry=hMxy local function hj3(RRESd,S1qoVmFR) if S1qoVmFR then for f2=1,#RRESd do table.insert(fqGD1rfW,S1qoVmFR+f2-1,RRESd[f2])end else for O3rHR=1,#RRESd do table.insert(fqGD1rfW,RRESd[O3rHR])end end
emGbhJGH.TotalSpace=#fqGD1rfW
zBMvU6()end
ZmbDgbg.AddEntries=hj3 local function M7q3pa8(YU80) if type(YU80)=="number"or type(YU80)=="nil"then table.remove(fqGD1rfW,YU80)else for ARnO_0E,Qh in pairs(fqGD1rfW)do if Qh==YU80 then table.remove(fqGD1rfW,ARnO_0E)break end end end
emGbhJGH.TotalSpace=#fqGD1rfW
zBMvU6()end
ZmbDgbg.RemoveEntry=M7q3pa8
NUhYw6R4(_1To2) lkzs.Changed:connect(function(lqxbMC)if lqxbMC== "AbsoluteSize"then emGbhJGH.VisibleSpace=math.floor(lkzs.AbsoluteSize.y/K0)zBMvU6()end end) function ZmbDgbg.Destroy() for qOk5Jm in pairs(ZmbDgbg)do ZmbDgbg[qOk5Jm]=nil end for tpSe2fs,AuVgc7 in pairs(LgQF)do AuVgc7:Destroy()LgQF[tpSe2fs]=nil end
Hhwf3oO.Destroy()emGbhJGH.Destroy() _1To2:Destroy()end
return ZmbDgbg,_1To2 end
LB1Z.ScrollingList=xL7OTb local function w8T3f(vxnB,ZQOXXXd,cyBmTv)if vxnB==nil then vxnB=true end cyBmTv=cyBmTv or a local _TKd0F=NsoTwDs'Frame'{Name="ScrollingContainer",Size=UDim2.new(0,300,0,200),BackgroundTransparency=1} local Z=NsoTwDs'Frame'{Name="Boundary",BackgroundColor3=Color3.new(0,0,0),BorderColor3=Color3.new(1,1,1),ClipsDescendants=true,Parent=_TKd0F} local Dw=NsoTwDs'Frame'{Name="Container",BackgroundTransparency=1,Parent=Z}local bsFpM={GUI=_TKd0F,Boundary=Z,Container=Dw} if vxnB and ZQOXXXd then local h=qX(false,cyBmTv)h.PageIncrement=cyBmTv h.GUI.Position=UDim2.new(1,-cyBmTv,0,0)h.GUI.Size=UDim2.new(0,cyBmTv,1,-cyBmTv) h.GUI.Parent=_TKd0F
local doBTofya=h.Update h.UpdateCallback=function() Dw.Position=UDim2.new(0,Dw.Position.X.Offset,0,-h.ScrollIndex)end
local rNP=qX(true,cyBmTv)rNP.PageIncrement=cyBmTv
rNP.GUI.Position=UDim2.new(0,0,1,- cyBmTv) rNP.GUI.Size=UDim2.new(1,-cyBmTv,0,cyBmTv)rNP.GUI.Parent=_TKd0F
local TL=rNP.Update rNP.UpdateCallback=function() Dw.Position=UDim2.new(0,-rNP.ScrollIndex,0,Dw.Position.Y.Offset)end
Z.Size=UDim2.new(1,-cyBmTv,1,-cyBmTv)local function Tzgj_W()doBTofya() TL()end local function g0AS39(t2) if t2 =="AbsoluteSize"then h.TotalSpace=Dw.AbsoluteSize.y
h.VisibleSpace=Z.AbsoluteSize.y rNP.TotalSpace=Dw.AbsoluteSize.x
rNP.VisibleSpace=Z.AbsoluteSize.x
Tzgj_W()end end
Z.Changed:connect(g0AS39) Dw.Changed:connect(g0AS39)bsFpM.VScroll=h
bsFpM.HScroll=rNP
bsFpM.Update=Tzgj_W g0AS39("AbsoluteSize")Tzgj_W()elseif vxnB then local PDewNmM=qX(false,cyBmTv)PDewNmM.PageIncrement=cyBmTv
PDewNmM.GUI.Position=UDim2.new(1, -cyBmTv,0,0) PDewNmM.GUI.Size=UDim2.new(0,cyBmTv,1,0)PDewNmM.GUI.Parent=_TKd0F
local GFlD=PDewNmM.Update PDewNmM.UpdateCallback=function() Dw.Position=UDim2.new(0,Dw.Position.X.Offset,0, -PDewNmM.ScrollIndex)end local function y3owm5E(psHOEe2)if psHOEe2 =="AbsoluteSize"then PDewNmM.TotalSpace=Dw.AbsoluteSize.y PDewNmM.VisibleSpace=Z.AbsoluteSize.y
GFlD()end end
Z.Changed:connect(y3owm5E) Dw.Changed:connect(y3owm5E)bsFpM.VScroll=PDewNmM
bsFpM.Update=GFlD y3owm5E("AbsoluteSize")GFlD()elseif ZQOXXXd then local R1zT=qX(true,cyBmTv)R1zT.PageIncrement=cyBmTv
R1zT.GUI.Position=UDim2.new(0,0,1, -cyBmTv) R1zT.GUI.Size=UDim2.new(1,0,0,cyBmTv)R1zT.GUI.Parent=_TKd0F
local J2Df=R1zT.Update R1zT.UpdateCallback=function() Dw.Position=UDim2.new(0,- R1zT.ScrollIndex,0,Dw.Position.Y.Offset)end local function YyS(o)if o=="AbsoluteSize"then R1zT.TotalSpace=Dw.AbsoluteSize.x R1zT.VisibleSpace=Z.AbsoluteSize.x
J2Df()end end
Z.Changed:connect(YyS) Dw.Changed:connect(YyS)bsFpM.HScroll=R1zT
bsFpM.Update=J2Df
YyS("AbsoluteSize")J2Df()end
return bsFpM,_TKd0F end
LB1Z.ScrollingContainer=w8T3f local function K(MY16y,ZBUghmX,ncK)MY16y=MY16y or{}ncK=ncK or a
local Deq=0
local GH3wE=math.floor( Deq/ncK)local xZFv=0
local bc0w4j={}local OGMxal0={}local QlewVjkq={}local Q={} local yI={} local EDE3=NsoTwDs'Frame'{Size=UDim2.new(0,300,0,200),BackgroundTransparency=1,NsoTwDs'Frame'{Name="ListViewFrame",BackgroundTransparency=1,Size=UDim2.new(1,-ncK,1,-ncK),Position=UDim2.new(0,0,0,ncK)},NsoTwDs'Frame'{Name="ColumnHeaderFrame",BackgroundTransparency=1,Size=UDim2.new(1, -ncK,0,ncK),Position=UDim2.new(0,0,0,0)}}local FpWG11U=EDE3.ListViewFrame
local kRY46C=EDE3.ColumnHeaderFrame local MvOaiq=zhzpBSx{TextColor3=Color3.new(1,1,1),TextTransparency=0,Font=Enum.Font.ArialBold,FontSize=Enum.FontSize.Size14} local DUic_1K=zhzpBSx{BackgroundColor3=Color3.new(0,0,0),BorderColor3=Color3.new(1,1,1),BorderSizePixel=1,BackgroundTransparency=0.7}MvOaiq.AddStylist(DUic_1K) local rVj9z4=zhzpBSx{BackgroundColor3=Color3.new(1,1,1),BorderColor3=Color3.new(1,1,1),BorderSizePixel=1,BackgroundTransparency=0.8}MvOaiq.AddStylist(rVj9z4) local mWkmCx=zhzpBSx{BackgroundTransparency=1}MvOaiq.AddStylist(mWkmCx)local qQpo={}local qXKzBXo0={} local cJ,HI4G3oH=qX(false,ncK) HGli(HI4G3oH){Size=UDim2.new(0,ncK,1,-ncK),Position=UDim2.new(1,-ncK,0,ncK),Parent=EDE3}local ncWw=cJ.Update local kdS={Data=MY16y,GUI=EDE3,Stylist={Global=MvOaiq,Cell=DUic_1K,Header=rVj9z4,RowSpan=mWkmCx,Rows=qQpo,Columns=qXKzBXo0},Update=ncWw}local OS60=0 cJ.UpdateCallback=function()OS60=OS60+1
local DIoX3=OS60
for sjXYan,KxB8fW in pairs(Q)do if OS60 ~=DIoX3 then return end KxB8fW.Visible=false
Q[sjXYan]=nil end for M=1,cJ.VisibleSpace do if OS60 ~=DIoX3 then return end local JmyAd=bc0w4j[M+cJ.ScrollIndex] if JmyAd then Q[#Q+1]=JmyAd JmyAd.Position=UDim2.new(0,0,0,(M-1)*ncK)JmyAd.Size=UDim2.new(1,0,0,ncK)JmyAd.Visible=true end end end FpWG11U.Changed:connect(function(L) if L=="AbsoluteSize"then cJ.VisibleSpace=math.floor( FpWG11U.AbsoluteSize.y/ncK)ncWw()end end) local dl=NsoTwDs'Frame'{Name="SortGraphic",BackgroundTransparency=1,Size=UDim2.new(0,ncK,0,ncK),Position=UDim2.new(1,-ncK*0.75,0.5,-ncK/8)} local b2UK={["TextColor3"]="BackgroundColor3",["TextTransparency"]="BackgroundTransparency",["BorderSizePixel"]=""} local FC0yhp,lL30T=seMLr("arrow-up",Vector2.new(ncK,ncK))MvOaiq.AddStylist(FC0yhp.Stylist,b2UK) lL30T.Visible=false
lL30T.Parent=dl local zt,Ofgm3g=seMLr("arrow-down",Vector2.new(ncK,ncK))MvOaiq.AddStylist(zt.Stylist,b2UK) Ofgm3g.Visible=false
Ofgm3g.Parent=dl local function z6WE21dc(U,uAbuU) if uAbuU then if uAbuU.TextXAlignment==Enum.TextXAlignment.Right then dl.Position=UDim2.new(0,0,0,0)else dl.Position=UDim2.new(1,-ncK,0,0)end end if U>0 then lL30T.Visible=true
Ofgm3g.Visible=false
if dl.ZIndex~=uAbuU.ZIndex then m6SCS0(dl,uAbuU.ZIndex)end
dl.Parent=uAbuU elseif U<0 then lL30T.Visible=false Ofgm3g.Visible=true if dl.ZIndex~=uAbuU.ZIndex then m6SCS0(dl,uAbuU.ZIndex)end
dl.Parent=uAbuU else lL30T.Visible=false
Ofgm3g.Visible=false
dl.Parent=nil end end local function rJg9H(EF205E,YFR5myC)for KMu,PPqE in pairs(MY16y)do bc0w4j[KMu]=OGMxal0[PPqE]end local K1Lgio=kRY46C:GetChildren()[EF205E]z6WE21dc(0) if YFR5myC==iD1IUx.ASCENDING then table.sort(bc0w4j,function(sOE,hf9m_U8) local dTQ,k29Z4=QlewVjkq[sOE][EF205E],QlewVjkq[hf9m_U8][EF205E]local ai=type(dTQ) if ai=="table"then dTQ,k29Z4=dTQ[1],k29Z4[1]ai=type(dTQ)end if ai=="boolean"then return tostring(dTQ)>tostring(k29Z4)elseif ai== "number"or ai=="string"then return dTQ<k29Z4 else return tostring(dTQ)<tostring(k29Z4)end end)z6WE21dc(1,K1Lgio)elseif YFR5myC==iD1IUx.DESCENDING then table.sort(bc0w4j,function(t,TmE) local xR,LJ3E=QlewVjkq[t][EF205E],QlewVjkq[TmE][EF205E]local Vjx=type(xR) if Vjx=="table"then xR,LJ3E=xR[1],LJ3E[1]Vjx=type(xR)end if Vjx=="boolean"then return tostring(xR)<tostring(LJ3E)elseif Vjx=="number"or Vjx=="string"then return xR>LJ3E else return tostring(xR)>tostring(LJ3E)end end)local K1Lgio=kRY46C:GetChildren()[EF205E] z6WE21dc(-1,K1Lgio)end
ncWw()end local sNyznm3W=NsoTwDs'Frame'{Name="Row",Visible=false} local function UU(curjMDD,gBS9Zk) if gBS9Zk==nil then curjMDD.Text=""else gBS9Zk=tostring(gBS9Zk) if #gBS9Zk>0 and curjMDD.TextXAlignment~=Enum.TextXAlignment.Center then if curjMDD.TextXAlignment==Enum.TextXAlignment.Left then curjMDD.Text=" ".. gBS9Zk elseif curjMDD.TextXAlignment==Enum.TextXAlignment.Right then curjMDD.Text=gBS9Zk.." "end else curjMDD.Text=gBS9Zk end end end local function YBciOAz2(Xr,UPp)local hWpZC=yI[Xr]local bFF8,RXM=hWpZC.Checked,hWpZC.Unchecked if type(RXM)=="string"then Xr.Image=UPp and""or RXM elseif type(RXM)=="table"then if UPp then RXM.GUI.Parent=nil else if RXM.GUI.ZIndex~=Xr.ZIndex then m6SCS0(RXM.GUI,Xr.ZIndex)end
RXM.GUI.Parent=Xr end end if type(bFF8)=="string"then Xr.Image=UPp and bFF8 or""elseif type(bFF8)=="table"then if UPp then if bFF8.GUI.ZIndex~=Xr.ZIndex then m6SCS0(bFF8.GUI,Xr.ZIndex)end
bFF8.GUI.Parent=Xr else bFF8.GUI.Parent=nil end end end
local wJvNH=nil
local dOvZoN=iD1IUx.NONE
local IP01vP=UDim.new() for Ieb1cGC,Bf in pairs(ZBUghmX)do local hKJi2=zhzpBSx(Bf.style)qXKzBXo0[Ieb1cGC]=hKJi2
local jW=Bf.type
local JkVK if jW=="text"then JkVK=Instance.new("TextLabel",sNyznm3W)JkVK.Name="Text"elseif jW=="image"then JkVK=Instance.new("ImageLabel",sNyznm3W)JkVK.Name="Image"elseif jW=="text-button"then JkVK=Instance.new("TextButton",sNyznm3W)JkVK.Name="TextButton"elseif jW=="image-button"then JkVK=Instance.new("ImageButton",sNyznm3W)JkVK.Name="ImageButton"elseif jW=="text-field"then JkVK=Instance.new("TextBox",sNyznm3W)JkVK.Name="TextField"JkVK.ClearTextOnFocus=false elseif jW=="check-box"then JkVK=Instance.new("ImageButton",sNyznm3W)JkVK.Name="CheckBox"end local oXM7=NsoTwDs'TextButton'{Name="ColumnHeader",Parent=kRY46C}rVj9z4.AddObject(oXM7)hKJi2.AddObject(oXM7) UU(oXM7,Bf.name) oXM7.MouseButton1Click:connect(function() if wJvNH==oXM7 then if dOvZoN==iD1IUx.ASCENDING then dOvZoN=iD1IUx.DESCENDING elseif dOvZoN==iD1IUx.DESCENDING then dOvZoN=iD1IUx.NONE else dOvZoN=iD1IUx.ASCENDING end else dOvZoN=iD1IUx.ASCENDING end
wJvNH=oXM7
rJg9H(Ieb1cGC,dOvZoN)end)local z__Va=Bf.width oXM7.Size=UDim2.new(z__Va.Scale,z__Va.Offset,1,0) oXM7.Position=UDim2.new(IP01vP.Scale,IP01vP.Offset,0,0)IP01vP=IP01vP+z__Va end
IP01vP=nil function kdS.UpdateRow(uGbp)local OXK0 if type(uGbp)=="number"then OXK0=MY16y[uGbp]else OXK0=uGbp end
local Ek3QueoD=OGMxal0[OXK0]local g=Ek3QueoD:GetChildren() local m_l=UDim.new() for L,XmcB in pairs(ZBUghmX)do local l5Nd=XmcB.type
local sEMv=g[L]local VPX=OXK0[L]local c=XmcB.width if l5Nd== "text"then UU(sEMv,VPX)elseif l5Nd=="image"then sEMv.Image=VPX elseif l5Nd=="text-button"then UU(sEMv,VPX)elseif l5Nd=="image-button"then sEMv.Image=VPX elseif l5Nd=="text-field"then UU(sEMv,VPX)elseif l5Nd== "check-box"then YBciOAz2(sEMv,VPX)end
sEMv.Size=UDim2.new(c.Scale,c.Offset,1,0) sEMv.Position=UDim2.new(m_l.Scale,m_l.Offset,0,0)m_l=m_l+c end end function kdS.AddRow(VGJdue,ztMtdy,rA)local zHapMi=sNyznm3W:Clone() if ztMtdy then ztMtdy=ztMtdy>#MY16y+1 and #MY16y+1 or ztMtdy<1 and 1 or ztMtdy
table.insert(MY16y,ztMtdy,VGJdue) table.insert(bc0w4j,ztMtdy,zHapMi)else table.insert(MY16y,VGJdue) table.insert(bc0w4j,zHapMi)end
cJ.TotalSpace=#MY16y
mWkmCx.AddObject(zHapMi) zHapMi.Size=UDim2.new(1,0,0,ncK)zHapMi.ZIndex=EDE3.ZIndex
zHapMi.Parent=FpWG11U local Jmsve1Q=zHapMi:GetChildren()local _B8W1YL=UDim.new()local F=zhzpBSx(rA)qQpo[VGJdue]=F for FN7,cpNryuPy in pairs(ZBUghmX)do local mVKRd8=cpNryuPy.type
local TBV0052=Jmsve1Q[FN7]TBV0052.ZIndex=EDE3.ZIndex DUic_1K.AddObject(TBV0052)qXKzBXo0[FN7].AddObject(TBV0052) F.AddObject(TBV0052)local cGBeq=VGJdue[FN7]local PRXb=cpNryuPy.width if mVKRd8 =="text"then UU(TBV0052,cGBeq)elseif mVKRd8 =="image"then TBV0052.Image=cGBeq elseif mVKRd8 =="text-button"then UU(TBV0052,cGBeq) TBV0052.MouseButton1Click:connect(function() cpNryuPy.callback(VGJdue,kdS)end)elseif mVKRd8 =="image-button"then TBV0052.Image=cGBeq TBV0052.MouseButton1Click:connect(function() cpNryuPy.callback(VGJdue,kdS)end)elseif mVKRd8 =="text-field"then UU(TBV0052,cGBeq)local t=cGBeq TBV0052.FocusLost:connect(function(Jk3TbYo) local Nm61D3Il=cpNryuPy.callback(TBV0052.Text,VGJdue,kdS,Jk3TbYo)if Nm61D3Il then VGJdue[FN7]=Nm61D3Il
UU(TBV0052,Nm61D3Il)t=Nm61D3Il else UU(TBV0052,t)end end)elseif mVKRd8 =="check-box"then yI[TBV0052]={} if type(cpNryuPy.checked)=="table"then local Qjx7nk=seMLr(cpNryuPy.checked[1],cpNryuPy.checked[2])m6SCS0(Qjx7nk.GUI,EDE3.ZIndex) MvOaiq.AddStylist(Qjx7nk.Stylist,b2UK)yI[TBV0052].Checked=Qjx7nk else yI[TBV0052].Checked=cpNryuPy.checked end if type(cpNryuPy.unchecked)=="table"then local ZfqIP=seMLr(cpNryuPy.unchecked[1],cpNryuPy.unchecked[2])m6SCS0(ZfqIP.GUI,EDE3.ZIndex) MvOaiq.AddStylist(ZfqIP.Stylist,b2UK)yI[TBV0052].Unchecked=ZfqIP else yI[TBV0052].Unchecked=cpNryuPy.unchecked end
YBciOAz2(TBV0052,cGBeq) TBV0052.MouseButton1Click:connect(function() local p4ZD2RW=true if cpNryuPy.callback then p4ZD2RW=cpNryuPy.callback(VGJdue,kdS)end
if p4ZD2RW then VGJdue[FN7]=not VGJdue[FN7] YBciOAz2(TBV0052,VGJdue[FN7])end end)end TBV0052.Size=UDim2.new(PRXb.Scale,PRXb.Offset,1,0) TBV0052.Position=UDim2.new(_B8W1YL.Scale,_B8W1YL.Offset,0,0)_B8W1YL=_B8W1YL+PRXb end
OGMxal0[VGJdue]=zHapMi
QlewVjkq[zHapMi]=VGJdue
ncWw()return VGJdue end function kdS.RemoveRow(o)local QK5cr if type(o)=="number"or type(o)=="nil"then QK5cr=table.remove(MY16y,o)else for e575,OP in pairs(MY16y)do if OP==o then QK5cr=table.remove(MY16y,e575)break end end end if QK5cr then local HxUqj4B=qQpo[QK5cr]HxUqj4B.Destroy()qQpo[QK5cr]=nil local dryo7a=OGMxal0[QK5cr]QlewVjkq[dryo7a]=nil
OGMxal0[QK5cr]=nil for Vvmt,z1jKKH in pairs(bc0w4j)do if z1jKKH==dryo7a then for Vvmt,A in pairs(z1jKKH:GetChildren())do MvOaiq.RemoveObject(A) qXKzBXo0[Vvmt].RemoveObject(A)DUic_1K.RemoveObject(A)end
table.remove(bc0w4j,Vvmt)break end end
cJ.TotalSpace=#MY16y for i_ASR7X,lneZ2 in pairs(Q)do if lneZ2 ==dryo7a then table.remove(Q,i_ASR7X)break end end
dryo7a:Destroy()end
ncWw()return QK5cr end do local wZLxwQr={} for Z,b3h1 in pairs(MY16y)do wZLxwQr[Z]=b3h1
MY16y[Z]=nil end
for AGn=1,#wZLxwQr do kdS.AddRow(wZLxwQr[AGn])end end
NUhYw6R4(EDE3) function kdS.Destroy()local function EQVz(pYXX) for GvHSsw in pairs(pYXX)do pYXX[GvHSsw]=nil end end
EQVz(kdS.Stylist) EQVz(kdS)EQVz(bc0w4j)EQVz(OGMxal0)EQVz(QlewVjkq)EQVz(Q) EQVz(yI)MvOaiq.Destroy()DUic_1K.Destroy() rVj9z4.Destroy()mWkmCx.Destroy() for XvK5,bK2 in pairs(qQpo)do bK2.Destroy()qQpo[XvK5]=nil end for U,FVkHUl7 in pairs(qXKzBXo0)do FVkHUl7.Destroy()qXKzBXo0[U]=nil end
cJ.Destroy()sNyznm3W:Destroy()EDE3:Destroy()end
kdS.Update()return kdS,EDE3 end
LB1Z.DetailedList=K local function qL(FOA,eF0tAUG,_x)eF0tAUG=eF0tAUG or 24
_x=_x or 20
local J2o6d=0
local r={} local PKiW0={}local odc5tp={} local t3yD=NsoTwDs'Frame'{Name="TabContainer",Size=UDim2.new(0,300,0,200),BackgroundTransparency=1,NsoTwDs'Frame'{Name="Content",Size=UDim2.new(1,0,1,- eF0tAUG),Position=UDim2.new(0,0,0,eF0tAUG),BackgroundColor3=Color3.new(),BorderColor3=Color3.new(1,1,1)},NsoTwDs'Frame'{Parent=TabContainerFrame,Name="Tabs",BackgroundTransparency=1}}local _nofE2=t3yD.Content
local kPOaEej=t3yD.Tabs
local XrKR=h_8(kPOaEej,true,true) local EZSc2rAA=zhzpBSx({BackgroundColor3=Color3.new(),BackgroundTransparency=0.5,BorderColor3=Color3.new(1,1,1),TextColor3=Color3.new(1,1,1),Font="ArialBold",FontSize="Size14"})EZSc2rAA.AddObject(_nofE2) local r0aOmY=zhzpBSx({BackgroundColor3=Color3.new(),BackgroundTransparency=0.5,BorderColor3=Color3.new(1,1,1),TextColor3=Color3.new(1,1,1),Font="ArialBold",FontSize="Size14"}) local function hPQ(Yo)for nkWKbF,M9 in pairs(r)do if M9 ==Yo then return nkWKbF end end end
local function YzL3P1()return J2o6d,r[J2o6d]end
local function R1FIoQI(cVvE,R8)local CsDz=#r+ (R8 or 0) cVvE=math.floor(cVvE) return cVvE<1 and 1 or cVvE>CsDz and CsDz or cVvE end local function a2(u) if#r>0 then if type(u)~="number"then u=hPQ(u)end if u then u=R1FIoQI(u) if J2o6d>0 then local m5STS=r[J2o6d]m5STS.Visible=false
local CJ4gk6Xx=PKiW0[m5STS] CJ4gk6Xx.LockAxis(nil,_x)r0aOmY.RemoveObject(CJ4gk6Xx,GUI) EZSc2rAA.AddObject(CJ4gk6Xx.GUI)end
local Ru8E=r[u]Ru8E.Visible=true
local nK=PKiW0[Ru8E] nK.LockAxis(nil,eF0tAUG)EZSc2rAA.RemoveObject(nK.GUI) r0aOmY.AddObject(nK.GUI)J2o6d=u end else J2o6d=0 end end local function hrEWj(WwPLCA3t,YAwrq) if YAwrq then YAwrq=R1FIoQI(YAwrq,1) table.insert(r,YAwrq,WwPLCA3t)else table.insert(r,WwPLCA3t)YAwrq=#r end
WwPLCA3t.Visible=false
WwPLCA3t.Parent=_nofE2 local VHZ4I=NsoTwDs'TextButton'{Name="Tab",Text=WwPLCA3t.Name}local JTS=rHSjalVy(VHZ4I)PKiW0[WwPLCA3t]=JTS JTS.SetPadding(0,4)JTS.LockAxis(nil,_x)EZSc2rAA.AddObject(VHZ4I) XrKR.AddObject(VHZ4I,YAwrq) VHZ4I.MouseButton1Click:connect(function()a2(WwPLCA3t)end) odc5tp[WwPLCA3t]=WwPLCA3t.Changed:connect(function(zRbXf)if zRbXf=="Name"then VHZ4I.Text=WwPLCA3t.Name end end) if J2o6d==0 then a2(YAwrq)elseif YAwrq<=J2o6d then J2o6d=J2o6d+1 end end local function Qgeq(caDLM) if#r>0 then if type(caDLM)~="number"then if caDLM==nil then caDLM=#r else caDLM=hPQ(caDLM)end end if caDLM then caDLM=R1FIoQI(caDLM) local Pj=table.remove(r,caDLM)Pj.Parent=nil
odc5tp[Pj]:disconnect()odc5tp[Pj]=nil local xm=PKiW0[Pj]XrKR.RemoveObject(caDLM)PKiW0[Pj]=nil
xm.Destroy() if caDLM== J2o6d then a2(caDLM)elseif caDLM<J2o6d then J2o6d=J2o6d-1 end
return Pj end end end local function ay_Dm(we,uv) if#r>0 then if type(we)~="number"then we=hPQ(we)end
if type(uv)~="number"then uv=hPQ(uv)end if we and uv then we=R1FIoQI(we)uv=R1FIoQI(uv) local eu=table.remove(r,we)table.insert(r,uv,eu)XrKR.MoveObject(we,uv)if we==J2o6d then J2o6d=uv elseif we>J2o6d and uv<=J2o6d then J2o6d=J2o6d+1 elseif we<J2o6d and uv>=J2o6d then J2o6d=J2o6d-1 end end end end local z8K0j={GUI=t3yD,GetIndex=hPQ,GetSelectedIndex=YzL3P1,SelectTab=a2,AddTab=hrEWj,RemoveTab=Qgeq,MoveTab=ay_Dm,TabStylist=EZSc2rAA,SelectedTabStylist=r0aOmY}NUhYw6R4(t3yD) local function yh() for j7Zsjoj in pairs(z8K0j)do z8K0j[j7Zsjoj]=nil end
r0aOmY.Destroy()EZSc2rAA.Destroy() XrKR.Destroy() for VDXpXH,NT23H in pairs(odc5tp)do NT23H:disconnect()odc5tp[VDXpXH]=nil end
for N8WCvTtk,vk7 in pairs(r)do vk7.Parent=nil
r[N8WCvTtk]=nil end for aaOq,F7JMSq_H in pairs(PKiW0)do PKiW0[aaOq]=nil
F7JMSq_H.Destroy()end
t3yD:Destroy()end
z8K0j.Destroy=yh
if FOA then for BNZ09E,mcJGlQD6 in pairs(FOA)do hrEWj(mcJGlQD6,BNZ09E)end end
return z8K0j,t3yD end
LB1Z.TabContainer=qL
local vfIyB={} function vfIyB.Confirm(AcM1nG,mMJQWw,sC,RE) GlobalStylist=sC or Stylist{BackgroundColor3=Color3.new(0,0,0),BorderColor3=Color3.new(1,1,1),TextColor3=Color3.new(1,1,1),Font="ArialBold",FontSize="Size14"} ButtonStylist=RE or Stylist{Style="RobloxButton"}local mPRxk=zhzpBSx(style)local iVO=zhzpBSx(button_style) local S5PgiAbz=mPRxk.StylistIn(iVO)mPRxk.AddStylist(iVO) local jj1oYjc=NsoTwDs'Frame'{Name="ConfirmDialog",Size=UDim2.new(1.5,0,1.5,0),Position=UDim2.new( -0.25,0,-0.25,0),BorderSizePixel=0,BackgroundTransparency=0.5,BackgroundColor3=Color3.new(0,0,0),Active=true,mPRxk.AddObject(NsoTwDs'Frame'{Name="DialogBox",Size=UDim2.new(0,250,0,150),Position=UDim2.new(0.5, -125,0.5,-75),NsoTwDs'Frame'{Name="MarginBox",BackgroundTransparency=1,Size=UDim2.new(1,-16,1,-16),Position=UDim2.new(0,8,0,8),mPRxk.AddObject(NsoTwDs'TextLabel'{BackgroundTransparency=1,TextScaled=true,Text= mMJQWw or"",Size=UDim2.new(1,-16,0.8,-24),Position=UDim2.new(0,8,0,8)}),NsoTwDs'Frame'{Name="Buttons",BackgroundTransparency=1,Size=UDim2.new(1,0,0.2,0),Position=UDim2.new(0,0,0.8,0),iVO.AddObject(NsoTwDs'TextButton'{Name="YesButton",Text="Yes",Size=UDim2.new( 1/3,0,1,0),Position=UDim2.new(0/3,0,0,0)}),iVO.AddObject(NsoTwDs'TextButton'{Name="NoButton",Text="No",Size=UDim2.new( 1/3,0,1,0),Position=UDim2.new(1/3,0,0,0)}),iVO.AddObject(NsoTwDs'TextButton'{Name="CancelButton",Text="Cancel",Size=UDim2.new( 1/3,0,1,0),Position=UDim2.new(2/3,0,0,0)})}}})}local YVjxMh=jj1oYjc.DialogBox.MarginBox.Buttons local sERpty=nil
local R9WhkbR=Instance.new("BindableEvent") YVjxMh.YesButton.MouseButton1Click:connect(function() sERpty=true
R9WhkbR:Fire()end) YVjxMh.NoButton.MouseButton1Click:connect(function()sERpty=false R9WhkbR:Fire()end) YVjxMh.CancelButton.MouseButton1Click:connect(function()sERpty=nil R9WhkbR:Fire()end)m6SCS0(jj1oYjc,10)jj1oYjc.Parent=AcM1nG R9WhkbR.Event:wait()jj1oYjc:Destroy()R9WhkbR:Destroy() if sC==nil then mPRxk.Destroy()else if not S5PgiAbz then mPRxk.RemoveStylist(iVO)end end
if RE==nil then iVO.Destroy()end
return sERpty end
LB1Z.dialog=vfIyB do local Wjj={} for X9n9mro,Uj6hK in pairs(N9L)do if type(X9n9mro)=="string"then table.insert(Wjj,X9n9mro)end end
table.sort(Wjj)for qk3r,Otbx_3g in pairs(Wjj)do default_help=default_help.."\t"..Otbx_3g.."\n"end end
local quNsijN={}quNsijN[false]=default_help function LB1Z.Help(XRg,Q7c8C2T)if type(XRg)=="string"then XRg=XRg:lower()end local Gz=quNsijN[XRg]or quNsijN[false] if not Q7c8C2T then print(string.rep("_",80)) for XfMQy in Gz:gsub("\r\n?","\n"):gmatch("(.-)\n")do XfMQy=XfMQy:gsub(" ","\160") XfMQy=XfMQy:gsub("\t",string.rep("\160",8)) print(#XfMQy==0 and"\160"or XfMQy)end
print("\160")end
return Gz end for mu_2r,Es in pairs(N9L)do if type(mu_2r)=="string"then quNsijN[mu_2r:lower()]=Es
local c=LB1Z[mu_2r] if type(c)=="function"then quNsijN[c]=Es end end end setmetatable(LB1Z,{__tostring=function()return ("%s GUI Library [v%s] (use %s.Help() for help)"):format(tczrIB,hDc_M,tczrIB)end})_G.gloo=LB1Z end
gloostart()end end
Workspace=Game:GetService'Workspace' Players=Game:GetService'Players'MarketplaceService=Game:GetService'MarketplaceService' ContentProvider=Game:GetService'ContentProvider'SoundService=Game:GetService'SoundService' UserInputService=Game:GetService'UserInputService'SelectionService=Game:GetService'Selection' CoreGui=Game:GetService'CoreGui'HttpService=Game:GetService'HttpService' ChangeHistoryService=Game:GetService'ChangeHistoryService' Assets={DarkSlantedRectangle='http://www.roblox.com/asset/?id=127774197',LightSlantedRectangle='http://www.roblox.com/asset/?id=127772502',ActionCompletionSound='http://www.roblox.com/asset/?id=99666917',ExpandArrow='http://www.roblox.com/asset/?id=134367382',UndoActiveDecal='http://www.roblox.com/asset/?id=141741408',UndoInactiveDecal='http://www.roblox.com/asset/?id=142074557',RedoActiveDecal='http://www.roblox.com/asset/?id=141741327',RedoInactiveDecal='http://www.roblox.com/asset/?id=142074553',DeleteActiveDecal='http://www.roblox.com/asset/?id=141896298',DeleteInactiveDecal='http://www.roblox.com/asset/?id=142074644',ExportActiveDecal='http://www.roblox.com/asset/?id=141741337',ExportInactiveDecal='http://www.roblox.com/asset/?id=142074569',CloneActiveDecal='http://www.roblox.com/asset/?id=142073926',CloneInactiveDecal='http://www.roblox.com/asset/?id=142074563',PluginIcon='http://www.roblox.com/asset/?id=142287521',GroupLockIcon='http://www.roblox.com/asset/?id=175396862',GroupUnlockIcon='http://www.roblox.com/asset/?id=160408836',GroupUpdateOKIcon='http://www.roblox.com/asset/?id=164421681',GroupUpdateIcon='http://www.roblox.com/asset/?id=160402908'}ToolAssetID=142785488
Player=Players.LocalPlayer
Mouse=nil if plugin then ToolType='plugin'GUIContainer=CoreGui ToolbarButton=plugin:CreateToolbar('Building Tools by F3X'):CreateButton('','Building Tools by F3X',Assets.PluginIcon)elseif Tool:IsA'Tool'then ToolType='tool' GUIContainer=Player:WaitForChild'PlayerGui'end
RbxUtility=t
Support={}SupportLibrary={} function SupportLibrary.FindTableOccurrences(C,o0Xe6nHM) local ulAVnjc={}for zF6Bw,zuKqH in pairs(C)do if zuKqH==o0Xe6nHM then table.insert(ulAVnjc,zF6Bw)end end
return ulAVnjc end function SupportLibrary.FindTableOccurrence(litdqp,r) for n,uSzWLeSi in pairs(litdqp)do if uSzWLeSi==r then return n end end
return nil end function SupportLibrary.IsInTable(phUBXWJ9,Qgtt7) for yTthTeWK,pG in pairs(phUBXWJ9)do if pG==Qgtt7 then return true end end
return false end function SupportLibrary.Round(um_kO,ngCGBaF)local A8TTTd8=10^ (ngCGBaF or 0)return math.floor( um_kO*A8TTTd8+0.5)/A8TTTd8 end function SupportLibrary.CloneTable(yGa)local j4bdRB6o=getmetatable(yGa)return setmetatable({unpack(yGa)},j4bdRB6o)end function SupportLibrary.GetAllDescendants(f8jh)local OLzzUp={} for VlN,r in pairs(f8jh:GetChildren())do table.insert(OLzzUp,r)for VlN,mhEYg in pairs(SupportLibrary.GetAllDescendants(r))do table.insert(OLzzUp,mhEYg)end end
return OLzzUp end function SupportLibrary.GetDescendantCount(rUJN6)local cYH30J=0
for VR,pyzkzd in pairs(rUJN6:GetChildren())do cYH30J=cYH30J+1 cYH30J=cYH30J+SupportLibrary.GetDescendantCount(pyzkzd)end
return cYH30J end
function SupportLibrary.CloneParts(ksDuO71)local BAy={} for tTCbo2,p in pairs(ksDuO71)do BAy[tTCbo2]=p:Clone()end
return BAy end function SupportLibrary.SplitString(UNyk,cG0) local kzTZ7={}local f8SnhE4T=('([^%s]+)'):format(cG0) UNyk:gsub(f8SnhE4T,function(aascxP) table.insert(kzTZ7,aascxP)end)return kzTZ7 end function SupportLibrary.GetChildOfClass(eSG8f8ru,w2yJAi,lH1c) if not lH1c then for CHS,fQdTWIXs in pairs(eSG8f8ru:GetChildren())do if fQdTWIXs.ClassName==w2yJAi then return fQdTWIXs end end else for QG,d78 in pairs(eSG8f8ru:GetChildren())do if d78:IsA(w2yJAi)then return d78 end end end
return nil end function SupportLibrary.GetChildrenOfClass(C6pS,GwH,O)local sbuS4={} if not O then for Rrfir0,lXr in pairs(C6pS:GetChildren())do if lXr.ClassName==GwH then table.insert(sbuS4,lXr)end end else for hz,f in pairs(C6pS:GetChildren())do if f:IsA(GwH)then table.insert(sbuS4,f)end end end
return sbuS4 end function SupportLibrary.HSVToRGB(knCGg,UPf,amxXn)if UPf==0 then return amxXn end local CSwsYPyj=math.floor(knCGg/60)local I9I=(knCGg/60)-CSwsYPyj
local aB=amxXn* (1-UPf)local BiUZ8vx4=amxXn* (1-UPf* I9I) local v=amxXn* (1-UPf* (1-I9I)) if CSwsYPyj==0 then return amxXn,v,aB elseif CSwsYPyj==1 then return BiUZ8vx4,amxXn,aB elseif CSwsYPyj==2 then return aB,amxXn,v elseif CSwsYPyj==3 then return aB,BiUZ8vx4,amxXn elseif CSwsYPyj==4 then return v,aB,amxXn elseif CSwsYPyj==5 then return amxXn,aB,BiUZ8vx4 end end function SupportLibrary.RGBToHSV(W8dN,eL,U4G6f)local gmhVDH,a,NesXI
local OZ8oHL=math.min(W8dN,eL,U4G6f) local sa=math.max(W8dN,eL,U4G6f)NesXI=sa
local hT=sa-OZ8oHL if sa~=0 then a=hT/sa else a=0
gmhVDH=-1
return gmhVDH,a,NesXI end if W8dN==sa then gmhVDH=(eL-U4G6f)/hT elseif eL==sa then gmhVDH=2+ (U4G6f-W8dN)/hT else gmhVDH=4+ (W8dN-eL)/hT end
gmhVDH=gmhVDH*60
if gmhVDH<0 then gmhVDH=gmhVDH+360 end return gmhVDH,a,NesXI end function SupportLibrary.IdentifyCommonItem(zICb5)local HB_RPF=nil for kJZlA,blNC in pairs(zICb5)do if kJZlA==1 then HB_RPF=blNC else if blNC~=HB_RPF then return nil end end end
return HB_RPF end function SupportLibrary.IdentifyCommonProperty(l,y9)local z={}for MjtdB7KS,_M_Cmn9C in pairs(l)do table.insert(z,_M_Cmn9C[y9])end
return SupportLibrary.IdentifyCommonItem(z)end function SupportLibrary.CreateSignal() local GZQBW7r7={Connections={},Connect=function(VHBi5G,Z1D6NL) table.insert(VHBi5G.Connections,Z1D6NL) local XAy={Handler=Z1D6NL,Disconnect=function(zxyLTb) local rhMWaiC=SupportLibrary.FindTableOccurrences(VHBi5G.Connections,zxyLTb.Handler)if#rhMWaiC>0 then local pM=rhMWaiC[1] table.remove(VHBi5G.Connections,pM)end end}XAy.disconnect=XAy.Disconnect
return XAy end,Fire=function(i,...)for k,hr in pairs(i.Connections)do hr(...)end end}GZQBW7r7.connect=GZQBW7r7.Connect
GZQBW7r7.fire=GZQBW7r7.Fire
return GZQBW7r7 end function SupportLibrary.GetPartCorners(M)local Ucy5ca=table.insert local ycyK=CFrame.new().toWorldSpace
local Yfm6hogh=CFrame.new
local T6eti=M.CFrame local z7j,CGz,aukN3ZWX=M.Size.x/2,M.Size.y/2,M.Size.z/2
local eSCsri5={} Ucy5ca(eSCsri5,ycyK(T6eti,Yfm6hogh(z7j,CGz,aukN3ZWX))) Ucy5ca(eSCsri5,ycyK(T6eti,Yfm6hogh(-z7j,CGz,aukN3ZWX))) Ucy5ca(eSCsri5,ycyK(T6eti,Yfm6hogh(z7j,-CGz,aukN3ZWX))) Ucy5ca(eSCsri5,ycyK(T6eti,Yfm6hogh(z7j,CGz,-aukN3ZWX))) Ucy5ca(eSCsri5,ycyK(T6eti,Yfm6hogh(-z7j,CGz,-aukN3ZWX))) Ucy5ca(eSCsri5,ycyK(T6eti,Yfm6hogh(-z7j,-CGz,aukN3ZWX))) Ucy5ca(eSCsri5,ycyK(T6eti,Yfm6hogh(z7j,-CGz,-aukN3ZWX))) Ucy5ca(eSCsri5,ycyK(T6eti,Yfm6hogh(-z7j,-CGz,-aukN3ZWX)))return eSCsri5 end function SupportLibrary.CreatePart(_g10f_)local r4cyFP if _g10f_=='Normal'then r4cyFP=Instance.new('Part')r4cyFP.Size=Vector3.new(4,1,2)elseif _g10f_=='Truss'then r4cyFP=Instance.new('TrussPart')elseif _g10f_=='Wedge'then r4cyFP=Instance.new('WedgePart') r4cyFP.Size=Vector3.new(4,1,2)elseif _g10f_=='Corner'then r4cyFP=Instance.new('CornerWedgePart')elseif _g10f_== 'Cylinder'then r4cyFP=Instance.new('Part')r4cyFP.Shape='Cylinder' r4cyFP.TopSurface=Enum.SurfaceType.Smooth
r4cyFP.BottomSurface=Enum.SurfaceType.Smooth r4cyFP.Size=Vector3.new(2,2,2)elseif _g10f_=='Ball'then r4cyFP=Instance.new('Part')r4cyFP.Shape='Ball' r4cyFP.TopSurface=Enum.SurfaceType.Smooth
r4cyFP.BottomSurface=Enum.SurfaceType.Smooth elseif _g10f_=='Seat'then r4cyFP=Instance.new('Seat')r4cyFP.Size=Vector3.new(4,1,2)elseif _g10f_=='Vehicle Seat'then r4cyFP=Instance.new('VehicleSeat')r4cyFP.Size=Vector3.new(4,1,2)elseif _g10f_=='Spawn'then r4cyFP=Instance.new('SpawnLocation')r4cyFP.Size=Vector3.new(4,1,2)end
r4cyFP.Anchored=true
return r4cyFP end function SupportLibrary.ImportServices()local fcSy4_k0=getfenv(2) fcSy4_k0.Workspace=Game:GetService'Workspace'fcSy4_k0.Players=Game:GetService'Players' fcSy4_k0.MarketplaceService=Game:GetService'MarketplaceService'fcSy4_k0.ContentProvider=Game:GetService'ContentProvider' fcSy4_k0.SoundService=Game:GetService'SoundService'fcSy4_k0.UserInputService=Game:GetService'UserInputService' fcSy4_k0.SelectionService=Game:GetService'Selection'fcSy4_k0.CoreGui=Game:GetService'CoreGui' fcSy4_k0.HttpService=Game:GetService'HttpService' fcSy4_k0.ChangeHistoryService=Game:GetService'ChangeHistoryService'fcSy4_k0.ReplicatedStorage=Game:GetService'ReplicatedStorage' fcSy4_k0.GroupService=Game:GetService'GroupService' fcSy4_k0.ServerScriptService=Game:GetService'ServerScriptService'fcSy4_k0.StarterGui=Game:GetService'StarterGui'end function SupportLibrary.GetListMembers(TrC17,MEwJPiqM)local jHIxW_={}for gny,KabKdEUu in pairs(TrC17)do table.insert(jHIxW_,KabKdEUu[MEwJPiqM])end
return jHIxW_ end function SupportLibrary.AddUserInputListener(oQ8AOvfn,m,cX88nonB,kkWQP4)local m=Enum.UserInputType[m] return Game:GetService('UserInputService')[ 'Input'..oQ8AOvfn]:connect(function(E4F,E)if E and not cX88nonB then return end if E4F.UserInputType~=m then return end if m==Enum.UserInputType.Keyboard and Game:GetService('UserInputService'):GetFocusedTextBox()then return end
kkWQP4(E4F)end)end function SupportLibrary.AddGuiInputListener(IGef7Hc5,RY1,bkV,VOG,r8MEhbdT)local bkV=Enum.UserInputType[bkV] return IGef7Hc5['Input'..RY1]:connect(function(klSf0ZT5,t85a4rt)if t85a4rt and not VOG then return end if klSf0ZT5.UserInputType~=bkV then return end
r8MEhbdT(klSf0ZT5)end)end function SupportLibrary.AreKeysPressed(...)local OfQcD=0 local Yj=SupportLibrary.GetListMembers(Game:GetService('UserInputService'):GetKeysPressed(),'KeyCode')for LvKdRh,_D in pairs({...})do if SupportLibrary.IsInTable(Yj,_D)then OfQcD=OfQcD+1 end end
return OfQcD==#{...}end function SupportLibrary.MergeTable(uYwYKAU,mq) for m7YIn,tYqOsEJ in pairs(mq)do table.insert(uYwYKAU,tYqOsEJ)end
return uYwYKAU end
function SupportLibrary.ClearTable(udoq) for boTHtaG in pairs(udoq)do udoq[boTHtaG]=nil end
return udoq end Support=SupportLibrary for zbQgT,duYPlVu in pairs(Assets)do ContentProvider:Preload(duYPlVu)end
repeat wait(0)until _G.gloo
Gloo=_G.gloo
HttpInterface={} HttpInterface.GetAsync=function(n5,zl5hfbAb) print("preforming GetAsync")local xVvJF=game:GetService('HttpService')local zsKRyBU={} ypcall(function() zsKRyBU={xVvJF:GetAsync(n5,zl5hfbAb)}end)return unpack(zsKRyBU)end HttpInterface.PostAsync=function(Lukg,rkKj,yAaxRZGY)print("preforming PostAsync") local _Tb=game:GetService('HttpService')local BJRFwSz={} ypcall(function() BJRFwSz={_Tb:PostAsync(Lukg,rkKj,yAaxRZGY)}end)return unpack(BJRFwSz)end HttpInterface.Test=function()print("preforming test") local C3MNkiZ=game:GetService('HttpService') local beAAh6T,yUaD=ypcall(function()C3MNkiZ:GetAsync'http://www.google.com'end)return beAAh6T,yUaD end
print("Begin UI")local DFb100j=nil do NG1=Instance.new("Frame") NG1.Name=dCD([=[Vagresnprf]=])NG2=Instance.new("Frame")NG2.Active=true NG2.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG2.BackgroundTransparency=1
NG2.BorderSizePixel=0 NG2.Name=dCD([=[OGZngrevnyGbbyTHV]=])NG2.Position=UDim2.new(0,0,0,172) NG2.Size=UDim2.new(0,200,0,145)NG2.Draggable=true
NG2.Parent=NG1
NG3=Instance.new("Frame") NG3.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG3.BackgroundTransparency=1
NG3.BorderSizePixel=0
NG3.Name=dCD([=[Gvgyr]=]) NG3.Size=UDim2.new(1,0,0,20)NG3.Parent=NG2
NG4=Instance.new("Frame") NG4.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG4.BorderSizePixel=0
NG4.Name=dCD([=[PbybeOne]=]) NG4.Position=UDim2.new(0,5,0,-3)NG4.Size=UDim2.new(1,-5,0,2)NG4.Parent=NG3 NG5=Instance.new("TextLabel") NG5.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG5.BackgroundTransparency=1
NG5.BorderSizePixel=0
NG5.Name=dCD([=[Ynory]=]) NG5.Position=UDim2.new(0,10,0,1)NG5.Size=UDim2.new(1,-10,1,0) NG5.Font=Enum.Font.ArialBold
NG5.FontSize=Enum.FontSize.Size10
NG5.Text=dCD([=[ZNGREVNY GBBY]=]) NG5.TextColor3=Color3.new(1,1,1)NG5.TextStrokeTransparency=0
NG5.TextWrapped=true NG5.TextXAlignment=Enum.TextXAlignment.Left
NG5.Parent=NG3
NG6=Instance.new("TextLabel") NG6.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG6.BackgroundTransparency=1
NG6.BorderSizePixel=0 NG6.Name=dCD([=[S3KFvtangher]=])NG6.Position=UDim2.new(0,10,0,1) NG6.Size=UDim2.new(1,-10,1,0)NG6.Font=Enum.Font.ArialBold NG6.FontSize=Enum.FontSize.Size14
NG6.Text=dCD([=[S3K]=])NG6.TextColor3=Color3.new(1,1,1) NG6.TextStrokeTransparency=0.89999997615814
NG6.TextWrapped=true NG6.TextXAlignment=Enum.TextXAlignment.Right
NG6.Parent=NG3
NG7=Instance.new("Frame") NG7.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG7.BackgroundTransparency=1
NG7.BorderSizePixel=0 NG7.Name=dCD([=[ZngrevnyBcgvba]=])NG7.Position=UDim2.new(0,14,0,30) NG7.Size=UDim2.new(1,-14,0,25)NG7.Parent=NG2
NG8=Instance.new("TextLabel") NG8.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG8.BackgroundTransparency=1
NG8.BorderSizePixel=0
NG8.Name=dCD([=[Ynory]=]) NG8.Size=UDim2.new(0,40,0,25)NG8.Font=Enum.Font.ArialBold NG8.FontSize=Enum.FontSize.Size10
NG8.Text=dCD([=[Zngrevny]=])NG8.TextColor3=Color3.new(1,1,1) NG8.TextStrokeTransparency=0
NG8.TextWrapped=true NG8.TextXAlignment=Enum.TextXAlignment.Left
NG8.Parent=NG7
NG9=Instance.new("Frame") NG9.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG9.BackgroundTransparency=1
NG9.BorderSizePixel=0 NG9.Name=dCD([=[GenafcneraplBcgvba]=])NG9.Position=UDim2.new(0,0,0,65) NG9.Size=UDim2.new(0,0,0,0)NG9.Parent=NG2
NG10=Instance.new("TextLabel") NG10.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG10.BackgroundTransparency=1
NG10.BorderSizePixel=0 NG10.Name=dCD([=[Ynory]=])NG10.Position=UDim2.new(0,14,0,0) NG10.Size=UDim2.new(0,70,0,25)NG10.Font=Enum.Font.ArialBold NG10.FontSize=Enum.FontSize.Size10
NG10.Text=dCD([=[Genafcnerapl]=]) NG10.TextColor3=Color3.new(1,1,1)NG10.TextStrokeTransparency=0
NG10.TextWrapped=true NG10.TextXAlignment=Enum.TextXAlignment.Left
NG10.Parent=NG9
NG11=Instance.new("Frame") NG11.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG11.BackgroundTransparency=1
NG11.BorderSizePixel=0 NG11.Name=dCD([=[GenafcneraplVachg]=])NG11.Position=UDim2.new(0,90,0,0) NG11.Size=UDim2.new(0,50,0,25)NG11.Parent=NG9
NG12=Instance.new("TextButton") NG12.Active=true
NG12.AutoButtonColor=false NG12.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG12.BackgroundTransparency=1
NG12.BorderSizePixel=0 NG12.Selectable=true
NG12.Size=UDim2.new(1,0,1,0) NG12.Style=Enum.ButtonStyle.Custom
NG12.ZIndex=2
NG12.Font=Enum.Font.Legacy NG12.FontSize=Enum.FontSize.Size8
NG12.Text=dCD([=[]=])NG12.Parent=NG11 NG13=Instance.new("ImageLabel")NG13.Active=false NG13.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG13.BackgroundTransparency=1
NG13.BorderSizePixel=0 NG13.Name=dCD([=[Onpxtebhaq]=])NG13.Selectable=false
NG13.Size=UDim2.new(1,0,1,0) NG13.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG13.Parent=NG11
NG14=Instance.new("Frame") NG14.BorderSizePixel=0
NG14.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG14.Position=UDim2.new(0,5,0,-2)NG14.Size=UDim2.new(1,-4,0,2)NG14.Parent=NG11 NG15=Instance.new("TextBox") NG15.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG15.BackgroundTransparency=1
NG15.BorderSizePixel=0 NG15.Position=UDim2.new(0,5,0,0)NG15.Size=UDim2.new(1,-10,1,0) NG15.Font=Enum.Font.ArialBold
NG15.FontSize=Enum.FontSize.Size10
NG15.Text=dCD([=[]=]) NG15.TextColor3=Color3.new(1,1,1)NG15.Parent=NG11
NG16=Instance.new("Frame") NG16.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG16.BackgroundTransparency=1
NG16.BorderSizePixel=0 NG16.Name=dCD([=[ErsyrpgnaprBcgvba]=])NG16.Position=UDim2.new(0,0,0,100) NG16.Size=UDim2.new(0,0,0,0)NG16.Parent=NG2
NG17=Instance.new("TextLabel") NG17.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG17.BackgroundTransparency=1
NG17.BorderSizePixel=0 NG17.Name=dCD([=[Ynory]=])NG17.Position=UDim2.new(0,14,0,0) NG17.Size=UDim2.new(0,70,0,25)NG17.Font=Enum.Font.ArialBold NG17.FontSize=Enum.FontSize.Size10
NG17.Text=dCD([=[Ersyrpgnapr]=])NG17.TextColor3=Color3.new(1,1,1) NG17.TextStrokeTransparency=0
NG17.TextWrapped=true NG17.TextXAlignment=Enum.TextXAlignment.Left
NG17.Parent=NG16
NG18=Instance.new("Frame") NG18.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG18.BackgroundTransparency=1
NG18.BorderSizePixel=0 NG18.Name=dCD([=[ErsyrpgnaprVachg]=])NG18.Position=UDim2.new(0,85,0,0) NG18.Size=UDim2.new(0,50,0,25)NG18.Parent=NG16
NG19=Instance.new("TextButton") NG19.Active=true
NG19.AutoButtonColor=false NG19.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG19.BackgroundTransparency=1
NG19.BorderSizePixel=0 NG19.Selectable=true
NG19.Size=UDim2.new(1,0,1,0) NG19.Style=Enum.ButtonStyle.Custom
NG19.ZIndex=2
NG19.Font=Enum.Font.Legacy NG19.FontSize=Enum.FontSize.Size8
NG19.Text=dCD([=[]=])NG19.Parent=NG18 NG20=Instance.new("Frame")NG20.BorderSizePixel=0
NG20.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG20.Position=UDim2.new(0,5,0, -2)NG20.Size=UDim2.new(1,-4,0,2) NG20.Parent=NG18
NG21=Instance.new("ImageLabel")NG21.Active=false NG21.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG21.BackgroundTransparency=1
NG21.BorderSizePixel=0 NG21.Name=dCD([=[Onpxtebhaq]=])NG21.Selectable=false
NG21.Size=UDim2.new(1,0,1,0) NG21.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG21.Parent=NG18
NG22=Instance.new("TextBox") NG22.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG22.BackgroundTransparency=1
NG22.BorderSizePixel=0 NG22.Position=UDim2.new(0,5,0,0)NG22.Size=UDim2.new(1,-10,1,0) NG22.Font=Enum.Font.ArialBold
NG22.FontSize=Enum.FontSize.Size10
NG22.Text=dCD([=[]=]) NG22.TextColor3=Color3.new(1,1,1)NG22.Parent=NG18
NG23=Instance.new("Frame") NG23.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG23.BackgroundTransparency=1
NG23.BorderSizePixel=0 NG23.Name=dCD([=[Obggbz]=])NG23.Position=UDim2.new(0,5,1,-10) NG23.Size=UDim2.new(1,-5,0,20)NG23.Parent=NG2
NG24=Instance.new("Frame") NG24.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG24.BorderSizePixel=0
NG24.Name=dCD([=[PbybeOne]=]) NG24.Size=UDim2.new(1,0,0,2)NG24.Parent=NG23
NG25=Instance.new("TextLabel") NG25.BackgroundTransparency=1
NG25.BorderSizePixel=0
NG25.Name=dCD([=[FryrpgAbgr]=]) NG25.Position=UDim2.new(0,10,0,27)NG25.Size=UDim2.new(1,-10,0,15)NG25.Visible=false NG25.FontSize=Enum.FontSize.Size14
NG25.Text=dCD([=[Fryrpg fbzrguvat gb hfr guvf gbby.]=]) NG25.TextColor3=Color3.new(1,1,1)NG25.TextScaled=true
NG25.TextStrokeTransparency=0.5 NG25.TextWrapped=true
NG25.TextXAlignment=Enum.TextXAlignment.Left
NG25.Parent=NG2 NG26=Instance.new("Frame")NG26.Active=true NG26.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG26.BackgroundTransparency=1
NG26.BorderSizePixel=0 NG26.Name=dCD([=[OGArjCnegGbbyTHV]=])NG26.Position=UDim2.new(0,0,0,280) NG26.Size=UDim2.new(0,220,0,90)NG26.Draggable=true
NG26.Parent=NG1 NG27=Instance.new("Frame") NG27.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG27.BackgroundTransparency=1
NG27.BorderSizePixel=0 NG27.Name=dCD([=[Gvgyr]=])NG27.Size=UDim2.new(1,0,0,20)NG27.Parent=NG26 NG28=Instance.new("Frame") NG28.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG28.BorderSizePixel=0
NG28.Name=dCD([=[PbybeOne]=]) NG28.Position=UDim2.new(0,5,0,-3)NG28.Size=UDim2.new(1,-5,0,2)NG28.Parent=NG27 NG29=Instance.new("TextLabel") NG29.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG29.BackgroundTransparency=1
NG29.BorderSizePixel=0 NG29.Name=dCD([=[Ynory]=])NG29.Position=UDim2.new(0,10,0,1) NG29.Size=UDim2.new(1,-10,1,0)NG29.Font=Enum.Font.ArialBold NG29.FontSize=Enum.FontSize.Size10
NG29.Text=dCD([=[ARJ CNEG GBBY]=]) NG29.TextColor3=Color3.new(1,1,1)NG29.TextStrokeTransparency=0
NG29.TextWrapped=true NG29.TextXAlignment=Enum.TextXAlignment.Left
NG29.Parent=NG27
NG30=Instance.new("TextLabel") NG30.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG30.BackgroundTransparency=1
NG30.BorderSizePixel=0 NG30.Name=dCD([=[S3KFvtangher]=])NG30.Position=UDim2.new(0,10,0,1) NG30.Size=UDim2.new(1,-10,1,0)NG30.Font=Enum.Font.ArialBold NG30.FontSize=Enum.FontSize.Size14
NG30.Text=dCD([=[S3K]=])NG30.TextColor3=Color3.new(1,1,1) NG30.TextStrokeTransparency=0.89999997615814
NG30.TextWrapped=true NG30.TextXAlignment=Enum.TextXAlignment.Right
NG30.Parent=NG27
NG31=Instance.new("Frame") NG31.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG31.BackgroundTransparency=1
NG31.BorderSizePixel=0 NG31.Name=dCD([=[GlcrBcgvba]=])NG31.Position=UDim2.new(0,0,0,30) NG31.Size=UDim2.new(0,0,0,0)NG31.Parent=NG26
NG32=Instance.new("TextLabel") NG32.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG32.BackgroundTransparency=1
NG32.BorderSizePixel=0 NG32.Name=dCD([=[Ynory]=])NG32.Position=UDim2.new(0,14,0,0) NG32.Size=UDim2.new(0,50,0,25)NG32.Font=Enum.Font.ArialBold NG32.FontSize=Enum.FontSize.Size10
NG32.Text=dCD([=[Cneg Glcr]=])NG32.TextColor3=Color3.new(1,1,1) NG32.TextStrokeTransparency=0
NG32.TextWrapped=true NG32.TextXAlignment=Enum.TextXAlignment.Left
NG32.Parent=NG31
NG33=Instance.new("Frame") NG33.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG33.BackgroundTransparency=1
NG33.BorderSizePixel=0 NG33.Name=dCD([=[Gvc]=])NG33.Position=UDim2.new(0,5,0,70) NG33.Size=UDim2.new(1,-5,0,20)NG33.Parent=NG26
NG34=Instance.new("Frame") NG34.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG34.BorderSizePixel=0
NG34.Name=dCD([=[PbybeOne]=]) NG34.Size=UDim2.new(1,0,0,2)NG34.Parent=NG33
NG35=Instance.new("TextLabel") NG35.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG35.BackgroundTransparency=1
NG35.BorderSizePixel=0 NG35.Name=dCD([=[Grkg]=])NG35.Position=UDim2.new(0,0,0,2) NG35.Size=UDim2.new(1,0,0,20)NG35.Font=Enum.Font.ArialBold NG35.FontSize=Enum.FontSize.Size10
NG35.Text=dCD([=[GVC: Cbvag naq pyvpx sbe n arj cneg.]=]) NG35.TextColor3=Color3.new(1,1,1)NG35.TextStrokeTransparency=0.5
NG35.TextWrapped=true
NG35.Parent=NG33 NG36=Instance.new("Frame")NG36.Active=true NG36.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG36.BackgroundTransparency=1
NG36.BorderSizePixel=0 NG36.Name=dCD([=[OGCnvagGbbyTHV]=])NG36.Position=UDim2.new(0,0,0,230) NG36.Size=UDim2.new(0,205,0,230)NG36.Draggable=true
NG36.Parent=NG1 NG37=Instance.new("Frame") NG37.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG37.BackgroundTransparency=1
NG37.BorderSizePixel=0 NG37.Name=dCD([=[Gvgyr]=])NG37.Size=UDim2.new(1,0,0,20)NG37.Parent=NG36 NG38=Instance.new("Frame")NG38.BackgroundColor3=Color3.new(1,0,0)NG38.BorderSizePixel=0 NG38.Name=dCD([=[PbybeOne]=])NG38.Position=UDim2.new(0,5,0,-3) NG38.Size=UDim2.new(1,-5,0,2)NG38.Parent=NG37
NG39=Instance.new("TextLabel") NG39.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG39.BackgroundTransparency=1
NG39.BorderSizePixel=0 NG39.Name=dCD([=[Ynory]=])NG39.Position=UDim2.new(0,10,0,1) NG39.Size=UDim2.new(1,-10,1,0)NG39.Font=Enum.Font.ArialBold NG39.FontSize=Enum.FontSize.Size10
NG39.Text=dCD([=[CNVAG GBBY]=])NG39.TextColor3=Color3.new(1,1,1) NG39.TextStrokeTransparency=0
NG39.TextWrapped=true NG39.TextXAlignment=Enum.TextXAlignment.Left
NG39.Parent=NG37
NG40=Instance.new("TextLabel") NG40.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG40.BackgroundTransparency=1
NG40.BorderSizePixel=0 NG40.Name=dCD([=[S3KFvtangher]=])NG40.Position=UDim2.new(0,10,0,1) NG40.Size=UDim2.new(1,-10,1,0)NG40.Font=Enum.Font.ArialBold NG40.FontSize=Enum.FontSize.Size14
NG40.Text=dCD([=[S3K]=])NG40.TextColor3=Color3.new(1,1,1) NG40.TextStrokeTransparency=0.89999997615814
NG40.TextWrapped=true NG40.TextXAlignment=Enum.TextXAlignment.Right
NG40.Parent=NG37
NG41=Instance.new("Frame") NG41.BackgroundColor3=Color3.new(0,0,0)NG41.BackgroundTransparency=1
NG41.Name=dCD([=[Cnyrggr]=]) NG41.Position=UDim2.new(0,5,0,20)NG41.Size=UDim2.new(0,205,0,205)NG41.Parent=NG36 NG42=Instance.new("TextButton")NG42.Active=true NG42.BackgroundColor3=Color3.new(0.643137,0.741176,0.278431)NG42.BorderSizePixel=0
NG42.Name=dCD([=[Oe. lryybjvfu terra]=]) NG42.Position=UDim2.new(0,5,0,5)NG42.Selectable=true
NG42.Size=UDim2.new(0,20,0,20) NG42.Style=Enum.ButtonStyle.Custom
NG42.Font=Enum.Font.Arial NG42.FontSize=Enum.FontSize.Size10
NG42.Text=dCD([=[]=])NG42.TextColor3=Color3.new(1,1,1) NG42.TextStrokeTransparency=0.75
NG42.Parent=NG41
NG43=Instance.new("TextButton") NG43.Active=true NG43.BackgroundColor3=Color3.new(0.960784,0.803922,0.188235)NG43.BorderSizePixel=0
NG43.Name=dCD([=[Oevtug lryybj]=]) NG43.Position=UDim2.new(0,30,0,5)NG43.Selectable=true
NG43.Size=UDim2.new(0,20,0,20) NG43.Style=Enum.ButtonStyle.Custom
NG43.Font=Enum.Font.Arial NG43.FontSize=Enum.FontSize.Size10
NG43.Text=dCD([=[]=])NG43.TextColor3=Color3.new(1,1,1) NG43.TextStrokeTransparency=0.75
NG43.Parent=NG41
NG44=Instance.new("TextButton") NG44.Active=true NG44.BackgroundColor3=Color3.new(0.854902,0.521569,0.254902)NG44.BorderSizePixel=0
NG44.Name=dCD([=[Oevtug benatr]=]) NG44.Position=UDim2.new(0,55,0,5)NG44.Selectable=true
NG44.Size=UDim2.new(0,20,0,20) NG44.Style=Enum.ButtonStyle.Custom
NG44.Font=Enum.Font.Arial NG44.FontSize=Enum.FontSize.Size10
NG44.Text=dCD([=[]=])NG44.TextColor3=Color3.new(1,1,1) NG44.TextStrokeTransparency=0.75
NG44.Parent=NG41
NG45=Instance.new("TextButton") NG45.Active=true NG45.BackgroundColor3=Color3.new(0.768628,0.156863,0.109804)NG45.BorderSizePixel=0
NG45.Name=dCD([=[Oevtug erq]=]) NG45.Position=UDim2.new(0,80,0,5)NG45.Selectable=true
NG45.Size=UDim2.new(0,20,0,20) NG45.Style=Enum.ButtonStyle.Custom
NG45.Font=Enum.Font.Arial NG45.FontSize=Enum.FontSize.Size10
NG45.Text=dCD([=[]=])NG45.TextColor3=Color3.new(1,1,1) NG45.TextStrokeTransparency=0.75
NG45.Parent=NG41
NG46=Instance.new("TextButton") NG46.Active=true NG46.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG46.BorderSizePixel=0
NG46.Name=dCD([=[Oevtug ivbyrg]=]) NG46.Position=UDim2.new(0,105,0,5)NG46.Selectable=true
NG46.Size=UDim2.new(0,20,0,20) NG46.Style=Enum.ButtonStyle.Custom
NG46.Font=Enum.Font.Arial NG46.FontSize=Enum.FontSize.Size10
NG46.Text=dCD([=[]=])NG46.TextColor3=Color3.new(1,1,1) NG46.TextStrokeTransparency=0.75
NG46.Parent=NG41
NG47=Instance.new("TextButton") NG47.Active=true NG47.BackgroundColor3=Color3.new(0.0509804,0.411765,0.67451)NG47.BorderSizePixel=0
NG47.Name=dCD([=[Oevtug oyhr]=]) NG47.Position=UDim2.new(0,130,0,5)NG47.Selectable=true
NG47.Size=UDim2.new(0,20,0,20) NG47.Style=Enum.ButtonStyle.Custom
NG47.Font=Enum.Font.Arial NG47.FontSize=Enum.FontSize.Size10
NG47.Text=dCD([=[]=])NG47.TextColor3=Color3.new(1,1,1) NG47.TextStrokeTransparency=0.75
NG47.Parent=NG41
NG48=Instance.new("TextButton") NG48.Active=true
NG48.BackgroundColor3=Color3.new(0,0.560784,0.611765) NG48.BorderSizePixel=0
NG48.Name=dCD([=[Oevtug oyhvfu terra]=]) NG48.Position=UDim2.new(0,155,0,5)NG48.Selectable=true
NG48.Size=UDim2.new(0,20,0,20) NG48.Style=Enum.ButtonStyle.Custom
NG48.Font=Enum.Font.Arial NG48.FontSize=Enum.FontSize.Size10
NG48.Text=dCD([=[]=])NG48.TextColor3=Color3.new(1,1,1) NG48.TextStrokeTransparency=0.75
NG48.Parent=NG41
NG49=Instance.new("TextButton") NG49.Active=true NG49.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG49.BorderSizePixel=0
NG49.Name=dCD([=[Oevtug terra]=]) NG49.Position=UDim2.new(0,180,0,5)NG49.Selectable=true
NG49.Size=UDim2.new(0,20,0,20) NG49.Style=Enum.ButtonStyle.Custom
NG49.Font=Enum.Font.Arial NG49.FontSize=Enum.FontSize.Size10
NG49.Text=dCD([=[]=])NG49.TextColor3=Color3.new(1,1,1) NG49.TextStrokeTransparency=0.75
NG49.Parent=NG41
NG50=Instance.new("TextButton") NG50.Active=true NG50.BackgroundColor3=Color3.new(0.972549,0.972549,0.972549)NG50.BorderSizePixel=0
NG50.Name=dCD([=[Vafgvghgvbany juvgr]=]) NG50.Position=UDim2.new(0,5,0,30)NG50.Selectable=true
NG50.Size=UDim2.new(0,20,0,20) NG50.Style=Enum.ButtonStyle.Custom
NG50.Font=Enum.Font.Arial NG50.FontSize=Enum.FontSize.Size10
NG50.Text=dCD([=[]=])NG50.TextColor3=Color3.new(1,1,1) NG50.TextStrokeTransparency=0.75
NG50.Parent=NG41
NG51=Instance.new("TextButton") NG51.Active=true NG51.BackgroundColor3=Color3.new(0.94902,0.952941,0.952941)NG51.BorderSizePixel=0
NG51.Name=dCD([=[Juvgr]=]) NG51.Position=UDim2.new(0,30,0,30)NG51.Selectable=true
NG51.Size=UDim2.new(0,20,0,20) NG51.Style=Enum.ButtonStyle.Custom
NG51.Font=Enum.Font.Arial NG51.FontSize=Enum.FontSize.Size10
NG51.Text=dCD([=[]=])NG51.TextColor3=Color3.new(1,1,1) NG51.TextStrokeTransparency=0.75
NG51.Parent=NG41
NG52=Instance.new("TextButton") NG52.Active=true NG52.BackgroundColor3=Color3.new(0.898039,0.894118,0.87451)NG52.BorderSizePixel=0
NG52.Name=dCD([=[Yvtug fgbar terl]=]) NG52.Position=UDim2.new(0,55,0,30)NG52.Selectable=true
NG52.Size=UDim2.new(0,20,0,20) NG52.Style=Enum.ButtonStyle.Custom
NG52.Font=Enum.Font.Arial NG52.FontSize=Enum.FontSize.Size10
NG52.Text=dCD([=[]=])NG52.TextColor3=Color3.new(1,1,1) NG52.TextStrokeTransparency=0.75
NG52.Parent=NG41
NG53=Instance.new("TextButton") NG53.Active=true NG53.BackgroundColor3=Color3.new(0.803922,0.803922,0.803922)NG53.BorderSizePixel=0
NG53.Name=dCD([=[Zvq tenl]=]) NG53.Position=UDim2.new(0,80,0,30)NG53.Selectable=true
NG53.Size=UDim2.new(0,20,0,20) NG53.Style=Enum.ButtonStyle.Custom
NG53.Font=Enum.Font.Arial NG53.FontSize=Enum.FontSize.Size10
NG53.Text=dCD([=[]=])NG53.TextColor3=Color3.new(1,1,1) NG53.TextStrokeTransparency=0.75
NG53.Parent=NG41
NG54=Instance.new("TextButton") NG54.Active=true NG54.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG54.BorderSizePixel=0
NG54.Name=dCD([=[Zrqvhz fgbar terl]=]) NG54.Position=UDim2.new(0,105,0,30)NG54.Selectable=true
NG54.Size=UDim2.new(0,20,0,20) NG54.Style=Enum.ButtonStyle.Custom
NG54.Font=Enum.Font.Arial NG54.FontSize=Enum.FontSize.Size10
NG54.Text=dCD([=[]=])NG54.TextColor3=Color3.new(1,1,1) NG54.TextStrokeTransparency=0.75
NG54.Parent=NG41
NG55=Instance.new("TextButton") NG55.Active=true NG55.BackgroundColor3=Color3.new(0.388235,0.372549,0.384314)NG55.BorderSizePixel=0
NG55.Name=dCD([=[Qnex fgbar terl]=]) NG55.Position=UDim2.new(0,130,0,30)NG55.Selectable=true
NG55.Size=UDim2.new(0,20,0,20) NG55.Style=Enum.ButtonStyle.Custom
NG55.Font=Enum.Font.Arial NG55.FontSize=Enum.FontSize.Size10
NG55.Text=dCD([=[]=])NG55.TextColor3=Color3.new(1,1,1) NG55.TextStrokeTransparency=0.75
NG55.Parent=NG41
NG56=Instance.new("TextButton") NG56.Active=true NG56.BackgroundColor3=Color3.new(0.105882,0.164706,0.207843)NG56.BorderSizePixel=0
NG56.Name=dCD([=[Oynpx]=]) NG56.Position=UDim2.new(0,155,0,30)NG56.Selectable=true
NG56.Size=UDim2.new(0,20,0,20) NG56.Style=Enum.ButtonStyle.Custom
NG56.Font=Enum.Font.Arial NG56.FontSize=Enum.FontSize.Size10
NG56.Text=dCD([=[]=])NG56.TextColor3=Color3.new(1,1,1) NG56.TextStrokeTransparency=0.75
NG56.Parent=NG41
NG57=Instance.new("TextButton") NG57.Active=true NG57.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG57.BorderSizePixel=0
NG57.Name=dCD([=[Ernyyl oynpx]=]) NG57.Position=UDim2.new(0,180,0,30)NG57.Selectable=true
NG57.Size=UDim2.new(0,20,0,20) NG57.Style=Enum.ButtonStyle.Custom
NG57.Font=Enum.Font.Arial NG57.FontSize=Enum.FontSize.Size10
NG57.Text=dCD([=[]=])NG57.TextColor3=Color3.new(1,1,1) NG57.TextStrokeTransparency=0.75
NG57.Parent=NG41
NG58=Instance.new("TextButton") NG58.Active=true NG58.BackgroundColor3=Color3.new(0.498039,0.556863,0.392157)NG58.BorderSizePixel=0
NG58.Name=dCD([=[Tevzr]=]) NG58.Position=UDim2.new(0,5,0,55)NG58.Selectable=true
NG58.Size=UDim2.new(0,20,0,20) NG58.Style=Enum.ButtonStyle.Custom
NG58.Font=Enum.Font.Arial NG58.FontSize=Enum.FontSize.Size10
NG58.Text=dCD([=[]=])NG58.TextColor3=Color3.new(1,1,1) NG58.TextStrokeTransparency=0.75
NG58.Parent=NG41
NG59=Instance.new("TextButton") NG59.Active=true NG59.BackgroundColor3=Color3.new(0.886275,0.607843,0.25098)NG59.BorderSizePixel=0
NG59.Name=dCD([=[Oe. lryybjvfu benatr]=]) NG59.Position=UDim2.new(0,30,0,55)NG59.Selectable=true
NG59.Size=UDim2.new(0,20,0,20) NG59.Style=Enum.ButtonStyle.Custom
NG59.Font=Enum.Font.Arial NG59.FontSize=Enum.FontSize.Size10
NG59.Text=dCD([=[]=])NG59.TextColor3=Color3.new(1,1,1) NG59.TextStrokeTransparency=0.75
NG59.Parent=NG41
NG60=Instance.new("TextButton") NG60.Active=true NG60.BackgroundColor3=Color3.new(0.917647,0.721569,0.572549)NG60.BorderSizePixel=0
NG60.Name=dCD([=[Yvtug benatr]=]) NG60.Position=UDim2.new(0,55,0,55)NG60.Selectable=true
NG60.Size=UDim2.new(0,20,0,20) NG60.Style=Enum.ButtonStyle.Custom
NG60.Font=Enum.Font.Arial NG60.FontSize=Enum.FontSize.Size10
NG60.Text=dCD([=[]=])NG60.TextColor3=Color3.new(1,1,1) NG60.TextStrokeTransparency=0.75
NG60.Parent=NG41
NG61=Instance.new("TextButton") NG61.Active=true NG61.BackgroundColor3=Color3.new(0.584314,0.47451,0.466667)NG61.BorderSizePixel=0
NG61.Name=dCD([=[Fnaq erq]=]) NG61.Position=UDim2.new(0,80,0,55)NG61.Selectable=true
NG61.Size=UDim2.new(0,20,0,20) NG61.Style=Enum.ButtonStyle.Custom
NG61.Font=Enum.Font.Arial NG61.FontSize=Enum.FontSize.Size10
NG61.Text=dCD([=[]=])NG61.TextColor3=Color3.new(1,1,1) NG61.TextStrokeTransparency=0.75
NG61.Parent=NG41
NG62=Instance.new("TextButton") NG62.Active=true NG62.BackgroundColor3=Color3.new(0.54902,0.356863,0.623529)NG62.BorderSizePixel=0
NG62.Name=dCD([=[Yniraqre]=]) NG62.Position=UDim2.new(0,105,0,55)NG62.Selectable=true
NG62.Size=UDim2.new(0,20,0,20) NG62.Style=Enum.ButtonStyle.Custom
NG62.Font=Enum.Font.Arial NG62.FontSize=Enum.FontSize.Size10
NG62.Text=dCD([=[]=])NG62.TextColor3=Color3.new(1,1,1) NG62.TextStrokeTransparency=0.75
NG62.Parent=NG41
NG63=Instance.new("TextButton") NG63.Active=true NG63.BackgroundColor3=Color3.new(0.454902,0.52549,0.615686)NG63.BorderSizePixel=0
NG63.Name=dCD([=[Fnaq oyhr]=]) NG63.Position=UDim2.new(0,130,0,55)NG63.Selectable=true
NG63.Size=UDim2.new(0,20,0,20) NG63.Style=Enum.ButtonStyle.Custom
NG63.Font=Enum.Font.Arial NG63.FontSize=Enum.FontSize.Size10
NG63.Text=dCD([=[]=])NG63.TextColor3=Color3.new(1,1,1) NG63.TextStrokeTransparency=0.75
NG63.Parent=NG41
NG64=Instance.new("TextButton") NG64.Active=true
NG64.BackgroundColor3=Color3.new(0.431373,0.6,0.792157) NG64.BorderSizePixel=0
NG64.Name=dCD([=[Zrqvhz oyhr]=]) NG64.Position=UDim2.new(0,155,0,55)NG64.Selectable=true
NG64.Size=UDim2.new(0,20,0,20) NG64.Style=Enum.ButtonStyle.Custom
NG64.Font=Enum.Font.Arial NG64.FontSize=Enum.FontSize.Size10
NG64.Text=dCD([=[]=])NG64.TextColor3=Color3.new(1,1,1) NG64.TextStrokeTransparency=0.75
NG64.Parent=NG41
NG65=Instance.new("TextButton") NG65.Active=true NG65.BackgroundColor3=Color3.new(0.470588,0.564706,0.509804)NG65.BorderSizePixel=0
NG65.Name=dCD([=[Fnaq terra]=]) NG65.Position=UDim2.new(0,180,0,55)NG65.Selectable=true
NG65.Size=UDim2.new(0,20,0,20) NG65.Style=Enum.ButtonStyle.Custom
NG65.Font=Enum.Font.Arial NG65.FontSize=Enum.FontSize.Size10
NG65.Text=dCD([=[]=])NG65.TextColor3=Color3.new(1,1,1) NG65.TextStrokeTransparency=0.75
NG65.Parent=NG41
NG66=Instance.new("TextButton") NG66.Active=true NG66.BackgroundColor3=Color3.new(0.843137,0.772549,0.603922)NG66.BorderSizePixel=0
NG66.Name=dCD([=[Oevpx lryybj]=]) NG66.Position=UDim2.new(0,5,0,80)NG66.Selectable=true
NG66.Size=UDim2.new(0,20,0,20) NG66.Style=Enum.ButtonStyle.Custom
NG66.Font=Enum.Font.Arial NG66.FontSize=Enum.FontSize.Size10
NG66.Text=dCD([=[]=])NG66.TextColor3=Color3.new(1,1,1) NG66.TextStrokeTransparency=0.75
NG66.Parent=NG41
NG67=Instance.new("TextButton") NG67.Active=true NG67.BackgroundColor3=Color3.new(0.992157,0.917647,0.552941)NG67.BorderSizePixel=0
NG67.Name=dCD([=[Pbby lryybj]=]) NG67.Position=UDim2.new(0,30,0,80)NG67.Selectable=true
NG67.Size=UDim2.new(0,20,0,20) NG67.Style=Enum.ButtonStyle.Custom
NG67.Font=Enum.Font.Arial NG67.FontSize=Enum.FontSize.Size10
NG67.Text=dCD([=[]=])NG67.TextColor3=Color3.new(1,1,1) NG67.TextStrokeTransparency=0.75
NG67.Parent=NG41
NG68=Instance.new("TextButton") NG68.Active=true NG68.BackgroundColor3=Color3.new(0.835294,0.45098,0.239216)NG68.BorderSizePixel=0
NG68.Name=dCD([=[Arba benatr]=]) NG68.Position=UDim2.new(0,55,0,80)NG68.Selectable=true
NG68.Size=UDim2.new(0,20,0,20) NG68.Style=Enum.ButtonStyle.Custom
NG68.Font=Enum.Font.Arial NG68.FontSize=Enum.FontSize.Size10
NG68.Text=dCD([=[]=])NG68.TextColor3=Color3.new(1,1,1) NG68.TextStrokeTransparency=0.75
NG68.Parent=NG41
NG69=Instance.new("TextButton") NG69.Active=true NG69.BackgroundColor3=Color3.new(0.854902,0.52549,0.478431)NG69.BorderSizePixel=0
NG69.Name=dCD([=[Zrqvhz erq]=]) NG69.Position=UDim2.new(0,80,0,80)NG69.Selectable=true
NG69.Size=UDim2.new(0,20,0,20) NG69.Style=Enum.ButtonStyle.Custom
NG69.Font=Enum.Font.Arial NG69.FontSize=Enum.FontSize.Size10
NG69.Text=dCD([=[]=])NG69.TextColor3=Color3.new(1,1,1) NG69.TextStrokeTransparency=0.75
NG69.Parent=NG41
NG70=Instance.new("TextButton") NG70.Active=true NG70.BackgroundColor3=Color3.new(0.909804,0.729412,0.784314)NG70.BorderSizePixel=0
NG70.Name=dCD([=[Yvtug erqqvfu ivbyrg]=]) NG70.Position=UDim2.new(0,105,0,80)NG70.Selectable=true
NG70.Size=UDim2.new(0,20,0,20) NG70.Style=Enum.ButtonStyle.Custom
NG70.Font=Enum.Font.Arial NG70.FontSize=Enum.FontSize.Size10
NG70.Text=dCD([=[]=])NG70.TextColor3=Color3.new(1,1,1) NG70.TextStrokeTransparency=0.75
NG70.Parent=NG41
NG71=Instance.new("TextButton") NG71.Active=true NG71.BackgroundColor3=Color3.new(0.501961,0.733333,0.858824)NG71.BorderSizePixel=0
NG71.Name=dCD([=[Cnfgry Oyhr]=]) NG71.Position=UDim2.new(0,130,0,80)NG71.Selectable=true
NG71.Size=UDim2.new(0,20,0,20) NG71.Style=Enum.ButtonStyle.Custom
NG71.Font=Enum.Font.Arial NG71.FontSize=Enum.FontSize.Size10
NG71.Text=dCD([=[]=])NG71.TextColor3=Color3.new(1,1,1) NG71.TextStrokeTransparency=0.75
NG71.Parent=NG41
NG72=Instance.new("TextButton") NG72.Active=true NG72.BackgroundColor3=Color3.new(0.0705882,0.933333,0.831373)NG72.BorderSizePixel=0
NG72.Name=dCD([=[Grny]=]) NG72.Position=UDim2.new(0,155,0,80)NG72.Selectable=true
NG72.Size=UDim2.new(0,20,0,20) NG72.Style=Enum.ButtonStyle.Custom
NG72.Font=Enum.Font.Arial NG72.FontSize=Enum.FontSize.Size10
NG72.Text=dCD([=[]=])NG72.TextColor3=Color3.new(1,1,1) NG72.TextStrokeTransparency=0.75
NG72.Parent=NG41
NG73=Instance.new("TextButton") NG73.Active=true NG73.BackgroundColor3=Color3.new(0.631373,0.768628,0.54902)NG73.BorderSizePixel=0
NG73.Name=dCD([=[Zrqvhz terra]=]) NG73.Position=UDim2.new(0,180,0,80)NG73.Selectable=true
NG73.Size=UDim2.new(0,20,0,20) NG73.Style=Enum.ButtonStyle.Custom
NG73.Font=Enum.Font.Arial NG73.FontSize=Enum.FontSize.Size10
NG73.Text=dCD([=[]=])NG73.TextColor3=Color3.new(1,1,1) NG73.TextStrokeTransparency=0.75
NG73.Parent=NG41
NG74=Instance.new("TextButton") NG74.Active=true
NG74.BackgroundColor3=Color3.new(1,0.8,0.6) NG74.BorderSizePixel=0
NG74.Name=dCD([=[Cnfgry oebja]=]) NG74.Position=UDim2.new(0,5,0,105)NG74.Selectable=true
NG74.Size=UDim2.new(0,20,0,20) NG74.Style=Enum.ButtonStyle.Custom
NG74.Font=Enum.Font.Arial NG74.FontSize=Enum.FontSize.Size10
NG74.Text=dCD([=[]=])NG74.TextColor3=Color3.new(1,1,1) NG74.TextStrokeTransparency=0.75
NG74.Parent=NG41
NG75=Instance.new("TextButton") NG75.Active=true
NG75.BackgroundColor3=Color3.new(1,1,0.8) NG75.BorderSizePixel=0
NG75.Name=dCD([=[Cnfgry lryybj]=]) NG75.Position=UDim2.new(0,30,0,105)NG75.Selectable=true
NG75.Size=UDim2.new(0,20,0,20) NG75.Style=Enum.ButtonStyle.Custom
NG75.Font=Enum.Font.Arial NG75.FontSize=Enum.FontSize.Size10
NG75.Text=dCD([=[]=])NG75.TextColor3=Color3.new(1,1,1) NG75.TextStrokeTransparency=0.75
NG75.Parent=NG41
NG76=Instance.new("TextButton") NG76.Active=true
NG76.BackgroundColor3=Color3.new(1,0.788235,0.788235) NG76.BorderSizePixel=0
NG76.Name=dCD([=[Cnfgry benatr]=]) NG76.Position=UDim2.new(0,55,0,105)NG76.Selectable=true
NG76.Size=UDim2.new(0,20,0,20) NG76.Style=Enum.ButtonStyle.Custom
NG76.Font=Enum.Font.Arial NG76.FontSize=Enum.FontSize.Size10
NG76.Text=dCD([=[]=])NG76.TextColor3=Color3.new(1,1,1) NG76.TextStrokeTransparency=0.75
NG76.Parent=NG41
NG77=Instance.new("TextButton") NG77.Active=true
NG77.BackgroundColor3=Color3.new(1,0.4,0.8) NG77.BorderSizePixel=0
NG77.Name=dCD([=[Cvax]=])NG77.Position=UDim2.new(0,80,0,105) NG77.Selectable=true
NG77.Size=UDim2.new(0,20,0,20) NG77.Style=Enum.ButtonStyle.Custom
NG77.Font=Enum.Font.Arial NG77.FontSize=Enum.FontSize.Size10
NG77.Text=dCD([=[]=])NG77.TextColor3=Color3.new(1,1,1) NG77.TextStrokeTransparency=0.75
NG77.Parent=NG41
NG78=Instance.new("TextButton") NG78.Active=true
NG78.BackgroundColor3=Color3.new(0.694118,0.654902,1) NG78.BorderSizePixel=0
NG78.Name=dCD([=[Cnfgry ivbyrg]=]) NG78.Position=UDim2.new(0,105,0,105)NG78.Selectable=true
NG78.Size=UDim2.new(0,20,0,20) NG78.Style=Enum.ButtonStyle.Custom
NG78.Font=Enum.Font.Arial NG78.FontSize=Enum.FontSize.Size10
NG78.Text=dCD([=[]=])NG78.TextColor3=Color3.new(1,1,1) NG78.TextStrokeTransparency=0.75
NG78.Parent=NG41
NG79=Instance.new("TextButton") NG79.Active=true
NG79.BackgroundColor3=Color3.new(0.686275,0.866667,1) NG79.BorderSizePixel=0
NG79.Name=dCD([=[Cnfgry yvtug oyhr]=]) NG79.Position=UDim2.new(0,130,0,105)NG79.Selectable=true
NG79.Size=UDim2.new(0,20,0,20) NG79.Style=Enum.ButtonStyle.Custom
NG79.Font=Enum.Font.Arial NG79.FontSize=Enum.FontSize.Size10
NG79.Text=dCD([=[]=])NG79.TextColor3=Color3.new(1,1,1) NG79.TextStrokeTransparency=0.75
NG79.Parent=NG41
NG80=Instance.new("TextButton") NG80.Active=true NG80.BackgroundColor3=Color3.new(0.623529,0.952941,0.913726)NG80.BorderSizePixel=0
NG80.Name=dCD([=[Cnfgry oyhr-terra]=]) NG80.Position=UDim2.new(0,155,0,105)NG80.Selectable=true
NG80.Size=UDim2.new(0,20,0,20) NG80.Style=Enum.ButtonStyle.Custom
NG80.Font=Enum.Font.Arial NG80.FontSize=Enum.FontSize.Size10
NG80.Text=dCD([=[]=])NG80.TextColor3=Color3.new(1,1,1) NG80.TextStrokeTransparency=0.75
NG80.Parent=NG41
NG81=Instance.new("TextButton") NG81.Active=true
NG81.BackgroundColor3=Color3.new(0.8,1,0.8) NG81.BorderSizePixel=0
NG81.Name=dCD([=[Cnfgry terra]=]) NG81.Position=UDim2.new(0,180,0,105)NG81.Selectable=true
NG81.Size=UDim2.new(0,20,0,20) NG81.Style=Enum.ButtonStyle.Custom
NG81.Font=Enum.Font.Arial NG81.FontSize=Enum.FontSize.Size10
NG81.Text=dCD([=[]=])NG81.TextColor3=Color3.new(1,1,1) NG81.TextStrokeTransparency=0.75
NG81.Parent=NG41
NG82=Instance.new("TextButton") NG82.Active=true NG82.BackgroundColor3=Color3.new(0.756863,0.745098,0.258824)NG82.BorderSizePixel=0
NG82.Name=dCD([=[Byvir]=]) NG82.Position=UDim2.new(0,5,0,130)NG82.Selectable=true
NG82.Size=UDim2.new(0,20,0,20) NG82.Style=Enum.ButtonStyle.Custom
NG82.Font=Enum.Font.Arial NG82.FontSize=Enum.FontSize.Size10
NG82.Text=dCD([=[]=])NG82.TextColor3=Color3.new(1,1,1) NG82.TextStrokeTransparency=0.75
NG82.Parent=NG41
NG83=Instance.new("TextButton") NG83.Active=true
NG83.BackgroundColor3=Color3.new(1,1,0)NG83.BorderSizePixel=0 NG83.Name=dCD([=[Arj Lryyre]=])NG83.Position=UDim2.new(0,30,0,130)NG83.Selectable=true NG83.Size=UDim2.new(0,20,0,20)NG83.Style=Enum.ButtonStyle.Custom NG83.Font=Enum.Font.Arial
NG83.FontSize=Enum.FontSize.Size10
NG83.Text=dCD([=[]=]) NG83.TextColor3=Color3.new(1,1,1)NG83.TextStrokeTransparency=0.75
NG83.Parent=NG41 NG84=Instance.new("TextButton")NG84.Active=true NG84.BackgroundColor3=Color3.new(1,0.686275,0)NG84.BorderSizePixel=0
NG84.Name=dCD([=[Qrrc benatr]=]) NG84.Position=UDim2.new(0,55,0,130)NG84.Selectable=true
NG84.Size=UDim2.new(0,20,0,20) NG84.Style=Enum.ButtonStyle.Custom
NG84.Font=Enum.Font.Arial NG84.FontSize=Enum.FontSize.Size10
NG84.Text=dCD([=[]=])NG84.TextColor3=Color3.new(1,1,1) NG84.TextStrokeTransparency=0.75
NG84.Parent=NG41
NG85=Instance.new("TextButton") NG85.Active=true
NG85.BackgroundColor3=Color3.new(1,0,0)NG85.BorderSizePixel=0 NG85.Name=dCD([=[Ernyyl erq]=])NG85.Position=UDim2.new(0,80,0,130)NG85.Selectable=true NG85.Size=UDim2.new(0,20,0,20)NG85.Style=Enum.ButtonStyle.Custom NG85.Font=Enum.Font.Arial
NG85.FontSize=Enum.FontSize.Size10
NG85.Text=dCD([=[]=]) NG85.TextColor3=Color3.new(1,1,1)NG85.TextStrokeTransparency=0.75
NG85.Parent=NG41 NG86=Instance.new("TextButton")NG86.Active=true NG86.BackgroundColor3=Color3.new(1,0,0.74902)NG86.BorderSizePixel=0
NG86.Name=dCD([=[Ubg cvax]=]) NG86.Position=UDim2.new(0,105,0,130)NG86.Selectable=true
NG86.Size=UDim2.new(0,20,0,20) NG86.Style=Enum.ButtonStyle.Custom
NG86.Font=Enum.Font.Arial NG86.FontSize=Enum.FontSize.Size10
NG86.Text=dCD([=[]=])NG86.TextColor3=Color3.new(1,1,1) NG86.TextStrokeTransparency=0.75
NG86.Parent=NG41
NG87=Instance.new("TextButton") NG87.Active=true
NG87.BackgroundColor3=Color3.new(0,0,1)NG87.BorderSizePixel=0 NG87.Name=dCD([=[Ernyyl oyhr]=])NG87.Position=UDim2.new(0,130,0,130)NG87.Selectable=true NG87.Size=UDim2.new(0,20,0,20)NG87.Style=Enum.ButtonStyle.Custom NG87.Font=Enum.Font.Arial
NG87.FontSize=Enum.FontSize.Size10
NG87.Text=dCD([=[]=]) NG87.TextColor3=Color3.new(1,1,1)NG87.TextStrokeTransparency=0.75
NG87.Parent=NG41 NG88=Instance.new("TextButton")NG88.Active=true
NG88.BackgroundColor3=Color3.new(0,1,1) NG88.BorderSizePixel=0
NG88.Name=dCD([=[Gbbgucnfgr]=]) NG88.Position=UDim2.new(0,155,0,130)NG88.Selectable=true
NG88.Size=UDim2.new(0,20,0,20) NG88.Style=Enum.ButtonStyle.Custom
NG88.Font=Enum.Font.Arial NG88.FontSize=Enum.FontSize.Size10
NG88.Text=dCD([=[]=])NG88.TextColor3=Color3.new(1,1,1) NG88.TextStrokeTransparency=0.75
NG88.Parent=NG41
NG89=Instance.new("TextButton") NG89.Active=true
NG89.BackgroundColor3=Color3.new(0,1,0)NG89.BorderSizePixel=0 NG89.Name=dCD([=[Yvzr terra]=])NG89.Position=UDim2.new(0,180,0,130)NG89.Selectable=true NG89.Size=UDim2.new(0,20,0,20)NG89.Style=Enum.ButtonStyle.Custom NG89.Font=Enum.Font.Arial
NG89.FontSize=Enum.FontSize.Size10
NG89.Text=dCD([=[]=]) NG89.TextColor3=Color3.new(1,1,1)NG89.TextStrokeTransparency=0.75
NG89.Parent=NG41 NG90=Instance.new("TextButton")NG90.Active=true NG90.BackgroundColor3=Color3.new(0.486275,0.360784,0.27451)NG90.BorderSizePixel=0
NG90.Name=dCD([=[Oebja]=]) NG90.Position=UDim2.new(0,5,0,155)NG90.Selectable=true
NG90.Size=UDim2.new(0,20,0,20) NG90.Style=Enum.ButtonStyle.Custom
NG90.Font=Enum.Font.Arial NG90.FontSize=Enum.FontSize.Size10
NG90.Text=dCD([=[]=])NG90.TextColor3=Color3.new(1,1,1) NG90.TextStrokeTransparency=0.75
NG90.Parent=NG41
NG91=Instance.new("TextButton") NG91.Active=true
NG91.BackgroundColor3=Color3.new(0.8,0.556863,0.411765) NG91.BorderSizePixel=0
NG91.Name=dCD([=[Abhtng]=])NG91.Position=UDim2.new(0,30,0,155) NG91.Selectable=true
NG91.Size=UDim2.new(0,20,0,20) NG91.Style=Enum.ButtonStyle.Custom
NG91.Font=Enum.Font.Arial NG91.FontSize=Enum.FontSize.Size10
NG91.Text=dCD([=[]=])NG91.TextColor3=Color3.new(1,1,1) NG91.TextStrokeTransparency=0.75
NG91.Parent=NG41
NG92=Instance.new("TextButton") NG92.Active=true NG92.BackgroundColor3=Color3.new(0.627451,0.372549,0.207843)NG92.BorderSizePixel=0
NG92.Name=dCD([=[Qnex benatr]=]) NG92.Position=UDim2.new(0,55,0,155)NG92.Selectable=true
NG92.Size=UDim2.new(0,20,0,20) NG92.Style=Enum.ButtonStyle.Custom
NG92.Font=Enum.Font.Arial NG92.FontSize=Enum.FontSize.Size10
NG92.Text=dCD([=[]=])NG92.TextColor3=Color3.new(1,1,1) NG92.TextStrokeTransparency=0.75
NG92.Parent=NG41
NG93=Instance.new("TextButton") NG93.Active=true NG93.BackgroundColor3=Color3.new(0.384314,0.145098,0.819608)NG93.BorderSizePixel=0
NG93.Name=dCD([=[Eblny checyr]=]) NG93.Position=UDim2.new(0,80,0,155)NG93.Selectable=true
NG93.Size=UDim2.new(0,20,0,20) NG93.Style=Enum.ButtonStyle.Custom
NG93.Font=Enum.Font.Arial NG93.FontSize=Enum.FontSize.Size10
NG93.Text=dCD([=[]=])NG93.TextColor3=Color3.new(1,1,1) NG93.TextStrokeTransparency=0.75
NG93.Parent=NG41
NG94=Instance.new("TextButton") NG94.Active=true
NG94.BackgroundColor3=Color3.new(0.705882,0.501961,1) NG94.BorderSizePixel=0
NG94.Name=dCD([=[Nyqre]=])NG94.Position=UDim2.new(0,105,0,155) NG94.Selectable=true
NG94.Size=UDim2.new(0,20,0,20) NG94.Style=Enum.ButtonStyle.Custom
NG94.Font=Enum.Font.Arial NG94.FontSize=Enum.FontSize.Size10
NG94.Text=dCD([=[]=])NG94.TextColor3=Color3.new(1,1,1) NG94.TextStrokeTransparency=0.75
NG94.Parent=NG41
NG95=Instance.new("TextButton") NG95.Active=true NG95.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG95.BorderSizePixel=0
NG95.Name=dCD([=[Plna]=]) NG95.Position=UDim2.new(0,130,0,155)NG95.Selectable=true
NG95.Size=UDim2.new(0,20,0,20) NG95.Style=Enum.ButtonStyle.Custom
NG95.Font=Enum.Font.Arial NG95.FontSize=Enum.FontSize.Size10
NG95.Text=dCD([=[]=])NG95.TextColor3=Color3.new(1,1,1) NG95.TextStrokeTransparency=0.75
NG95.Parent=NG41
NG96=Instance.new("TextButton") NG96.Active=true NG96.BackgroundColor3=Color3.new(0.705882,0.823529,0.894118)NG96.BorderSizePixel=0
NG96.Name=dCD([=[Yvtug oyhr]=]) NG96.Position=UDim2.new(0,155,0,155)NG96.Selectable=true
NG96.Size=UDim2.new(0,20,0,20) NG96.Style=Enum.ButtonStyle.Custom
NG96.Font=Enum.Font.Arial NG96.FontSize=Enum.FontSize.Size10
NG96.Text=dCD([=[]=])NG96.TextColor3=Color3.new(1,1,1) NG96.TextStrokeTransparency=0.75
NG96.Parent=NG41
NG97=Instance.new("TextButton") NG97.Active=true NG97.BackgroundColor3=Color3.new(0.227451,0.490196,0.0823529)NG97.BorderSizePixel=0
NG97.Name=dCD([=[Pnzb]=]) NG97.Position=UDim2.new(0,180,0,155)NG97.Selectable=true
NG97.Size=UDim2.new(0,20,0,20) NG97.Style=Enum.ButtonStyle.Custom
NG97.Font=Enum.Font.Arial NG97.FontSize=Enum.FontSize.Size10
NG97.Text=dCD([=[]=])NG97.TextColor3=Color3.new(1,1,1) NG97.TextStrokeTransparency=0.75
NG97.Parent=NG41
NG98=Instance.new("TextButton") NG98.Active=true NG98.BackgroundColor3=Color3.new(0.411765,0.25098,0.156863)NG98.BorderSizePixel=0
NG98.Name=dCD([=[Erqqvfu oebja]=]) NG98.Position=UDim2.new(0,5,0,180)NG98.Selectable=true
NG98.Size=UDim2.new(0,20,0,20) NG98.Style=Enum.ButtonStyle.Custom
NG98.Font=Enum.Font.Arial NG98.FontSize=Enum.FontSize.Size10
NG98.Text=dCD([=[]=])NG98.TextColor3=Color3.new(1,1,1) NG98.TextStrokeTransparency=0.75
NG98.Parent=NG41
NG99=Instance.new("TextButton") NG99.Active=true
NG99.BackgroundColor3=Color3.new(0.666667,0.333333,0) NG99.BorderSizePixel=0
NG99.Name=dCD([=[PTN oebja]=]) NG99.Position=UDim2.new(0,30,0,180)NG99.Selectable=true
NG99.Size=UDim2.new(0,20,0,20) NG99.Style=Enum.ButtonStyle.Custom
NG99.Font=Enum.Font.Arial NG99.FontSize=Enum.FontSize.Size10
NG99.Text=dCD([=[]=])NG99.TextColor3=Color3.new(1,1,1) NG99.TextStrokeTransparency=0.75
NG99.Parent=NG41
NG100=Instance.new("TextButton") NG100.Active=true NG100.BackgroundColor3=Color3.new(0.639216,0.294118,0.294118)NG100.BorderSizePixel=0
NG100.Name=dCD([=[Qhfgl Ebfr]=]) NG100.Position=UDim2.new(0,55,0,180)NG100.Selectable=true
NG100.Size=UDim2.new(0,20,0,20) NG100.Style=Enum.ButtonStyle.Custom
NG100.Font=Enum.Font.Arial NG100.FontSize=Enum.FontSize.Size10
NG100.Text=dCD([=[]=])NG100.TextColor3=Color3.new(1,1,1) NG100.TextStrokeTransparency=0.75
NG100.Parent=NG41
NG101=Instance.new("TextButton") NG101.Active=true
NG101.BackgroundColor3=Color3.new(0.666667,0,0.666667) NG101.BorderSizePixel=0
NG101.Name=dCD([=[Zntragn]=]) NG101.Position=UDim2.new(0,80,0,180)NG101.Selectable=true
NG101.Size=UDim2.new(0,20,0,20) NG101.Style=Enum.ButtonStyle.Custom
NG101.Font=Enum.Font.Arial NG101.FontSize=Enum.FontSize.Size10
NG101.Text=dCD([=[]=])NG101.TextColor3=Color3.new(1,1,1) NG101.TextStrokeTransparency=0.75
NG101.Parent=NG41
NG102=Instance.new("TextButton") NG102.Active=true NG102.BackgroundColor3=Color3.new(0.129412,0.329412,0.72549)NG102.BorderSizePixel=0
NG102.Name=dCD([=[Qrrc oyhr]=]) NG102.Position=UDim2.new(0,105,0,180)NG102.Selectable=true
NG102.Size=UDim2.new(0,20,0,20) NG102.Style=Enum.ButtonStyle.Custom
NG102.Font=Enum.Font.Arial NG102.FontSize=Enum.FontSize.Size10
NG102.Text=dCD([=[]=])NG102.TextColor3=Color3.new(1,1,1) NG102.TextStrokeTransparency=0.75
NG102.Parent=NG41
NG103=Instance.new("TextButton") NG103.Active=true
NG103.BackgroundColor3=Color3.new(0,0.12549,0.376471) NG103.BorderSizePixel=0
NG103.Name=dCD([=[Anil oyhr]=]) NG103.Position=UDim2.new(0,130,0,180)NG103.Selectable=true
NG103.Size=UDim2.new(0,20,0,20) NG103.Style=Enum.ButtonStyle.Custom
NG103.Font=Enum.Font.Arial NG103.FontSize=Enum.FontSize.Size10
NG103.Text=dCD([=[]=])NG103.TextColor3=Color3.new(1,1,1) NG103.TextStrokeTransparency=0.75
NG103.Parent=NG41
NG104=Instance.new("TextButton") NG104.Active=true NG104.BackgroundColor3=Color3.new(0.156863,0.498039,0.278431)NG104.BorderSizePixel=0
NG104.Name=dCD([=[Qnex terra]=]) NG104.Position=UDim2.new(0,155,0,180)NG104.Selectable=true
NG104.Size=UDim2.new(0,20,0,20) NG104.Style=Enum.ButtonStyle.Custom
NG104.Font=Enum.Font.Arial NG104.FontSize=Enum.FontSize.Size10
NG104.Text=dCD([=[]=])NG104.TextColor3=Color3.new(1,1,1) NG104.TextStrokeTransparency=0.75
NG104.Parent=NG41
NG105=Instance.new("TextButton") NG105.Active=true NG105.BackgroundColor3=Color3.new(0.152941,0.27451,0.176471)NG105.BorderSizePixel=0
NG105.Name=dCD([=[Rnegu terra]=]) NG105.Position=UDim2.new(0,180,0,180)NG105.Selectable=true
NG105.Size=UDim2.new(0,20,0,20) NG105.Style=Enum.ButtonStyle.Custom
NG105.Font=Enum.Font.Arial NG105.FontSize=Enum.FontSize.Size10
NG105.Text=dCD([=[]=])NG105.TextColor3=Color3.new(1,1,1) NG105.TextStrokeTransparency=0.75
NG105.Parent=NG41
NG106=Instance.new("Frame") NG106.Active=true NG106.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG106.BackgroundTransparency=1
NG106.BorderSizePixel=0 NG106.Name=dCD([=[OGZbirGbbyTHV]=])NG106.Position=UDim2.new(0,0,0,280) NG106.Size=UDim2.new(0,245,0,90)NG106.Draggable=true
NG106.Parent=NG1 NG107=Instance.new("Frame") NG107.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG107.BackgroundTransparency=1
NG107.BorderSizePixel=0 NG107.Name=dCD([=[Punatrf]=])NG107.Position=UDim2.new(0,5,0,100) NG107.Size=UDim2.new(1,-5,0,20)NG107.Parent=NG106
NG108=Instance.new("TextLabel") NG108.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG108.BackgroundTransparency=1
NG108.BorderSizePixel=0 NG108.Name=dCD([=[Grkg]=])NG108.Position=UDim2.new(0,10,0,2) NG108.Size=UDim2.new(1,-10,0,20)NG108.Font=Enum.Font.ArialBold NG108.FontSize=Enum.FontSize.Size10
NG108.Text=dCD([=[zbirq 0 fghqf]=]) NG108.TextColor3=Color3.new(1,1,1)NG108.TextStrokeTransparency=0.5
NG108.TextWrapped=true NG108.TextXAlignment=Enum.TextXAlignment.Right
NG108.Parent=NG107
NG109=Instance.new("Frame") NG109.BackgroundColor3=Color3.new(1,0.666667,0)NG109.BorderSizePixel=0
NG109.Name=dCD([=[PbybeOne]=]) NG109.Size=UDim2.new(1,0,0,2)NG109.Parent=NG107
NG110=Instance.new("Frame") NG110.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG110.BackgroundTransparency=1
NG110.BorderSizePixel=0 NG110.Name=dCD([=[Vasb]=])NG110.Position=UDim2.new(0,5,0,100) NG110.Size=UDim2.new(1,-5,0,60)NG110.Visible=false
NG110.Parent=NG106 NG111=Instance.new("Frame") NG111.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG111.BackgroundTransparency=1
NG111.BorderSizePixel=0 NG111.Name=dCD([=[Pragre]=])NG111.Position=UDim2.new(0,0,0,30) NG111.Size=UDim2.new(0,0,0,0)NG111.Parent=NG110
NG112=Instance.new("Frame") NG112.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG112.BackgroundTransparency=1
NG112.BorderSizePixel=0 NG112.Name=dCD([=[M]=])NG112.Position=UDim2.new(0,164,0,0) NG112.Size=UDim2.new(0,50,0,25)NG112.Parent=NG111
NG113=Instance.new("ImageLabel") NG113.Active=false NG113.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG113.BackgroundTransparency=1
NG113.BorderSizePixel=0 NG113.Name=dCD([=[Onpxtebhaq]=])NG113.Selectable=false
NG113.Size=UDim2.new(1,0,1,0) NG113.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG113.Parent=NG112
NG114=Instance.new("TextButton") NG114.Active=true
NG114.AutoButtonColor=false NG114.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG114.BackgroundTransparency=1
NG114.BorderSizePixel=0 NG114.Selectable=true
NG114.Size=UDim2.new(1,0,1,0) NG114.Style=Enum.ButtonStyle.Custom
NG114.ZIndex=3
NG114.Font=Enum.Font.Legacy NG114.FontSize=Enum.FontSize.Size8
NG114.Text=dCD([=[]=])NG114.Parent=NG112 NG115=Instance.new("TextBox") NG115.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG115.BackgroundTransparency=1
NG115.BorderSizePixel=0 NG115.Position=UDim2.new(0,5,0,0)NG115.Size=UDim2.new(1,-10,1,0)NG115.ZIndex=2 NG115.Font=Enum.Font.ArialBold
NG115.FontSize=Enum.FontSize.Size10
NG115.Text=dCD([=[]=]) NG115.TextColor3=Color3.new(1,1,1)NG115.Parent=NG112
NG116=Instance.new("Frame") NG116.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG116.BackgroundTransparency=1
NG116.BorderSizePixel=0 NG116.Name=dCD([=[L]=])NG116.Position=UDim2.new(0,117,0,0) NG116.Size=UDim2.new(0,50,0,25)NG116.Parent=NG111
NG117=Instance.new("TextButton") NG117.Active=true
NG117.AutoButtonColor=false NG117.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG117.BackgroundTransparency=1
NG117.BorderSizePixel=0 NG117.Selectable=true
NG117.Size=UDim2.new(1,0,1,0) NG117.Style=Enum.ButtonStyle.Custom
NG117.ZIndex=3
NG117.Font=Enum.Font.Legacy NG117.FontSize=Enum.FontSize.Size8
NG117.Text=dCD([=[]=])NG117.Parent=NG116 NG118=Instance.new("TextBox") NG118.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG118.BackgroundTransparency=1
NG118.BorderSizePixel=0 NG118.Position=UDim2.new(0,5,0,0)NG118.Size=UDim2.new(1,-10,1,0)NG118.ZIndex=2 NG118.Font=Enum.Font.ArialBold
NG118.FontSize=Enum.FontSize.Size10
NG118.Text=dCD([=[]=]) NG118.TextColor3=Color3.new(1,1,1)NG118.Parent=NG116
NG119=Instance.new("ImageLabel") NG119.Active=false NG119.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG119.BackgroundTransparency=1
NG119.BorderSizePixel=0 NG119.Name=dCD([=[Onpxtebhaq]=])NG119.Selectable=false
NG119.Size=UDim2.new(1,0,1,0) NG119.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG119.Parent=NG116
NG120=Instance.new("Frame") NG120.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG120.BackgroundTransparency=1
NG120.BorderSizePixel=0 NG120.Name=dCD([=[K]=])NG120.Position=UDim2.new(0,70,0,0) NG120.Size=UDim2.new(0,50,0,25)NG120.Parent=NG111
NG121=Instance.new("TextBox") NG121.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG121.BackgroundTransparency=1
NG121.BorderSizePixel=0 NG121.Position=UDim2.new(0,5,0,0)NG121.Size=UDim2.new(1,-10,1,0)NG121.ZIndex=2 NG121.Font=Enum.Font.ArialBold
NG121.FontSize=Enum.FontSize.Size10
NG121.Text=dCD([=[]=]) NG121.TextColor3=Color3.new(1,1,1)NG121.Parent=NG120
NG122=Instance.new("TextButton") NG122.Active=true
NG122.AutoButtonColor=false NG122.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG122.BackgroundTransparency=1
NG122.BorderSizePixel=0 NG122.Selectable=true
NG122.Size=UDim2.new(1,0,1,0) NG122.Style=Enum.ButtonStyle.Custom
NG122.ZIndex=3
NG122.Font=Enum.Font.Legacy NG122.FontSize=Enum.FontSize.Size8
NG122.Text=dCD([=[]=])NG122.Parent=NG120 NG123=Instance.new("ImageLabel")NG123.Active=false NG123.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG123.BackgroundTransparency=1
NG123.BorderSizePixel=0 NG123.Name=dCD([=[Onpxtebhaq]=])NG123.Selectable=false
NG123.Size=UDim2.new(1,0,1,0) NG123.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG123.Parent=NG120
NG124=Instance.new("TextLabel") NG124.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG124.BackgroundTransparency=1
NG124.BorderSizePixel=0 NG124.Size=UDim2.new(0,75,0,25)NG124.Font=Enum.Font.ArialBold NG124.FontSize=Enum.FontSize.Size10
NG124.Text=dCD([=[Cbfvgvba]=])NG124.TextColor3=Color3.new(1,1,1) NG124.TextStrokeTransparency=0
NG124.TextWrapped=true
NG124.Parent=NG111 NG125=Instance.new("TextLabel") NG125.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG125.BackgroundTransparency=1
NG125.BorderSizePixel=0 NG125.Name=dCD([=[Ynory]=])NG125.Position=UDim2.new(0,10,0,2) NG125.Size=UDim2.new(1,-10,0,20)NG125.Font=Enum.Font.ArialBold NG125.FontSize=Enum.FontSize.Size10
NG125.Text=dCD([=[FRYRPGVBA VASB]=]) NG125.TextColor3=Color3.new(1,1,1)NG125.TextStrokeTransparency=0
NG125.TextWrapped=true NG125.TextXAlignment=Enum.TextXAlignment.Left
NG125.Parent=NG110
NG126=Instance.new("Frame") NG126.BackgroundColor3=Color3.new(1,0.666667,0)NG126.BorderSizePixel=0
NG126.Name=dCD([=[PbybeOne]=]) NG126.Size=UDim2.new(1,0,0,2)NG126.Parent=NG110
NG127=Instance.new("Frame") NG127.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG127.BackgroundTransparency=1
NG127.BorderSizePixel=0 NG127.Name=dCD([=[VaperzragBcgvba]=])NG127.Position=UDim2.new(0,0,0,65) NG127.Size=UDim2.new(0,0,0,0)NG127.Parent=NG106
NG128=Instance.new("Frame") NG128.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG128.BackgroundTransparency=1
NG128.BorderSizePixel=0 NG128.Name=dCD([=[Ynory]=])NG128.Size=UDim2.new(0,75,0,25)NG128.Parent=NG127 NG129=Instance.new("TextLabel") NG129.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG129.BackgroundTransparency=1
NG129.BorderSizePixel=0 NG129.Size=UDim2.new(1,0,1,0)NG129.Font=Enum.Font.ArialBold NG129.FontSize=Enum.FontSize.Size10
NG129.Text=dCD([=[Vaperzrag]=]) NG129.TextColor3=Color3.new(1,1,1)NG129.TextStrokeTransparency=0
NG129.TextWrapped=true NG129.Parent=NG128
NG130=Instance.new("Frame") NG130.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG130.BackgroundTransparency=1
NG130.BorderSizePixel=0 NG130.Name=dCD([=[Vaperzrag]=])NG130.Position=UDim2.new(0,70,0,0) NG130.Size=UDim2.new(0,50,0,25)NG130.Parent=NG127
NG131=Instance.new("ImageLabel") NG131.Active=false NG131.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG131.BackgroundTransparency=1
NG131.BorderSizePixel=0 NG131.Name=dCD([=[Onpxtebhaq]=])NG131.Selectable=false
NG131.Size=UDim2.new(1,0,1,0) NG131.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG131.Parent=NG130
NG132=Instance.new("TextBox") NG132.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG132.BackgroundTransparency=1
NG132.BorderSizePixel=0 NG132.Position=UDim2.new(0,5,0,0)NG132.Size=UDim2.new(1,-10,1,0)NG132.ZIndex=2 NG132.Font=Enum.Font.ArialBold
NG132.FontSize=Enum.FontSize.Size10
NG132.Text=dCD([=[1]=]) NG132.TextColor3=Color3.new(1,1,1)NG132.Parent=NG130
NG133=Instance.new("Frame") NG133.BorderSizePixel=0
NG133.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG133.Position=UDim2.new(0,5,0,-2)NG133.Size=UDim2.new(1,-4,0,2)NG133.Parent=NG130 NG134=Instance.new("Frame") NG134.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG134.BackgroundTransparency=1
NG134.BorderSizePixel=0 NG134.Name=dCD([=[Gvgyr]=])NG134.Size=UDim2.new(1,0,0,20)NG134.Parent=NG106 NG135=Instance.new("TextLabel") NG135.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG135.BackgroundTransparency=1
NG135.BorderSizePixel=0 NG135.Name=dCD([=[S3KFvtangher]=])NG135.Position=UDim2.new(0,10,0,1) NG135.Size=UDim2.new(1,-10,1,0)NG135.Font=Enum.Font.ArialBold NG135.FontSize=Enum.FontSize.Size14
NG135.Text=dCD([=[S3K]=])NG135.TextColor3=Color3.new(1,1,1) NG135.TextStrokeTransparency=0.89999997615814
NG135.TextWrapped=true NG135.TextXAlignment=Enum.TextXAlignment.Right
NG135.Parent=NG134
NG136=Instance.new("TextLabel") NG136.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG136.BackgroundTransparency=1
NG136.BorderSizePixel=0 NG136.Name=dCD([=[Ynory]=])NG136.Position=UDim2.new(0,10,0,1) NG136.Size=UDim2.new(1,-10,1,0)NG136.Font=Enum.Font.ArialBold NG136.FontSize=Enum.FontSize.Size10
NG136.Text=dCD([=[ZBIR GBBY]=]) NG136.TextColor3=Color3.new(1,1,1)NG136.TextStrokeTransparency=0
NG136.TextWrapped=true NG136.TextXAlignment=Enum.TextXAlignment.Left
NG136.Parent=NG134
NG137=Instance.new("Frame") NG137.BackgroundColor3=Color3.new(1,0.666667,0)NG137.BorderSizePixel=0
NG137.Name=dCD([=[PbybeOne]=]) NG137.Position=UDim2.new(0,5,0,-3)NG137.Size=UDim2.new(1,-5,0,2)NG137.Parent=NG134 NG138=Instance.new("Frame") NG138.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG138.BackgroundTransparency=1
NG138.BorderSizePixel=0 NG138.Name=dCD([=[NkrfBcgvba]=])NG138.Position=UDim2.new(0,0,0,30) NG138.Size=UDim2.new(0,0,0,0)NG138.Parent=NG106
NG139=Instance.new("Frame") NG139.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG139.BackgroundTransparency=1
NG139.BorderSizePixel=0 NG139.Name=dCD([=[Ynory]=])NG139.Size=UDim2.new(0,50,0,25)NG139.Parent=NG138 NG140=Instance.new("TextLabel") NG140.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG140.BackgroundTransparency=1
NG140.BorderSizePixel=0 NG140.Size=UDim2.new(1,0,1,0)NG140.Font=Enum.Font.ArialBold NG140.FontSize=Enum.FontSize.Size10
NG140.Text=dCD([=[Nkrf]=])NG140.TextColor3=Color3.new(1,1,1) NG140.TextStrokeTransparency=0
NG140.TextWrapped=true
NG140.Parent=NG139 NG141=Instance.new("Frame") NG141.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG141.BackgroundTransparency=1
NG141.BorderSizePixel=0 NG141.Name=dCD([=[Ynfg]=])NG141.Position=UDim2.new(0,175,0,0) NG141.Size=UDim2.new(0,70,0,25)NG141.Parent=NG138
NG142=Instance.new("TextLabel") NG142.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG142.BackgroundTransparency=1
NG142.BorderSizePixel=0 NG142.Name=dCD([=[Ynory]=])NG142.Size=UDim2.new(1,0,1,0)NG142.ZIndex=2 NG142.Font=Enum.Font.ArialBold
NG142.FontSize=Enum.FontSize.Size10
NG142.Text=dCD([=[YNFG]=]) NG142.TextColor3=Color3.new(1,1,1)NG142.Parent=NG141
NG143=Instance.new("ImageLabel") NG143.Active=false NG143.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG143.BackgroundTransparency=1
NG143.BorderSizePixel=0 NG143.Name=dCD([=[Onpxtebhaq]=])NG143.Selectable=false
NG143.Size=UDim2.new(1,0,1,0) NG143.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG143.Parent=NG141
NG144=Instance.new("TextButton") NG144.Active=true NG144.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG144.BackgroundTransparency=1
NG144.BorderSizePixel=0 NG144.Name=dCD([=[Ohggba]=])NG144.Position=UDim2.new(0,5,0,0)NG144.Selectable=true
NG144.Size=UDim2.new(1, -10,1,0) NG144.Style=Enum.ButtonStyle.Custom
NG144.ZIndex=2
NG144.Font=Enum.Font.Legacy NG144.FontSize=Enum.FontSize.Size8
NG144.Text=dCD([=[]=])NG144.TextTransparency=1
NG144.Parent=NG141 NG145=Instance.new("Frame")NG145.BackgroundTransparency=1
NG145.BorderSizePixel=0 NG145.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG145.Position=UDim2.new(0,6,0,-2) NG145.Size=UDim2.new(1,-5,0,2)NG145.Parent=NG141
NG146=Instance.new("Frame") NG146.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG146.BackgroundTransparency=1
NG146.BorderSizePixel=0 NG146.Name=dCD([=[Ybpny]=])NG146.Position=UDim2.new(0,110,0,0) NG146.Size=UDim2.new(0,70,0,25)NG146.Parent=NG138
NG147=Instance.new("TextLabel") NG147.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG147.BackgroundTransparency=1
NG147.BorderSizePixel=0 NG147.Name=dCD([=[Ynory]=])NG147.Size=UDim2.new(1,0,1,0)NG147.ZIndex=2 NG147.Font=Enum.Font.ArialBold
NG147.FontSize=Enum.FontSize.Size10
NG147.Text=dCD([=[YBPNY]=]) NG147.TextColor3=Color3.new(1,1,1)NG147.Parent=NG146
NG148=Instance.new("ImageLabel") NG148.Active=false NG148.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG148.BackgroundTransparency=1
NG148.BorderSizePixel=0 NG148.Name=dCD([=[Onpxtebhaq]=])NG148.Selectable=false
NG148.Size=UDim2.new(1,0,1,0) NG148.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG148.Parent=NG146
NG149=Instance.new("TextButton") NG149.Active=true NG149.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG149.BackgroundTransparency=1
NG149.BorderSizePixel=0 NG149.Name=dCD([=[Ohggba]=])NG149.Position=UDim2.new(0,5,0,0)NG149.Selectable=true
NG149.Size=UDim2.new(1, -10,1,0) NG149.Style=Enum.ButtonStyle.Custom
NG149.ZIndex=2
NG149.Font=Enum.Font.Legacy NG149.FontSize=Enum.FontSize.Size8
NG149.Text=dCD([=[]=])NG149.TextTransparency=1
NG149.Parent=NG146 NG150=Instance.new("Frame")NG150.BackgroundTransparency=1
NG150.BorderSizePixel=0 NG150.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG150.Position=UDim2.new(0,6,0,-2) NG150.Size=UDim2.new(1,-5,0,2)NG150.Parent=NG146
NG151=Instance.new("Frame") NG151.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG151.BackgroundTransparency=1
NG151.BorderSizePixel=0 NG151.Name=dCD([=[Tybony]=])NG151.Position=UDim2.new(0,45,0,0) NG151.Size=UDim2.new(0,70,0,25)NG151.Parent=NG138
NG152=Instance.new("TextLabel") NG152.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG152.BackgroundTransparency=1
NG152.BorderSizePixel=0 NG152.Name=dCD([=[Ynory]=])NG152.Size=UDim2.new(1,0,1,0)NG152.ZIndex=2 NG152.Font=Enum.Font.ArialBold
NG152.FontSize=Enum.FontSize.Size10
NG152.Text=dCD([=[TYBONY]=]) NG152.TextColor3=Color3.new(1,1,1)NG152.Parent=NG151
NG153=Instance.new("ImageLabel") NG153.Active=false NG153.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG153.BackgroundTransparency=1
NG153.BorderSizePixel=0 NG153.Name=dCD([=[Onpxtebhaq]=])NG153.Selectable=false
NG153.Size=UDim2.new(1,0,1,0) NG153.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127774197]=])NG153.Parent=NG151
NG154=Instance.new("TextButton") NG154.Active=true NG154.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG154.BackgroundTransparency=1
NG154.BorderSizePixel=0 NG154.Name=dCD([=[Ohggba]=])NG154.Position=UDim2.new(0,5,0,0)NG154.Selectable=true
NG154.Size=UDim2.new(1, -10,1,0) NG154.Style=Enum.ButtonStyle.Custom
NG154.ZIndex=2
NG154.Font=Enum.Font.Legacy NG154.FontSize=Enum.FontSize.Size8
NG154.Text=dCD([=[]=])NG154.TextTransparency=1
NG154.Parent=NG151 NG155=Instance.new("Frame")NG155.BorderSizePixel=0
NG155.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG155.Position=UDim2.new(0,6,0, -2)NG155.Size=UDim2.new(1,-5,0,2) NG155.Parent=NG151
NG156=Instance.new("Frame")NG156.Active=true NG156.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG156.BackgroundTransparency=1
NG156.BorderSizePixel=0 NG156.Name=dCD([=[OGErfvmrGbbyTHV]=])NG156.Position=UDim2.new(0,0,0,280) NG156.Size=UDim2.new(0,245,0,90)NG156.Draggable=true
NG156.Parent=NG1 NG157=Instance.new("Frame") NG157.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG157.BackgroundTransparency=1
NG157.BorderSizePixel=0 NG157.Name=dCD([=[QverpgvbafBcgvba]=])NG157.Position=UDim2.new(0,0,0,30) NG157.Size=UDim2.new(0,0,0,0)NG157.Parent=NG156
NG158=Instance.new("Frame") NG158.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG158.BackgroundTransparency=1
NG158.BorderSizePixel=0 NG158.Name=dCD([=[Abezny]=])NG158.Position=UDim2.new(0,70,0,0) NG158.Size=UDim2.new(0,70,0,25)NG158.Parent=NG157
NG159=Instance.new("Frame") NG159.BorderSizePixel=0
NG159.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG159.Position=UDim2.new(0,6,0,-2)NG159.Size=UDim2.new(1,-5,0,2)NG159.Parent=NG158 NG160=Instance.new("TextButton")NG160.Active=true NG160.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG160.BackgroundTransparency=1
NG160.BorderSizePixel=0 NG160.Name=dCD([=[Ohggba]=])NG160.Position=UDim2.new(0,5,0,0)NG160.Selectable=true
NG160.Size=UDim2.new(1, -10,1,0) NG160.Style=Enum.ButtonStyle.Custom
NG160.ZIndex=2
NG160.Font=Enum.Font.Legacy NG160.FontSize=Enum.FontSize.Size8
NG160.Text=dCD([=[]=])NG160.TextTransparency=1
NG160.Parent=NG158 NG161=Instance.new("ImageLabel")NG161.Active=false NG161.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG161.BackgroundTransparency=1
NG161.BorderSizePixel=0 NG161.Name=dCD([=[Onpxtebhaq]=])NG161.Selectable=false
NG161.Size=UDim2.new(1,0,1,0) NG161.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127774197]=])NG161.Parent=NG158
NG162=Instance.new("TextLabel") NG162.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG162.BackgroundTransparency=1
NG162.BorderSizePixel=0 NG162.Name=dCD([=[Ynory]=])NG162.Size=UDim2.new(1,0,1,0) NG162.Font=Enum.Font.ArialBold
NG162.FontSize=Enum.FontSize.Size10
NG162.Text=dCD([=[ABEZNY]=]) NG162.TextColor3=Color3.new(1,1,1)NG162.Parent=NG158
NG163=Instance.new("Frame") NG163.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG163.BackgroundTransparency=1
NG163.BorderSizePixel=0 NG163.Name=dCD([=[Obgu]=])NG163.Position=UDim2.new(0,135,0,0) NG163.Size=UDim2.new(0,70,0,25)NG163.Parent=NG157
NG164=Instance.new("Frame") NG164.BackgroundTransparency=1
NG164.BorderSizePixel=0
NG164.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG164.Position=UDim2.new(0,6,0, -2)NG164.Size=UDim2.new(1,-5,0,2) NG164.Parent=NG163
NG165=Instance.new("TextButton")NG165.Active=true NG165.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG165.BackgroundTransparency=1
NG165.BorderSizePixel=0 NG165.Name=dCD([=[Ohggba]=])NG165.Position=UDim2.new(0,5,0,0)NG165.Selectable=true
NG165.Size=UDim2.new(1, -10,1,0) NG165.Style=Enum.ButtonStyle.Custom
NG165.ZIndex=2
NG165.Font=Enum.Font.Legacy NG165.FontSize=Enum.FontSize.Size8
NG165.Text=dCD([=[]=])NG165.TextTransparency=1
NG165.Parent=NG163 NG166=Instance.new("ImageLabel")NG166.Active=false NG166.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG166.BackgroundTransparency=1
NG166.BorderSizePixel=0 NG166.Name=dCD([=[Onpxtebhaq]=])NG166.Selectable=false
NG166.Size=UDim2.new(1,0,1,0) NG166.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG166.Parent=NG163
NG167=Instance.new("TextLabel") NG167.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG167.BackgroundTransparency=1
NG167.BorderSizePixel=0 NG167.Name=dCD([=[Ynory]=])NG167.Size=UDim2.new(1,0,1,0) NG167.Font=Enum.Font.ArialBold
NG167.FontSize=Enum.FontSize.Size10
NG167.Text=dCD([=[OBGU]=]) NG167.TextColor3=Color3.new(1,1,1)NG167.Parent=NG163
NG168=Instance.new("Frame") NG168.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG168.BackgroundTransparency=1
NG168.BorderSizePixel=0 NG168.Name=dCD([=[Ynory]=])NG168.Size=UDim2.new(0,75,0,25)NG168.Parent=NG157 NG169=Instance.new("TextLabel") NG169.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG169.BackgroundTransparency=1
NG169.BorderSizePixel=0 NG169.Size=UDim2.new(1,0,1,0)NG169.Font=Enum.Font.ArialBold NG169.FontSize=Enum.FontSize.Size10
NG169.Text=dCD([=[Qverpgvbaf]=]) NG169.TextColor3=Color3.new(1,1,1)NG169.TextStrokeTransparency=0
NG169.TextWrapped=true NG169.Parent=NG168
NG170=Instance.new("Frame") NG170.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG170.BackgroundTransparency=1
NG170.BorderSizePixel=0 NG170.Name=dCD([=[Gvgyr]=])NG170.Size=UDim2.new(1,0,0,20)NG170.Parent=NG156 NG171=Instance.new("Frame") NG171.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG171.BorderSizePixel=0
NG171.Name=dCD([=[PbybeOne]=]) NG171.Position=UDim2.new(0,5,0,-3)NG171.Size=UDim2.new(1,-5,0,2)NG171.Parent=NG170 NG172=Instance.new("TextLabel") NG172.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG172.BackgroundTransparency=1
NG172.BorderSizePixel=0 NG172.Name=dCD([=[Ynory]=])NG172.Position=UDim2.new(0,10,0,1) NG172.Size=UDim2.new(1,-10,1,0)NG172.Font=Enum.Font.ArialBold NG172.FontSize=Enum.FontSize.Size10
NG172.Text=dCD([=[ERFVMR GBBY]=]) NG172.TextColor3=Color3.new(1,1,1)NG172.TextStrokeTransparency=0
NG172.TextWrapped=true NG172.TextXAlignment=Enum.TextXAlignment.Left
NG172.Parent=NG170
NG173=Instance.new("TextLabel") NG173.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG173.BackgroundTransparency=1
NG173.BorderSizePixel=0 NG173.Name=dCD([=[S3KFvtangher]=])NG173.Position=UDim2.new(0,10,0,1) NG173.Size=UDim2.new(1,-10,1,0)NG173.Font=Enum.Font.ArialBold NG173.FontSize=Enum.FontSize.Size14
NG173.Text=dCD([=[S3K]=])NG173.TextColor3=Color3.new(1,1,1) NG173.TextStrokeTransparency=0.89999997615814
NG173.TextWrapped=true NG173.TextXAlignment=Enum.TextXAlignment.Right
NG173.Parent=NG170
NG174=Instance.new("Frame") NG174.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG174.BackgroundTransparency=1
NG174.BorderSizePixel=0 NG174.Name=dCD([=[VaperzragBcgvba]=])NG174.Position=UDim2.new(0,0,0,65) NG174.Size=UDim2.new(0,0,0,0)NG174.Parent=NG156
NG175=Instance.new("Frame") NG175.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG175.BackgroundTransparency=1
NG175.BorderSizePixel=0 NG175.Name=dCD([=[Vaperzrag]=])NG175.Position=UDim2.new(0,70,0,0) NG175.Size=UDim2.new(0,50,0,25)NG175.Parent=NG174
NG176=Instance.new("Frame") NG176.BorderSizePixel=0
NG176.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG176.Position=UDim2.new(0,5,0,-2)NG176.Size=UDim2.new(1,-4,0,2)NG176.Parent=NG175 NG177=Instance.new("TextBox") NG177.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG177.BackgroundTransparency=1
NG177.BorderSizePixel=0 NG177.Position=UDim2.new(0,5,0,0)NG177.Size=UDim2.new(1,-10,1,0)NG177.ZIndex=2 NG177.Font=Enum.Font.ArialBold
NG177.FontSize=Enum.FontSize.Size10
NG177.Text=dCD([=[1]=]) NG177.TextColor3=Color3.new(1,1,1)NG177.Parent=NG175
NG178=Instance.new("ImageLabel") NG178.Active=false NG178.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG178.BackgroundTransparency=1
NG178.BorderSizePixel=0 NG178.Name=dCD([=[Onpxtebhaq]=])NG178.Selectable=false
NG178.Size=UDim2.new(1,0,1,0) NG178.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG178.Parent=NG175
NG179=Instance.new("Frame") NG179.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG179.BackgroundTransparency=1
NG179.BorderSizePixel=0 NG179.Name=dCD([=[Ynory]=])NG179.Size=UDim2.new(0,75,0,25)NG179.Parent=NG174 NG180=Instance.new("TextLabel") NG180.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG180.BackgroundTransparency=1
NG180.BorderSizePixel=0 NG180.Size=UDim2.new(1,0,1,0)NG180.Font=Enum.Font.ArialBold NG180.FontSize=Enum.FontSize.Size10
NG180.Text=dCD([=[Vaperzrag]=]) NG180.TextColor3=Color3.new(1,1,1)NG180.TextStrokeTransparency=0
NG180.TextWrapped=true NG180.Parent=NG179
NG181=Instance.new("Frame") NG181.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG181.BackgroundTransparency=1
NG181.BorderSizePixel=0 NG181.Name=dCD([=[Vasb]=])NG181.Position=UDim2.new(0,5,0,100) NG181.Size=UDim2.new(1,-5,0,60)NG181.Visible=false
NG181.Parent=NG156 NG182=Instance.new("Frame") NG182.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG182.BorderSizePixel=0
NG182.Name=dCD([=[PbybeOne]=]) NG182.Size=UDim2.new(1,0,0,2)NG182.Parent=NG181
NG183=Instance.new("TextLabel") NG183.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG183.BackgroundTransparency=1
NG183.BorderSizePixel=0 NG183.Name=dCD([=[Ynory]=])NG183.Position=UDim2.new(0,10,0,2) NG183.Size=UDim2.new(1,-10,0,20)NG183.Font=Enum.Font.ArialBold NG183.FontSize=Enum.FontSize.Size10
NG183.Text=dCD([=[FRYRPGVBA VASB]=]) NG183.TextColor3=Color3.new(1,1,1)NG183.TextStrokeTransparency=0
NG183.TextWrapped=true NG183.TextXAlignment=Enum.TextXAlignment.Left
NG183.Parent=NG181
NG184=Instance.new("Frame") NG184.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG184.BackgroundTransparency=1
NG184.BorderSizePixel=0 NG184.Name=dCD([=[FvmrVasb]=])NG184.Position=UDim2.new(0,0,0,30) NG184.Size=UDim2.new(0,0,0,0)NG184.Parent=NG181
NG185=Instance.new("TextLabel") NG185.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG185.BackgroundTransparency=1
NG185.BorderSizePixel=0 NG185.Size=UDim2.new(0,75,0,25)NG185.Font=Enum.Font.ArialBold NG185.FontSize=Enum.FontSize.Size10
NG185.Text=dCD([=[Fvmr]=])NG185.TextColor3=Color3.new(1,1,1) NG185.TextStrokeTransparency=0
NG185.TextWrapped=true
NG185.Parent=NG184 NG186=Instance.new("Frame") NG186.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG186.BackgroundTransparency=1
NG186.BorderSizePixel=0 NG186.Name=dCD([=[K]=])NG186.Position=UDim2.new(0,70,0,0) NG186.Size=UDim2.new(0,50,0,25)NG186.Parent=NG184
NG187=Instance.new("TextBox") NG187.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG187.BackgroundTransparency=1
NG187.BorderSizePixel=0 NG187.Position=UDim2.new(0,5,0,0)NG187.Size=UDim2.new(1,-10,1,0)NG187.ZIndex=2 NG187.Font=Enum.Font.ArialBold
NG187.FontSize=Enum.FontSize.Size10
NG187.Text=dCD([=[]=]) NG187.TextColor3=Color3.new(1,1,1)NG187.Parent=NG186
NG188=Instance.new("TextButton") NG188.Active=true
NG188.AutoButtonColor=false NG188.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG188.BackgroundTransparency=1
NG188.BorderSizePixel=0 NG188.Selectable=true
NG188.Size=UDim2.new(1,0,1,0) NG188.Style=Enum.ButtonStyle.Custom
NG188.ZIndex=3
NG188.Font=Enum.Font.Legacy NG188.FontSize=Enum.FontSize.Size8
NG188.Text=dCD([=[]=])NG188.Parent=NG186 NG189=Instance.new("ImageLabel")NG189.Active=false NG189.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG189.BackgroundTransparency=1
NG189.BorderSizePixel=0 NG189.Name=dCD([=[Onpxtebhaq]=])NG189.Selectable=false
NG189.Size=UDim2.new(1,0,1,0) NG189.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG189.Parent=NG186
NG190=Instance.new("Frame") NG190.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG190.BackgroundTransparency=1
NG190.BorderSizePixel=0 NG190.Name=dCD([=[L]=])NG190.Position=UDim2.new(0,117,0,0) NG190.Size=UDim2.new(0,50,0,25)NG190.Parent=NG184
NG191=Instance.new("TextBox") NG191.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG191.BackgroundTransparency=1
NG191.BorderSizePixel=0 NG191.Position=UDim2.new(0,5,0,0)NG191.Size=UDim2.new(1,-10,1,0)NG191.ZIndex=2 NG191.Font=Enum.Font.ArialBold
NG191.FontSize=Enum.FontSize.Size10
NG191.Text=dCD([=[]=]) NG191.TextColor3=Color3.new(1,1,1)NG191.Parent=NG190
NG192=Instance.new("TextButton") NG192.Active=true
NG192.AutoButtonColor=false NG192.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG192.BackgroundTransparency=1
NG192.BorderSizePixel=0 NG192.Selectable=true
NG192.Size=UDim2.new(1,0,1,0) NG192.Style=Enum.ButtonStyle.Custom
NG192.ZIndex=3
NG192.Font=Enum.Font.Legacy NG192.FontSize=Enum.FontSize.Size8
NG192.Text=dCD([=[]=])NG192.Parent=NG190 NG193=Instance.new("ImageLabel")NG193.Active=false NG193.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG193.BackgroundTransparency=1
NG193.BorderSizePixel=0 NG193.Name=dCD([=[Onpxtebhaq]=])NG193.Selectable=false
NG193.Size=UDim2.new(1,0,1,0) NG193.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG193.Parent=NG190
NG194=Instance.new("Frame") NG194.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG194.BackgroundTransparency=1
NG194.BorderSizePixel=0 NG194.Name=dCD([=[M]=])NG194.Position=UDim2.new(0,164,0,0) NG194.Size=UDim2.new(0,50,0,25)NG194.Parent=NG184
NG195=Instance.new("TextBox") NG195.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG195.BackgroundTransparency=1
NG195.BorderSizePixel=0 NG195.Position=UDim2.new(0,5,0,0)NG195.Size=UDim2.new(1,-10,1,0)NG195.ZIndex=2 NG195.Font=Enum.Font.ArialBold
NG195.FontSize=Enum.FontSize.Size10
NG195.Text=dCD([=[]=]) NG195.TextColor3=Color3.new(1,1,1)NG195.Parent=NG194
NG196=Instance.new("TextButton") NG196.Active=true
NG196.AutoButtonColor=false NG196.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG196.BackgroundTransparency=1
NG196.BorderSizePixel=0 NG196.Selectable=true
NG196.Size=UDim2.new(1,0,1,0) NG196.Style=Enum.ButtonStyle.Custom
NG196.ZIndex=3
NG196.Font=Enum.Font.Legacy NG196.FontSize=Enum.FontSize.Size8
NG196.Text=dCD([=[]=])NG196.Parent=NG194 NG197=Instance.new("ImageLabel")NG197.Active=false NG197.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG197.BackgroundTransparency=1
NG197.BorderSizePixel=0 NG197.Name=dCD([=[Onpxtebhaq]=])NG197.Selectable=false
NG197.Size=UDim2.new(1,0,1,0) NG197.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG197.Parent=NG194
NG198=Instance.new("Frame") NG198.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG198.BackgroundTransparency=1
NG198.BorderSizePixel=0 NG198.Name=dCD([=[Punatrf]=])NG198.Position=UDim2.new(0,5,0,100) NG198.Size=UDim2.new(1,-5,0,20)NG198.Parent=NG156
NG199=Instance.new("Frame") NG199.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG199.BorderSizePixel=0
NG199.Name=dCD([=[PbybeOne]=]) NG199.Size=UDim2.new(1,0,0,2)NG199.Parent=NG198
NG200=Instance.new("TextLabel") NG200.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG200.BackgroundTransparency=1
NG200.BorderSizePixel=0 NG200.Name=dCD([=[Grkg]=])NG200.Position=UDim2.new(0,10,0,2) NG200.Size=UDim2.new(1,-10,0,20)NG200.Font=Enum.Font.ArialBold NG200.FontSize=Enum.FontSize.Size10
NG200.Text=dCD([=[erfvmrq 0 fghqf]=]) NG200.TextColor3=Color3.new(1,1,1)NG200.TextStrokeTransparency=0.5
NG200.TextWrapped=true NG200.TextXAlignment=Enum.TextXAlignment.Right
NG200.Parent=NG198
NG201=Instance.new("Frame") NG201.Active=true NG201.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG201.BackgroundTransparency=1
NG201.BorderSizePixel=0 NG201.Name=dCD([=[OGFhesnprGbbyTHV]=])NG201.Position=UDim2.new(0,0,0,172) NG201.Size=UDim2.new(0,245,0,90)NG201.Draggable=true
NG201.Parent=NG1 NG202=Instance.new("Frame") NG202.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG202.BackgroundTransparency=1
NG202.BorderSizePixel=0 NG202.Name=dCD([=[Gvgyr]=])NG202.Size=UDim2.new(1,0,0,20)NG202.Parent=NG201 NG203=Instance.new("Frame") NG203.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG203.BorderSizePixel=0
NG203.Name=dCD([=[PbybeOne]=]) NG203.Position=UDim2.new(0,5,0,-3)NG203.Size=UDim2.new(1,-5,0,2)NG203.Parent=NG202 NG204=Instance.new("TextLabel") NG204.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG204.BackgroundTransparency=1
NG204.BorderSizePixel=0 NG204.Name=dCD([=[Ynory]=])NG204.Position=UDim2.new(0,10,0,1) NG204.Size=UDim2.new(1,-10,1,0)NG204.Font=Enum.Font.ArialBold NG204.FontSize=Enum.FontSize.Size10
NG204.Text=dCD([=[FHESNPR GBBY]=]) NG204.TextColor3=Color3.new(1,1,1)NG204.TextStrokeTransparency=0
NG204.TextWrapped=true NG204.TextXAlignment=Enum.TextXAlignment.Left
NG204.Parent=NG202
NG205=Instance.new("TextLabel") NG205.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG205.BackgroundTransparency=1
NG205.BorderSizePixel=0 NG205.Name=dCD([=[S3KFvtangher]=])NG205.Position=UDim2.new(0,10,0,1) NG205.Size=UDim2.new(1,-10,1,0)NG205.Font=Enum.Font.ArialBold NG205.FontSize=Enum.FontSize.Size14
NG205.Text=dCD([=[S3K]=])NG205.TextColor3=Color3.new(1,1,1) NG205.TextStrokeTransparency=0.89999997615814
NG205.TextWrapped=true NG205.TextXAlignment=Enum.TextXAlignment.Right
NG205.Parent=NG202
NG206=Instance.new("Frame") NG206.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG206.BackgroundTransparency=1
NG206.BorderSizePixel=0 NG206.Name=dCD([=[FvqrBcgvba]=])NG206.Position=UDim2.new(0,14,0,30) NG206.Size=UDim2.new(0,120,0,25)NG206.Parent=NG201
NG207=Instance.new("TextLabel") NG207.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG207.BackgroundTransparency=1
NG207.BorderSizePixel=0 NG207.Name=dCD([=[Ynory]=])NG207.Size=UDim2.new(0,40,0,25) NG207.Font=Enum.Font.ArialBold
NG207.FontSize=Enum.FontSize.Size10
NG207.Text=dCD([=[Fvqr]=]) NG207.TextColor3=Color3.new(1,1,1)NG207.TextStrokeTransparency=0
NG207.TextWrapped=true NG207.TextXAlignment=Enum.TextXAlignment.Left
NG207.Parent=NG206
NG208=Instance.new("Frame") NG208.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG208.BackgroundTransparency=1
NG208.BorderSizePixel=0 NG208.Name=dCD([=[GlcrBcgvba]=])NG208.Position=UDim2.new(0,124,0,30) NG208.Size=UDim2.new(0,120,0,25)NG208.Parent=NG201
NG209=Instance.new("TextLabel") NG209.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG209.BackgroundTransparency=1
NG209.BorderSizePixel=0 NG209.Name=dCD([=[Ynory]=])NG209.Size=UDim2.new(0,40,0,25) NG209.Font=Enum.Font.ArialBold
NG209.FontSize=Enum.FontSize.Size10
NG209.Text=dCD([=[Glcr]=]) NG209.TextColor3=Color3.new(1,1,1)NG209.TextStrokeTransparency=0
NG209.TextWrapped=true NG209.TextXAlignment=Enum.TextXAlignment.Left
NG209.Parent=NG208
NG210=Instance.new("Frame") NG210.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG210.BackgroundTransparency=1
NG210.BorderSizePixel=0 NG210.Name=dCD([=[Gvc]=])NG210.Position=UDim2.new(0,5,0,70) NG210.Size=UDim2.new(1,-5,0,20)NG210.Parent=NG201
NG211=Instance.new("Frame") NG211.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG211.BorderSizePixel=0
NG211.Name=dCD([=[PbybeOne]=]) NG211.Size=UDim2.new(1,0,0,2)NG211.Parent=NG210
NG212=Instance.new("TextLabel") NG212.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG212.BackgroundTransparency=1
NG212.BorderSizePixel=0 NG212.Name=dCD([=[Grkg]=])NG212.Position=UDim2.new(0,6,0,2) NG212.Size=UDim2.new(1,-6,0,20)NG212.Font=Enum.Font.ArialBold NG212.FontSize=Enum.FontSize.Size10
NG212.Text=dCD([=[GVC: Fryrpg n cneg naq evtug pyvpx ba n fhesnpr]=]) NG212.TextColor3=Color3.new(1,1,1)NG212.TextStrokeTransparency=0.5
NG212.TextWrapped=true NG212.TextXAlignment=Enum.TextXAlignment.Left
NG212.Parent=NG210
NG213=Instance.new("Frame") NG213.Active=true NG213.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG213.BackgroundTransparency=1
NG213.BorderSizePixel=0 NG213.Name=dCD([=[OGGrkgherGbbyTHV]=])NG213.Position=UDim2.new(0,0,0,172) NG213.Size=UDim2.new(0,200,0,205)NG213.Draggable=true
NG213.Parent=NG1 NG214=Instance.new("Frame") NG214.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG214.BackgroundTransparency=1
NG214.BorderSizePixel=0 NG214.Name=dCD([=[Gvgyr]=])NG214.Size=UDim2.new(1,0,0,20)NG214.Parent=NG213 NG215=Instance.new("Frame") NG215.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG215.BorderSizePixel=0
NG215.Name=dCD([=[PbybeOne]=]) NG215.Position=UDim2.new(0,5,0,-3)NG215.Size=UDim2.new(1,-5,0,2)NG215.Parent=NG214 NG216=Instance.new("TextLabel") NG216.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG216.BackgroundTransparency=1
NG216.BorderSizePixel=0 NG216.Name=dCD([=[Ynory]=])NG216.Position=UDim2.new(0,10,0,1) NG216.Size=UDim2.new(1,-10,1,0)NG216.Font=Enum.Font.ArialBold NG216.FontSize=Enum.FontSize.Size10
NG216.Text=dCD([=[GRKGHER GBBY]=]) NG216.TextColor3=Color3.new(1,1,1)NG216.TextStrokeTransparency=0
NG216.TextWrapped=true NG216.TextXAlignment=Enum.TextXAlignment.Left
NG216.Parent=NG214
NG217=Instance.new("TextLabel") NG217.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG217.BackgroundTransparency=1
NG217.BorderSizePixel=0 NG217.Name=dCD([=[S3KFvtangher]=])NG217.Position=UDim2.new(0,10,0,1) NG217.Size=UDim2.new(1,-10,1,0)NG217.Font=Enum.Font.ArialBold NG217.FontSize=Enum.FontSize.Size14
NG217.Text=dCD([=[S3K]=])NG217.TextColor3=Color3.new(1,1,1) NG217.TextStrokeTransparency=0.89999997615814
NG217.TextWrapped=true NG217.TextXAlignment=Enum.TextXAlignment.Right
NG217.Parent=NG214
NG218=Instance.new("Frame") NG218.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG218.BackgroundTransparency=1
NG218.BorderSizePixel=0 NG218.Name=dCD([=[FvqrBcgvba]=])NG218.Position=UDim2.new(0,14,0,65) NG218.Size=UDim2.new(1,-14,0,25)NG218.Parent=NG213
NG219=Instance.new("TextLabel") NG219.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG219.BackgroundTransparency=1
NG219.BorderSizePixel=0 NG219.Name=dCD([=[Ynory]=])NG219.Size=UDim2.new(0,30,0,25) NG219.Font=Enum.Font.ArialBold
NG219.FontSize=Enum.FontSize.Size10
NG219.Text=dCD([=[Fvqr]=]) NG219.TextColor3=Color3.new(1,1,1)NG219.TextStrokeTransparency=0
NG219.TextWrapped=true NG219.TextXAlignment=Enum.TextXAlignment.Left
NG219.Parent=NG218
NG220=Instance.new("Frame") NG220.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG220.BackgroundTransparency=1
NG220.BorderSizePixel=0 NG220.Name=dCD([=[ErcrngBcgvba]=])NG220.Position=UDim2.new(0,0,0,205) NG220.Size=UDim2.new(0,0,0,0)NG220.Visible=false
NG220.Parent=NG213 NG221=Instance.new("TextLabel") NG221.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG221.BackgroundTransparency=1
NG221.BorderSizePixel=0 NG221.Name=dCD([=[Ynory]=])NG221.Position=UDim2.new(0,14,0,0) NG221.Size=UDim2.new(0,70,0,25)NG221.Font=Enum.Font.ArialBold NG221.FontSize=Enum.FontSize.Size10
NG221.Text=dCD([=[Ercrng]=])NG221.TextColor3=Color3.new(1,1,1) NG221.TextStrokeTransparency=0
NG221.TextWrapped=true NG221.TextXAlignment=Enum.TextXAlignment.Left
NG221.Parent=NG220
NG222=Instance.new("Frame") NG222.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG222.BackgroundTransparency=1
NG222.BorderSizePixel=0 NG222.Name=dCD([=[KVachg]=])NG222.Position=UDim2.new(0,60,0,0) NG222.Size=UDim2.new(0,45,0,25)NG222.Parent=NG220
NG223=Instance.new("TextButton") NG223.Active=true
NG223.AutoButtonColor=false NG223.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG223.BackgroundTransparency=1
NG223.BorderSizePixel=0 NG223.Selectable=true
NG223.Size=UDim2.new(1,0,1,0) NG223.Style=Enum.ButtonStyle.Custom
NG223.ZIndex=2
NG223.Font=Enum.Font.Legacy NG223.FontSize=Enum.FontSize.Size8
NG223.Text=dCD([=[]=])NG223.Parent=NG222 NG224=Instance.new("ImageLabel")NG224.Active=false NG224.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG224.BackgroundTransparency=1
NG224.BorderSizePixel=0 NG224.Name=dCD([=[Onpxtebhaq]=])NG224.Selectable=false
NG224.Size=UDim2.new(1,0,1,0) NG224.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG224.Parent=NG222
NG225=Instance.new("Frame") NG225.BorderSizePixel=0
NG225.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG225.Position=UDim2.new(0,5,0,-2)NG225.Size=UDim2.new(1,-4,0,2)NG225.Parent=NG222 NG226=Instance.new("TextBox") NG226.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG226.BackgroundTransparency=1
NG226.BorderSizePixel=0 NG226.Position=UDim2.new(0,5,0,0)NG226.Size=UDim2.new(1,-10,1,0) NG226.Font=Enum.Font.ArialBold
NG226.FontSize=Enum.FontSize.Size10
NG226.Text=dCD([=[2]=]) NG226.TextColor3=Color3.new(1,1,1)NG226.Parent=NG222
NG227=Instance.new("Frame") NG227.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG227.BackgroundTransparency=1
NG227.BorderSizePixel=0 NG227.Name=dCD([=[LVachg]=])NG227.Position=UDim2.new(0,105,0,0) NG227.Size=UDim2.new(0,45,0,25)NG227.Parent=NG220
NG228=Instance.new("TextButton") NG228.Active=true
NG228.AutoButtonColor=false NG228.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG228.BackgroundTransparency=1
NG228.BorderSizePixel=0 NG228.Selectable=true
NG228.Size=UDim2.new(1,0,1,0) NG228.Style=Enum.ButtonStyle.Custom
NG228.ZIndex=2
NG228.Font=Enum.Font.Legacy NG228.FontSize=Enum.FontSize.Size8
NG228.Text=dCD([=[]=])NG228.Parent=NG227 NG229=Instance.new("ImageLabel")NG229.Active=false NG229.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG229.BackgroundTransparency=1
NG229.BorderSizePixel=0 NG229.Name=dCD([=[Onpxtebhaq]=])NG229.Selectable=false
NG229.Size=UDim2.new(1,0,1,0) NG229.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG229.Parent=NG227
NG230=Instance.new("Frame") NG230.BorderSizePixel=0
NG230.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG230.Position=UDim2.new(0,5,0,-2)NG230.Size=UDim2.new(1,-4,0,2)NG230.Parent=NG227 NG231=Instance.new("TextBox") NG231.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG231.BackgroundTransparency=1
NG231.BorderSizePixel=0 NG231.Position=UDim2.new(0,5,0,0)NG231.Size=UDim2.new(1,-10,1,0) NG231.Font=Enum.Font.ArialBold
NG231.FontSize=Enum.FontSize.Size10
NG231.Text=dCD([=[2]=]) NG231.TextColor3=Color3.new(1,1,1)NG231.Parent=NG227
NG232=Instance.new("Frame") NG232.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG232.BorderSizePixel=0
NG232.Name=dCD([=[ObggbzPbybeOne]=])NG232.Position=UDim2.new(0,5,1, -2)NG232.Size=UDim2.new(1,0,0,2) NG232.Parent=NG213
NG233=Instance.new("Frame") NG233.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG233.BackgroundTransparency=1
NG233.BorderSizePixel=0 NG233.Name=dCD([=[GenafcneraplBcgvba]=])NG233.Position=UDim2.new(0,14,0,135) NG233.Size=UDim2.new(1,0,0,25)NG233.Parent=NG213
NG234=Instance.new("TextLabel") NG234.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG234.BackgroundTransparency=1
NG234.BorderSizePixel=0 NG234.Name=dCD([=[Ynory]=])NG234.Size=UDim2.new(0,70,0,25) NG234.Font=Enum.Font.ArialBold
NG234.FontSize=Enum.FontSize.Size10 NG234.Text=dCD([=[Genafcnerapl]=])NG234.TextColor3=Color3.new(1,1,1) NG234.TextStrokeTransparency=0
NG234.TextWrapped=true NG234.TextXAlignment=Enum.TextXAlignment.Left
NG234.Parent=NG233
NG235=Instance.new("Frame") NG235.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG235.BackgroundTransparency=1
NG235.BorderSizePixel=0 NG235.Name=dCD([=[GenafcneraplVachg]=])NG235.Position=UDim2.new(0,75,0,0) NG235.Size=UDim2.new(0,45,0,25)NG235.Parent=NG233
NG236=Instance.new("TextButton") NG236.Active=true
NG236.AutoButtonColor=false NG236.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG236.BackgroundTransparency=1
NG236.BorderSizePixel=0 NG236.Selectable=true
NG236.Size=UDim2.new(1,0,1,0) NG236.Style=Enum.ButtonStyle.Custom
NG236.ZIndex=2
NG236.Font=Enum.Font.Legacy NG236.FontSize=Enum.FontSize.Size8
NG236.Text=dCD([=[]=])NG236.Parent=NG235 NG237=Instance.new("ImageLabel")NG237.Active=false NG237.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG237.BackgroundTransparency=1
NG237.BorderSizePixel=0 NG237.Name=dCD([=[Onpxtebhaq]=])NG237.Selectable=false
NG237.Size=UDim2.new(1,0,1,0) NG237.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG237.Parent=NG235
NG238=Instance.new("Frame") NG238.BorderSizePixel=0
NG238.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG238.Position=UDim2.new(0,5,0,-2)NG238.Size=UDim2.new(1,-4,0,2)NG238.Parent=NG235 NG239=Instance.new("TextBox") NG239.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG239.BackgroundTransparency=1
NG239.BorderSizePixel=0 NG239.Position=UDim2.new(0,5,0,0)NG239.Size=UDim2.new(1,-10,1,0) NG239.Font=Enum.Font.ArialBold
NG239.FontSize=Enum.FontSize.Size10
NG239.Text=dCD([=[0]=]) NG239.TextColor3=Color3.new(1,1,1)NG239.Parent=NG235
NG240=Instance.new("Frame") NG240.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG240.BackgroundTransparency=1
NG240.BorderSizePixel=0 NG240.Name=dCD([=[ZbqrBcgvba]=])NG240.Position=UDim2.new(0,0,0,30) NG240.Size=UDim2.new(0,0,0,0)NG240.Parent=NG213
NG241=Instance.new("TextLabel") NG241.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG241.BackgroundTransparency=1
NG241.BorderSizePixel=0 NG241.Name=dCD([=[Ynory]=])NG241.Position=UDim2.new(0,14,0,0) NG241.Size=UDim2.new(0,40,0,25)NG241.Font=Enum.Font.ArialBold NG241.FontSize=Enum.FontSize.Size10
NG241.Text=dCD([=[Zbqr]=])NG241.TextColor3=Color3.new(1,1,1) NG241.TextStrokeTransparency=0
NG241.TextWrapped=true NG241.TextXAlignment=Enum.TextXAlignment.Left
NG241.Parent=NG240
NG242=Instance.new("Frame") NG242.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG242.BackgroundTransparency=1
NG242.BorderSizePixel=0 NG242.Name=dCD([=[Qrpny]=])NG242.Position=UDim2.new(0,55,0,0) NG242.Size=UDim2.new(0,70,0,25)NG242.Parent=NG240
NG243=Instance.new("Frame") NG243.BorderSizePixel=0
NG243.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG243.Position=UDim2.new(0,7,0,-2)NG243.Size=UDim2.new(1,-7,0,2)NG243.Parent=NG242 NG244=Instance.new("TextButton")NG244.Active=true NG244.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG244.BackgroundTransparency=1
NG244.BorderSizePixel=0 NG244.Name=dCD([=[Ohggba]=])NG244.Position=UDim2.new(0,5,0,0)NG244.Selectable=true
NG244.Size=UDim2.new(1, -10,1,0) NG244.Style=Enum.ButtonStyle.Custom
NG244.ZIndex=2
NG244.Font=Enum.Font.Legacy NG244.FontSize=Enum.FontSize.Size8
NG244.Text=dCD([=[]=])NG244.TextTransparency=1
NG244.Parent=NG242 NG245=Instance.new("ImageLabel")NG245.Active=false NG245.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG245.BackgroundTransparency=1
NG245.BorderSizePixel=0 NG245.Name=dCD([=[Onpxtebhaq]=])NG245.Selectable=false
NG245.Size=UDim2.new(1,0,1,0) NG245.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG245.Parent=NG242
NG246=Instance.new("TextLabel") NG246.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG246.BackgroundTransparency=1
NG246.BorderSizePixel=0 NG246.Name=dCD([=[Ynory]=])NG246.Size=UDim2.new(1,0,1,0) NG246.Font=Enum.Font.ArialBold
NG246.FontSize=Enum.FontSize.Size10
NG246.Text=dCD([=[QRPNY]=]) NG246.TextColor3=Color3.new(1,1,1)NG246.Parent=NG242
NG247=Instance.new("Frame") NG247.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG247.BackgroundTransparency=1
NG247.BorderSizePixel=0 NG247.Name=dCD([=[Grkgher]=])NG247.Position=UDim2.new(0,122,0,0) NG247.Size=UDim2.new(0,70,0,25)NG247.Parent=NG240
NG248=Instance.new("TextButton") NG248.Active=true NG248.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG248.BackgroundTransparency=1
NG248.BorderSizePixel=0 NG248.Name=dCD([=[Ohggba]=])NG248.Position=UDim2.new(0,5,0,0)NG248.Selectable=true
NG248.Size=UDim2.new(1, -10,1,0) NG248.Style=Enum.ButtonStyle.Custom
NG248.ZIndex=2
NG248.Font=Enum.Font.Legacy NG248.FontSize=Enum.FontSize.Size8
NG248.Text=dCD([=[]=])NG248.TextTransparency=1
NG248.Parent=NG247 NG249=Instance.new("ImageLabel")NG249.Active=false NG249.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG249.BackgroundTransparency=1
NG249.BorderSizePixel=0 NG249.Name=dCD([=[Onpxtebhaq]=])NG249.Selectable=false
NG249.Size=UDim2.new(1,0,1,0) NG249.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG249.Parent=NG247
NG250=Instance.new("TextLabel") NG250.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG250.BackgroundTransparency=1
NG250.BorderSizePixel=0 NG250.Name=dCD([=[Ynory]=])NG250.Size=UDim2.new(1,0,1,0) NG250.Font=Enum.Font.ArialBold
NG250.FontSize=Enum.FontSize.Size10
NG250.Text=dCD([=[GRKGHER]=]) NG250.TextColor3=Color3.new(1,1,1)NG250.Parent=NG247
NG251=Instance.new("Frame") NG251.BackgroundTransparency=1
NG251.BorderSizePixel=0
NG251.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG251.Position=UDim2.new(0,7,0, -2)NG251.Size=UDim2.new(1,-7,0,2) NG251.Parent=NG247
NG252=Instance.new("Frame") NG252.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG252.BackgroundTransparency=1
NG252.BorderSizePixel=0 NG252.Name=dCD([=[VzntrVQBcgvba]=])NG252.Position=UDim2.new(0,14,0,100) NG252.Size=UDim2.new(1,0,0,25)NG252.Parent=NG213
NG253=Instance.new("TextLabel") NG253.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG253.BackgroundTransparency=1
NG253.BorderSizePixel=0 NG253.Name=dCD([=[Ynory]=])NG253.Size=UDim2.new(0,70,0,25) NG253.Font=Enum.Font.ArialBold
NG253.FontSize=Enum.FontSize.Size10
NG253.Text=dCD([=[Vzntr VQ]=]) NG253.TextColor3=Color3.new(1,1,1)NG253.TextStrokeTransparency=0
NG253.TextWrapped=true NG253.TextXAlignment=Enum.TextXAlignment.Left
NG253.Parent=NG252
NG254=Instance.new("Frame") NG254.BackgroundTransparency=1
NG254.BorderSizePixel=0
NG254.Name=dCD([=[GrkgObkObeqre]=]) NG254.Position=UDim2.new(0,61,0,17)NG254.Size=UDim2.new(0,85,0,3)NG254.Parent=NG252 NG255=Instance.new("Frame")NG255.BackgroundColor3=Color3.new(0.333333,0,0.498039) NG255.BorderSizePixel=0
NG255.Name=dCD([=[ObggbzObeqre]=]) NG255.Position=UDim2.new(0,0,1,-1)NG255.Size=UDim2.new(1,0,0,1)NG255.Parent=NG254 NG256=Instance.new("Frame")NG256.BackgroundColor3=Color3.new(0.333333,0,0.498039) NG256.BorderSizePixel=0
NG256.Name=dCD([=[YrsgObeqre]=])NG256.Size=UDim2.new(0,1,1,0) NG256.Parent=NG254
NG257=Instance.new("Frame") NG257.BackgroundColor3=Color3.new(0.333333,0,0.498039)NG257.BorderSizePixel=0
NG257.Name=dCD([=[EvtugObeqre]=]) NG257.Position=UDim2.new(1,-1,0,0)NG257.Size=UDim2.new(0,1,1,0)NG257.Parent=NG254 NG258=Instance.new("Frame")NG258.BackgroundColor3=Color3.new(0.333333,0,0.498039) NG258.BackgroundTransparency=0.89999997615814
NG258.BorderSizePixel=0
NG258.Name=dCD([=[GrkgObkOnpxtebhaq]=])NG258.Position=UDim2.new(0,60,0, -2)NG258.Size=UDim2.new(0,86,0,22) NG258.Parent=NG252
NG259=Instance.new("TextButton")NG259.Active=true NG259.BackgroundTransparency=1
NG259.BorderSizePixel=0
NG259.Position=UDim2.new(0,65,0,-1) NG259.Selectable=true
NG259.Size=UDim2.new(0,80,0,18) NG259.Style=Enum.ButtonStyle.Custom
NG259.ZIndex=2
NG259.FontSize=Enum.FontSize.Size14 NG259.Text=dCD([=[]=])NG259.Parent=NG252
NG260=Instance.new("TextBox") NG260.BackgroundColor3=Color3.new(0.333333,0,0.498039)NG260.BackgroundTransparency=1 NG260.BorderColor3=Color3.new(0,0,0)NG260.BorderSizePixel=0
NG260.Position=UDim2.new(0,65,0,-1) NG260.Size=UDim2.new(0,80,0,18)NG260.Font=Enum.Font.SourceSansBold NG260.FontSize=Enum.FontSize.Size10
NG260.Text=dCD([=[]=])NG260.TextColor3=Color3.new(1,1,1) NG260.TextScaled=true
NG260.TextStrokeTransparency=0.5
NG260.TextWrapped=true NG260.TextXAlignment=Enum.TextXAlignment.Left
NG260.Parent=NG252
NG261=Instance.new("Frame") NG261.BackgroundColor3=Color3.new(0,0,0)NG261.BackgroundTransparency=1
NG261.BorderSizePixel=0 NG261.Name=dCD([=[NqqOhggba]=])NG261.Position=UDim2.new(0,10,0,100) NG261.Size=UDim2.new(1,-10,0,20)NG261.Visible=false
NG261.Parent=NG213 NG262=Instance.new("TextButton")NG262.Active=true
NG262.BackgroundColor3=Color3.new(0,0,0) NG262.BackgroundTransparency=0.44999998807907
NG262.BorderSizePixel=0
NG262.Name=dCD([=[Ohggba]=])NG262.Selectable=true NG262.Size=UDim2.new(1,0,1,0)NG262.Style=Enum.ButtonStyle.Custom NG262.Font=Enum.Font.ArialBold
NG262.FontSize=Enum.FontSize.Size10 NG262.Text=dCD([=[NQQ QRPNY]=])NG262.TextColor3=Color3.new(1,1,1) NG262.TextStrokeTransparency=0.80000001192093
NG262.Parent=NG261
NG263=Instance.new("Frame") NG263.BackgroundColor3=Color3.new(0,0,0)NG263.BackgroundTransparency=0.30000001192093
NG263.BorderSizePixel=0 NG263.Name=dCD([=[Funqbj]=])NG263.Position=UDim2.new(0,0,1,0) NG263.Size=UDim2.new(1,0,0,2)NG263.ZIndex=2
NG263.Parent=NG261 NG264=Instance.new("Frame")NG264.BackgroundColor3=Color3.new(0,0,0) NG264.BackgroundTransparency=1
NG264.BorderSizePixel=0
NG264.Name=dCD([=[ErzbirOhggba]=])NG264.Position=UDim2.new(0,10,1, -35) NG264.Size=UDim2.new(1,-10,0,20)NG264.Parent=NG213
NG265=Instance.new("TextButton") NG265.Active=true
NG265.BackgroundColor3=Color3.new(0,0,0) NG265.BackgroundTransparency=0.44999998807907
NG265.BorderSizePixel=0
NG265.Name=dCD([=[Ohggba]=])NG265.Selectable=true NG265.Size=UDim2.new(1,0,1,0)NG265.Style=Enum.ButtonStyle.Custom NG265.Font=Enum.Font.ArialBold
NG265.FontSize=Enum.FontSize.Size10 NG265.Text=dCD([=[ERZBIR QRPNY]=])NG265.TextColor3=Color3.new(1,1,1) NG265.TextStrokeTransparency=0.80000001192093
NG265.Parent=NG264
NG266=Instance.new("Frame") NG266.BackgroundColor3=Color3.new(0,0,0)NG266.BackgroundTransparency=0.30000001192093
NG266.BorderSizePixel=0 NG266.Name=dCD([=[Funqbj]=])NG266.Position=UDim2.new(0,0,1,0) NG266.Size=UDim2.new(1,0,0,2)NG266.ZIndex=2
NG266.Parent=NG264 NG267=Instance.new("TextLabel") NG267.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG267.BackgroundTransparency=1
NG267.BorderSizePixel=0 NG267.Name=dCD([=[Grkg]=])NG267.Position=UDim2.new(0,6,1,2) NG267.Size=UDim2.new(1,-6,0,20)NG267.Font=Enum.Font.ArialBold NG267.FontSize=Enum.FontSize.Size10
NG267.Text=dCD([=[GVC: Fryrpg n cneg & evtug pyvpx ba n fhesnpr]=]) NG267.TextColor3=Color3.new(1,1,1)NG267.TextStrokeTransparency=0.5
NG267.TextWrapped=true NG267.TextXAlignment=Enum.TextXAlignment.Left
NG267.Parent=NG213
NG268=Instance.new("Frame") NG268.Active=true NG268.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG268.BackgroundTransparency=1
NG268.BorderSizePixel=0 NG268.Name=dCD([=[OGJryqGbbyTHV]=])NG268.Position=UDim2.new(0,0,0,280) NG268.Size=UDim2.new(0,220,0,90)NG268.Draggable=true
NG268.Parent=NG1 NG269=Instance.new("Frame") NG269.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG269.BackgroundTransparency=1
NG269.BorderSizePixel=0 NG269.Name=dCD([=[Gvgyr]=])NG269.Size=UDim2.new(1,0,0,20)NG269.Parent=NG268 NG270=Instance.new("Frame") NG270.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG270.BorderSizePixel=0
NG270.Name=dCD([=[PbybeOne]=]) NG270.Position=UDim2.new(0,5,0,-3)NG270.Size=UDim2.new(1,-5,0,2)NG270.Parent=NG269 NG271=Instance.new("TextLabel") NG271.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG271.BackgroundTransparency=1
NG271.BorderSizePixel=0 NG271.Name=dCD([=[Ynory]=])NG271.Position=UDim2.new(0,10,0,1) NG271.Size=UDim2.new(1,-10,1,0)NG271.Font=Enum.Font.ArialBold NG271.FontSize=Enum.FontSize.Size10
NG271.Text=dCD([=[JRYQ GBBY]=]) NG271.TextColor3=Color3.new(1,1,1)NG271.TextStrokeTransparency=0
NG271.TextWrapped=true NG271.TextXAlignment=Enum.TextXAlignment.Left
NG271.Parent=NG269
NG272=Instance.new("TextLabel") NG272.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG272.BackgroundTransparency=1
NG272.BorderSizePixel=0 NG272.Name=dCD([=[S3KFvtangher]=])NG272.Position=UDim2.new(0,10,0,1) NG272.Size=UDim2.new(1,-10,1,0)NG272.Font=Enum.Font.ArialBold NG272.FontSize=Enum.FontSize.Size14
NG272.Text=dCD([=[S3K]=])NG272.TextColor3=Color3.new(1,1,1) NG272.TextStrokeTransparency=0.89999997615814
NG272.TextWrapped=true NG272.TextXAlignment=Enum.TextXAlignment.Right
NG272.Parent=NG269
NG273=Instance.new("Frame") NG273.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG273.BackgroundTransparency=1
NG273.BorderSizePixel=0 NG273.Name=dCD([=[Vagresnpr]=])NG273.Position=UDim2.new(0,10,0,30) NG273.Size=UDim2.new(1,-10,0,0)NG273.Parent=NG268
NG274=Instance.new("TextButton") NG274.Active=true
NG274.BackgroundColor3=Color3.new(0,0,0) NG274.BackgroundTransparency=0.40000000596046
NG274.BorderSizePixel=0
NG274.Name=dCD([=[JryqOhggba]=]) NG274.Selectable=true
NG274.Size=UDim2.new(0.479999989,0,0,25) NG274.Style=Enum.ButtonStyle.Custom
NG274.Font=Enum.Font.ArialBold NG274.FontSize=Enum.FontSize.Size10
NG274.Text=dCD([=[JRYQ GB YNFG]=]) NG274.TextColor3=Color3.new(1,1,1)NG274.TextStrokeTransparency=0.85000002384186
NG274.Parent=NG273 NG275=Instance.new("Frame")NG275.BackgroundColor3=Color3.new(0,0,0) NG275.BackgroundTransparency=0.15000000596046
NG275.BorderSizePixel=0
NG275.Name=dCD([=[Funqbj]=]) NG275.Position=UDim2.new(0,0,1,-2)NG275.Size=UDim2.new(1,0,0,2)NG275.Parent=NG274 NG276=Instance.new("TextButton")NG276.Active=true
NG276.BackgroundColor3=Color3.new(0,0,0) NG276.BackgroundTransparency=0.40000000596046
NG276.BorderSizePixel=0
NG276.Name=dCD([=[OernxJryqfOhggba]=]) NG276.Position=UDim2.new(0.519999981,0,0,0)NG276.Selectable=true NG276.Size=UDim2.new(0.479999989,0,0,25)NG276.Style=Enum.ButtonStyle.Custom NG276.Font=Enum.Font.ArialBold
NG276.FontSize=Enum.FontSize.Size10 NG276.Text=dCD([=[OERNX JRYQF]=])NG276.TextColor3=Color3.new(1,1,1) NG276.TextStrokeTransparency=0.85000002384186
NG276.Parent=NG273
NG277=Instance.new("Frame") NG277.BackgroundColor3=Color3.new(0,0,0)NG277.BackgroundTransparency=0.15000000596046
NG277.BorderSizePixel=0 NG277.Name=dCD([=[Funqbj]=])NG277.Position=UDim2.new(0,0,1,-2) NG277.Size=UDim2.new(1,0,0,2)NG277.Parent=NG276
NG278=Instance.new("Frame") NG278.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG278.BackgroundTransparency=1
NG278.BorderSizePixel=0 NG278.Name=dCD([=[Punatrf]=])NG278.Position=UDim2.new(0,5,0,70) NG278.Size=UDim2.new(1,-5,0,20)NG278.Parent=NG268
NG279=Instance.new("Frame") NG279.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG279.BorderSizePixel=0
NG279.Name=dCD([=[PbybeOne]=]) NG279.Size=UDim2.new(1,0,0,2)NG279.Parent=NG278
NG280=Instance.new("TextLabel") NG280.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG280.BackgroundTransparency=1
NG280.BorderSizePixel=0 NG280.Name=dCD([=[Grkg]=])NG280.Position=UDim2.new(0,0,0,2) NG280.Size=UDim2.new(1,0,0,20)NG280.Font=Enum.Font.ArialBold NG280.FontSize=Enum.FontSize.Size10
NG280.Text=dCD([=[]=])NG280.TextColor3=Color3.new(1,1,1) NG280.TextStrokeTransparency=0.5
NG280.TextWrapped=true NG280.TextXAlignment=Enum.TextXAlignment.Right
NG280.Parent=NG278
NG281=Instance.new("Frame") NG281.Active=true NG281.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG281.BackgroundTransparency=1
NG281.BorderSizePixel=0 NG281.Name=dCD([=[OGYvtugvatGbbyTHV]=])NG281.Position=UDim2.new(0,0,0,172) NG281.Size=UDim2.new(0,200,0,95)NG281.Draggable=true
NG281.Parent=NG1 NG282=Instance.new("Frame")NG282.BackgroundColor3=Color3.new(0,0,0) NG282.BorderSizePixel=0
NG282.Name=dCD([=[ObggbzPbybeOne]=]) NG282.Position=UDim2.new(0,5,1,-2)NG282.Size=UDim2.new(1,0,0,2)NG282.Parent=NG281 NG283=Instance.new("Frame") NG283.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG283.BackgroundTransparency=1
NG283.BorderSizePixel=0 NG283.Name=dCD([=[Gvgyr]=])NG283.Size=UDim2.new(1,0,0,20)NG283.Parent=NG281 NG284=Instance.new("Frame")NG284.BackgroundColor3=Color3.new(0,0,0) NG284.BorderSizePixel=0
NG284.Name=dCD([=[PbybeOne]=])NG284.Position=UDim2.new(0,5,0,-3)NG284.Size=UDim2.new(1, -5,0,2)NG284.Parent=NG283 NG285=Instance.new("TextLabel") NG285.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG285.BackgroundTransparency=1
NG285.BorderSizePixel=0 NG285.Name=dCD([=[Ynory]=])NG285.Position=UDim2.new(0,10,0,1) NG285.Size=UDim2.new(1,-10,1,0)NG285.Font=Enum.Font.ArialBold NG285.FontSize=Enum.FontSize.Size10
NG285.Text=dCD([=[YVTUGVAT GBBY]=]) NG285.TextColor3=Color3.new(1,1,1)NG285.TextStrokeTransparency=0
NG285.TextWrapped=true NG285.TextXAlignment=Enum.TextXAlignment.Left
NG285.Parent=NG283
NG286=Instance.new("TextLabel") NG286.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG286.BackgroundTransparency=1
NG286.BorderSizePixel=0 NG286.Name=dCD([=[S3KFvtangher]=])NG286.Position=UDim2.new(0,10,0,1) NG286.Size=UDim2.new(1,-10,1,0)NG286.Font=Enum.Font.ArialBold NG286.FontSize=Enum.FontSize.Size14
NG286.Text=dCD([=[S3K]=])NG286.TextColor3=Color3.new(1,1,1) NG286.TextStrokeTransparency=0.89999997615814
NG286.TextWrapped=true NG286.TextXAlignment=Enum.TextXAlignment.Right
NG286.Parent=NG283
NG287=Instance.new("Frame") NG287.BackgroundColor3=Color3.new(0,0,0)NG287.BackgroundTransparency=0.67500001192093
NG287.BorderSizePixel=0 NG287.Name=dCD([=[Fcbgyvtug]=])NG287.Position=UDim2.new(0,10,0,30) NG287.Size=UDim2.new(1,-10,0,25)NG287.Parent=NG281
NG288=Instance.new("TextLabel") NG288.BackgroundTransparency=1
NG288.BorderSizePixel=0
NG288.Name=dCD([=[Ynory]=]) NG288.Position=UDim2.new(0,35,0,0)NG288.Size=UDim2.new(0,60,0,25) NG288.Font=Enum.Font.ArialBold
NG288.FontSize=Enum.FontSize.Size10 NG288.Text=dCD([=[Fcbgyvtug]=])NG288.TextColor3=Color3.new(1,1,1) NG288.TextStrokeTransparency=0.5
NG288.TextWrapped=true NG288.TextXAlignment=Enum.TextXAlignment.Left
NG288.Parent=NG287
NG289=Instance.new("ImageButton") NG289.BackgroundTransparency=1
NG289.BorderSizePixel=0
NG289.Name=dCD([=[NeebjOhggba]=]) NG289.Position=UDim2.new(0,10,0,3)NG289.Size=UDim2.new(0,20,0,20) NG289.Style=Enum.ButtonStyle.Custom
NG289.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=134367382]=]) NG289.Parent=NG287
NG290=Instance.new("Frame") NG290.BackgroundColor3=Color3.new(1,0.682353,0.235294)NG290.BorderSizePixel=0
NG290.Name=dCD([=[PbybeOne]=]) NG290.Size=UDim2.new(0,3,1,0)NG290.Parent=NG287
NG291=Instance.new("TextButton") NG291.Active=true
NG291.BackgroundColor3=Color3.new(0,0,0) NG291.BackgroundTransparency=0.75
NG291.BorderColor3=Color3.new(0,0,0)NG291.BorderSizePixel=0 NG291.Name=dCD([=[NqqOhggba]=])NG291.Position=UDim2.new(1,-40,0,3)NG291.Selectable=true NG291.Size=UDim2.new(0,35,0,19)NG291.Style=Enum.ButtonStyle.Custom NG291.Font=Enum.Font.ArialBold
NG291.FontSize=Enum.FontSize.Size10
NG291.Text=dCD([=[NQQ]=]) NG291.TextColor3=Color3.new(1,1,1)NG291.Parent=NG287
NG292=Instance.new("TextButton") NG292.Active=true
NG292.BackgroundColor3=Color3.new(0,0,0) NG292.BackgroundTransparency=0.75
NG292.BorderColor3=Color3.new(0,0,0)NG292.BorderSizePixel=0 NG292.Name=dCD([=[ErzbirOhggba]=])NG292.Position=UDim2.new(0,127,0,3)NG292.Selectable=true NG292.Size=UDim2.new(0,58,0,19)NG292.Style=Enum.ButtonStyle.Custom
NG292.Visible=false NG292.Font=Enum.Font.ArialBold
NG292.FontSize=Enum.FontSize.Size10
NG292.Text=dCD([=[ERZBIR]=]) NG292.TextColor3=Color3.new(1,1,1)NG292.Parent=NG287
NG293=Instance.new("Frame") NG293.BackgroundColor3=Color3.new(0,0,0)NG293.BackgroundTransparency=0.75
NG293.BorderSizePixel=0 NG293.Name=dCD([=[Funqbj]=])NG293.Position=UDim2.new(0,0,1,-1) NG293.Size=UDim2.new(1,0,0,1)NG293.Parent=NG287
NG294=Instance.new("Frame") NG294.BackgroundTransparency=1
NG294.BorderSizePixel=0
NG294.Name=dCD([=[Bcgvbaf]=]) NG294.Position=UDim2.new(0,3,1,0)NG294.Size=UDim2.new(1,-3,0,0)NG294.ClipsDescendants=true NG294.Parent=NG287
NG295=Instance.new("Frame") NG295.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG295.BackgroundTransparency=1
NG295.BorderSizePixel=0 NG295.Name=dCD([=[PbybeBcgvba]=])NG295.Position=UDim2.new(0,0,0,10) NG295.Size=UDim2.new(1,0,0,25)NG295.Parent=NG294
NG296=Instance.new("TextLabel") NG296.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG296.BackgroundTransparency=1
NG296.BorderSizePixel=0 NG296.Name=dCD([=[Ynory]=])NG296.Size=UDim2.new(0,70,0,25) NG296.Font=Enum.Font.ArialBold
NG296.FontSize=Enum.FontSize.Size10
NG296.Text=dCD([=[Pbybe]=]) NG296.TextColor3=Color3.new(1,1,1)NG296.TextStrokeTransparency=0
NG296.TextWrapped=true NG296.TextXAlignment=Enum.TextXAlignment.Left
NG296.Parent=NG295
NG297=Instance.new("Frame") NG297.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG297.BackgroundTransparency=1
NG297.BorderSizePixel=0 NG297.Name=dCD([=[EVachg]=])NG297.Position=UDim2.new(0,35,0,0) NG297.Size=UDim2.new(0,38,0,25)NG297.Parent=NG295
NG298=Instance.new("TextButton") NG298.Active=true
NG298.AutoButtonColor=false NG298.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG298.BackgroundTransparency=1
NG298.BorderSizePixel=0 NG298.Selectable=true
NG298.Size=UDim2.new(1,0,1,0) NG298.Style=Enum.ButtonStyle.Custom
NG298.ZIndex=2
NG298.Font=Enum.Font.Legacy NG298.FontSize=Enum.FontSize.Size8
NG298.Text=dCD([=[]=])NG298.Parent=NG297 NG299=Instance.new("ImageLabel")NG299.Active=false NG299.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG299.BackgroundTransparency=1
NG299.BorderSizePixel=0 NG299.Name=dCD([=[Onpxtebhaq]=])NG299.Selectable=false
NG299.Size=UDim2.new(1,0,1,0) NG299.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG299.Parent=NG297
NG300=Instance.new("Frame") NG300.BackgroundColor3=Color3.new(1,0,0)NG300.BorderSizePixel=0
NG300.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG300.Position=UDim2.new(0,3,0, -2)NG300.Size=UDim2.new(1,-3,0,2) NG300.Parent=NG297
NG301=Instance.new("TextBox") NG301.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG301.BackgroundTransparency=1
NG301.BorderSizePixel=0 NG301.Position=UDim2.new(0,5,0,0)NG301.Size=UDim2.new(1,-10,1,0) NG301.Font=Enum.Font.ArialBold
NG301.FontSize=Enum.FontSize.Size10
NG301.Text=dCD([=[255]=]) NG301.TextColor3=Color3.new(1,1,1)NG301.Parent=NG297
NG302=Instance.new("Frame") NG302.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG302.BackgroundTransparency=1
NG302.BorderSizePixel=0 NG302.Name=dCD([=[TVachg]=])NG302.Position=UDim2.new(0,72,0,0) NG302.Size=UDim2.new(0,38,0,25)NG302.Parent=NG295
NG303=Instance.new("TextButton") NG303.Active=true
NG303.AutoButtonColor=false NG303.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG303.BackgroundTransparency=1
NG303.BorderSizePixel=0 NG303.Selectable=true
NG303.Size=UDim2.new(1,0,1,0) NG303.Style=Enum.ButtonStyle.Custom
NG303.ZIndex=2
NG303.Font=Enum.Font.Legacy NG303.FontSize=Enum.FontSize.Size8
NG303.Text=dCD([=[]=])NG303.Parent=NG302 NG304=Instance.new("ImageLabel")NG304.Active=false NG304.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG304.BackgroundTransparency=1
NG304.BorderSizePixel=0 NG304.Name=dCD([=[Onpxtebhaq]=])NG304.Selectable=false
NG304.Size=UDim2.new(1,0,1,0) NG304.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG304.Parent=NG302
NG305=Instance.new("Frame") NG305.BackgroundColor3=Color3.new(0,1,0)NG305.BorderSizePixel=0
NG305.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG305.Position=UDim2.new(0,3,0, -2)NG305.Size=UDim2.new(1,-3,0,2) NG305.Parent=NG302
NG306=Instance.new("TextBox") NG306.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG306.BackgroundTransparency=1
NG306.BorderSizePixel=0 NG306.Position=UDim2.new(0,5,0,0)NG306.Size=UDim2.new(1,-10,1,0) NG306.Font=Enum.Font.ArialBold
NG306.FontSize=Enum.FontSize.Size10
NG306.Text=dCD([=[255]=]) NG306.TextColor3=Color3.new(1,1,1)NG306.Parent=NG302
NG307=Instance.new("Frame") NG307.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG307.BackgroundTransparency=1
NG307.BorderSizePixel=0 NG307.Name=dCD([=[OVachg]=])NG307.Position=UDim2.new(0,109,0,0) NG307.Size=UDim2.new(0,38,0,25)NG307.Parent=NG295
NG308=Instance.new("TextButton") NG308.Active=true
NG308.AutoButtonColor=false NG308.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG308.BackgroundTransparency=1
NG308.BorderSizePixel=0 NG308.Selectable=true
NG308.Size=UDim2.new(1,0,1,0) NG308.Style=Enum.ButtonStyle.Custom
NG308.ZIndex=2
NG308.Font=Enum.Font.Legacy NG308.FontSize=Enum.FontSize.Size8
NG308.Text=dCD([=[]=])NG308.Parent=NG307 NG309=Instance.new("ImageLabel")NG309.Active=false NG309.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG309.BackgroundTransparency=1
NG309.BorderSizePixel=0 NG309.Name=dCD([=[Onpxtebhaq]=])NG309.Selectable=false
NG309.Size=UDim2.new(1,0,1,0) NG309.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG309.Parent=NG307
NG310=Instance.new("Frame") NG310.BackgroundColor3=Color3.new(0,0,1)NG310.BorderSizePixel=0
NG310.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG310.Position=UDim2.new(0,3,0, -2)NG310.Size=UDim2.new(1,-3,0,2) NG310.Parent=NG307
NG311=Instance.new("TextBox") NG311.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG311.BackgroundTransparency=1
NG311.BorderSizePixel=0 NG311.Position=UDim2.new(0,5,0,0)NG311.Size=UDim2.new(1,-10,1,0) NG311.Font=Enum.Font.ArialBold
NG311.FontSize=Enum.FontSize.Size10
NG311.Text=dCD([=[255]=]) NG311.TextColor3=Color3.new(1,1,1)NG311.Parent=NG307
NG312=Instance.new("ImageButton") NG312.BackgroundColor3=Color3.new(0,0,0)NG312.BackgroundTransparency=0.40000000596046
NG312.BorderSizePixel=0 NG312.Name=dCD([=[UFICvpxre]=])NG312.Position=UDim2.new(0,160,0,-2) NG312.Size=UDim2.new(0,27,0,27)NG312.Style=Enum.ButtonStyle.Custom NG312.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141313631]=])NG312.Parent=NG295
NG313=Instance.new("Frame") NG313.BackgroundColor3=Color3.new(0,0,0)NG313.BackgroundTransparency=0.75
NG313.BorderSizePixel=0 NG313.Name=dCD([=[Funqbj]=])NG313.Position=UDim2.new(0,0,1,-2) NG313.Size=UDim2.new(1,0,0,2)NG313.Parent=NG312
NG314=Instance.new("Frame") NG314.BackgroundColor3=Color3.new(0,0,0)NG314.BackgroundTransparency=0.5 NG314.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG314.BorderSizePixel=0
NG314.Name=dCD([=[Frcnengbe]=]) NG314.Position=UDim2.new(0,151,0,4)NG314.Size=UDim2.new(0,4,0,4)NG314.Parent=NG295 NG315=Instance.new("Frame")NG315.BackgroundColor3=Color3.new(0,0,0) NG315.BackgroundTransparency=0.5 NG315.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG315.BorderSizePixel=0
NG315.Name=dCD([=[Frcnengbe]=]) NG315.Position=UDim2.new(0,151,0,16)NG315.Size=UDim2.new(0,4,0,4)NG315.Parent=NG295 NG316=Instance.new("Frame")NG316.BackgroundColor3=Color3.new(0,0,0) NG316.BackgroundTransparency=0.5 NG316.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG316.BorderSizePixel=0
NG316.Name=dCD([=[Frcnengbe]=]) NG316.Position=UDim2.new(0,151,0,10)NG316.Size=UDim2.new(0,4,0,4)NG316.Parent=NG295 NG317=Instance.new("Frame") NG317.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG317.BackgroundTransparency=1
NG317.BorderSizePixel=0 NG317.Name=dCD([=[OevtugarffBcgvba]=])NG317.Position=UDim2.new(0,0,0,45) NG317.Size=UDim2.new(1,0,0,25)NG317.Parent=NG294
NG318=Instance.new("TextLabel") NG318.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG318.BackgroundTransparency=1
NG318.BorderSizePixel=0 NG318.Name=dCD([=[Ynory]=])NG318.Size=UDim2.new(0,70,0,25) NG318.Font=Enum.Font.ArialBold
NG318.FontSize=Enum.FontSize.Size10 NG318.Text=dCD([=[Oevtugarff]=])NG318.TextColor3=Color3.new(1,1,1) NG318.TextStrokeTransparency=0
NG318.TextWrapped=true NG318.TextXAlignment=Enum.TextXAlignment.Left
NG318.Parent=NG317
NG319=Instance.new("Frame") NG319.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG319.BackgroundTransparency=1
NG319.BorderSizePixel=0 NG319.Name=dCD([=[Vachg]=])NG319.Position=UDim2.new(0,60,0,0) NG319.Size=UDim2.new(0,38,0,25)NG319.Parent=NG317
NG320=Instance.new("TextButton") NG320.Active=true
NG320.AutoButtonColor=false NG320.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG320.BackgroundTransparency=1
NG320.BorderSizePixel=0 NG320.Selectable=true
NG320.Size=UDim2.new(1,0,1,0) NG320.Style=Enum.ButtonStyle.Custom
NG320.ZIndex=2
NG320.Font=Enum.Font.Legacy NG320.FontSize=Enum.FontSize.Size8
NG320.Text=dCD([=[]=])NG320.Parent=NG319 NG321=Instance.new("ImageLabel")NG321.Active=false NG321.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG321.BackgroundTransparency=1
NG321.BorderSizePixel=0 NG321.Name=dCD([=[Onpxtebhaq]=])NG321.Selectable=false
NG321.Size=UDim2.new(1,0,1,0) NG321.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG321.Parent=NG319
NG322=Instance.new("Frame") NG322.BorderSizePixel=0
NG322.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG322.Position=UDim2.new(0,3,0,-2)NG322.Size=UDim2.new(1,-3,0,2)NG322.Parent=NG319 NG323=Instance.new("TextBox") NG323.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG323.BackgroundTransparency=1
NG323.BorderSizePixel=0 NG323.Position=UDim2.new(0,5,0,0)NG323.Size=UDim2.new(1,-10,1,0) NG323.Font=Enum.Font.ArialBold
NG323.FontSize=Enum.FontSize.Size10
NG323.Text=dCD([=[1]=]) NG323.TextColor3=Color3.new(1,1,1)NG323.Parent=NG319
NG324=Instance.new("Frame") NG324.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG324.BackgroundTransparency=1
NG324.BorderSizePixel=0 NG324.Name=dCD([=[NatyrBcgvba]=])NG324.Position=UDim2.new(0,115,0,46) NG324.Size=UDim2.new(1,-115,0,25)NG324.Parent=NG294
NG325=Instance.new("TextLabel") NG325.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG325.BackgroundTransparency=1
NG325.BorderSizePixel=0 NG325.Name=dCD([=[Ynory]=])NG325.Size=UDim2.new(0,70,0,25) NG325.Font=Enum.Font.ArialBold
NG325.FontSize=Enum.FontSize.Size10
NG325.Text=dCD([=[Natyr]=]) NG325.TextColor3=Color3.new(1,1,1)NG325.TextStrokeTransparency=0
NG325.TextWrapped=true NG325.TextXAlignment=Enum.TextXAlignment.Left
NG325.Parent=NG324
NG326=Instance.new("Frame") NG326.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG326.BackgroundTransparency=1
NG326.BorderSizePixel=0 NG326.Name=dCD([=[Vachg]=])NG326.Position=UDim2.new(0,35,0,0) NG326.Size=UDim2.new(0,38,0,25)NG326.Parent=NG324
NG327=Instance.new("TextButton") NG327.Active=true
NG327.AutoButtonColor=false NG327.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG327.BackgroundTransparency=1
NG327.BorderSizePixel=0 NG327.Selectable=true
NG327.Size=UDim2.new(1,0,1,0) NG327.Style=Enum.ButtonStyle.Custom
NG327.ZIndex=2
NG327.Font=Enum.Font.Legacy NG327.FontSize=Enum.FontSize.Size8
NG327.Text=dCD([=[]=])NG327.Parent=NG326 NG328=Instance.new("ImageLabel")NG328.Active=false NG328.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG328.BackgroundTransparency=1
NG328.BorderSizePixel=0 NG328.Name=dCD([=[Onpxtebhaq]=])NG328.Selectable=false
NG328.Size=UDim2.new(1,0,1,0) NG328.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG328.Parent=NG326
NG329=Instance.new("Frame") NG329.BorderSizePixel=0
NG329.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG329.Position=UDim2.new(0,3,0,-2)NG329.Size=UDim2.new(1,-3,0,2)NG329.Parent=NG326 NG330=Instance.new("TextBox") NG330.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG330.BackgroundTransparency=1
NG330.BorderSizePixel=0 NG330.Position=UDim2.new(0,5,0,0)NG330.Size=UDim2.new(1,-10,1,0) NG330.Font=Enum.Font.ArialBold
NG330.FontSize=Enum.FontSize.Size10
NG330.Text=dCD([=[90]=]) NG330.TextColor3=Color3.new(1,1,1)NG330.Parent=NG326
NG331=Instance.new("Frame") NG331.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG331.BackgroundTransparency=1
NG331.BorderSizePixel=0 NG331.Name=dCD([=[EnatrBcgvba]=])NG331.Position=UDim2.new(0,0,0,80) NG331.Size=UDim2.new(1,0,0,25)NG331.Parent=NG294
NG332=Instance.new("TextLabel") NG332.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG332.BackgroundTransparency=1
NG332.BorderSizePixel=0 NG332.Name=dCD([=[Ynory]=])NG332.Size=UDim2.new(0,70,0,25) NG332.Font=Enum.Font.ArialBold
NG332.FontSize=Enum.FontSize.Size10
NG332.Text=dCD([=[Enatr]=]) NG332.TextColor3=Color3.new(1,1,1)NG332.TextStrokeTransparency=0
NG332.TextWrapped=true NG332.TextXAlignment=Enum.TextXAlignment.Left
NG332.Parent=NG331
NG333=Instance.new("Frame") NG333.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG333.BackgroundTransparency=1
NG333.BorderSizePixel=0 NG333.Name=dCD([=[Vachg]=])NG333.Position=UDim2.new(0,40,0,0) NG333.Size=UDim2.new(0,38,0,25)NG333.Parent=NG331
NG334=Instance.new("TextButton") NG334.Active=true
NG334.AutoButtonColor=false NG334.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG334.BackgroundTransparency=1
NG334.BorderSizePixel=0 NG334.Selectable=true
NG334.Size=UDim2.new(1,0,1,0) NG334.Style=Enum.ButtonStyle.Custom
NG334.ZIndex=2
NG334.Font=Enum.Font.Legacy NG334.FontSize=Enum.FontSize.Size8
NG334.Text=dCD([=[]=])NG334.Parent=NG333 NG335=Instance.new("ImageLabel")NG335.Active=false NG335.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG335.BackgroundTransparency=1
NG335.BorderSizePixel=0 NG335.Name=dCD([=[Onpxtebhaq]=])NG335.Selectable=false
NG335.Size=UDim2.new(1,0,1,0) NG335.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG335.Parent=NG333
NG336=Instance.new("Frame") NG336.BorderSizePixel=0
NG336.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG336.Position=UDim2.new(0,3,0,-2)NG336.Size=UDim2.new(1,-3,0,2)NG336.Parent=NG333 NG337=Instance.new("TextBox") NG337.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG337.BackgroundTransparency=1
NG337.BorderSizePixel=0 NG337.Position=UDim2.new(0,5,0,0)NG337.Size=UDim2.new(1,-10,1,0) NG337.Font=Enum.Font.ArialBold
NG337.FontSize=Enum.FontSize.Size10
NG337.Text=dCD([=[16]=]) NG337.TextColor3=Color3.new(1,1,1)NG337.Parent=NG333
NG338=Instance.new("Frame") NG338.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG338.BackgroundTransparency=1
NG338.BorderSizePixel=0 NG338.Name=dCD([=[FvqrBcgvba]=])NG338.Position=UDim2.new(0,0,0,115) NG338.Size=UDim2.new(1,0,0,25)NG338.Parent=NG294
NG339=Instance.new("TextLabel") NG339.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG339.BackgroundTransparency=1
NG339.BorderSizePixel=0 NG339.Name=dCD([=[Ynory]=])NG339.Size=UDim2.new(0,70,0,25) NG339.Font=Enum.Font.ArialBold
NG339.FontSize=Enum.FontSize.Size10
NG339.Text=dCD([=[Fvqr]=]) NG339.TextColor3=Color3.new(1,1,1)NG339.TextStrokeTransparency=0
NG339.TextWrapped=true NG339.TextXAlignment=Enum.TextXAlignment.Left
NG339.Parent=NG338
NG340=Instance.new("Frame") NG340.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG340.BackgroundTransparency=1
NG340.BorderSizePixel=0 NG340.Name=dCD([=[FunqbjfBcgvba]=])NG340.Position=UDim2.new(0,0,0,150) NG340.Size=UDim2.new(1,0,0,25)NG340.Parent=NG294
NG341=Instance.new("TextLabel") NG341.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG341.BackgroundTransparency=1
NG341.BorderSizePixel=0 NG341.Name=dCD([=[Ynory]=])NG341.Size=UDim2.new(0,50,0,25) NG341.Font=Enum.Font.ArialBold
NG341.FontSize=Enum.FontSize.Size10
NG341.Text=dCD([=[Funqbjf]=]) NG341.TextColor3=Color3.new(1,1,1)NG341.TextStrokeTransparency=0
NG341.TextWrapped=true NG341.TextXAlignment=Enum.TextXAlignment.Left
NG341.Parent=NG340
NG342=Instance.new("Frame") NG342.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG342.BackgroundTransparency=1
NG342.BorderSizePixel=0 NG342.Name=dCD([=[Ba]=])NG342.Position=UDim2.new(0,55,0,0) NG342.Size=UDim2.new(0,45,0,25)NG342.Parent=NG340
NG343=Instance.new("Frame") NG343.BackgroundTransparency=1
NG343.BorderSizePixel=0
NG343.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG343.Position=UDim2.new(0,4,0, -2)NG343.Size=UDim2.new(1,-4,0,2) NG343.Parent=NG342
NG344=Instance.new("TextButton")NG344.Active=true NG344.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG344.BackgroundTransparency=1
NG344.BorderSizePixel=0 NG344.Name=dCD([=[Ohggba]=])NG344.Position=UDim2.new(0,5,0,0)NG344.Selectable=true
NG344.Size=UDim2.new(1, -10,1,0) NG344.Style=Enum.ButtonStyle.Custom
NG344.ZIndex=2
NG344.Font=Enum.Font.Legacy NG344.FontSize=Enum.FontSize.Size8
NG344.Text=dCD([=[]=])NG344.TextTransparency=1
NG344.Parent=NG342 NG345=Instance.new("ImageLabel")NG345.Active=false NG345.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG345.BackgroundTransparency=1
NG345.BorderSizePixel=0 NG345.Name=dCD([=[Onpxtebhaq]=])NG345.Selectable=false
NG345.Size=UDim2.new(1,0,1,0) NG345.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG345.Parent=NG342
NG346=Instance.new("TextLabel") NG346.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG346.BackgroundTransparency=1
NG346.BorderSizePixel=0 NG346.Name=dCD([=[Ynory]=])NG346.Size=UDim2.new(1,0,1,0) NG346.Font=Enum.Font.ArialBold
NG346.FontSize=Enum.FontSize.Size10
NG346.Text=dCD([=[BA]=]) NG346.TextColor3=Color3.new(1,1,1)NG346.Parent=NG342
NG347=Instance.new("Frame") NG347.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG347.BackgroundTransparency=1
NG347.BorderSizePixel=0 NG347.Name=dCD([=[Bss]=])NG347.Position=UDim2.new(0,100,0,0) NG347.Size=UDim2.new(0,45,0,25)NG347.Parent=NG340
NG348=Instance.new("Frame") NG348.BackgroundTransparency=1
NG348.BorderSizePixel=0
NG348.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG348.Position=UDim2.new(0,4,0, -2)NG348.Size=UDim2.new(1,-4,0,2) NG348.Parent=NG347
NG349=Instance.new("TextButton")NG349.Active=true NG349.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG349.BackgroundTransparency=1
NG349.BorderSizePixel=0 NG349.Name=dCD([=[Ohggba]=])NG349.Position=UDim2.new(0,5,0,0)NG349.Selectable=true
NG349.Size=UDim2.new(1, -10,1,0) NG349.Style=Enum.ButtonStyle.Custom
NG349.ZIndex=2
NG349.Font=Enum.Font.Legacy NG349.FontSize=Enum.FontSize.Size8
NG349.Text=dCD([=[]=])NG349.TextTransparency=1
NG349.Parent=NG347 NG350=Instance.new("ImageLabel")NG350.Active=false NG350.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG350.BackgroundTransparency=1
NG350.BorderSizePixel=0 NG350.Name=dCD([=[Onpxtebhaq]=])NG350.Selectable=false
NG350.Size=UDim2.new(1,0,1,0) NG350.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG350.Parent=NG347
NG351=Instance.new("TextLabel") NG351.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG351.BackgroundTransparency=1
NG351.BorderSizePixel=0 NG351.Name=dCD([=[Ynory]=])NG351.Size=UDim2.new(1,0,1,0) NG351.Font=Enum.Font.ArialBold
NG351.FontSize=Enum.FontSize.Size10
NG351.Text=dCD([=[BSS]=]) NG351.TextColor3=Color3.new(1,1,1)NG351.Parent=NG347
NG352=Instance.new("TextLabel") NG352.BackgroundTransparency=1
NG352.BorderSizePixel=0
NG352.Name=dCD([=[FryrpgAbgr]=]) NG352.Position=UDim2.new(0,10,0,27)NG352.Size=UDim2.new(1,-10,0,15)NG352.Visible=false NG352.FontSize=Enum.FontSize.Size14
NG352.Text=dCD([=[Fryrpg fbzrguvat gb hfr guvf gbby.]=]) NG352.TextColor3=Color3.new(1,1,1)NG352.TextScaled=true
NG352.TextStrokeTransparency=0.5 NG352.TextWrapped=true
NG352.TextXAlignment=Enum.TextXAlignment.Left NG352.Parent=NG281
NG353=Instance.new("Frame") NG353.BackgroundColor3=Color3.new(0,0,0)NG353.BackgroundTransparency=0.67500001192093
NG353.BorderSizePixel=0 NG353.Name=dCD([=[CbvagYvtug]=])NG353.Position=UDim2.new(0,10,0,60) NG353.Size=UDim2.new(1,-10,0,25)NG353.Parent=NG281
NG354=Instance.new("TextLabel") NG354.BackgroundTransparency=1
NG354.BorderSizePixel=0
NG354.Name=dCD([=[Ynory]=]) NG354.Position=UDim2.new(0,35,0,0)NG354.Size=UDim2.new(0,60,0,25) NG354.Font=Enum.Font.ArialBold
NG354.FontSize=Enum.FontSize.Size10 NG354.Text=dCD([=[Cbvag yvtug]=])NG354.TextColor3=Color3.new(1,1,1) NG354.TextStrokeTransparency=0.5
NG354.TextWrapped=true NG354.TextXAlignment=Enum.TextXAlignment.Left
NG354.Parent=NG353
NG355=Instance.new("ImageButton") NG355.BackgroundTransparency=1
NG355.BorderSizePixel=0
NG355.Name=dCD([=[NeebjOhggba]=]) NG355.Position=UDim2.new(0,10,0,3)NG355.Size=UDim2.new(0,20,0,20) NG355.Style=Enum.ButtonStyle.Custom
NG355.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=134367382]=]) NG355.Parent=NG353
NG356=Instance.new("Frame") NG356.BackgroundColor3=Color3.new(0.85098,0,1)NG356.BorderSizePixel=0
NG356.Name=dCD([=[PbybeOne]=]) NG356.Size=UDim2.new(0,3,1,0)NG356.Parent=NG353
NG357=Instance.new("TextButton") NG357.Active=true
NG357.BackgroundColor3=Color3.new(0,0,0) NG357.BackgroundTransparency=0.75
NG357.BorderColor3=Color3.new(0,0,0)NG357.BorderSizePixel=0 NG357.Name=dCD([=[NqqOhggba]=])NG357.Position=UDim2.new(1,-40,0,3)NG357.Selectable=true NG357.Size=UDim2.new(0,35,0,19)NG357.Style=Enum.ButtonStyle.Custom NG357.Font=Enum.Font.ArialBold
NG357.FontSize=Enum.FontSize.Size10
NG357.Text=dCD([=[NQQ]=]) NG357.TextColor3=Color3.new(1,1,1)NG357.Parent=NG353
NG358=Instance.new("TextButton") NG358.Active=true
NG358.BackgroundColor3=Color3.new(0,0,0) NG358.BackgroundTransparency=0.75
NG358.BorderColor3=Color3.new(0,0,0)NG358.BorderSizePixel=0 NG358.Name=dCD([=[ErzbirOhggba]=])NG358.Position=UDim2.new(0,90,0,3)NG358.Selectable=true NG358.Size=UDim2.new(0,58,0,19)NG358.Style=Enum.ButtonStyle.Custom
NG358.Visible=false NG358.Font=Enum.Font.ArialBold
NG358.FontSize=Enum.FontSize.Size10
NG358.Text=dCD([=[ERZBIR]=]) NG358.TextColor3=Color3.new(1,1,1)NG358.Parent=NG353
NG359=Instance.new("Frame") NG359.BackgroundColor3=Color3.new(0,0,0)NG359.BackgroundTransparency=0.75
NG359.BorderSizePixel=0 NG359.Name=dCD([=[Funqbj]=])NG359.Position=UDim2.new(0,0,1,-1) NG359.Size=UDim2.new(1,0,0,1)NG359.Parent=NG353
NG360=Instance.new("Frame") NG360.BackgroundTransparency=1
NG360.BorderSizePixel=0
NG360.Name=dCD([=[Bcgvbaf]=]) NG360.Position=UDim2.new(0,3,1,0)NG360.Size=UDim2.new(1,-3,0,0)NG360.ClipsDescendants=true NG360.Parent=NG353
NG361=Instance.new("Frame") NG361.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG361.BackgroundTransparency=1
NG361.BorderSizePixel=0 NG361.Name=dCD([=[PbybeBcgvba]=])NG361.Position=UDim2.new(0,0,0,10) NG361.Size=UDim2.new(1,0,0,25)NG361.Parent=NG360
NG362=Instance.new("TextLabel") NG362.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG362.BackgroundTransparency=1
NG362.BorderSizePixel=0 NG362.Name=dCD([=[Ynory]=])NG362.Size=UDim2.new(0,70,0,25) NG362.Font=Enum.Font.ArialBold
NG362.FontSize=Enum.FontSize.Size10
NG362.Text=dCD([=[Pbybe]=]) NG362.TextColor3=Color3.new(1,1,1)NG362.TextStrokeTransparency=0
NG362.TextWrapped=true NG362.TextXAlignment=Enum.TextXAlignment.Left
NG362.Parent=NG361
NG363=Instance.new("Frame") NG363.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG363.BackgroundTransparency=1
NG363.BorderSizePixel=0 NG363.Name=dCD([=[EVachg]=])NG363.Position=UDim2.new(0,35,0,0) NG363.Size=UDim2.new(0,38,0,25)NG363.Parent=NG361
NG364=Instance.new("TextButton") NG364.Active=true
NG364.AutoButtonColor=false NG364.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG364.BackgroundTransparency=1
NG364.BorderSizePixel=0 NG364.Selectable=true
NG364.Size=UDim2.new(1,0,1,0) NG364.Style=Enum.ButtonStyle.Custom
NG364.ZIndex=2
NG364.Font=Enum.Font.Legacy NG364.FontSize=Enum.FontSize.Size8
NG364.Text=dCD([=[]=])NG364.Parent=NG363 NG365=Instance.new("ImageLabel")NG365.Active=false NG365.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG365.BackgroundTransparency=1
NG365.BorderSizePixel=0 NG365.Name=dCD([=[Onpxtebhaq]=])NG365.Selectable=false
NG365.Size=UDim2.new(1,0,1,0) NG365.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG365.Parent=NG363
NG366=Instance.new("Frame") NG366.BackgroundColor3=Color3.new(1,0,0)NG366.BorderSizePixel=0
NG366.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG366.Position=UDim2.new(0,3,0, -2)NG366.Size=UDim2.new(1,-3,0,2) NG366.Parent=NG363
NG367=Instance.new("TextBox") NG367.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG367.BackgroundTransparency=1
NG367.BorderSizePixel=0 NG367.Position=UDim2.new(0,5,0,0)NG367.Size=UDim2.new(1,-10,1,0) NG367.Font=Enum.Font.ArialBold
NG367.FontSize=Enum.FontSize.Size10
NG367.Text=dCD([=[255]=]) NG367.TextColor3=Color3.new(1,1,1)NG367.Parent=NG363
NG368=Instance.new("Frame") NG368.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG368.BackgroundTransparency=1
NG368.BorderSizePixel=0 NG368.Name=dCD([=[TVachg]=])NG368.Position=UDim2.new(0,72,0,0) NG368.Size=UDim2.new(0,38,0,25)NG368.Parent=NG361
NG369=Instance.new("TextButton") NG369.Active=true
NG369.AutoButtonColor=false NG369.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG369.BackgroundTransparency=1
NG369.BorderSizePixel=0 NG369.Selectable=true
NG369.Size=UDim2.new(1,0,1,0) NG369.Style=Enum.ButtonStyle.Custom
NG369.ZIndex=2
NG369.Font=Enum.Font.Legacy NG369.FontSize=Enum.FontSize.Size8
NG369.Text=dCD([=[]=])NG369.Parent=NG368 NG370=Instance.new("ImageLabel")NG370.Active=false NG370.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG370.BackgroundTransparency=1
NG370.BorderSizePixel=0 NG370.Name=dCD([=[Onpxtebhaq]=])NG370.Selectable=false
NG370.Size=UDim2.new(1,0,1,0) NG370.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG370.Parent=NG368
NG371=Instance.new("Frame") NG371.BackgroundColor3=Color3.new(0,1,0)NG371.BorderSizePixel=0
NG371.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG371.Position=UDim2.new(0,3,0, -2)NG371.Size=UDim2.new(1,-3,0,2) NG371.Parent=NG368
NG372=Instance.new("TextBox") NG372.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG372.BackgroundTransparency=1
NG372.BorderSizePixel=0 NG372.Position=UDim2.new(0,5,0,0)NG372.Size=UDim2.new(1,-10,1,0) NG372.Font=Enum.Font.ArialBold
NG372.FontSize=Enum.FontSize.Size10
NG372.Text=dCD([=[255]=]) NG372.TextColor3=Color3.new(1,1,1)NG372.Parent=NG368
NG373=Instance.new("Frame") NG373.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG373.BackgroundTransparency=1
NG373.BorderSizePixel=0 NG373.Name=dCD([=[OVachg]=])NG373.Position=UDim2.new(0,109,0,0) NG373.Size=UDim2.new(0,38,0,25)NG373.Parent=NG361
NG374=Instance.new("TextButton") NG374.Active=true
NG374.AutoButtonColor=false NG374.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG374.BackgroundTransparency=1
NG374.BorderSizePixel=0 NG374.Selectable=true
NG374.Size=UDim2.new(1,0,1,0) NG374.Style=Enum.ButtonStyle.Custom
NG374.ZIndex=2
NG374.Font=Enum.Font.Legacy NG374.FontSize=Enum.FontSize.Size8
NG374.Text=dCD([=[]=])NG374.Parent=NG373 NG375=Instance.new("ImageLabel")NG375.Active=false NG375.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG375.BackgroundTransparency=1
NG375.BorderSizePixel=0 NG375.Name=dCD([=[Onpxtebhaq]=])NG375.Selectable=false
NG375.Size=UDim2.new(1,0,1,0) NG375.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG375.Parent=NG373
NG376=Instance.new("Frame") NG376.BackgroundColor3=Color3.new(0,0,1)NG376.BorderSizePixel=0
NG376.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG376.Position=UDim2.new(0,3,0, -2)NG376.Size=UDim2.new(1,-3,0,2) NG376.Parent=NG373
NG377=Instance.new("TextBox") NG377.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG377.BackgroundTransparency=1
NG377.BorderSizePixel=0 NG377.Position=UDim2.new(0,5,0,0)NG377.Size=UDim2.new(1,-10,1,0) NG377.Font=Enum.Font.ArialBold
NG377.FontSize=Enum.FontSize.Size10
NG377.Text=dCD([=[255]=]) NG377.TextColor3=Color3.new(1,1,1)NG377.Parent=NG373
NG378=Instance.new("ImageButton") NG378.BackgroundColor3=Color3.new(0,0,0)NG378.BackgroundTransparency=0.40000000596046
NG378.BorderSizePixel=0 NG378.Name=dCD([=[UFICvpxre]=])NG378.Position=UDim2.new(0,160,0,-2) NG378.Size=UDim2.new(0,27,0,27)NG378.Style=Enum.ButtonStyle.Custom
NG378.ZIndex=2 NG378.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141313631]=])NG378.Parent=NG361
NG379=Instance.new("Frame") NG379.BackgroundColor3=Color3.new(0,0,0)NG379.BackgroundTransparency=0.75
NG379.BorderSizePixel=0 NG379.Name=dCD([=[Funqbj]=])NG379.Position=UDim2.new(0,0,1,-2) NG379.Size=UDim2.new(1,0,0,2)NG379.Parent=NG378
NG380=Instance.new("Frame") NG380.BackgroundColor3=Color3.new(0,0,0)NG380.BackgroundTransparency=0.5 NG380.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG380.BorderSizePixel=0
NG380.Name=dCD([=[Frcnengbe]=]) NG380.Position=UDim2.new(0,151,0,4)NG380.Size=UDim2.new(0,4,0,4)NG380.Parent=NG361 NG381=Instance.new("Frame")NG381.BackgroundColor3=Color3.new(0,0,0) NG381.BackgroundTransparency=0.5 NG381.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG381.BorderSizePixel=0
NG381.Name=dCD([=[Frcnengbe]=]) NG381.Position=UDim2.new(0,151,0,16)NG381.Size=UDim2.new(0,4,0,4)NG381.Parent=NG361 NG382=Instance.new("Frame")NG382.BackgroundColor3=Color3.new(0,0,0) NG382.BackgroundTransparency=0.5 NG382.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG382.BorderSizePixel=0
NG382.Name=dCD([=[Frcnengbe]=]) NG382.Position=UDim2.new(0,151,0,10)NG382.Size=UDim2.new(0,4,0,4)NG382.Parent=NG361 NG383=Instance.new("Frame") NG383.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG383.BackgroundTransparency=1
NG383.BorderSizePixel=0 NG383.Name=dCD([=[OevtugarffBcgvba]=])NG383.Position=UDim2.new(0,0,0,45) NG383.Size=UDim2.new(1,0,0,25)NG383.Parent=NG360
NG384=Instance.new("TextLabel") NG384.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG384.BackgroundTransparency=1
NG384.BorderSizePixel=0 NG384.Name=dCD([=[Ynory]=])NG384.Size=UDim2.new(0,70,0,25) NG384.Font=Enum.Font.ArialBold
NG384.FontSize=Enum.FontSize.Size10 NG384.Text=dCD([=[Oevtugarff]=])NG384.TextColor3=Color3.new(1,1,1) NG384.TextStrokeTransparency=0
NG384.TextWrapped=true NG384.TextXAlignment=Enum.TextXAlignment.Left
NG384.Parent=NG383
NG385=Instance.new("Frame") NG385.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG385.BackgroundTransparency=1
NG385.BorderSizePixel=0 NG385.Name=dCD([=[Vachg]=])NG385.Position=UDim2.new(0,60,0,0) NG385.Size=UDim2.new(0,38,0,25)NG385.Parent=NG383
NG386=Instance.new("TextButton") NG386.Active=true
NG386.AutoButtonColor=false NG386.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG386.BackgroundTransparency=1
NG386.BorderSizePixel=0 NG386.Selectable=true
NG386.Size=UDim2.new(1,0,1,0) NG386.Style=Enum.ButtonStyle.Custom
NG386.ZIndex=2
NG386.Font=Enum.Font.Legacy NG386.FontSize=Enum.FontSize.Size8
NG386.Text=dCD([=[]=])NG386.Parent=NG385 NG387=Instance.new("ImageLabel")NG387.Active=false NG387.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG387.BackgroundTransparency=1
NG387.BorderSizePixel=0 NG387.Name=dCD([=[Onpxtebhaq]=])NG387.Selectable=false
NG387.Size=UDim2.new(1,0,1,0) NG387.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG387.Parent=NG385
NG388=Instance.new("Frame") NG388.BorderSizePixel=0
NG388.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG388.Position=UDim2.new(0,3,0,-2)NG388.Size=UDim2.new(1,-3,0,2)NG388.Parent=NG385 NG389=Instance.new("TextBox") NG389.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG389.BackgroundTransparency=1
NG389.BorderSizePixel=0 NG389.Position=UDim2.new(0,5,0,0)NG389.Size=UDim2.new(1,-10,1,0) NG389.Font=Enum.Font.ArialBold
NG389.FontSize=Enum.FontSize.Size10
NG389.Text=dCD([=[1]=]) NG389.TextColor3=Color3.new(1,1,1)NG389.Parent=NG385
NG390=Instance.new("Frame") NG390.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG390.BackgroundTransparency=1
NG390.BorderSizePixel=0 NG390.Name=dCD([=[EnatrBcgvba]=])NG390.Position=UDim2.new(0,110,0,45) NG390.Size=UDim2.new(1,0,0,25)NG390.Parent=NG360
NG391=Instance.new("TextLabel") NG391.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG391.BackgroundTransparency=1
NG391.BorderSizePixel=0 NG391.Name=dCD([=[Ynory]=])NG391.Size=UDim2.new(0,70,0,25) NG391.Font=Enum.Font.ArialBold
NG391.FontSize=Enum.FontSize.Size10
NG391.Text=dCD([=[Enatr]=]) NG391.TextColor3=Color3.new(1,1,1)NG391.TextStrokeTransparency=0
NG391.TextWrapped=true NG391.TextXAlignment=Enum.TextXAlignment.Left
NG391.Parent=NG390
NG392=Instance.new("Frame") NG392.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG392.BackgroundTransparency=1
NG392.BorderSizePixel=0 NG392.Name=dCD([=[Vachg]=])NG392.Position=UDim2.new(0,40,0,0) NG392.Size=UDim2.new(0,38,0,25)NG392.Parent=NG390
NG393=Instance.new("TextButton") NG393.Active=true
NG393.AutoButtonColor=false NG393.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG393.BackgroundTransparency=1
NG393.BorderSizePixel=0 NG393.Selectable=true
NG393.Size=UDim2.new(1,0,1,0) NG393.Style=Enum.ButtonStyle.Custom
NG393.ZIndex=2
NG393.Font=Enum.Font.Legacy NG393.FontSize=Enum.FontSize.Size8
NG393.Text=dCD([=[]=])NG393.Parent=NG392 NG394=Instance.new("ImageLabel")NG394.Active=false NG394.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG394.BackgroundTransparency=1
NG394.BorderSizePixel=0 NG394.Name=dCD([=[Onpxtebhaq]=])NG394.Selectable=false
NG394.Size=UDim2.new(1,0,1,0) NG394.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG394.Parent=NG392
NG395=Instance.new("Frame") NG395.BorderSizePixel=0
NG395.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG395.Position=UDim2.new(0,3,0,-2)NG395.Size=UDim2.new(1,-3,0,2)NG395.Parent=NG392 NG396=Instance.new("TextBox") NG396.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG396.BackgroundTransparency=1
NG396.BorderSizePixel=0 NG396.Position=UDim2.new(0,5,0,0)NG396.Size=UDim2.new(1,-10,1,0) NG396.Font=Enum.Font.ArialBold
NG396.FontSize=Enum.FontSize.Size10
NG396.Text=dCD([=[16]=]) NG396.TextColor3=Color3.new(1,1,1)NG396.Parent=NG392
NG397=Instance.new("Frame") NG397.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG397.BackgroundTransparency=1
NG397.BorderSizePixel=0 NG397.Name=dCD([=[FunqbjfBcgvba]=])NG397.Position=UDim2.new(0,0,0,80) NG397.Size=UDim2.new(0,0,0,0)NG397.Parent=NG360
NG398=Instance.new("TextLabel") NG398.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG398.BackgroundTransparency=1
NG398.BorderSizePixel=0 NG398.Name=dCD([=[Ynory]=])NG398.Size=UDim2.new(0,50,0,25) NG398.Font=Enum.Font.ArialBold
NG398.FontSize=Enum.FontSize.Size10
NG398.Text=dCD([=[Funqbjf]=]) NG398.TextColor3=Color3.new(1,1,1)NG398.TextStrokeTransparency=0
NG398.TextWrapped=true NG398.TextXAlignment=Enum.TextXAlignment.Left
NG398.Parent=NG397
NG399=Instance.new("Frame") NG399.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG399.BackgroundTransparency=1
NG399.BorderSizePixel=0 NG399.Name=dCD([=[Ba]=])NG399.Position=UDim2.new(0,55,0,0) NG399.Size=UDim2.new(0,45,0,25)NG399.Parent=NG397
NG400=Instance.new("Frame") NG400.BackgroundTransparency=1
NG400.BorderSizePixel=0
NG400.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG400.Position=UDim2.new(0,4,0, -2)NG400.Size=UDim2.new(1,-4,0,2) NG400.Parent=NG399
NG401=Instance.new("TextButton")NG401.Active=true NG401.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG401.BackgroundTransparency=1
NG401.BorderSizePixel=0 NG401.Name=dCD([=[Ohggba]=])NG401.Position=UDim2.new(0,5,0,0)NG401.Selectable=true
NG401.Size=UDim2.new(1, -10,1,0) NG401.Style=Enum.ButtonStyle.Custom
NG401.ZIndex=2
NG401.Font=Enum.Font.Legacy NG401.FontSize=Enum.FontSize.Size8
NG401.Text=dCD([=[]=])NG401.TextTransparency=1
NG401.Parent=NG399 NG402=Instance.new("ImageLabel")NG402.Active=false NG402.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG402.BackgroundTransparency=1
NG402.BorderSizePixel=0 NG402.Name=dCD([=[Onpxtebhaq]=])NG402.Selectable=false
NG402.Size=UDim2.new(1,0,1,0) NG402.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG402.Parent=NG399
NG403=Instance.new("TextLabel") NG403.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG403.BackgroundTransparency=1
NG403.BorderSizePixel=0 NG403.Name=dCD([=[Ynory]=])NG403.Size=UDim2.new(1,0,1,0) NG403.Font=Enum.Font.ArialBold
NG403.FontSize=Enum.FontSize.Size10
NG403.Text=dCD([=[BA]=]) NG403.TextColor3=Color3.new(1,1,1)NG403.Parent=NG399
NG404=Instance.new("Frame") NG404.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG404.BackgroundTransparency=1
NG404.BorderSizePixel=0 NG404.Name=dCD([=[Bss]=])NG404.Position=UDim2.new(0,100,0,0) NG404.Size=UDim2.new(0,45,0,25)NG404.Parent=NG397
NG405=Instance.new("Frame") NG405.BackgroundTransparency=1
NG405.BorderSizePixel=0
NG405.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG405.Position=UDim2.new(0,4,0, -2)NG405.Size=UDim2.new(1,-4,0,2) NG405.Parent=NG404
NG406=Instance.new("TextButton")NG406.Active=true NG406.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG406.BackgroundTransparency=1
NG406.BorderSizePixel=0 NG406.Name=dCD([=[Ohggba]=])NG406.Position=UDim2.new(0,5,0,0)NG406.Selectable=true
NG406.Size=UDim2.new(1, -10,1,0) NG406.Style=Enum.ButtonStyle.Custom
NG406.ZIndex=2
NG406.Font=Enum.Font.Legacy NG406.FontSize=Enum.FontSize.Size8
NG406.Text=dCD([=[]=])NG406.TextTransparency=1
NG406.Parent=NG404 NG407=Instance.new("ImageLabel")NG407.Active=false NG407.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG407.BackgroundTransparency=1
NG407.BorderSizePixel=0 NG407.Name=dCD([=[Onpxtebhaq]=])NG407.Selectable=false
NG407.Size=UDim2.new(1,0,1,0) NG407.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG407.Parent=NG404
NG408=Instance.new("TextLabel") NG408.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG408.BackgroundTransparency=1
NG408.BorderSizePixel=0 NG408.Name=dCD([=[Ynory]=])NG408.Size=UDim2.new(1,0,1,0) NG408.Font=Enum.Font.ArialBold
NG408.FontSize=Enum.FontSize.Size10
NG408.Text=dCD([=[BSS]=]) NG408.TextColor3=Color3.new(1,1,1)NG408.Parent=NG404
NG409=Instance.new("Frame") NG409.Active=true
NG409.BackgroundColor3=Color3.new(0,0,0) NG409.BackgroundTransparency=0.89999997615814
NG409.BorderSizePixel=0
NG409.Name=dCD([=[OGUFIPbybeCvpxre]=]) NG409.Position=UDim2.new(0,220,0,116)NG409.Size=UDim2.new(0,250,0,380)NG409.Draggable=true NG409.Parent=NG1
NG410=Instance.new("ImageButton") NG410.BorderColor3=Color3.new(0.207843,0.207843,0.207843)NG410.Name=dCD([=[UhrFnghengvba]=]) NG410.Position=UDim2.new(0,10,0,10)NG410.Size=UDim2.new(0,209,0,200) NG410.Style=Enum.ButtonStyle.Custom
NG410.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg?vq=141066192]=]) NG410.Parent=NG409
NG411=Instance.new("ImageLabel")NG411.Active=false NG411.BackgroundTransparency=1
NG411.BorderSizePixel=0
NG411.Name=dCD([=[Phefbe]=]) NG411.Position=UDim2.new(0,-8,0,194)NG411.Selectable=false
NG411.Size=UDim2.new(0,16,0,16) NG411.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141186650]=])NG411.Parent=NG410
NG412=Instance.new("ImageButton") NG412.BackgroundTransparency=1 NG412.BorderColor3=Color3.new(0.207843,0.207843,0.207843)NG412.BorderSizePixel=0
NG412.Name=dCD([=[Inyhr]=]) NG412.Position=UDim2.new(0,229,0,10)NG412.Size=UDim2.new(0,13,0,200) NG412.Style=Enum.ButtonStyle.Custom
NG412.ZIndex=2 NG412.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141066196]=])NG412.Parent=NG409
NG413=Instance.new("Frame") NG413.BorderSizePixel=0
NG413.Name=dCD([=[PbybeOT]=])NG413.Size=UDim2.new(1,0,1,0) NG413.Parent=NG412
NG414=Instance.new("ImageLabel")NG414.Active=false NG414.BackgroundTransparency=1
NG414.BorderSizePixel=0
NG414.Name=dCD([=[Phefbe]=]) NG414.Position=UDim2.new(0,-2,0,-8)NG414.Selectable=false
NG414.Size=UDim2.new(0,16,0,16) NG414.ZIndex=2
NG414.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141186650]=]) NG414.Parent=NG412
NG415=Instance.new("Frame")NG415.BackgroundTransparency=1 NG415.BorderSizePixel=0
NG415.Name=dCD([=[UhrBcgvba]=]) NG415.Position=UDim2.new(0,10,0,218)NG415.Size=UDim2.new(1,-25,0,34)NG415.Parent=NG409 NG416=Instance.new("TextLabel")NG416.BackgroundTransparency=1
NG416.BorderSizePixel=0 NG416.Name=dCD([=[Ynory]=])NG416.Position=UDim2.new(0,15,0,0) NG416.Size=UDim2.new(0,100,1,0)NG416.Font=Enum.Font.SourceSansBold NG416.FontSize=Enum.FontSize.Size18
NG416.Text=dCD([=[Uhr]=])NG416.TextColor3=Color3.new(1,1,1) NG416.TextStrokeTransparency=0.5
NG416.TextWrapped=true NG416.TextXAlignment=Enum.TextXAlignment.Left
NG416.Parent=NG415
NG417=Instance.new("Frame") NG417.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG417.BackgroundTransparency=1
NG417.BorderSizePixel=0 NG417.Name=dCD([=[Vachg]=])NG417.Position=UDim2.new(0,55,0,4) NG417.Size=UDim2.new(0,50,0,26)NG417.Parent=NG415
NG418=Instance.new("TextButton") NG418.Active=true
NG418.AutoButtonColor=false NG418.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG418.BackgroundTransparency=1
NG418.BorderSizePixel=0 NG418.Selectable=true
NG418.Size=UDim2.new(1,0,1,0) NG418.Style=Enum.ButtonStyle.Custom
NG418.ZIndex=2
NG418.Font=Enum.Font.Legacy NG418.FontSize=Enum.FontSize.Size8
NG418.Text=dCD([=[]=])NG418.Parent=NG417 NG419=Instance.new("ImageLabel")NG419.Active=false NG419.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG419.BackgroundTransparency=1
NG419.BorderSizePixel=0 NG419.Name=dCD([=[Onpxtebhaq]=])NG419.Selectable=false
NG419.Size=UDim2.new(1,0,1,0) NG419.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG419.Parent=NG417
NG420=Instance.new("TextBox") NG420.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG420.BackgroundTransparency=1
NG420.BorderSizePixel=0 NG420.Position=UDim2.new(0,5,0,0)NG420.Size=UDim2.new(1,-10,1,0) NG420.Font=Enum.Font.ArialBold
NG420.FontSize=Enum.FontSize.Size10
NG420.Text=dCD([=[360]=]) NG420.TextColor3=Color3.new(1,1,1)NG420.Parent=NG417
NG421=Instance.new("Frame") NG421.BorderSizePixel=0
NG421.Name=dCD([=[One]=])NG421.Position=UDim2.new(0,0,0,2)NG421.Size=UDim2.new(0,3,1, -4)NG421.Parent=NG415 NG422=Instance.new("Frame")NG422.BackgroundColor3=Color3.new(0,0,0) NG422.BackgroundTransparency=0.89999997615814
NG422.BorderSizePixel=0
NG422.Name=dCD([=[Funqbj]=]) NG422.Position=UDim2.new(0,0,1,-3)NG422.Size=UDim2.new(1,0,0,3)NG422.Parent=NG421 NG423=Instance.new("Frame")NG423.BackgroundTransparency=1
NG423.BorderSizePixel=0 NG423.Name=dCD([=[FnghengvbaBcgvba]=])NG423.Position=UDim2.new(0,10,0,255) NG423.Size=UDim2.new(1,-25,0,34)NG423.Parent=NG409
NG424=Instance.new("TextLabel") NG424.BackgroundTransparency=1
NG424.BorderSizePixel=0
NG424.Name=dCD([=[Ynory]=]) NG424.Position=UDim2.new(0,15,0,0)NG424.Size=UDim2.new(0,100,1,0) NG424.Font=Enum.Font.SourceSansBold
NG424.FontSize=Enum.FontSize.Size18 NG424.Text=dCD([=[Fnghengvba]=])NG424.TextColor3=Color3.new(1,1,1) NG424.TextStrokeTransparency=0.5
NG424.TextWrapped=true NG424.TextXAlignment=Enum.TextXAlignment.Left
NG424.Parent=NG423
NG425=Instance.new("Frame") NG425.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG425.BackgroundTransparency=1
NG425.BorderSizePixel=0 NG425.Name=dCD([=[Vachg]=])NG425.Position=UDim2.new(0,100,0,4) NG425.Size=UDim2.new(0,50,0,26)NG425.Parent=NG423
NG426=Instance.new("TextButton") NG426.Active=true
NG426.AutoButtonColor=false NG426.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG426.BackgroundTransparency=1
NG426.BorderSizePixel=0 NG426.Selectable=true
NG426.Size=UDim2.new(1,0,1,0) NG426.Style=Enum.ButtonStyle.Custom
NG426.ZIndex=2
NG426.Font=Enum.Font.Legacy NG426.FontSize=Enum.FontSize.Size8
NG426.Text=dCD([=[]=])NG426.Parent=NG425 NG427=Instance.new("ImageLabel")NG427.Active=false NG427.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG427.BackgroundTransparency=1
NG427.BorderSizePixel=0 NG427.Name=dCD([=[Onpxtebhaq]=])NG427.Selectable=false
NG427.Size=UDim2.new(1,0,1,0) NG427.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG427.Parent=NG425
NG428=Instance.new("TextBox") NG428.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG428.BackgroundTransparency=1
NG428.BorderSizePixel=0 NG428.Position=UDim2.new(0,5,0,0)NG428.Size=UDim2.new(1,-10,1,0) NG428.Font=Enum.Font.ArialBold
NG428.FontSize=Enum.FontSize.Size10
NG428.Text=dCD([=[100%]=]) NG428.TextColor3=Color3.new(1,1,1)NG428.Parent=NG425
NG429=Instance.new("Frame") NG429.BorderSizePixel=0
NG429.Name=dCD([=[One]=])NG429.Position=UDim2.new(0,0,0,2)NG429.Size=UDim2.new(0,3,1, -4)NG429.Parent=NG423 NG430=Instance.new("Frame")NG430.BackgroundColor3=Color3.new(0,0,0) NG430.BackgroundTransparency=0.89999997615814
NG430.BorderSizePixel=0
NG430.Name=dCD([=[Funqbj]=]) NG430.Position=UDim2.new(0,0,1,-3)NG430.Size=UDim2.new(1,0,0,3)NG430.Parent=NG429 NG431=Instance.new("Frame")NG431.BackgroundTransparency=1
NG431.BorderSizePixel=0 NG431.Name=dCD([=[InyhrBcgvba]=])NG431.Position=UDim2.new(0,10,0,292) NG431.Size=UDim2.new(1,-25,0,34)NG431.Parent=NG409
NG432=Instance.new("TextLabel") NG432.BackgroundTransparency=1
NG432.BorderSizePixel=0
NG432.Name=dCD([=[Ynory]=]) NG432.Position=UDim2.new(0,15,0,0)NG432.Size=UDim2.new(0,100,1,0) NG432.Font=Enum.Font.SourceSansBold
NG432.FontSize=Enum.FontSize.Size18 NG432.Text=dCD([=[Oevtugarff]=])NG432.TextColor3=Color3.new(1,1,1) NG432.TextStrokeTransparency=0.5
NG432.TextWrapped=true NG432.TextXAlignment=Enum.TextXAlignment.Left
NG432.Parent=NG431
NG433=Instance.new("Frame") NG433.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG433.BackgroundTransparency=1
NG433.BorderSizePixel=0 NG433.Name=dCD([=[Vachg]=])NG433.Position=UDim2.new(0,100,0,4) NG433.Size=UDim2.new(0,50,0,26)NG433.Parent=NG431
NG434=Instance.new("TextButton") NG434.Active=true
NG434.AutoButtonColor=false NG434.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG434.BackgroundTransparency=1
NG434.BorderSizePixel=0 NG434.Selectable=true
NG434.Size=UDim2.new(1,0,1,0) NG434.Style=Enum.ButtonStyle.Custom
NG434.ZIndex=2
NG434.Font=Enum.Font.Legacy NG434.FontSize=Enum.FontSize.Size8
NG434.Text=dCD([=[]=])NG434.Parent=NG433 NG435=Instance.new("ImageLabel")NG435.Active=false NG435.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG435.BackgroundTransparency=1
NG435.BorderSizePixel=0 NG435.Name=dCD([=[Onpxtebhaq]=])NG435.Selectable=false
NG435.Size=UDim2.new(1,0,1,0) NG435.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG435.Parent=NG433
NG436=Instance.new("TextBox") NG436.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG436.BackgroundTransparency=1
NG436.BorderSizePixel=0 NG436.Position=UDim2.new(0,5,0,0)NG436.Size=UDim2.new(1,-10,1,0) NG436.Font=Enum.Font.ArialBold
NG436.FontSize=Enum.FontSize.Size10
NG436.Text=dCD([=[100%]=]) NG436.TextColor3=Color3.new(1,1,1)NG436.Parent=NG433
NG437=Instance.new("Frame") NG437.BorderSizePixel=0
NG437.Name=dCD([=[One]=])NG437.Position=UDim2.new(0,0,0,2)NG437.Size=UDim2.new(0,3,1, -4)NG437.Parent=NG431 NG438=Instance.new("Frame")NG438.BackgroundColor3=Color3.new(0,0,0) NG438.BackgroundTransparency=0.89999997615814
NG438.BorderSizePixel=0
NG438.Name=dCD([=[Funqbj]=]) NG438.Position=UDim2.new(0,0,1,-3)NG438.Size=UDim2.new(1,0,0,3)NG438.Parent=NG437 NG439=Instance.new("Frame")NG439.BorderSizePixel=0
NG439.Name=dCD([=[PbybeQvfcynl]=]) NG439.Position=UDim2.new(0,180,0,220)NG439.Size=UDim2.new(0,60,0,103)NG439.Parent=NG409 NG440=Instance.new("Frame")NG440.BackgroundColor3=Color3.new(0,0,0) NG440.BackgroundTransparency=0.89999997615814
NG440.BorderSizePixel=0
NG440.Name=dCD([=[Funqbj]=]) NG440.Position=UDim2.new(0,0,1,-3)NG440.Size=UDim2.new(1,0,0,3)NG440.Parent=NG439 NG441=Instance.new("TextButton")NG441.Active=true NG441.BackgroundColor3=Color3.new(1,0.635294,0.184314)NG441.BorderSizePixel=0
NG441.Name=dCD([=[BxOhggba]=]) NG441.Position=UDim2.new(0,10,0,335)NG441.Selectable=true
NG441.Size=UDim2.new(0,140,0,30) NG441.Style=Enum.ButtonStyle.Custom
NG441.ZIndex=2
NG441.Font=Enum.Font.SourceSansBold NG441.FontSize=Enum.FontSize.Size18
NG441.Text=dCD([=[Bx]=])NG441.TextColor3=Color3.new(1,1,1) NG441.TextStrokeTransparency=0.85000002384186
NG441.Parent=NG409
NG442=Instance.new("Frame") NG442.BackgroundColor3=Color3.new(0.8,0.505882,0.145098)NG442.BorderSizePixel=0
NG442.Name=dCD([=[Oriry]=]) NG442.Position=UDim2.new(0,0,1,-2)NG442.Size=UDim2.new(1,0,0,2)NG442.ZIndex=2 NG442.Parent=NG441
NG443=Instance.new("TextButton")NG443.Active=true NG443.BackgroundColor3=Color3.new(1,0.635294,0.184314)NG443.BackgroundTransparency=0.60000002384186
NG443.BorderSizePixel=0 NG443.Name=dCD([=[PnapryOhggba]=])NG443.Position=UDim2.new(0,160,0,335)NG443.Selectable=true NG443.Size=UDim2.new(0,80,0,30)NG443.Style=Enum.ButtonStyle.Custom
NG443.ZIndex=2 NG443.Font=Enum.Font.SourceSansBold
NG443.FontSize=Enum.FontSize.Size18
NG443.Text=dCD([=[Pnapry]=]) NG443.TextColor3=Color3.new(1,1,1)NG443.TextStrokeTransparency=0.85000002384186
NG443.Parent=NG409 NG444=Instance.new("Frame") NG444.BackgroundColor3=Color3.new(0.8,0.505882,0.145098)NG444.BackgroundTransparency=0.60000002384186
NG444.BorderSizePixel=0 NG444.Name=dCD([=[Oriry]=])NG444.Position=UDim2.new(0,0,1,-2) NG444.Size=UDim2.new(1,0,0,2)NG444.ZIndex=2
NG444.Parent=NG443 NG445=Instance.new("Frame")NG445.Active=true NG445.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG445.BackgroundTransparency=1
NG445.BorderSizePixel=0 NG445.Name=dCD([=[OGZrfuGbbyTHV]=])NG445.Position=UDim2.new(0,0,0,172) NG445.Size=UDim2.new(0,200,0,55)NG445.Draggable=true
NG445.Parent=NG1 NG446=Instance.new("Frame") NG446.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG446.BackgroundTransparency=1
NG446.BorderSizePixel=0 NG446.Name=dCD([=[Gvgyr]=])NG446.Size=UDim2.new(1,0,0,20)NG446.Parent=NG445 NG447=Instance.new("Frame") NG447.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG447.BorderSizePixel=0
NG447.Name=dCD([=[PbybeOne]=]) NG447.Position=UDim2.new(0,5,0,-3)NG447.Size=UDim2.new(1,-5,0,2)NG447.Parent=NG446 NG448=Instance.new("TextLabel") NG448.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG448.BackgroundTransparency=1
NG448.BorderSizePixel=0 NG448.Name=dCD([=[Ynory]=])NG448.Position=UDim2.new(0,10,0,1) NG448.Size=UDim2.new(1,-10,1,0)NG448.Font=Enum.Font.ArialBold NG448.FontSize=Enum.FontSize.Size10
NG448.Text=dCD([=[ZRFU GBBY]=]) NG448.TextColor3=Color3.new(1,1,1)NG448.TextStrokeTransparency=0
NG448.TextWrapped=true NG448.TextXAlignment=Enum.TextXAlignment.Left
NG448.Parent=NG446
NG449=Instance.new("TextLabel") NG449.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG449.BackgroundTransparency=1
NG449.BorderSizePixel=0 NG449.Name=dCD([=[S3KFvtangher]=])NG449.Position=UDim2.new(0,10,0,1) NG449.Size=UDim2.new(1,-10,1,0)NG449.Font=Enum.Font.ArialBold NG449.FontSize=Enum.FontSize.Size14
NG449.Text=dCD([=[S3K]=])NG449.TextColor3=Color3.new(1,1,1) NG449.TextStrokeTransparency=0.89999997615814
NG449.TextWrapped=true NG449.TextXAlignment=Enum.TextXAlignment.Right
NG449.Parent=NG446
NG450=Instance.new("Frame") NG450.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG450.BackgroundTransparency=1
NG450.BorderSizePixel=0 NG450.Name=dCD([=[GlcrBcgvba]=])NG450.Position=UDim2.new(0,14,0,65) NG450.Size=UDim2.new(1,-14,0,25)NG450.Visible=false
NG450.Parent=NG445 NG451=Instance.new("TextLabel") NG451.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG451.BackgroundTransparency=1
NG451.BorderSizePixel=0 NG451.Name=dCD([=[Ynory]=])NG451.Size=UDim2.new(0,30,0,25) NG451.Font=Enum.Font.ArialBold
NG451.FontSize=Enum.FontSize.Size10
NG451.Text=dCD([=[Glcr]=]) NG451.TextColor3=Color3.new(1,1,1)NG451.TextStrokeTransparency=0
NG451.TextWrapped=true NG451.TextXAlignment=Enum.TextXAlignment.Left
NG451.Parent=NG450
NG452=Instance.new("Frame") NG452.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG452.BackgroundTransparency=1
NG452.BorderSizePixel=0 NG452.Name=dCD([=[FpnyrBcgvba]=])NG452.Position=UDim2.new(0,0,0,100) NG452.Size=UDim2.new(0,0,0,0)NG452.Visible=false
NG452.Parent=NG445 NG453=Instance.new("TextLabel") NG453.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG453.BackgroundTransparency=1
NG453.BorderSizePixel=0 NG453.Name=dCD([=[Ynory]=])NG453.Position=UDim2.new(0,14,0,0) NG453.Size=UDim2.new(0,70,0,25)NG453.Font=Enum.Font.ArialBold NG453.FontSize=Enum.FontSize.Size10
NG453.Text=dCD([=[Fpnyr]=])NG453.TextColor3=Color3.new(1,1,1) NG453.TextStrokeTransparency=0
NG453.TextWrapped=true NG453.TextXAlignment=Enum.TextXAlignment.Left
NG453.Parent=NG452
NG454=Instance.new("Frame") NG454.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG454.BackgroundTransparency=1
NG454.BorderSizePixel=0 NG454.Name=dCD([=[KVachg]=])NG454.Position=UDim2.new(0,55,0,0) NG454.Size=UDim2.new(0,45,0,25)NG454.Parent=NG452
NG455=Instance.new("TextButton") NG455.Active=true
NG455.AutoButtonColor=false NG455.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG455.BackgroundTransparency=1
NG455.BorderSizePixel=0 NG455.Selectable=true
NG455.Size=UDim2.new(1,0,1,0) NG455.Style=Enum.ButtonStyle.Custom
NG455.ZIndex=2
NG455.Font=Enum.Font.Legacy NG455.FontSize=Enum.FontSize.Size8
NG455.Text=dCD([=[]=])NG455.Parent=NG454 NG456=Instance.new("ImageLabel")NG456.Active=false NG456.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG456.BackgroundTransparency=1
NG456.BorderSizePixel=0 NG456.Name=dCD([=[Onpxtebhaq]=])NG456.Selectable=false
NG456.Size=UDim2.new(1,0,1,0) NG456.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG456.Parent=NG454
NG457=Instance.new("Frame") NG457.BorderSizePixel=0
NG457.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG457.Position=UDim2.new(0,5,0,-2)NG457.Size=UDim2.new(1,-4,0,2)NG457.Parent=NG454 NG458=Instance.new("TextBox") NG458.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG458.BackgroundTransparency=1
NG458.BorderSizePixel=0 NG458.Position=UDim2.new(0,5,0,0)NG458.Size=UDim2.new(1,-10,1,0) NG458.Font=Enum.Font.ArialBold
NG458.FontSize=Enum.FontSize.Size10
NG458.Text=dCD([=[1]=]) NG458.TextColor3=Color3.new(1,1,1)NG458.Parent=NG454
NG459=Instance.new("Frame") NG459.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG459.BackgroundTransparency=1
NG459.BorderSizePixel=0 NG459.Name=dCD([=[LVachg]=])NG459.Position=UDim2.new(0,100,0,0) NG459.Size=UDim2.new(0,45,0,25)NG459.Parent=NG452
NG460=Instance.new("TextButton") NG460.Active=true
NG460.AutoButtonColor=false NG460.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG460.BackgroundTransparency=1
NG460.BorderSizePixel=0 NG460.Selectable=true
NG460.Size=UDim2.new(1,0,1,0) NG460.Style=Enum.ButtonStyle.Custom
NG460.ZIndex=2
NG460.Font=Enum.Font.Legacy NG460.FontSize=Enum.FontSize.Size8
NG460.Text=dCD([=[]=])NG460.Parent=NG459 NG461=Instance.new("ImageLabel")NG461.Active=false NG461.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG461.BackgroundTransparency=1
NG461.BorderSizePixel=0 NG461.Name=dCD([=[Onpxtebhaq]=])NG461.Selectable=false
NG461.Size=UDim2.new(1,0,1,0) NG461.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG461.Parent=NG459
NG462=Instance.new("Frame") NG462.BorderSizePixel=0
NG462.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG462.Position=UDim2.new(0,5,0,-2)NG462.Size=UDim2.new(1,-4,0,2)NG462.Parent=NG459 NG463=Instance.new("TextBox") NG463.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG463.BackgroundTransparency=1
NG463.BorderSizePixel=0 NG463.Position=UDim2.new(0,5,0,0)NG463.Size=UDim2.new(1,-10,1,0) NG463.Font=Enum.Font.ArialBold
NG463.FontSize=Enum.FontSize.Size10
NG463.Text=dCD([=[1]=]) NG463.TextColor3=Color3.new(1,1,1)NG463.Parent=NG459
NG464=Instance.new("Frame") NG464.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG464.BackgroundTransparency=1
NG464.BorderSizePixel=0 NG464.Name=dCD([=[MVachg]=])NG464.Position=UDim2.new(0,145,0,0) NG464.Size=UDim2.new(0,45,0,25)NG464.Parent=NG452
NG465=Instance.new("TextButton") NG465.Active=true
NG465.AutoButtonColor=false NG465.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG465.BackgroundTransparency=1
NG465.BorderSizePixel=0 NG465.Selectable=true
NG465.Size=UDim2.new(1,0,1,0) NG465.Style=Enum.ButtonStyle.Custom
NG465.ZIndex=2
NG465.Font=Enum.Font.Legacy NG465.FontSize=Enum.FontSize.Size8
NG465.Text=dCD([=[]=])NG465.Parent=NG464 NG466=Instance.new("ImageLabel")NG466.Active=false NG466.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG466.BackgroundTransparency=1
NG466.BorderSizePixel=0 NG466.Name=dCD([=[Onpxtebhaq]=])NG466.Selectable=false
NG466.Size=UDim2.new(1,0,1,0) NG466.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG466.Parent=NG464
NG467=Instance.new("Frame") NG467.BorderSizePixel=0
NG467.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG467.Position=UDim2.new(0,5,0,-2)NG467.Size=UDim2.new(1,-4,0,2)NG467.Parent=NG464 NG468=Instance.new("TextBox") NG468.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG468.BackgroundTransparency=1
NG468.BorderSizePixel=0 NG468.Position=UDim2.new(0,5,0,0)NG468.Size=UDim2.new(1,-10,1,0) NG468.Font=Enum.Font.ArialBold
NG468.FontSize=Enum.FontSize.Size10
NG468.Text=dCD([=[1]=]) NG468.TextColor3=Color3.new(1,1,1)NG468.Parent=NG464
NG469=Instance.new("Frame") NG469.BackgroundColor3=Color3.new(0,0,0)NG469.BackgroundTransparency=1
NG469.BorderSizePixel=0 NG469.Name=dCD([=[NqqOhggba]=])NG469.Position=UDim2.new(0,10,0,30) NG469.Size=UDim2.new(1,-10,0,20)NG469.Visible=false
NG469.Parent=NG445 NG470=Instance.new("TextButton")NG470.Active=true
NG470.BackgroundColor3=Color3.new(0,0,0) NG470.BackgroundTransparency=0.44999998807907
NG470.BorderSizePixel=0
NG470.Name=dCD([=[Ohggba]=])NG470.Selectable=true NG470.Size=UDim2.new(1,0,1,0)NG470.Style=Enum.ButtonStyle.Custom NG470.Font=Enum.Font.ArialBold
NG470.FontSize=Enum.FontSize.Size10
NG470.Text=dCD([=[NQQ ZRFU]=]) NG470.TextColor3=Color3.new(1,1,1)NG470.TextStrokeTransparency=0.80000001192093
NG470.Parent=NG469 NG471=Instance.new("Frame")NG471.BackgroundColor3=Color3.new(0,0,0) NG471.BackgroundTransparency=0.30000001192093
NG471.BorderSizePixel=0
NG471.Name=dCD([=[Funqbj]=]) NG471.Position=UDim2.new(0,0,1,0)NG471.Size=UDim2.new(1,0,0,2)NG471.ZIndex=2 NG471.Parent=NG469
NG472=Instance.new("Frame") NG472.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG472.BackgroundTransparency=1
NG472.BorderSizePixel=0 NG472.Name=dCD([=[ZrfuVQBcgvba]=])NG472.Position=UDim2.new(0,14,0,135) NG472.Size=UDim2.new(1,0,0,25)NG472.Visible=false
NG472.Parent=NG445 NG473=Instance.new("TextLabel") NG473.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG473.BackgroundTransparency=1
NG473.BorderSizePixel=0 NG473.Name=dCD([=[Ynory]=])NG473.Size=UDim2.new(0,70,0,25) NG473.Font=Enum.Font.ArialBold
NG473.FontSize=Enum.FontSize.Size10
NG473.Text=dCD([=[Zrfu VQ]=]) NG473.TextColor3=Color3.new(1,1,1)NG473.TextStrokeTransparency=0
NG473.TextWrapped=true NG473.TextXAlignment=Enum.TextXAlignment.Left
NG473.Parent=NG472
NG474=Instance.new("TextBox") NG474.BackgroundColor3=Color3.new(0.333333,0,0.498039)NG474.BackgroundTransparency=1 NG474.BorderColor3=Color3.new(0,0,0)NG474.BorderSizePixel=0
NG474.Position=UDim2.new(0,60,0,-1) NG474.Size=UDim2.new(0,80,0,18)NG474.Font=Enum.Font.SourceSansBold NG474.FontSize=Enum.FontSize.Size10
NG474.Text=dCD([=[]=])NG474.TextColor3=Color3.new(1,1,1) NG474.TextScaled=true
NG474.TextStrokeTransparency=0.5
NG474.TextWrapped=true NG474.TextXAlignment=Enum.TextXAlignment.Left
NG474.Parent=NG472
NG475=Instance.new("Frame") NG475.BackgroundTransparency=1
NG475.BorderSizePixel=0
NG475.Name=dCD([=[GrkgObkObeqre]=]) NG475.Position=UDim2.new(0,56,0,17)NG475.Size=UDim2.new(0,85,0,3)NG475.Parent=NG472 NG476=Instance.new("Frame")NG476.BackgroundColor3=Color3.new(0.333333,0,0.498039) NG476.BorderSizePixel=0
NG476.Name=dCD([=[ObggbzObeqre]=]) NG476.Position=UDim2.new(0,0,1,-1)NG476.Size=UDim2.new(1,0,0,1)NG476.Parent=NG475 NG477=Instance.new("Frame")NG477.BackgroundColor3=Color3.new(0.333333,0,0.498039) NG477.BorderSizePixel=0
NG477.Name=dCD([=[YrsgObeqre]=])NG477.Size=UDim2.new(0,1,1,0) NG477.Parent=NG475
NG478=Instance.new("Frame") NG478.BackgroundColor3=Color3.new(0.333333,0,0.498039)NG478.BorderSizePixel=0
NG478.Name=dCD([=[EvtugObeqre]=]) NG478.Position=UDim2.new(1,-1,0,0)NG478.Size=UDim2.new(0,1,1,0)NG478.Parent=NG475 NG479=Instance.new("Frame")NG479.BackgroundColor3=Color3.new(0.333333,0,0.498039) NG479.BackgroundTransparency=0.89999997615814
NG479.BorderSizePixel=0
NG479.Name=dCD([=[GrkgObkOnpxtebhaq]=])NG479.Position=UDim2.new(0,55,0, -2)NG479.Size=UDim2.new(0,86,0,22) NG479.Parent=NG472
NG480=Instance.new("TextButton")NG480.Active=true NG480.BackgroundTransparency=1
NG480.BorderSizePixel=0
NG480.Position=UDim2.new(0,60,0,-1) NG480.Selectable=true
NG480.Size=UDim2.new(0,80,0,18) NG480.Style=Enum.ButtonStyle.Custom
NG480.ZIndex=2
NG480.FontSize=Enum.FontSize.Size14 NG480.Text=dCD([=[]=])NG480.Parent=NG472
NG481=Instance.new("Frame") NG481.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG481.BorderSizePixel=0
NG481.Name=dCD([=[ObggbzPbybeOne]=])NG481.Position=UDim2.new(0,5,1, -2)NG481.Size=UDim2.new(1,0,0,2) NG481.Parent=NG445
NG482=Instance.new("Frame") NG482.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG482.BackgroundTransparency=1
NG482.BorderSizePixel=0 NG482.Name=dCD([=[GrkgherVQBcgvba]=])NG482.Position=UDim2.new(0,14,0,165) NG482.Size=UDim2.new(1,0,0,25)NG482.Visible=false
NG482.Parent=NG445 NG483=Instance.new("TextLabel") NG483.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG483.BackgroundTransparency=1
NG483.BorderSizePixel=0 NG483.Name=dCD([=[Ynory]=])NG483.Size=UDim2.new(0,70,0,25) NG483.Font=Enum.Font.ArialBold
NG483.FontSize=Enum.FontSize.Size10 NG483.Text=dCD([=[Grkgher VQ]=])NG483.TextColor3=Color3.new(1,1,1) NG483.TextStrokeTransparency=0
NG483.TextWrapped=true NG483.TextXAlignment=Enum.TextXAlignment.Left
NG483.Parent=NG482
NG484=Instance.new("TextBox") NG484.BackgroundColor3=Color3.new(0.333333,0,0.498039)NG484.BackgroundTransparency=1 NG484.BorderColor3=Color3.new(0,0,0)NG484.BorderSizePixel=0
NG484.Position=UDim2.new(0,65,0,-1) NG484.Size=UDim2.new(0,80,0,18)NG484.Font=Enum.Font.SourceSansBold NG484.FontSize=Enum.FontSize.Size10
NG484.Text=dCD([=[]=])NG484.TextColor3=Color3.new(1,1,1) NG484.TextScaled=true
NG484.TextStrokeTransparency=0.5
NG484.TextWrapped=true NG484.TextXAlignment=Enum.TextXAlignment.Left
NG484.Parent=NG482
NG485=Instance.new("Frame") NG485.BackgroundTransparency=1
NG485.BorderSizePixel=0
NG485.Name=dCD([=[GrkgObkObeqre]=]) NG485.Position=UDim2.new(0,61,0,17)NG485.Size=UDim2.new(0,85,0,3)NG485.Parent=NG482 NG486=Instance.new("Frame")NG486.BackgroundColor3=Color3.new(0.333333,0,0.498039) NG486.BorderSizePixel=0
NG486.Name=dCD([=[ObggbzObeqre]=]) NG486.Position=UDim2.new(0,0,1,-1)NG486.Size=UDim2.new(1,0,0,1)NG486.Parent=NG485 NG487=Instance.new("Frame")NG487.BackgroundColor3=Color3.new(0.333333,0,0.498039) NG487.BorderSizePixel=0
NG487.Name=dCD([=[YrsgObeqre]=])NG487.Size=UDim2.new(0,1,1,0) NG487.Parent=NG485
NG488=Instance.new("Frame") NG488.BackgroundColor3=Color3.new(0.333333,0,0.498039)NG488.BorderSizePixel=0
NG488.Name=dCD([=[EvtugObeqre]=]) NG488.Position=UDim2.new(1,-1,0,0)NG488.Size=UDim2.new(0,1,1,0)NG488.Parent=NG485 NG489=Instance.new("Frame")NG489.BackgroundColor3=Color3.new(0.333333,0,0.498039) NG489.BackgroundTransparency=0.89999997615814
NG489.BorderSizePixel=0
NG489.Name=dCD([=[GrkgObkOnpxtebhaq]=])NG489.Position=UDim2.new(0,60,0, -2)NG489.Size=UDim2.new(0,86,0,22) NG489.Parent=NG482
NG490=Instance.new("TextButton")NG490.Active=true NG490.BackgroundTransparency=1
NG490.BorderSizePixel=0
NG490.Position=UDim2.new(0,65,0,-1) NG490.Selectable=true
NG490.Size=UDim2.new(0,80,0,18) NG490.Style=Enum.ButtonStyle.Custom
NG490.ZIndex=2
NG490.FontSize=Enum.FontSize.Size14 NG490.Text=dCD([=[]=])NG490.Parent=NG482
NG491=Instance.new("Frame") NG491.BackgroundColor3=Color3.new(0,0,0)NG491.BackgroundTransparency=1
NG491.BorderSizePixel=0 NG491.Name=dCD([=[ErzbirOhggba]=])NG491.Position=UDim2.new(0,10,1,-30) NG491.Size=UDim2.new(1,-10,0,20)NG491.Visible=false
NG491.Parent=NG445 NG492=Instance.new("TextButton")NG492.Active=true
NG492.BackgroundColor3=Color3.new(0,0,0) NG492.BackgroundTransparency=0.44999998807907
NG492.BorderSizePixel=0
NG492.Name=dCD([=[Ohggba]=])NG492.Selectable=true NG492.Size=UDim2.new(1,0,1,0)NG492.Style=Enum.ButtonStyle.Custom NG492.Font=Enum.Font.ArialBold
NG492.FontSize=Enum.FontSize.Size10 NG492.Text=dCD([=[ERZBIR ZRFU]=])NG492.TextColor3=Color3.new(1,1,1) NG492.TextStrokeTransparency=0.80000001192093
NG492.Parent=NG491
NG493=Instance.new("Frame") NG493.BackgroundColor3=Color3.new(0,0,0)NG493.BackgroundTransparency=0.30000001192093
NG493.BorderSizePixel=0 NG493.Name=dCD([=[Funqbj]=])NG493.Position=UDim2.new(0,0,1,0) NG493.Size=UDim2.new(1,0,0,2)NG493.ZIndex=2
NG493.Parent=NG491 NG494=Instance.new("Frame") NG494.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG494.BackgroundTransparency=1
NG494.BorderSizePixel=0 NG494.Name=dCD([=[GvagBcgvba]=])NG494.Position=UDim2.new(0,0,0,200) NG494.Size=UDim2.new(0,0,0,0)NG494.Visible=false
NG494.Parent=NG445 NG495=Instance.new("TextLabel") NG495.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG495.BackgroundTransparency=1
NG495.BorderSizePixel=0 NG495.Name=dCD([=[Ynory]=])NG495.Position=UDim2.new(0,14,0,0) NG495.Size=UDim2.new(0,70,0,25)NG495.Font=Enum.Font.ArialBold NG495.FontSize=Enum.FontSize.Size10
NG495.Text=dCD([=[Gvag]=])NG495.TextColor3=Color3.new(1,1,1) NG495.TextStrokeTransparency=0
NG495.TextWrapped=true NG495.TextXAlignment=Enum.TextXAlignment.Left
NG495.Parent=NG494
NG496=Instance.new("Frame") NG496.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG496.BackgroundTransparency=1
NG496.BorderSizePixel=0 NG496.Name=dCD([=[OVachg]=])NG496.Position=UDim2.new(0,114,0,0) NG496.Size=UDim2.new(0,38,0,25)NG496.Parent=NG494
NG497=Instance.new("TextButton") NG497.Active=true
NG497.AutoButtonColor=false NG497.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG497.BackgroundTransparency=1
NG497.BorderSizePixel=0 NG497.Selectable=true
NG497.Size=UDim2.new(1,0,1,0) NG497.Style=Enum.ButtonStyle.Custom
NG497.ZIndex=2
NG497.Font=Enum.Font.Legacy NG497.FontSize=Enum.FontSize.Size8
NG497.Text=dCD([=[]=])NG497.Parent=NG496 NG498=Instance.new("ImageLabel")NG498.Active=false NG498.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG498.BackgroundTransparency=1
NG498.BorderSizePixel=0 NG498.Name=dCD([=[Onpxtebhaq]=])NG498.Selectable=false
NG498.Size=UDim2.new(1,0,1,0) NG498.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG498.Parent=NG496
NG499=Instance.new("Frame") NG499.BackgroundColor3=Color3.new(0,0,1)NG499.BorderSizePixel=0
NG499.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG499.Position=UDim2.new(0,3,0, -2)NG499.Size=UDim2.new(1,-3,0,2) NG499.Parent=NG496
NG500=Instance.new("TextBox") NG500.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG500.BackgroundTransparency=1
NG500.BorderSizePixel=0 NG500.Position=UDim2.new(0,5,0,0)NG500.Size=UDim2.new(1,-10,1,0) NG500.Font=Enum.Font.ArialBold
NG500.FontSize=Enum.FontSize.Size10
NG500.Text=dCD([=[255]=]) NG500.TextColor3=Color3.new(1,1,1)NG500.Parent=NG496
NG501=Instance.new("Frame") NG501.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG501.BackgroundTransparency=1
NG501.BorderSizePixel=0 NG501.Name=dCD([=[TVachg]=])NG501.Position=UDim2.new(0,77,0,0) NG501.Size=UDim2.new(0,38,0,25)NG501.Parent=NG494
NG502=Instance.new("TextButton") NG502.Active=true
NG502.AutoButtonColor=false NG502.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG502.BackgroundTransparency=1
NG502.BorderSizePixel=0 NG502.Selectable=true
NG502.Size=UDim2.new(1,0,1,0) NG502.Style=Enum.ButtonStyle.Custom
NG502.ZIndex=2
NG502.Font=Enum.Font.Legacy NG502.FontSize=Enum.FontSize.Size8
NG502.Text=dCD([=[]=])NG502.Parent=NG501 NG503=Instance.new("ImageLabel")NG503.Active=false NG503.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG503.BackgroundTransparency=1
NG503.BorderSizePixel=0 NG503.Name=dCD([=[Onpxtebhaq]=])NG503.Selectable=false
NG503.Size=UDim2.new(1,0,1,0) NG503.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG503.Parent=NG501
NG504=Instance.new("Frame") NG504.BackgroundColor3=Color3.new(0,1,0)NG504.BorderSizePixel=0
NG504.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG504.Position=UDim2.new(0,3,0, -2)NG504.Size=UDim2.new(1,-3,0,2) NG504.Parent=NG501
NG505=Instance.new("TextBox") NG505.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG505.BackgroundTransparency=1
NG505.BorderSizePixel=0 NG505.Position=UDim2.new(0,5,0,0)NG505.Size=UDim2.new(1,-10,1,0) NG505.Font=Enum.Font.ArialBold
NG505.FontSize=Enum.FontSize.Size10
NG505.Text=dCD([=[255]=]) NG505.TextColor3=Color3.new(1,1,1)NG505.Parent=NG501
NG506=Instance.new("Frame") NG506.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG506.BackgroundTransparency=1
NG506.BorderSizePixel=0 NG506.Name=dCD([=[EVachg]=])NG506.Position=UDim2.new(0,40,0,0) NG506.Size=UDim2.new(0,38,0,25)NG506.Parent=NG494
NG507=Instance.new("TextButton") NG507.Active=true
NG507.AutoButtonColor=false NG507.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG507.BackgroundTransparency=1
NG507.BorderSizePixel=0 NG507.Selectable=true
NG507.Size=UDim2.new(1,0,1,0) NG507.Style=Enum.ButtonStyle.Custom
NG507.ZIndex=2
NG507.Font=Enum.Font.Legacy NG507.FontSize=Enum.FontSize.Size8
NG507.Text=dCD([=[]=])NG507.Parent=NG506 NG508=Instance.new("ImageLabel")NG508.Active=false NG508.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG508.BackgroundTransparency=1
NG508.BorderSizePixel=0 NG508.Name=dCD([=[Onpxtebhaq]=])NG508.Selectable=false
NG508.Size=UDim2.new(1,0,1,0) NG508.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG508.Parent=NG506
NG509=Instance.new("Frame") NG509.BackgroundColor3=Color3.new(1,0,0)NG509.BorderSizePixel=0
NG509.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG509.Position=UDim2.new(0,3,0, -2)NG509.Size=UDim2.new(1,-3,0,2) NG509.Parent=NG506
NG510=Instance.new("TextBox") NG510.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG510.BackgroundTransparency=1
NG510.BorderSizePixel=0 NG510.Position=UDim2.new(0,5,0,0)NG510.Size=UDim2.new(1,-10,1,0) NG510.Font=Enum.Font.ArialBold
NG510.FontSize=Enum.FontSize.Size10
NG510.Text=dCD([=[255]=]) NG510.TextColor3=Color3.new(1,1,1)NG510.Parent=NG506
NG511=Instance.new("Frame") NG511.BackgroundColor3=Color3.new(0,0,0)NG511.BackgroundTransparency=0.5 NG511.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG511.BorderSizePixel=0
NG511.Name=dCD([=[Frcnengbe]=]) NG511.Position=UDim2.new(0,156,0,4)NG511.Size=UDim2.new(0,4,0,4)NG511.Parent=NG494 NG512=Instance.new("Frame")NG512.BackgroundColor3=Color3.new(0,0,0) NG512.BackgroundTransparency=0.5 NG512.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG512.BorderSizePixel=0
NG512.Name=dCD([=[Frcnengbe]=]) NG512.Position=UDim2.new(0,156,0,16)NG512.Size=UDim2.new(0,4,0,4)NG512.Parent=NG494 NG513=Instance.new("Frame")NG513.BackgroundColor3=Color3.new(0,0,0) NG513.BackgroundTransparency=0.5 NG513.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG513.BorderSizePixel=0
NG513.Name=dCD([=[Frcnengbe]=]) NG513.Position=UDim2.new(0,156,0,10)NG513.Size=UDim2.new(0,4,0,4)NG513.Parent=NG494 NG514=Instance.new("ImageButton")NG514.BackgroundColor3=Color3.new(0,0,0) NG514.BackgroundTransparency=0.40000000596046
NG514.BorderSizePixel=0
NG514.Name=dCD([=[UFICvpxre]=]) NG514.Position=UDim2.new(0,165,0,-2)NG514.Size=UDim2.new(0,27,0,27) NG514.Style=Enum.ButtonStyle.Custom
NG514.ZIndex=2 NG514.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141313631]=])NG514.Parent=NG494
NG515=Instance.new("Frame") NG515.BackgroundColor3=Color3.new(0,0,0)NG515.BackgroundTransparency=0.75
NG515.BorderSizePixel=0 NG515.Name=dCD([=[Funqbj]=])NG515.Position=UDim2.new(0,0,1,-2) NG515.Size=UDim2.new(1,0,0,2)NG515.Parent=NG514
NG516=Instance.new("TextLabel") NG516.BackgroundTransparency=1
NG516.BorderSizePixel=0
NG516.Name=dCD([=[FryrpgAbgr]=]) NG516.Position=UDim2.new(0,10,0,27)NG516.Size=UDim2.new(1,-10,0,15) NG516.FontSize=Enum.FontSize.Size14
NG516.Text=dCD([=[Fryrpg fbzrguvat gb hfr guvf gbby.]=]) NG516.TextColor3=Color3.new(1,1,1)NG516.TextScaled=true
NG516.TextStrokeTransparency=0.5 NG516.TextWrapped=true
NG516.TextXAlignment=Enum.TextXAlignment.Left NG516.Parent=NG445
NG517=Instance.new("Frame")NG517.Active=true NG517.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG517.BackgroundTransparency=1
NG517.BorderSizePixel=0 NG517.Name=dCD([=[OGZbirGbbyTHV]=])NG517.Position=UDim2.new(0,0,0,280) NG517.Size=UDim2.new(0,245,0,90)NG517.Draggable=true
NG517.Parent=NG1 NG518=Instance.new("Frame") NG518.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG518.BackgroundTransparency=1
NG518.BorderSizePixel=0 NG518.Name=dCD([=[Punatrf]=])NG518.Position=UDim2.new(0,5,0,100) NG518.Size=UDim2.new(1,-5,0,20)NG518.Parent=NG517
NG519=Instance.new("TextLabel") NG519.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG519.BackgroundTransparency=1
NG519.BorderSizePixel=0 NG519.Name=dCD([=[Grkg]=])NG519.Position=UDim2.new(0,10,0,2) NG519.Size=UDim2.new(1,-10,0,20)NG519.Font=Enum.Font.ArialBold NG519.FontSize=Enum.FontSize.Size10
NG519.Text=dCD([=[zbirq 0 fghqf]=]) NG519.TextColor3=Color3.new(1,1,1)NG519.TextStrokeTransparency=0.5
NG519.TextWrapped=true NG519.TextXAlignment=Enum.TextXAlignment.Right
NG519.Parent=NG518
NG520=Instance.new("Frame") NG520.BackgroundColor3=Color3.new(1,0.666667,0)NG520.BorderSizePixel=0
NG520.Name=dCD([=[PbybeOne]=]) NG520.Size=UDim2.new(1,0,0,2)NG520.Parent=NG518
NG521=Instance.new("Frame") NG521.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG521.BackgroundTransparency=1
NG521.BorderSizePixel=0 NG521.Name=dCD([=[Vasb]=])NG521.Position=UDim2.new(0,5,0,100) NG521.Size=UDim2.new(1,-5,0,60)NG521.Visible=false
NG521.Parent=NG517 NG522=Instance.new("Frame") NG522.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG522.BackgroundTransparency=1
NG522.BorderSizePixel=0 NG522.Name=dCD([=[Pragre]=])NG522.Position=UDim2.new(0,0,0,30) NG522.Size=UDim2.new(0,0,0,0)NG522.Parent=NG521
NG523=Instance.new("Frame") NG523.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG523.BackgroundTransparency=1
NG523.BorderSizePixel=0 NG523.Name=dCD([=[M]=])NG523.Position=UDim2.new(0,164,0,0) NG523.Size=UDim2.new(0,50,0,25)NG523.Parent=NG522
NG524=Instance.new("ImageLabel") NG524.Active=false NG524.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG524.BackgroundTransparency=1
NG524.BorderSizePixel=0 NG524.Name=dCD([=[Onpxtebhaq]=])NG524.Selectable=false
NG524.Size=UDim2.new(1,0,1,0) NG524.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG524.Parent=NG523
NG525=Instance.new("TextButton") NG525.Active=true
NG525.AutoButtonColor=false NG525.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG525.BackgroundTransparency=1
NG525.BorderSizePixel=0 NG525.Selectable=true
NG525.Size=UDim2.new(1,0,1,0) NG525.Style=Enum.ButtonStyle.Custom
NG525.ZIndex=2
NG525.Font=Enum.Font.Legacy NG525.FontSize=Enum.FontSize.Size8
NG525.Text=dCD([=[]=])NG525.Parent=NG523 NG526=Instance.new("TextBox") NG526.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG526.BackgroundTransparency=1
NG526.BorderSizePixel=0 NG526.Position=UDim2.new(0,5,0,0)NG526.Size=UDim2.new(1,-10,1,0) NG526.Font=Enum.Font.ArialBold
NG526.FontSize=Enum.FontSize.Size10
NG526.Text=dCD([=[]=]) NG526.TextColor3=Color3.new(1,1,1)NG526.Parent=NG523
NG527=Instance.new("Frame") NG527.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG527.BackgroundTransparency=1
NG527.BorderSizePixel=0 NG527.Name=dCD([=[L]=])NG527.Position=UDim2.new(0,117,0,0) NG527.Size=UDim2.new(0,50,0,25)NG527.Parent=NG522
NG528=Instance.new("TextButton") NG528.Active=true
NG528.AutoButtonColor=false NG528.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG528.BackgroundTransparency=1
NG528.BorderSizePixel=0 NG528.Selectable=true
NG528.Size=UDim2.new(1,0,1,0) NG528.Style=Enum.ButtonStyle.Custom
NG528.ZIndex=2
NG528.Font=Enum.Font.Legacy NG528.FontSize=Enum.FontSize.Size8
NG528.Text=dCD([=[]=])NG528.Parent=NG527 NG529=Instance.new("TextBox") NG529.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG529.BackgroundTransparency=1
NG529.BorderSizePixel=0 NG529.Position=UDim2.new(0,5,0,0)NG529.Size=UDim2.new(1,-10,1,0) NG529.Font=Enum.Font.ArialBold
NG529.FontSize=Enum.FontSize.Size10
NG529.Text=dCD([=[]=]) NG529.TextColor3=Color3.new(1,1,1)NG529.Parent=NG527
NG530=Instance.new("ImageLabel") NG530.Active=false NG530.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG530.BackgroundTransparency=1
NG530.BorderSizePixel=0 NG530.Name=dCD([=[Onpxtebhaq]=])NG530.Selectable=false
NG530.Size=UDim2.new(1,0,1,0) NG530.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG530.Parent=NG527
NG531=Instance.new("Frame") NG531.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG531.BackgroundTransparency=1
NG531.BorderSizePixel=0 NG531.Name=dCD([=[K]=])NG531.Position=UDim2.new(0,70,0,0) NG531.Size=UDim2.new(0,50,0,25)NG531.Parent=NG522
NG532=Instance.new("TextBox") NG532.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG532.BackgroundTransparency=1
NG532.BorderSizePixel=0 NG532.Position=UDim2.new(0,5,0,0)NG532.Size=UDim2.new(1,-10,1,0) NG532.Font=Enum.Font.ArialBold
NG532.FontSize=Enum.FontSize.Size10
NG532.Text=dCD([=[]=]) NG532.TextColor3=Color3.new(1,1,1)NG532.Parent=NG531
NG533=Instance.new("TextButton") NG533.Active=true
NG533.AutoButtonColor=false NG533.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG533.BackgroundTransparency=1
NG533.BorderSizePixel=0 NG533.Selectable=true
NG533.Size=UDim2.new(1,0,1,0) NG533.Style=Enum.ButtonStyle.Custom
NG533.ZIndex=2
NG533.Font=Enum.Font.Legacy NG533.FontSize=Enum.FontSize.Size8
NG533.Text=dCD([=[]=])NG533.Parent=NG531 NG534=Instance.new("ImageLabel")NG534.Active=false NG534.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG534.BackgroundTransparency=1
NG534.BorderSizePixel=0 NG534.Name=dCD([=[Onpxtebhaq]=])NG534.Selectable=false
NG534.Size=UDim2.new(1,0,1,0) NG534.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG534.Parent=NG531
NG535=Instance.new("TextLabel") NG535.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG535.BackgroundTransparency=1
NG535.BorderSizePixel=0 NG535.Size=UDim2.new(0,75,0,25)NG535.Font=Enum.Font.ArialBold NG535.FontSize=Enum.FontSize.Size10
NG535.Text=dCD([=[Cbfvgvba]=])NG535.TextColor3=Color3.new(1,1,1) NG535.TextStrokeTransparency=0
NG535.TextWrapped=true
NG535.Parent=NG522 NG536=Instance.new("TextLabel") NG536.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG536.BackgroundTransparency=1
NG536.BorderSizePixel=0 NG536.Name=dCD([=[Ynory]=])NG536.Position=UDim2.new(0,10,0,2) NG536.Size=UDim2.new(1,-10,0,20)NG536.Font=Enum.Font.ArialBold NG536.FontSize=Enum.FontSize.Size10
NG536.Text=dCD([=[FRYRPGVBA VASB]=]) NG536.TextColor3=Color3.new(1,1,1)NG536.TextStrokeTransparency=0
NG536.TextWrapped=true NG536.TextXAlignment=Enum.TextXAlignment.Left
NG536.Parent=NG521
NG537=Instance.new("Frame") NG537.BackgroundColor3=Color3.new(1,0.666667,0)NG537.BorderSizePixel=0
NG537.Name=dCD([=[PbybeOne]=]) NG537.Size=UDim2.new(1,0,0,2)NG537.Parent=NG521
NG538=Instance.new("Frame") NG538.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG538.BackgroundTransparency=1
NG538.BorderSizePixel=0 NG538.Name=dCD([=[VaperzragBcgvba]=])NG538.Position=UDim2.new(0,0,0,65) NG538.Size=UDim2.new(0,0,0,0)NG538.Parent=NG517
NG539=Instance.new("Frame") NG539.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG539.BackgroundTransparency=1
NG539.BorderSizePixel=0 NG539.Name=dCD([=[Ynory]=])NG539.Size=UDim2.new(0,75,0,25)NG539.Parent=NG538 NG540=Instance.new("TextLabel") NG540.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG540.BackgroundTransparency=1
NG540.BorderSizePixel=0 NG540.Size=UDim2.new(1,0,1,0)NG540.Font=Enum.Font.ArialBold NG540.FontSize=Enum.FontSize.Size10
NG540.Text=dCD([=[Vaperzrag]=]) NG540.TextColor3=Color3.new(1,1,1)NG540.TextStrokeTransparency=0
NG540.TextWrapped=true NG540.Parent=NG539
NG541=Instance.new("Frame") NG541.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG541.BackgroundTransparency=1
NG541.BorderSizePixel=0 NG541.Name=dCD([=[Vaperzrag]=])NG541.Position=UDim2.new(0,70,0,0) NG541.Size=UDim2.new(0,50,0,25)NG541.Parent=NG538
NG542=Instance.new("ImageLabel") NG542.Active=false NG542.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG542.BackgroundTransparency=1
NG542.BorderSizePixel=0 NG542.Name=dCD([=[Onpxtebhaq]=])NG542.Selectable=false
NG542.Size=UDim2.new(1,0,1,0) NG542.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG542.Parent=NG541
NG543=Instance.new("TextBox") NG543.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG543.BackgroundTransparency=1
NG543.BorderSizePixel=0 NG543.Position=UDim2.new(0,5,0,0)NG543.Size=UDim2.new(1,-10,1,0)NG543.ZIndex=2 NG543.Font=Enum.Font.ArialBold
NG543.FontSize=Enum.FontSize.Size10
NG543.Text=dCD([=[1]=]) NG543.TextColor3=Color3.new(1,1,1)NG543.Parent=NG541
NG544=Instance.new("Frame") NG544.BorderSizePixel=0
NG544.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG544.Position=UDim2.new(0,5,0,-2)NG544.Size=UDim2.new(1,-4,0,2)NG544.Parent=NG541 NG545=Instance.new("Frame") NG545.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG545.BackgroundTransparency=1
NG545.BorderSizePixel=0 NG545.Name=dCD([=[Gvgyr]=])NG545.Size=UDim2.new(1,0,0,20)NG545.Parent=NG517 NG546=Instance.new("TextLabel") NG546.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG546.BackgroundTransparency=1
NG546.BorderSizePixel=0 NG546.Name=dCD([=[S3KFvtangher]=])NG546.Position=UDim2.new(0,10,0,1) NG546.Size=UDim2.new(1,-10,1,0)NG546.Font=Enum.Font.ArialBold NG546.FontSize=Enum.FontSize.Size14
NG546.Text=dCD([=[S3K]=])NG546.TextColor3=Color3.new(1,1,1) NG546.TextStrokeTransparency=0.89999997615814
NG546.TextWrapped=true NG546.TextXAlignment=Enum.TextXAlignment.Right
NG546.Parent=NG545
NG547=Instance.new("TextLabel") NG547.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG547.BackgroundTransparency=1
NG547.BorderSizePixel=0 NG547.Name=dCD([=[Ynory]=])NG547.Position=UDim2.new(0,10,0,1) NG547.Size=UDim2.new(1,-10,1,0)NG547.Font=Enum.Font.ArialBold NG547.FontSize=Enum.FontSize.Size10
NG547.Text=dCD([=[ZBIR GBBY]=]) NG547.TextColor3=Color3.new(1,1,1)NG547.TextStrokeTransparency=0
NG547.TextWrapped=true NG547.TextXAlignment=Enum.TextXAlignment.Left
NG547.Parent=NG545
NG548=Instance.new("Frame") NG548.BackgroundColor3=Color3.new(1,0.666667,0)NG548.BorderSizePixel=0
NG548.Name=dCD([=[PbybeOne]=]) NG548.Position=UDim2.new(0,5,0,-3)NG548.Size=UDim2.new(1,-5,0,2)NG548.Parent=NG545 NG549=Instance.new("Frame") NG549.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG549.BackgroundTransparency=1
NG549.BorderSizePixel=0 NG549.Name=dCD([=[NkrfBcgvba]=])NG549.Position=UDim2.new(0,0,0,30) NG549.Size=UDim2.new(0,0,0,0)NG549.Parent=NG517
NG550=Instance.new("Frame") NG550.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG550.BackgroundTransparency=1
NG550.BorderSizePixel=0 NG550.Name=dCD([=[Ynory]=])NG550.Size=UDim2.new(0,50,0,25)NG550.Parent=NG549 NG551=Instance.new("TextLabel") NG551.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG551.BackgroundTransparency=1
NG551.BorderSizePixel=0 NG551.Size=UDim2.new(1,0,1,0)NG551.Font=Enum.Font.ArialBold NG551.FontSize=Enum.FontSize.Size10
NG551.Text=dCD([=[Nkrf]=])NG551.TextColor3=Color3.new(1,1,1) NG551.TextStrokeTransparency=0
NG551.TextWrapped=true
NG551.Parent=NG550 NG552=Instance.new("Frame") NG552.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG552.BackgroundTransparency=1
NG552.BorderSizePixel=0 NG552.Name=dCD([=[Ynfg]=])NG552.Position=UDim2.new(0,175,0,0) NG552.Size=UDim2.new(0,70,0,25)NG552.Parent=NG549
NG553=Instance.new("TextLabel") NG553.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG553.BackgroundTransparency=1
NG553.BorderSizePixel=0 NG553.Name=dCD([=[Ynory]=])NG553.Size=UDim2.new(1,0,1,0) NG553.Font=Enum.Font.ArialBold
NG553.FontSize=Enum.FontSize.Size10
NG553.Text=dCD([=[YNFG]=]) NG553.TextColor3=Color3.new(1,1,1)NG553.Parent=NG552
NG554=Instance.new("ImageLabel") NG554.Active=false NG554.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG554.BackgroundTransparency=1
NG554.BorderSizePixel=0 NG554.Name=dCD([=[Onpxtebhaq]=])NG554.Selectable=false
NG554.Size=UDim2.new(1,0,1,0) NG554.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG554.Parent=NG552
NG555=Instance.new("TextButton") NG555.Active=true NG555.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG555.BackgroundTransparency=1
NG555.BorderSizePixel=0 NG555.Name=dCD([=[Ohggba]=])NG555.Position=UDim2.new(0,5,0,0)NG555.Selectable=true
NG555.Size=UDim2.new(1, -10,1,0) NG555.Style=Enum.ButtonStyle.Custom
NG555.ZIndex=2
NG555.Font=Enum.Font.Legacy NG555.FontSize=Enum.FontSize.Size8
NG555.Text=dCD([=[]=])NG555.TextTransparency=1
NG555.Parent=NG552 NG556=Instance.new("Frame")NG556.BackgroundTransparency=1
NG556.BorderSizePixel=0 NG556.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG556.Position=UDim2.new(0,6,0,-2) NG556.Size=UDim2.new(1,-5,0,2)NG556.Parent=NG552
NG557=Instance.new("Frame") NG557.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG557.BackgroundTransparency=1
NG557.BorderSizePixel=0 NG557.Name=dCD([=[Ybpny]=])NG557.Position=UDim2.new(0,110,0,0) NG557.Size=UDim2.new(0,70,0,25)NG557.Parent=NG549
NG558=Instance.new("TextLabel") NG558.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG558.BackgroundTransparency=1
NG558.BorderSizePixel=0 NG558.Name=dCD([=[Ynory]=])NG558.Size=UDim2.new(1,0,1,0) NG558.Font=Enum.Font.ArialBold
NG558.FontSize=Enum.FontSize.Size10
NG558.Text=dCD([=[YBPNY]=]) NG558.TextColor3=Color3.new(1,1,1)NG558.Parent=NG557
NG559=Instance.new("ImageLabel") NG559.Active=false NG559.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG559.BackgroundTransparency=1
NG559.BorderSizePixel=0 NG559.Name=dCD([=[Onpxtebhaq]=])NG559.Selectable=false
NG559.Size=UDim2.new(1,0,1,0) NG559.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG559.Parent=NG557
NG560=Instance.new("TextButton") NG560.Active=true NG560.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG560.BackgroundTransparency=1
NG560.BorderSizePixel=0 NG560.Name=dCD([=[Ohggba]=])NG560.Position=UDim2.new(0,5,0,0)NG560.Selectable=true
NG560.Size=UDim2.new(1, -10,1,0) NG560.Style=Enum.ButtonStyle.Custom
NG560.ZIndex=2
NG560.Font=Enum.Font.Legacy NG560.FontSize=Enum.FontSize.Size8
NG560.Text=dCD([=[]=])NG560.TextTransparency=1
NG560.Parent=NG557 NG561=Instance.new("Frame")NG561.BackgroundTransparency=1
NG561.BorderSizePixel=0 NG561.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG561.Position=UDim2.new(0,6,0,-2) NG561.Size=UDim2.new(1,-5,0,2)NG561.Parent=NG557
NG562=Instance.new("Frame") NG562.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG562.BackgroundTransparency=1
NG562.BorderSizePixel=0 NG562.Name=dCD([=[Tybony]=])NG562.Position=UDim2.new(0,45,0,0) NG562.Size=UDim2.new(0,70,0,25)NG562.Parent=NG549
NG563=Instance.new("TextLabel") NG563.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG563.BackgroundTransparency=1
NG563.BorderSizePixel=0 NG563.Name=dCD([=[Ynory]=])NG563.Size=UDim2.new(1,0,1,0) NG563.Font=Enum.Font.ArialBold
NG563.FontSize=Enum.FontSize.Size10
NG563.Text=dCD([=[TYBONY]=]) NG563.TextColor3=Color3.new(1,1,1)NG563.Parent=NG562
NG564=Instance.new("ImageLabel") NG564.Active=false NG564.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG564.BackgroundTransparency=1
NG564.BorderSizePixel=0 NG564.Name=dCD([=[Onpxtebhaq]=])NG564.Selectable=false
NG564.Size=UDim2.new(1,0,1,0) NG564.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127774197]=])NG564.Parent=NG562
NG565=Instance.new("TextButton") NG565.Active=true NG565.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG565.BackgroundTransparency=1
NG565.BorderSizePixel=0 NG565.Name=dCD([=[Ohggba]=])NG565.Position=UDim2.new(0,5,0,0)NG565.Selectable=true
NG565.Size=UDim2.new(1, -10,1,0) NG565.Style=Enum.ButtonStyle.Custom
NG565.ZIndex=2
NG565.Font=Enum.Font.Legacy NG565.FontSize=Enum.FontSize.Size8
NG565.Text=dCD([=[]=])NG565.TextTransparency=1
NG565.Parent=NG562 NG566=Instance.new("Frame")NG566.BorderSizePixel=0
NG566.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG566.Position=UDim2.new(0,6,0, -2)NG566.Size=UDim2.new(1,-5,0,2) NG566.Parent=NG562
NG567=Instance.new("Frame")NG567.BackgroundTransparency=1 NG567.BorderSizePixel=0
NG567.Name=dCD([=[OGFgneghcAbgvsvpngvbaPbagnvare]=]) NG567.Position=UDim2.new(0,210,0,0)NG567.Size=UDim2.new(0,300,0,0)NG567.Draggable=true NG567.Parent=NG1
NG568=Instance.new("Frame") NG568.BackgroundColor3=Color3.new(0,0,0)NG568.BackgroundTransparency=0.69999998807907
NG568.BorderSizePixel=0 NG568.Name=dCD([=[GbbyHcqngrAbgvsvpngvba]=])NG568.Size=UDim2.new(1,0,0,65)NG568.Visible=false NG568.Parent=NG567
NG569=Instance.new("Frame") NG569.BackgroundColor3=Color3.new(1,0.666667,0)NG569.BorderSizePixel=0
NG569.Name=dCD([=[One]=]) NG569.Size=UDim2.new(1,0,0,2)NG569.Parent=NG568
NG570=Instance.new("TextButton") NG570.Active=true
NG570.BackgroundColor3=Color3.new(0,0,0) NG570.BackgroundTransparency=0.80000001192093
NG570.BorderColor3=Color3.new(0,0,0)NG570.BorderSizePixel=0 NG570.Name=dCD([=[BXOhggba]=])NG570.Position=UDim2.new(0,0,1,-22)NG570.Selectable=true NG570.Size=UDim2.new(0.5,0,0,22)NG570.Style=Enum.ButtonStyle.Custom NG570.Font=Enum.Font.Arial
NG570.FontSize=Enum.FontSize.Size10
NG570.Text=dCD([=[TBG VG]=]) NG570.TextColor3=Color3.new(1,1,1)NG570.Parent=NG568
NG571=Instance.new("TextButton") NG571.Active=true
NG571.BackgroundColor3=Color3.new(0,0,0) NG571.BackgroundTransparency=0.80000001192093
NG571.BorderColor3=Color3.new(0,0,0)NG571.BorderSizePixel=0 NG571.Name=dCD([=[UrycOhggba]=])NG571.Position=UDim2.new(0.5,0,1,-22)NG571.Selectable=true NG571.Size=UDim2.new(0.5,0,0,22)NG571.Style=Enum.ButtonStyle.Custom NG571.Font=Enum.Font.Arial
NG571.FontSize=Enum.FontSize.Size10 NG571.Text=dCD([=[JUNG PNA V QB?]=])NG571.TextColor3=Color3.new(1,1,1)NG571.Parent=NG568 NG572=Instance.new("Frame")NG572.BackgroundColor3=Color3.new(0,0,0) NG572.BackgroundTransparency=0.75
NG572.BorderSizePixel=0
NG572.Name=dCD([=[OhggbaFrcnengbe]=])NG572.Position=UDim2.new(0.5,0,1, -22)NG572.Size=UDim2.new(0,1,0,22) NG572.Parent=NG568
NG573=Instance.new("Frame")NG573.BackgroundTransparency=1 NG573.BorderSizePixel=0
NG573.Name=dCD([=[Abgvpr]=])NG573.Position=UDim2.new(0,0,0,2)NG573.Size=UDim2.new(1,0,1, -22)NG573.Parent=NG568 NG574=Instance.new("TextLabel")NG574.BackgroundTransparency=1 NG574.BorderColor3=Color3.new(0,0,0)NG574.BorderSizePixel=0
NG574.Size=UDim2.new(1,0,1,0) NG574.Font=Enum.Font.SourceSansBold
NG574.FontSize=Enum.FontSize.Size14 NG574.Text=dCD([=[Guvf irefvba bs Ohvyqvat Gbbyf vf bhgqngrq.]=])NG574.TextColor3=Color3.new(1,1,1) NG574.TextStrokeTransparency=0.80000001192093
NG574.TextWrapped=true
NG574.Parent=NG573 NG575=Instance.new("IntValue")NG575.Value=65
NG575.Parent=NG573 NG576=Instance.new("Frame")NG576.BackgroundTransparency=1
NG576.BorderSizePixel=0 NG576.Name=dCD([=[Uryc]=])NG576.Position=UDim2.new(0,0,0,2) NG576.Size=UDim2.new(1,0,1,-22)NG576.Visible=false
NG576.Parent=NG568 NG577=Instance.new("TextLabel")NG577.BackgroundTransparency=1 NG577.BorderColor3=Color3.new(0,0,0)NG577.BorderSizePixel=0
NG577.Position=UDim2.new(0,20,0,0)NG577.Size=UDim2.new(1, -20,1,0)NG577.Font=Enum.Font.SourceSansBold NG577.FontSize=Enum.FontSize.Size14 NG577.Text=dCD([=[Bja guvf cynpr? Fvzcyl ervafreg gur Ohvyqvat Gbbyf zbqry.]=])NG577.TextColor3=Color3.new(1,1,1) NG577.TextStrokeTransparency=0.80000001192093
NG577.TextWrapped=true NG577.TextXAlignment=Enum.TextXAlignment.Left
NG577.Parent=NG576
NG578=Instance.new("IntValue") NG578.Value=80
NG578.Parent=NG576
NG579=Instance.new("TextLabel") NG579.BackgroundTransparency=1
NG579.BorderColor3=Color3.new(0,0,0)NG579.BorderSizePixel=0 NG579.Position=UDim2.new(0,60,0,7)NG579.Size=UDim2.new(1,-20,1,0) NG579.FontSize=Enum.FontSize.Size14
NG579.Text=dCD([=[Bgurejvfr, gryy gur bjare gb qb gur nobir.]=]) NG579.TextColor3=Color3.new(1,1,1)NG579.TextStrokeTransparency=0.80000001192093
NG579.TextWrapped=true NG579.TextXAlignment=Enum.TextXAlignment.Left
NG579.Parent=NG576
NG580=Instance.new("Frame") NG580.BackgroundColor3=Color3.new(0,0,0)NG580.BackgroundTransparency=0.69999998807907
NG580.BorderSizePixel=0 NG580.Name=dCD([=[FbybJneavat]=])NG580.Size=UDim2.new(1,0,0,80)NG580.Visible=false NG580.Parent=NG567
NG581=Instance.new("Frame") NG581.BackgroundColor3=Color3.new(1,0,0.0156863)NG581.BorderSizePixel=0
NG581.Name=dCD([=[One]=]) NG581.Size=UDim2.new(1,0,0,2)NG581.Parent=NG580
NG582=Instance.new("TextButton") NG582.Active=true
NG582.BackgroundColor3=Color3.new(0,0,0) NG582.BackgroundTransparency=0.80000001192093
NG582.BorderColor3=Color3.new(0,0,0)NG582.BorderSizePixel=0 NG582.Name=dCD([=[BXOhggba]=])NG582.Position=UDim2.new(0,0,1,-22)NG582.Selectable=true NG582.Size=UDim2.new(0.5,0,0,22)NG582.Style=Enum.ButtonStyle.Custom NG582.Font=Enum.Font.Arial
NG582.FontSize=Enum.FontSize.Size10
NG582.Text=dCD([=[TBG VG]=]) NG582.TextColor3=Color3.new(1,1,1)NG582.Parent=NG580
NG583=Instance.new("TextButton") NG583.Active=true
NG583.BackgroundColor3=Color3.new(0,0,0) NG583.BackgroundTransparency=0.80000001192093
NG583.BorderColor3=Color3.new(0,0,0)NG583.BorderSizePixel=0 NG583.Name=dCD([=[UrycOhggba]=])NG583.Position=UDim2.new(0.5,0,1,-22)NG583.Selectable=true NG583.Size=UDim2.new(0.5,0,0,22)NG583.Style=Enum.ButtonStyle.Custom NG583.Font=Enum.Font.Arial
NG583.FontSize=Enum.FontSize.Size10 NG583.Text=dCD([=[JUNG PNA V QB?]=])NG583.TextColor3=Color3.new(1,1,1)NG583.Parent=NG580 NG584=Instance.new("Frame")NG584.BackgroundColor3=Color3.new(0,0,0) NG584.BackgroundTransparency=0.75
NG584.BorderSizePixel=0
NG584.Name=dCD([=[OhggbaFrcnengbe]=])NG584.Position=UDim2.new(0.5,0,1, -22)NG584.Size=UDim2.new(0,1,0,22) NG584.Parent=NG580
NG585=Instance.new("Frame")NG585.BackgroundTransparency=1 NG585.BorderSizePixel=0
NG585.Name=dCD([=[Abgvpr]=])NG585.Position=UDim2.new(0,0,0,2)NG585.Size=UDim2.new(1,0,1, -22)NG585.Parent=NG580 NG586=Instance.new("TextLabel")NG586.BackgroundTransparency=1 NG586.BorderColor3=Color3.new(0,0,0)NG586.BorderSizePixel=0
NG586.Position=UDim2.new(0,10,0,0)NG586.Size=UDim2.new(1, -20,1,0)NG586.Font=Enum.Font.SourceSansBold NG586.FontSize=Enum.FontSize.Size14 NG586.Text=dCD([=[Fbzr srngherf ner abg ninvynoyr ba ohvyq zbqr be qhevat fbyb grfgvat, vapyhqvat rkcbegvat.]=])NG586.TextColor3=Color3.new(1,1,1) NG586.TextStrokeTransparency=0.80000001192093
NG586.TextWrapped=true
NG586.Parent=NG585 NG587=Instance.new("IntValue")NG587.Value=80
NG587.Parent=NG585 NG588=Instance.new("Frame")NG588.BackgroundTransparency=1
NG588.BorderSizePixel=0 NG588.Name=dCD([=[Uryc]=])NG588.Position=UDim2.new(0,0,0,2) NG588.Size=UDim2.new(1,0,1,-22)NG588.Visible=false
NG588.Parent=NG580 NG589=Instance.new("TextLabel")NG589.BackgroundTransparency=1 NG589.BorderColor3=Color3.new(0,0,0)NG589.BorderSizePixel=0
NG589.Position=UDim2.new(0,10,0,0)NG589.Size=UDim2.new(1, -20,1,0)NG589.Font=Enum.Font.SourceSansBold NG589.FontSize=Enum.FontSize.Size14 NG589.Text=dCD([=[Sbe nyy srngherf gb or ninvynoyr, lbh fubhyq or va n tnzr freire (n erthyne tnzr, be crefbany ohvyqvat freire). Nygreangviryl, lbh pbhyq hfr gur Fghqvb cyhtva irefvba bs Ohvyqvat Gbbyf.]=])NG589.TextColor3=Color3.new(1,1,1) NG589.TextStrokeTransparency=0.80000001192093
NG589.TextWrapped=true
NG589.Parent=NG588 NG590=Instance.new("IntValue")NG590.Value=110
NG590.Parent=NG588 NG591=Instance.new("Frame")NG591.BackgroundColor3=Color3.new(0,0,0) NG591.BackgroundTransparency=0.69999998807907
NG591.BorderSizePixel=0
NG591.Name=dCD([=[CyhtvaHcqngrAbgvsvpngvba]=]) NG591.Size=UDim2.new(1,0,0,65)NG591.Visible=false
NG591.Parent=NG567 NG592=Instance.new("Frame")NG592.BackgroundColor3=Color3.new(1,0.666667,0) NG592.BorderSizePixel=0
NG592.Name=dCD([=[One]=])NG592.Size=UDim2.new(1,0,0,2) NG592.Parent=NG591
NG593=Instance.new("TextButton")NG593.Active=true NG593.BackgroundColor3=Color3.new(0,0,0)NG593.BackgroundTransparency=0.80000001192093 NG593.BorderColor3=Color3.new(0,0,0)NG593.BorderSizePixel=0
NG593.Name=dCD([=[BXOhggba]=]) NG593.Position=UDim2.new(0,0,1,-22)NG593.Selectable=true
NG593.Size=UDim2.new(0.5,0,0,22) NG593.Style=Enum.ButtonStyle.Custom
NG593.Font=Enum.Font.Arial NG593.FontSize=Enum.FontSize.Size10
NG593.Text=dCD([=[TBG VG]=])NG593.TextColor3=Color3.new(1,1,1) NG593.Parent=NG591
NG594=Instance.new("TextButton")NG594.Active=true NG594.BackgroundColor3=Color3.new(0,0,0)NG594.BackgroundTransparency=0.80000001192093 NG594.BorderColor3=Color3.new(0,0,0)NG594.BorderSizePixel=0
NG594.Name=dCD([=[UrycOhggba]=])NG594.Position=UDim2.new(0.5,0,1,- 22)NG594.Selectable=true NG594.Size=UDim2.new(0.5,0,0,22)NG594.Style=Enum.ButtonStyle.Custom NG594.Font=Enum.Font.Arial
NG594.FontSize=Enum.FontSize.Size10 NG594.Text=dCD([=[JUNG PNA V QB?]=])NG594.TextColor3=Color3.new(1,1,1)NG594.Parent=NG591 NG595=Instance.new("Frame")NG595.BackgroundColor3=Color3.new(0,0,0) NG595.BackgroundTransparency=0.75
NG595.BorderSizePixel=0
NG595.Name=dCD([=[OhggbaFrcnengbe]=])NG595.Position=UDim2.new(0.5,0,1, -22)NG595.Size=UDim2.new(0,1,0,22) NG595.Parent=NG591
NG596=Instance.new("Frame")NG596.BackgroundTransparency=1 NG596.BorderSizePixel=0
NG596.Name=dCD([=[Abgvpr]=])NG596.Position=UDim2.new(0,0,0,2)NG596.Size=UDim2.new(1,0,1, -22)NG596.Parent=NG591 NG597=Instance.new("TextLabel")NG597.BackgroundTransparency=1 NG597.BorderColor3=Color3.new(0,0,0)NG597.BorderSizePixel=0
NG597.Size=UDim2.new(1,0,1,0) NG597.Font=Enum.Font.SourceSansBold
NG597.FontSize=Enum.FontSize.Size14 NG597.Text=dCD([=[Guvf irefvba bs Ohvyqvat Gbbyf vf bhgqngrq.]=])NG597.TextColor3=Color3.new(1,1,1) NG597.TextStrokeTransparency=0.80000001192093
NG597.TextWrapped=true
NG597.Parent=NG596 NG598=Instance.new("IntValue")NG598.Value=65
NG598.Parent=NG596 NG599=Instance.new("Frame")NG599.BackgroundTransparency=1
NG599.BorderSizePixel=0 NG599.Name=dCD([=[Uryc]=])NG599.Position=UDim2.new(0,0,0,2) NG599.Size=UDim2.new(1,0,1,-22)NG599.Visible=false
NG599.Parent=NG591 NG600=Instance.new("TextLabel")NG600.BackgroundTransparency=1 NG600.BorderColor3=Color3.new(0,0,0)NG600.BorderSizePixel=0
NG600.Position=UDim2.new(0,10,0,0)NG600.Size=UDim2.new(1, -20,1,0)NG600.Font=Enum.Font.SourceSansBold NG600.FontSize=Enum.FontSize.Size14 NG600.Text=dCD([=[Tb gb Gbbyf > Znantr Cyhtvaf be Cyhtvaf > Znantr Cyhtvaf gb hcqngr cyhtvaf  :)]=])NG600.TextColor3=Color3.new(1,1,1) NG600.TextStrokeTransparency=0.80000001192093
NG600.TextWrapped=true
NG600.Parent=NG599 NG601=Instance.new("IntValue")NG601.Value=80
NG601.Parent=NG599 NG602=Instance.new("Frame")NG602.BackgroundColor3=Color3.new(0,0,0) NG602.BackgroundTransparency=0.69999998807907
NG602.BorderSizePixel=0
NG602.Name=dCD([=[UggcQvfnoyrqJneavat]=]) NG602.Size=UDim2.new(1,0,0,80)NG602.Visible=false
NG602.Parent=NG567 NG603=Instance.new("Frame")NG603.BackgroundColor3=Color3.new(1,0,0.0156863) NG603.BorderSizePixel=0
NG603.Name=dCD([=[One]=])NG603.Size=UDim2.new(1,0,0,2) NG603.Parent=NG602
NG604=Instance.new("TextButton")NG604.Active=true NG604.BackgroundColor3=Color3.new(0,0,0)NG604.BackgroundTransparency=0.80000001192093 NG604.BorderColor3=Color3.new(0,0,0)NG604.BorderSizePixel=0
NG604.Name=dCD([=[BXOhggba]=]) NG604.Position=UDim2.new(0,0,1,-22)NG604.Selectable=true
NG604.Size=UDim2.new(0.5,0,0,22) NG604.Style=Enum.ButtonStyle.Custom
NG604.Font=Enum.Font.Arial NG604.FontSize=Enum.FontSize.Size10
NG604.Text=dCD([=[TBG VG]=])NG604.TextColor3=Color3.new(1,1,1) NG604.Parent=NG602
NG605=Instance.new("TextButton")NG605.Active=true NG605.BackgroundColor3=Color3.new(0,0,0)NG605.BackgroundTransparency=0.80000001192093 NG605.BorderColor3=Color3.new(0,0,0)NG605.BorderSizePixel=0
NG605.Name=dCD([=[UrycOhggba]=])NG605.Position=UDim2.new(0.5,0,1,- 22)NG605.Selectable=true NG605.Size=UDim2.new(0.5,0,0,22)NG605.Style=Enum.ButtonStyle.Custom NG605.Font=Enum.Font.Arial
NG605.FontSize=Enum.FontSize.Size10 NG605.Text=dCD([=[JUNG PNA V QB?]=])NG605.TextColor3=Color3.new(1,1,1)NG605.Parent=NG602 NG606=Instance.new("Frame")NG606.BackgroundColor3=Color3.new(0,0,0) NG606.BackgroundTransparency=0.75
NG606.BorderSizePixel=0
NG606.Name=dCD([=[OhggbaFrcnengbe]=])NG606.Position=UDim2.new(0.5,0,1, -22)NG606.Size=UDim2.new(0,1,0,22) NG606.Parent=NG602
NG607=Instance.new("Frame")NG607.BackgroundTransparency=1 NG607.BorderSizePixel=0
NG607.Name=dCD([=[Abgvpr]=])NG607.Position=UDim2.new(0,0,0,2)NG607.Size=UDim2.new(1,0,1, -22)NG607.Parent=NG602 NG608=Instance.new("TextLabel")NG608.BackgroundTransparency=1 NG608.BorderColor3=Color3.new(0,0,0)NG608.BorderSizePixel=0
NG608.Size=UDim2.new(1,0,1,0) NG608.Font=Enum.Font.SourceSansBold
NG608.FontSize=Enum.FontSize.Size14 NG608.Text=dCD([=[Bu ab snz! UggcFreivpr vfa'g jbexvat ba lbhe pyvrag. Fbzr srngherf bs guvf unpxl s3k gbby jba'g jbex, vapyhqvat rkcbegvat.]=])NG608.TextColor3=Color3.new(1,1,1) NG608.TextStrokeTransparency=0.80000001192093
NG608.TextWrapped=true
NG608.Parent=NG607 NG609=Instance.new("IntValue")NG609.Value=80
NG609.Parent=NG607 NG610=Instance.new("Frame")NG610.BackgroundTransparency=1
NG610.BorderSizePixel=0 NG610.Name=dCD([=[Uryc]=])NG610.Position=UDim2.new(0,0,0,2) NG610.Size=UDim2.new(1,0,1,-22)NG610.Visible=false
NG610.Parent=NG602 NG611=Instance.new("TextLabel")NG611.BackgroundTransparency=1 NG611.BorderColor3=Color3.new(0,0,0)NG611.BorderSizePixel=0
NG611.Position=UDim2.new(0,10,0,0)NG611.Size=UDim2.new(1, -20,0.699999988,0) NG611.Font=Enum.Font.SourceSansBold
NG611.FontSize=Enum.FontSize.Size14 NG611.Text=dCD([=[Gurer vf abguvat lbh pna qb, vg vf rffragvnyyl bayl noyr gb jbex vs lbhe rkcybvg vf noyr gb ybnq UggcFreivpr.]=])NG611.TextColor3=Color3.new(1,1,1) NG611.TextStrokeTransparency=0.80000001192093
NG611.TextWrapped=true NG611.TextXAlignment=Enum.TextXAlignment.Left
NG611.Parent=NG610
NG612=Instance.new("TextLabel") NG612.BackgroundTransparency=1
NG612.BorderColor3=Color3.new(0,0,0)NG612.BorderSizePixel=0 NG612.Position=UDim2.new(0,10,0.649999976,0)NG612.Size=UDim2.new(1,-10,0.300000012,0) NG612.FontSize=Enum.FontSize.Size14
NG612.Text=dCD([=[V'z fbb fbeel 
( ~Avpxbnxm]=]) NG612.TextColor3=Color3.new(1,1,1)NG612.TextStrokeTransparency=0.80000001192093
NG612.TextWrapped=true NG612.TextXAlignment=Enum.TextXAlignment.Left
NG612.Parent=NG610
NG613=Instance.new("IntValue") NG613.Value=110
NG613.Parent=NG610
NG614=Instance.new("Frame") NG614.BackgroundColor3=Color3.new(0,0,0)NG614.BackgroundTransparency=0.69999998807907
NG614.BorderSizePixel=0 NG614.Name=dCD([=[UggcRanoyrqJneavat]=])NG614.Size=UDim2.new(1,0,0,80)NG614.Visible=false NG614.Parent=NG567
NG615=Instance.new("Frame") NG615.BackgroundColor3=Color3.new(0,0.666667,0)NG615.BorderSizePixel=0
NG615.Name=dCD([=[One]=]) NG615.Size=UDim2.new(1,0,0,2)NG615.Parent=NG614
NG616=Instance.new("TextButton") NG616.Active=true
NG616.BackgroundColor3=Color3.new(0,0,0) NG616.BackgroundTransparency=0.80000001192093
NG616.BorderColor3=Color3.new(0,0,0)NG616.BorderSizePixel=0 NG616.Name=dCD([=[BXOhggba]=])NG616.Position=UDim2.new(0,0,1,-22)NG616.Selectable=true NG616.Size=UDim2.new(0.5,0,0,22)NG616.Style=Enum.ButtonStyle.Custom NG616.Font=Enum.Font.Arial
NG616.FontSize=Enum.FontSize.Size10
NG616.Text=dCD([=[TBG VG]=]) NG616.TextColor3=Color3.new(1,1,1)NG616.Parent=NG614
NG617=Instance.new("TextButton") NG617.Active=true
NG617.BackgroundColor3=Color3.new(0,0,0) NG617.BackgroundTransparency=0.80000001192093
NG617.BorderColor3=Color3.new(0,0,0)NG617.BorderSizePixel=0 NG617.Name=dCD([=[UrycOhggba]=])NG617.Position=UDim2.new(0.5,0,1,-22)NG617.Selectable=true NG617.Size=UDim2.new(0.5,0,0,22)NG617.Style=Enum.ButtonStyle.Custom NG617.Font=Enum.Font.Arial
NG617.FontSize=Enum.FontSize.Size10 NG617.Text=dCD([=[JNVG JUNG?]=])NG617.TextColor3=Color3.new(1,1,1)NG617.Parent=NG614 NG618=Instance.new("Frame")NG618.BackgroundColor3=Color3.new(0,0,0) NG618.BackgroundTransparency=0.75
NG618.BorderSizePixel=0
NG618.Name=dCD([=[OhggbaFrcnengbe]=])NG618.Position=UDim2.new(0.5,0,1, -22)NG618.Size=UDim2.new(0,1,0,22) NG618.Parent=NG614
NG619=Instance.new("Frame")NG619.BackgroundTransparency=1 NG619.BorderSizePixel=0
NG619.Name=dCD([=[Abgvpr]=])NG619.Position=UDim2.new(0,0,0,2)NG619.Size=UDim2.new(1,0,1, -22)NG619.Parent=NG614 NG620=Instance.new("TextLabel")NG620.BackgroundTransparency=1 NG620.BorderColor3=Color3.new(0,0,0)NG620.BorderSizePixel=0
NG620.Size=UDim2.new(1,0,1,0) NG620.Font=Enum.Font.SourceSansBold
NG620.FontSize=Enum.FontSize.Size14 NG620.Text=dCD([=[JBB SNZ! UggcFreivpr jbexf sbe lbhe pyvrag! Lbh'yy or noyr gb fgrny cnegf sebz guvf tnzr hfvat guvf rkcybvg :)]=])NG620.TextColor3=Color3.new(1,1,1) NG620.TextStrokeTransparency=0.80000001192093
NG620.TextWrapped=true
NG620.Parent=NG619 NG621=Instance.new("IntValue")NG621.Value=80
NG621.Parent=NG619 NG622=Instance.new("Frame")NG622.BackgroundTransparency=1
NG622.BorderSizePixel=0 NG622.Name=dCD([=[Uryc]=])NG622.Position=UDim2.new(0,0,0,2) NG622.Size=UDim2.new(1,0,1,-22)NG622.Visible=false
NG622.Parent=NG614 NG623=Instance.new("TextLabel")NG623.BackgroundTransparency=1 NG623.BorderColor3=Color3.new(0,0,0)NG623.BorderSizePixel=0
NG623.Position=UDim2.new(0,10,0,0)NG623.Size=UDim2.new(1, -20,0.300000012,0) NG623.Font=Enum.Font.SourceSansBold
NG623.FontSize=Enum.FontSize.Size14 NG623.Text=dCD([=[Jung qb lbh zrna gung UGGCFreivpr vf ba?]=])NG623.TextColor3=Color3.new(1,1,1) NG623.TextStrokeTransparency=0.80000001192093
NG623.TextWrapped=true NG623.TextXAlignment=Enum.TextXAlignment.Left
NG623.Parent=NG622
NG624=Instance.new("TextLabel") NG624.BackgroundTransparency=1
NG624.BorderColor3=Color3.new(0,0,0)NG624.BorderSizePixel=0 NG624.Position=UDim2.new(0,10,0.200000003,0)NG624.Size=UDim2.new(1,-10,0.800000012,0) NG624.FontSize=Enum.FontSize.Size14 NG624.Text=dCD([=[Jryy hzz, lbh pna fryrpg n gba bs cnegf vatnzr, naq rkcbeg vg guebhtu guvf unpxl s3k gbby, naq or noyr gb fgrny gurz guebhtu Eboybk Fghqvb? Lrnu, gungf pbby snz!]=])NG624.TextColor3=Color3.new(1,1,1) NG624.TextStrokeTransparency=0.80000001192093
NG624.TextWrapped=true NG624.TextXAlignment=Enum.TextXAlignment.Left
NG624.Parent=NG622
NG625=Instance.new("IntValue") NG625.Value=110
NG625.Parent=NG622
NG626=Instance.new("Frame") NG626.BackgroundColor3=Color3.new(0,0,0)NG626.BackgroundTransparency=0.69999998807907
NG626.BorderSizePixel=0 NG626.Name=dCD([=[JrypbzrSrk]=])NG626.Size=UDim2.new(1,0,0,80)NG626.Visible=false NG626.Parent=NG567
NG627=Instance.new("TextButton")NG627.Active=true NG627.BackgroundColor3=Color3.new(0,0,0)NG627.BackgroundTransparency=0.80000001192093 NG627.BorderColor3=Color3.new(0,0,0)NG627.BorderSizePixel=0
NG627.Name=dCD([=[BXOhggba]=]) NG627.Position=UDim2.new(0,0,1,-22)NG627.Selectable=true
NG627.Size=UDim2.new(0.5,0,0,22) NG627.Style=Enum.ButtonStyle.Custom
NG627.Font=Enum.Font.Arial NG627.FontSize=Enum.FontSize.Size10
NG627.Text=dCD([=[TBG VG]=])NG627.TextColor3=Color3.new(1,1,1) NG627.Parent=NG626
NG628=Instance.new("TextButton")NG628.Active=true NG628.BackgroundColor3=Color3.new(0,0,0)NG628.BackgroundTransparency=0.80000001192093 NG628.BorderColor3=Color3.new(0,0,0)NG628.BorderSizePixel=0
NG628.Name=dCD([=[UrycOhggba]=])NG628.Position=UDim2.new(0.5,0,1,- 22)NG628.Selectable=true NG628.Size=UDim2.new(0.5,0,0,22)NG628.Style=Enum.ButtonStyle.Custom NG628.Font=Enum.Font.Arial
NG628.FontSize=Enum.FontSize.Size10 NG628.Text=dCD([=[JUNG PNA V QB?]=])NG628.TextColor3=Color3.new(1,1,1)NG628.Parent=NG626 NG629=Instance.new("Frame")NG629.BackgroundColor3=Color3.new(0,0,0) NG629.BackgroundTransparency=0.75
NG629.BorderSizePixel=0
NG629.Name=dCD([=[OhggbaFrcnengbe]=])NG629.Position=UDim2.new(0.5,0,1, -22)NG629.Size=UDim2.new(0,1,0,22) NG629.Parent=NG626
NG630=Instance.new("Frame")NG630.BackgroundTransparency=1 NG630.BorderSizePixel=0
NG630.Name=dCD([=[Abgvpr]=])NG630.Position=UDim2.new(0,0,0,2)NG630.Size=UDim2.new(1,0,1, -22)NG630.Parent=NG626 NG631=Instance.new("TextLabel")NG631.BackgroundTransparency=1 NG631.BorderColor3=Color3.new(0,0,0)NG631.BorderSizePixel=0
NG631.Size=UDim2.new(1,0,1,0) NG631.Font=Enum.Font.SourceSansBold
NG631.FontSize=Enum.FontSize.Size14 NG631.Text=dCD([=[S3KSbepr vf ehaavat. Znqr ol Avpxbnxm]=])NG631.TextColor3=Color3.new(1,1,1) NG631.TextStrokeTransparency=0.80000001192093
NG631.TextWrapped=true
NG631.Parent=NG630 NG632=Instance.new("IntValue")NG632.Value=80
NG632.Parent=NG630 NG633=Instance.new("Frame")NG633.BackgroundTransparency=1
NG633.BorderSizePixel=0 NG633.Name=dCD([=[Uryc]=])NG633.Position=UDim2.new(0,0,0,2) NG633.Size=UDim2.new(1,0,1,-22)NG633.Visible=false
NG633.Parent=NG626 NG634=Instance.new("TextLabel")NG634.BackgroundTransparency=1 NG634.BorderColor3=Color3.new(0,0,0)NG634.BorderSizePixel=0
NG634.Position=UDim2.new(0,10,0,0)NG634.Size=UDim2.new(1, -20,0.699999988,0) NG634.Font=Enum.Font.SourceSansBold
NG634.FontSize=Enum.FontSize.Size14 NG634.Text=dCD([=[Unir sha?]=])NG634.TextColor3=Color3.new(1,1,1) NG634.TextStrokeTransparency=0.80000001192093
NG634.TextWrapped=true NG634.TextXAlignment=Enum.TextXAlignment.Left
NG634.Parent=NG633
NG635=Instance.new("TextLabel") NG635.BackgroundTransparency=1
NG635.BorderColor3=Color3.new(0,0,0)NG635.BorderSizePixel=0 NG635.Position=UDim2.new(0,10,0.649999976,0)NG635.Size=UDim2.new(1,-10,0.300000012,0) NG635.FontSize=Enum.FontSize.Size14
NG635.Text=dCD([=[~Avpxbnxm]=]) NG635.TextColor3=Color3.new(1,1,1)NG635.TextStrokeTransparency=0.80000001192093
NG635.TextWrapped=true NG635.TextXAlignment=Enum.TextXAlignment.Left
NG635.Parent=NG633
NG636=Instance.new("IntValue") NG636.Value=110
NG636.Parent=NG633
NG637=Instance.new("Frame") NG637.BackgroundTransparency=1
NG637.BorderSizePixel=0
NG637.Name=dCD([=[ObggbzPbybeOne]=]) NG637.Position=UDim2.new(0,0,1,0)NG637.Rotation=180
NG637.Size=UDim2.new(1,0,0,3) NG637.Parent=NG626
NG638=Instance.new("Frame") NG638.BackgroundColor3=Color3.new(1,0.686275,0)NG638.BackgroundTransparency=0.25
NG638.BorderSizePixel=0 NG638.Name=dCD([=[Lryybj]=])NG638.Size=UDim2.new(0.200000003,0,1,0)NG638.Parent=NG637 NG639=Instance.new("Frame") NG639.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG639.BackgroundTransparency=0.25
NG639.BorderSizePixel=0 NG639.Name=dCD([=[Terra]=])NG639.Position=UDim2.new(0.200000003,0,0,0) NG639.Size=UDim2.new(0.200000003,0,1,0)NG639.Parent=NG637
NG640=Instance.new("Frame") NG640.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG640.BackgroundTransparency=0.25
NG640.BorderSizePixel=0 NG640.Name=dCD([=[Oyhr]=])NG640.Position=UDim2.new(0.400000006,0,0,0) NG640.Size=UDim2.new(0.200000003,0,1,0)NG640.Parent=NG637
NG641=Instance.new("Frame") NG641.BackgroundColor3=Color3.new(1,0,0)NG641.BackgroundTransparency=0.25
NG641.BorderSizePixel=0 NG641.Name=dCD([=[Erq]=])NG641.Position=UDim2.new(0.600000024,0,0,0) NG641.Size=UDim2.new(0.200000003,0,1,0)NG641.Parent=NG637
NG642=Instance.new("Frame") NG642.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG642.BackgroundTransparency=0.25
NG642.BorderSizePixel=0 NG642.Name=dCD([=[Checyr]=])NG642.Position=UDim2.new(0.800000012,0,0,0) NG642.Size=UDim2.new(0.200000003,0,1,0)NG642.Parent=NG637
NG643=Instance.new("Frame") NG643.BackgroundTransparency=1
NG643.BorderSizePixel=0
NG643.Name=dCD([=[GbcPbybeOne]=])NG643.Position=UDim2.new(0,0,0,- 2)NG643.Rotation=180 NG643.Size=UDim2.new(1,0,0,3)NG643.Parent=NG626
NG644=Instance.new("Frame") NG644.BackgroundColor3=Color3.new(1,0.686275,0)NG644.BackgroundTransparency=0.25
NG644.BorderSizePixel=0 NG644.Name=dCD([=[Lryybj]=])NG644.Size=UDim2.new(0.200000003,0,1,0)NG644.Parent=NG643 NG645=Instance.new("Frame") NG645.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG645.BackgroundTransparency=0.25
NG645.BorderSizePixel=0 NG645.Name=dCD([=[Terra]=])NG645.Position=UDim2.new(0.200000003,0,0,0) NG645.Size=UDim2.new(0.200000003,0,1,0)NG645.Parent=NG643
NG646=Instance.new("Frame") NG646.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG646.BackgroundTransparency=0.25
NG646.BorderSizePixel=0 NG646.Name=dCD([=[Oyhr]=])NG646.Position=UDim2.new(0.400000006,0,0,0) NG646.Size=UDim2.new(0.200000003,0,1,0)NG646.Parent=NG643
NG647=Instance.new("Frame") NG647.BackgroundColor3=Color3.new(1,0,0)NG647.BackgroundTransparency=0.25
NG647.BorderSizePixel=0 NG647.Name=dCD([=[Erq]=])NG647.Position=UDim2.new(0.600000024,0,0,0) NG647.Size=UDim2.new(0.200000003,0,1,0)NG647.Parent=NG643
NG648=Instance.new("Frame") NG648.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG648.BackgroundTransparency=0.25
NG648.BorderSizePixel=0 NG648.Name=dCD([=[Checyr]=])NG648.Position=UDim2.new(0.800000012,0,0,0) NG648.Size=UDim2.new(0.200000003,0,1,0)NG648.Parent=NG643
NG649=Instance.new("Frame") NG649.Active=true
NG649.BackgroundColor3=Color3.new(0,0,0) NG649.BackgroundTransparency=1 NG649.BorderColor3=Color3.new(0.137255,0.137255,0.137255)NG649.BorderSizePixel=0
NG649.Name=dCD([=[OGQbpxTHV]=]) NG649.Position=UDim2.new(0.699999988,0,0.300000012,0)NG649.Size=UDim2.new(0,70,0,380)NG649.Draggable=true NG649.Parent=NG1
NG650=Instance.new("Frame")NG650.BackgroundTransparency=1 NG650.BorderSizePixel=0
NG650.Name=dCD([=[Gbbygvcf]=]) NG650.Position=UDim2.new(0,-120,0,0)NG650.Size=UDim2.new(0,120,0,315)NG650.Parent=NG649 NG651=Instance.new("Frame") NG651.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG651.BackgroundTransparency=0.20000000298023
NG651.BorderSizePixel=0 NG651.Name=dCD([=[CnvagVasb]=])NG651.Size=UDim2.new(1,0,1,0)NG651.Visible=false NG651.Parent=NG650
NG652=Instance.new("Frame")NG652.BackgroundTransparency=1 NG652.BorderSizePixel=0
NG652.Name=dCD([=[Pbagrag]=])NG652.Size=UDim2.new(1,0,0,70) NG652.Parent=NG651
NG653=Instance.new("Frame") NG653.BackgroundColor3=Color3.new(1,0,0)NG653.BorderSizePixel=0
NG653.Name=dCD([=[PbybeOne]=]) NG653.Size=UDim2.new(1,0,0,2)NG653.Parent=NG652
NG654=Instance.new("TextLabel") NG654.BackgroundTransparency=1
NG654.BorderSizePixel=0
NG654.Name=dCD([=[GbbyQrfpevcgvba]=]) NG654.Position=UDim2.new(0,10,0,25)NG654.Size=UDim2.new(0,82,0,50) NG654.Font=Enum.Font.Arial
NG654.FontSize=Enum.FontSize.Size10 NG654.Text=dCD([=[Nyybjf lbh gb punatr gur pbybe bs cnegf.]=])NG654.TextColor3=Color3.new(1,1,1)NG654.TextWrapped=true NG654.TextXAlignment=Enum.TextXAlignment.Left
NG654.TextYAlignment=Enum.TextYAlignment.Top NG654.Parent=NG652
NG655=Instance.new("TextLabel") NG655.BackgroundTransparency=1
NG655.BorderSizePixel=0
NG655.Name=dCD([=[GbbyAnzr]=]) NG655.Position=UDim2.new(0,10,0,0)NG655.Size=UDim2.new(0,50,0,25) NG655.Font=Enum.Font.ArialBold
NG655.FontSize=Enum.FontSize.Size10 NG655.Text=dCD([=[CNVAG GBBY]=])NG655.TextColor3=Color3.new(1,1,1) NG655.TextXAlignment=Enum.TextXAlignment.Left
NG655.Parent=NG652
NG656=Instance.new("Frame") NG656.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG656.BackgroundTransparency=0.20000000298023
NG656.BorderSizePixel=0 NG656.Name=dCD([=[FhesnprVasb]=])NG656.Size=UDim2.new(1,0,1,0)NG656.Visible=false NG656.Parent=NG650
NG657=Instance.new("Frame")NG657.BackgroundTransparency=1 NG657.BorderSizePixel=0
NG657.Name=dCD([=[Pbagrag]=])NG657.Size=UDim2.new(1,0,0,150) NG657.Parent=NG656
NG658=Instance.new("Frame") NG658.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG658.BorderSizePixel=0
NG658.Name=dCD([=[PbybeOne]=]) NG658.Size=UDim2.new(1,0,0,2)NG658.Parent=NG657
NG659=Instance.new("TextLabel") NG659.BackgroundTransparency=1
NG659.BorderSizePixel=0
NG659.Name=dCD([=[GbbyQrfpevcgvba]=]) NG659.Position=UDim2.new(0,10,0,25)NG659.Size=UDim2.new(0,82,0,120) NG659.Font=Enum.Font.Arial
NG659.FontSize=Enum.FontSize.Size10 NG659.Text=dCD([=[Yrgf lbh punatr gur fhesnpr glcr bs cnegf.  GVC: Lbh pna fryrpg gur fvqr gb punatr ol evtug pyvpxvat ba n cneg'f fvqr.]=])NG659.TextColor3=Color3.new(1,1,1)NG659.TextWrapped=true NG659.TextXAlignment=Enum.TextXAlignment.Left
NG659.TextYAlignment=Enum.TextYAlignment.Top NG659.Parent=NG657
NG660=Instance.new("TextLabel") NG660.BackgroundTransparency=1
NG660.BorderSizePixel=0
NG660.Name=dCD([=[GbbyAnzr]=]) NG660.Position=UDim2.new(0,10,0,0)NG660.Size=UDim2.new(0,50,0,25) NG660.Font=Enum.Font.ArialBold
NG660.FontSize=Enum.FontSize.Size10 NG660.Text=dCD([=[FHESNPR GBBY]=])NG660.TextColor3=Color3.new(1,1,1) NG660.TextXAlignment=Enum.TextXAlignment.Left
NG660.Parent=NG657
NG661=Instance.new("Frame") NG661.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG661.BackgroundTransparency=0.20000000298023
NG661.BorderSizePixel=0 NG661.Name=dCD([=[ZngrevnyVasb]=])NG661.Size=UDim2.new(1,0,1,0)NG661.Visible=false NG661.Parent=NG650
NG662=Instance.new("Frame")NG662.BackgroundTransparency=1 NG662.BorderSizePixel=0
NG662.Name=dCD([=[Pbagrag]=])NG662.Size=UDim2.new(1,0,0,150) NG662.Parent=NG661
NG663=Instance.new("Frame") NG663.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG663.BorderSizePixel=0
NG663.Name=dCD([=[PbybeOne]=]) NG663.Size=UDim2.new(1,0,0,2)NG663.Parent=NG662
NG664=Instance.new("TextLabel") NG664.BackgroundTransparency=1
NG664.BorderSizePixel=0
NG664.Name=dCD([=[GbbyQrfpevcgvba]=]) NG664.Position=UDim2.new(0,10,0,25)NG664.Size=UDim2.new(0,80,0,120) NG664.Font=Enum.Font.Arial
NG664.FontSize=Enum.FontSize.Size10 NG664.Text=dCD([=[Yrgf lbh punatr gur zngrevny, genafcnerapl, naq ersyrpgnapr bs cnegf.]=])NG664.TextColor3=Color3.new(1,1,1)NG664.TextWrapped=true NG664.TextXAlignment=Enum.TextXAlignment.Left
NG664.TextYAlignment=Enum.TextYAlignment.Top NG664.Parent=NG662
NG665=Instance.new("TextLabel") NG665.BackgroundTransparency=1
NG665.BorderSizePixel=0
NG665.Name=dCD([=[GbbyAnzr]=]) NG665.Position=UDim2.new(0,10,0,0)NG665.Size=UDim2.new(0,50,0,25) NG665.Font=Enum.Font.ArialBold
NG665.FontSize=Enum.FontSize.Size10 NG665.Text=dCD([=[ZNGREVNY GBBY]=])NG665.TextColor3=Color3.new(1,1,1) NG665.TextXAlignment=Enum.TextXAlignment.Left
NG665.Parent=NG662
NG666=Instance.new("Frame") NG666.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG666.BackgroundTransparency=0.20000000298023
NG666.BorderSizePixel=0 NG666.Name=dCD([=[PbyyvfvbaVasb]=])NG666.Size=UDim2.new(1,0,1,0)NG666.Visible=false NG666.Parent=NG650
NG667=Instance.new("Frame")NG667.BackgroundTransparency=1 NG667.BorderSizePixel=0
NG667.Name=dCD([=[Pbagrag]=])NG667.Size=UDim2.new(1,0,0,150) NG667.Parent=NG666
NG668=Instance.new("Frame") NG668.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG668.BorderSizePixel=0
NG668.Name=dCD([=[PbybeOne]=]) NG668.Size=UDim2.new(1,0,0,2)NG668.Parent=NG667
NG669=Instance.new("TextLabel") NG669.BackgroundTransparency=1
NG669.BorderSizePixel=0
NG669.Name=dCD([=[GbbyQrfpevcgvba]=]) NG669.Position=UDim2.new(0,10,0,25)NG669.Size=UDim2.new(0,80,0,120) NG669.Font=Enum.Font.Arial
NG669.FontSize=Enum.FontSize.Size10 NG669.Text=dCD([=[Yrgf lbh punatr jurgure gur cnegf pbyyvqr jvgu bguref be abg.  GVC: Lbh pna gbttyr pbyyvfvba ol cerffvat Ragre.]=])NG669.TextColor3=Color3.new(1,1,1)NG669.TextWrapped=true NG669.TextXAlignment=Enum.TextXAlignment.Left
NG669.TextYAlignment=Enum.TextYAlignment.Top NG669.Parent=NG667
NG670=Instance.new("TextLabel") NG670.BackgroundTransparency=1
NG670.BorderSizePixel=0
NG670.Name=dCD([=[GbbyAnzr]=]) NG670.Position=UDim2.new(0,10,0,0)NG670.Size=UDim2.new(0,50,0,25) NG670.Font=Enum.Font.ArialBold
NG670.FontSize=Enum.FontSize.Size10 NG670.Text=dCD([=[PBYYVFVBA GBBY]=])NG670.TextColor3=Color3.new(1,1,1) NG670.TextXAlignment=Enum.TextXAlignment.Left
NG670.Parent=NG667
NG671=Instance.new("Frame") NG671.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG671.BackgroundTransparency=0.20000000298023
NG671.BorderSizePixel=0 NG671.Name=dCD([=[NapubeVasb]=])NG671.Size=UDim2.new(1,0,1,0)NG671.Visible=false NG671.Parent=NG650
NG672=Instance.new("Frame")NG672.BackgroundTransparency=1 NG672.BorderSizePixel=0
NG672.Name=dCD([=[Pbagrag]=])NG672.Size=UDim2.new(1,0,0,150) NG672.Parent=NG671
NG673=Instance.new("Frame") NG673.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG673.BorderSizePixel=0
NG673.Name=dCD([=[PbybeOne]=]) NG673.Size=UDim2.new(1,0,0,2)NG673.Parent=NG672
NG674=Instance.new("TextLabel") NG674.BackgroundTransparency=1
NG674.BorderSizePixel=0
NG674.Name=dCD([=[GbbyQrfpevcgvba]=]) NG674.Position=UDim2.new(0,10,0,25)NG674.Size=UDim2.new(0,80,0,120) NG674.Font=Enum.Font.Arial
NG674.FontSize=Enum.FontSize.Size10 NG674.Text=dCD([=[Yrgf lbh napube naq hanapube cnegf.  GVC: Lbh pna cerff Ragre gb gbttyr gur napube dhvpxyl.]=])NG674.TextColor3=Color3.new(1,1,1)NG674.TextWrapped=true NG674.TextXAlignment=Enum.TextXAlignment.Left
NG674.TextYAlignment=Enum.TextYAlignment.Top NG674.Parent=NG672
NG675=Instance.new("TextLabel") NG675.BackgroundTransparency=1
NG675.BorderSizePixel=0
NG675.Name=dCD([=[GbbyAnzr]=]) NG675.Position=UDim2.new(0,10,0,0)NG675.Size=UDim2.new(0,50,0,25) NG675.Font=Enum.Font.ArialBold
NG675.FontSize=Enum.FontSize.Size10 NG675.Text=dCD([=[NAPUBE GBBY]=])NG675.TextColor3=Color3.new(1,1,1) NG675.TextXAlignment=Enum.TextXAlignment.Left
NG675.Parent=NG672
NG676=Instance.new("Frame") NG676.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG676.BackgroundTransparency=0.20000000298023
NG676.BorderSizePixel=0 NG676.Name=dCD([=[ArjCnegVasb]=])NG676.Size=UDim2.new(1,0,1,0)NG676.Visible=false NG676.Parent=NG650
NG677=Instance.new("Frame")NG677.BackgroundTransparency=1 NG677.BorderSizePixel=0
NG677.Name=dCD([=[Pbagrag]=])NG677.Size=UDim2.new(1,0,0,150) NG677.Parent=NG676
NG678=Instance.new("Frame") NG678.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG678.BorderSizePixel=0
NG678.Name=dCD([=[PbybeOne]=]) NG678.Size=UDim2.new(1,0,0,2)NG678.Parent=NG677
NG679=Instance.new("TextLabel") NG679.BackgroundTransparency=1
NG679.BorderSizePixel=0
NG679.Name=dCD([=[GbbyQrfpevcgvba]=]) NG679.Position=UDim2.new(0,10,0,25)NG679.Size=UDim2.new(0,80,0,120) NG679.Font=Enum.Font.Arial
NG679.FontSize=Enum.FontSize.Size10 NG679.Text=dCD([=[Yrgf lbh perngr arj cnegf bs qvssrerag glcrf.  Fryrpg gur cneg glcr, gura pyvpx naq qent gb cynpr gur cneg.]=])NG679.TextColor3=Color3.new(1,1,1)NG679.TextWrapped=true NG679.TextXAlignment=Enum.TextXAlignment.Left
NG679.TextYAlignment=Enum.TextYAlignment.Top NG679.Parent=NG677
NG680=Instance.new("TextLabel") NG680.BackgroundTransparency=1
NG680.BorderSizePixel=0
NG680.Name=dCD([=[GbbyAnzr]=]) NG680.Position=UDim2.new(0,10,0,0)NG680.Size=UDim2.new(0,50,0,25) NG680.Font=Enum.Font.ArialBold
NG680.FontSize=Enum.FontSize.Size10 NG680.Text=dCD([=[ARJ CNEG GBBY]=])NG680.TextColor3=Color3.new(1,1,1) NG680.TextXAlignment=Enum.TextXAlignment.Left
NG680.Parent=NG677
NG681=Instance.new("Frame") NG681.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG681.BackgroundTransparency=0.20000000298023
NG681.BorderSizePixel=0 NG681.Name=dCD([=[ZrfuVasb]=])NG681.Size=UDim2.new(1,0,1,0)NG681.Visible=false NG681.Parent=NG650
NG682=Instance.new("Frame")NG682.BackgroundTransparency=1 NG682.BorderSizePixel=0
NG682.Name=dCD([=[Pbagrag]=])NG682.Size=UDim2.new(1,0,0,150) NG682.Parent=NG681
NG683=Instance.new("Frame") NG683.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG683.BorderSizePixel=0
NG683.Name=dCD([=[PbybeOne]=]) NG683.Size=UDim2.new(1,0,0,2)NG683.Parent=NG682
NG684=Instance.new("TextLabel") NG684.BackgroundTransparency=1
NG684.BorderSizePixel=0
NG684.Name=dCD([=[GbbyQrfpevcgvba]=]) NG684.Position=UDim2.new(0,10,0,25)NG684.Size=UDim2.new(0,84,0,260) NG684.Font=Enum.Font.Arial
NG684.FontSize=Enum.FontSize.Size10 NG684.Text=dCD([=[Yrgf lbh nqq zrfurf gb cnegf.  Vs lbh'er hfvat n svyr zrfu, lbh pna cnfgr gur HEY bs nalguvat jvgu n zrfu (r.t. n ung, trne, rgp.) naq vg jvyy svaq gur evtug zrfu/grkgher VQ sbe lbh.  ABGR: Vs UggcFreivpr vf abg ranoyrq, lbh zhfg glcr gur VQ bs gur zrfu/vzntr nffrg qverpgyl.]=])NG684.TextColor3=Color3.new(1,1,1)NG684.TextWrapped=true NG684.TextXAlignment=Enum.TextXAlignment.Left
NG684.TextYAlignment=Enum.TextYAlignment.Top NG684.Parent=NG682
NG685=Instance.new("TextLabel") NG685.BackgroundTransparency=1
NG685.BorderSizePixel=0
NG685.Name=dCD([=[GbbyAnzr]=]) NG685.Position=UDim2.new(0,10,0,0)NG685.Size=UDim2.new(0,50,0,25) NG685.Font=Enum.Font.ArialBold
NG685.FontSize=Enum.FontSize.Size10 NG685.Text=dCD([=[ZRFU GBBY]=])NG685.TextColor3=Color3.new(1,1,1) NG685.TextXAlignment=Enum.TextXAlignment.Left
NG685.Parent=NG682
NG686=Instance.new("Frame") NG686.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG686.BackgroundTransparency=0.20000000298023
NG686.BorderSizePixel=0 NG686.Name=dCD([=[GrkgherVasb]=])NG686.Size=UDim2.new(1,0,1,0)NG686.Visible=false NG686.Parent=NG650
NG687=Instance.new("Frame")NG687.BackgroundTransparency=1 NG687.BorderSizePixel=0
NG687.Name=dCD([=[Pbagrag]=])NG687.Size=UDim2.new(1,0,0,150) NG687.Parent=NG686
NG688=Instance.new("Frame") NG688.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG688.BorderSizePixel=0
NG688.Name=dCD([=[PbybeOne]=]) NG688.Size=UDim2.new(1,0,0,2)NG688.Parent=NG687
NG689=Instance.new("TextLabel") NG689.BackgroundTransparency=1
NG689.BorderSizePixel=0
NG689.Name=dCD([=[GbbyQrfpevcgvba]=]) NG689.Position=UDim2.new(0,10,0,25)NG689.Size=UDim2.new(0,84,0,250) NG689.Font=Enum.Font.Arial
NG689.FontSize=Enum.FontSize.Size10 NG689.Text=dCD([=[Yrgf lbh nqq qrpnyf naq grkgherf gb cnegf. Fvzcyl nqq n arj qrpny be grkgher, naq cnfgr gur HEY bs gur qrpny lbh jnag gb nqq.  GVC: Lbh pna fryrpg gur qrpny/grkgher fvqr ol evtug pyvpxvat.  ABGR: Vs UggcFreivpr vf abg ranoyrq, lbh zhfg glcr gur VQ bs gur vzntr vgrz (abg gur qrpny). Guvf pna hfhnyyl or sbhaq ol fhogenpgvat bar sebz gur VQ ahzore.]=])NG689.TextColor3=Color3.new(1,1,1)NG689.TextWrapped=true NG689.TextXAlignment=Enum.TextXAlignment.Left
NG689.TextYAlignment=Enum.TextYAlignment.Top NG689.Parent=NG687
NG690=Instance.new("TextLabel") NG690.BackgroundTransparency=1
NG690.BorderSizePixel=0
NG690.Name=dCD([=[GbbyAnzr]=]) NG690.Position=UDim2.new(0,10,0,0)NG690.Size=UDim2.new(0,50,0,25) NG690.Font=Enum.Font.ArialBold
NG690.FontSize=Enum.FontSize.Size10 NG690.Text=dCD([=[GRKGHER GBBY]=])NG690.TextColor3=Color3.new(1,1,1) NG690.TextXAlignment=Enum.TextXAlignment.Left
NG690.Parent=NG687
NG691=Instance.new("Frame") NG691.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG691.BackgroundTransparency=0.20000000298023
NG691.BorderSizePixel=0 NG691.Name=dCD([=[YvtugvatVasb]=])NG691.Size=UDim2.new(1,0,1,0)NG691.Visible=false NG691.Parent=NG650
NG692=Instance.new("Frame")NG692.BackgroundTransparency=1 NG692.BorderSizePixel=0
NG692.Name=dCD([=[Pbagrag]=])NG692.Size=UDim2.new(1,0,0,100) NG692.Parent=NG691
NG693=Instance.new("Frame") NG693.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG693.BorderSizePixel=0
NG693.Name=dCD([=[PbybeOne]=]) NG693.Size=UDim2.new(1,0,0,2)NG693.Parent=NG692
NG694=Instance.new("TextLabel") NG694.BackgroundTransparency=1
NG694.BorderSizePixel=0
NG694.Name=dCD([=[GbbyQrfpevcgvba]=]) NG694.Position=UDim2.new(0,10,0,25)NG694.Size=UDim2.new(0,80,0,200) NG694.Font=Enum.Font.Arial
NG694.FontSize=Enum.FontSize.Size10 NG694.Text=dCD([=[Nyybjf lbh gb nqq fcbgyvtugf be cbvag yvtugf gb cnegf.]=])NG694.TextColor3=Color3.new(1,1,1)NG694.TextWrapped=true NG694.TextXAlignment=Enum.TextXAlignment.Left
NG694.TextYAlignment=Enum.TextYAlignment.Top NG694.Parent=NG692
NG695=Instance.new("TextLabel") NG695.BackgroundTransparency=1
NG695.BorderSizePixel=0
NG695.Name=dCD([=[GbbyAnzr]=]) NG695.Position=UDim2.new(0,10,0,0)NG695.Size=UDim2.new(0,50,0,25) NG695.Font=Enum.Font.ArialBold
NG695.FontSize=Enum.FontSize.Size10 NG695.Text=dCD([=[YVTUGVAT GBBY]=])NG695.TextColor3=Color3.new(1,1,1) NG695.TextXAlignment=Enum.TextXAlignment.Left
NG695.Parent=NG692
NG696=Instance.new("Frame") NG696.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG696.BackgroundTransparency=0.20000000298023
NG696.BorderSizePixel=0 NG696.Name=dCD([=[QrpbengrVasb]=])NG696.Size=UDim2.new(1,0,1,0)NG696.Visible=false NG696.Parent=NG650
NG697=Instance.new("Frame")NG697.BackgroundTransparency=1 NG697.BorderSizePixel=0
NG697.Name=dCD([=[Pbagrag]=])NG697.Size=UDim2.new(1,0,0,100) NG697.Parent=NG696
NG698=Instance.new("Frame") NG698.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG698.BorderSizePixel=0
NG698.Name=dCD([=[PbybeOne]=]) NG698.Size=UDim2.new(1,0,0,2)NG698.Parent=NG697
NG699=Instance.new("TextLabel") NG699.BackgroundTransparency=1
NG699.BorderSizePixel=0
NG699.Name=dCD([=[GbbyQrfpevcgvba]=]) NG699.Position=UDim2.new(0,10,0,25)NG699.Size=UDim2.new(0,80,0,200) NG699.Font=Enum.Font.Arial
NG699.FontSize=Enum.FontSize.Size10 NG699.Text=dCD([=[Nyybjf lbh gb nqq fzbxr, sver, naq fcnexyrf gb cnegf.]=])NG699.TextColor3=Color3.new(1,1,1)NG699.TextWrapped=true NG699.TextXAlignment=Enum.TextXAlignment.Left
NG699.TextYAlignment=Enum.TextYAlignment.Top NG699.Parent=NG697
NG700=Instance.new("TextLabel") NG700.BackgroundTransparency=1
NG700.BorderSizePixel=0
NG700.Name=dCD([=[GbbyAnzr]=]) NG700.Position=UDim2.new(0,10,0,0)NG700.Size=UDim2.new(0,50,0,25) NG700.Font=Enum.Font.ArialBold
NG700.FontSize=Enum.FontSize.Size10 NG700.Text=dCD([=[QRPBENGR GBBY]=])NG700.TextColor3=Color3.new(1,1,1) NG700.TextXAlignment=Enum.TextXAlignment.Left
NG700.Parent=NG697
NG701=Instance.new("Frame") NG701.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG701.BackgroundTransparency=0.20000000298023
NG701.BorderSizePixel=0 NG701.Name=dCD([=[ZbirVasb]=])NG701.Size=UDim2.new(1,0,1,0)NG701.Visible=false NG701.Parent=NG650
NG702=Instance.new("Frame")NG702.BackgroundTransparency=1 NG702.BorderSizePixel=0
NG702.Name=dCD([=[Pbagrag]=])NG702.Size=UDim2.new(1,0,0,500) NG702.Parent=NG701
NG703=Instance.new("Frame")NG703.BackgroundTransparency=1 NG703.BorderSizePixel=0
NG703.Name=dCD([=[NkrfVasb]=])NG703.Position=UDim2.new(0,0,0,60) NG703.Size=UDim2.new(1,0,0,300)NG703.Parent=NG702
NG704=Instance.new("Frame") NG704.BackgroundColor3=Color3.new(1,0.666667,0)NG704.BorderSizePixel=0
NG704.Position=UDim2.new(0,10,0,83) NG704.Size=UDim2.new(0,2,0,123)NG704.Parent=NG703
NG705=Instance.new("TextLabel") NG705.BackgroundTransparency=1
NG705.BorderSizePixel=0
NG705.Position=UDim2.new(0,17,0,83) NG705.Size=UDim2.new(0,80,0,180)NG705.Font=Enum.Font.Arial NG705.FontSize=Enum.FontSize.Size10 NG705.Text=dCD([=[TYBONY - Abezny  YBPNY - Eryngvir gb rnpu cneg  YNFG - Eryngvir gb gur ynfg cneg fryrpgrq]=])NG705.TextColor3=Color3.new(1,1,1)NG705.TextWrapped=true NG705.TextXAlignment=Enum.TextXAlignment.Left
NG705.TextYAlignment=Enum.TextYAlignment.Top NG705.Parent=NG703
NG706=Instance.new("TextLabel") NG706.BackgroundTransparency=1
NG706.BorderSizePixel=0
NG706.Position=UDim2.new(0,10,0,15) NG706.Size=UDim2.new(0,80,0,60)NG706.Font=Enum.Font.Arial NG706.FontSize=Enum.FontSize.Size10 NG706.Text=dCD([=[Guvf bcgvba yrgf lbh pubbfr va juvpu qverpgvba gb zbir rnpu cneg.]=])NG706.TextColor3=Color3.new(1,1,1)NG706.TextWrapped=true NG706.TextXAlignment=Enum.TextXAlignment.Left
NG706.TextYAlignment=Enum.TextYAlignment.Top NG706.Parent=NG703
NG707=Instance.new("TextLabel") NG707.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG707.BackgroundTransparency=1
NG707.BorderSizePixel=0 NG707.Position=UDim2.new(0,10,0,0)NG707.Size=UDim2.new(0,80,0,12) NG707.Font=Enum.Font.ArialBold
NG707.FontSize=Enum.FontSize.Size10
NG707.Text=dCD([=[Nkrf]=]) NG707.TextColor3=Color3.new(1,1,1)NG707.TextWrapped=true NG707.TextXAlignment=Enum.TextXAlignment.Left
NG707.TextYAlignment=Enum.TextYAlignment.Top NG707.Parent=NG703
NG708=Instance.new("TextLabel") NG708.BackgroundTransparency=1
NG708.BorderSizePixel=0
NG708.Position=UDim2.new(0,10,0,210) NG708.Size=UDim2.new(0,80,0,90)NG708.Font=Enum.Font.Arial NG708.FontSize=Enum.FontSize.Size10 NG708.Text=dCD([=[GVC: Jura lbhe nkrf ner frg gb ybpny be ynfg, lbh pna evtug pyvpx gb punatr juvpu cneg unf gur unaqyrf.]=])NG708.TextColor3=Color3.new(1,1,1)NG708.TextWrapped=true NG708.TextXAlignment=Enum.TextXAlignment.Left
NG708.TextYAlignment=Enum.TextYAlignment.Top NG708.Parent=NG703
NG709=Instance.new("Frame") NG709.BackgroundColor3=Color3.new(1,0.666667,0)NG709.BorderSizePixel=0
NG709.Name=dCD([=[PbybeOne]=]) NG709.Size=UDim2.new(1,0,0,2)NG709.Parent=NG702
NG710=Instance.new("TextLabel") NG710.BackgroundTransparency=1
NG710.BorderSizePixel=0
NG710.Name=dCD([=[GbbyQrfpevcgvba]=]) NG710.Position=UDim2.new(0,10,0,25)NG710.Size=UDim2.new(0,80,0,50) NG710.Font=Enum.Font.Arial
NG710.FontSize=Enum.FontSize.Size10 NG710.Text=dCD([=[Nyybjf lbh gb zbir cnegf.]=])NG710.TextColor3=Color3.new(1,1,1)NG710.TextWrapped=true NG710.TextXAlignment=Enum.TextXAlignment.Left
NG710.TextYAlignment=Enum.TextYAlignment.Top NG710.Parent=NG702
NG711=Instance.new("TextLabel") NG711.BackgroundTransparency=1
NG711.BorderSizePixel=0
NG711.Name=dCD([=[GbbyAnzr]=]) NG711.Position=UDim2.new(0,10,0,0)NG711.Size=UDim2.new(0,50,0,25) NG711.Font=Enum.Font.ArialBold
NG711.FontSize=Enum.FontSize.Size10 NG711.Text=dCD([=[ZBIR GBBY]=])NG711.TextColor3=Color3.new(1,1,1) NG711.TextXAlignment=Enum.TextXAlignment.Left
NG711.Parent=NG702
NG712=Instance.new("Frame") NG712.BackgroundTransparency=1
NG712.BorderSizePixel=0
NG712.Name=dCD([=[VaperzragVasb]=]) NG712.Position=UDim2.new(0,0,0,365)NG712.Size=UDim2.new(1,0,0,300)NG712.Parent=NG702 NG713=Instance.new("TextLabel")NG713.BackgroundTransparency=1
NG713.BorderSizePixel=0 NG713.Position=UDim2.new(0,10,0,15)NG713.Size=UDim2.new(0,80,0,60) NG713.Font=Enum.Font.Arial
NG713.FontSize=Enum.FontSize.Size10 NG713.Text=dCD([=[Yrgf lbh pubbfr ubj znal fghqf gb zbir gur cnegf.]=])NG713.TextColor3=Color3.new(1,1,1)NG713.TextWrapped=true NG713.TextXAlignment=Enum.TextXAlignment.Left
NG713.TextYAlignment=Enum.TextYAlignment.Top NG713.Parent=NG712
NG714=Instance.new("TextLabel") NG714.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG714.BackgroundTransparency=1
NG714.BorderSizePixel=0 NG714.Position=UDim2.new(0,10,0,0)NG714.Size=UDim2.new(0,80,0,12) NG714.Font=Enum.Font.ArialBold
NG714.FontSize=Enum.FontSize.Size10 NG714.Text=dCD([=[Vaperzrag]=])NG714.TextColor3=Color3.new(1,1,1)NG714.TextWrapped=true NG714.TextXAlignment=Enum.TextXAlignment.Left
NG714.TextYAlignment=Enum.TextYAlignment.Top NG714.Parent=NG712
NG715=Instance.new("TextLabel") NG715.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG715.BackgroundTransparency=1
NG715.BorderSizePixel=0 NG715.Position=UDim2.new(0,10,0,70)NG715.Size=UDim2.new(0,80,0,50) NG715.Font=Enum.Font.Arial
NG715.FontSize=Enum.FontSize.Size10 NG715.Text=dCD([=[GVC: Hfr gur - xrl gb sbphf ba gur vaperzrag vachg.]=])NG715.TextColor3=Color3.new(1,1,1)NG715.TextWrapped=true NG715.TextXAlignment=Enum.TextXAlignment.Left
NG715.TextYAlignment=Enum.TextYAlignment.Top NG715.Parent=NG712
NG716=Instance.new("Frame") NG716.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG716.BackgroundTransparency=0.20000000298023
NG716.BorderSizePixel=0 NG716.Name=dCD([=[EbgngrVasb]=])NG716.Size=UDim2.new(1,0,1,0)NG716.Visible=false NG716.Parent=NG650
NG717=Instance.new("Frame")NG717.BackgroundTransparency=1 NG717.BorderSizePixel=0
NG717.Name=dCD([=[Pbagrag]=])NG717.Size=UDim2.new(1,0,0,530) NG717.Parent=NG716
NG718=Instance.new("Frame")NG718.BackgroundTransparency=1 NG718.BorderSizePixel=0
NG718.Name=dCD([=[CvibgVasb]=]) NG718.Position=UDim2.new(0,0,0,60)NG718.Size=UDim2.new(1,0,0,300)NG718.Parent=NG717 NG719=Instance.new("Frame") NG719.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG719.BorderSizePixel=0
NG719.Position=UDim2.new(0,10,0,73) NG719.Size=UDim2.new(0,2,0,168)NG719.Parent=NG718
NG720=Instance.new("TextLabel") NG720.BackgroundTransparency=1
NG720.BorderSizePixel=0
NG720.Position=UDim2.new(0,17,0,71) NG720.Size=UDim2.new(0,80,0,180)NG720.Font=Enum.Font.Arial NG720.FontSize=Enum.FontSize.Size10 NG720.Text=dCD([=[PRAGRE - Ebgngr nebhaq gur pragre bs gur tebhc bs fryrpgrq cnegf  YBPNY - Ebgngr rnpu cneg nebhaq vgf bja pragre  YNFG - Ebgngr rnpu cneg nebhaq gur pragre bs gur ynfg cneg fryrpgrq]=])NG720.TextColor3=Color3.new(1,1,1)NG720.TextWrapped=true NG720.TextXAlignment=Enum.TextXAlignment.Left
NG720.TextYAlignment=Enum.TextYAlignment.Top NG720.Parent=NG718
NG721=Instance.new("TextLabel") NG721.BackgroundTransparency=1
NG721.BorderSizePixel=0
NG721.Position=UDim2.new(0,10,0,15) NG721.Size=UDim2.new(0,80,0,60)NG721.Font=Enum.Font.Arial NG721.FontSize=Enum.FontSize.Size10 NG721.Text=dCD([=[Guvf bcgvba yrgf lbh pubbfr jung gb ebgngr gur cnegf nebhaq.]=])NG721.TextColor3=Color3.new(1,1,1)NG721.TextWrapped=true NG721.TextXAlignment=Enum.TextXAlignment.Left
NG721.TextYAlignment=Enum.TextYAlignment.Top NG721.Parent=NG718
NG722=Instance.new("TextLabel") NG722.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG722.BackgroundTransparency=1
NG722.BorderSizePixel=0 NG722.Position=UDim2.new(0,10,0,0)NG722.Size=UDim2.new(0,80,0,12) NG722.Font=Enum.Font.ArialBold
NG722.FontSize=Enum.FontSize.Size10
NG722.Text=dCD([=[Cvibg]=]) NG722.TextColor3=Color3.new(1,1,1)NG722.TextWrapped=true NG722.TextXAlignment=Enum.TextXAlignment.Left
NG722.TextYAlignment=Enum.TextYAlignment.Top NG722.Parent=NG718
NG723=Instance.new("TextLabel") NG723.BackgroundTransparency=1
NG723.BorderSizePixel=0
NG723.Position=UDim2.new(0,10,0,250) NG723.Size=UDim2.new(0,80,0,90)NG723.Font=Enum.Font.Arial NG723.FontSize=Enum.FontSize.Size10 NG723.Text=dCD([=[GVC: Jura gur cvibg vf frg gb ybpny be ynfg, lbh pna evtug pyvpx gb fjvgpu juvpu cneg unf gur unaqyrf.]=])NG723.TextColor3=Color3.new(1,1,1)NG723.TextWrapped=true NG723.TextXAlignment=Enum.TextXAlignment.Left
NG723.TextYAlignment=Enum.TextYAlignment.Top NG723.Parent=NG718
NG724=Instance.new("Frame") NG724.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG724.BorderSizePixel=0
NG724.Name=dCD([=[PbybeOne]=]) NG724.Size=UDim2.new(1,0,0,2)NG724.Parent=NG717
NG725=Instance.new("TextLabel") NG725.BackgroundTransparency=1
NG725.BorderSizePixel=0
NG725.Name=dCD([=[GbbyQrfpevcgvba]=]) NG725.Position=UDim2.new(0,10,0,25)NG725.Size=UDim2.new(0,80,0,50) NG725.Font=Enum.Font.Arial
NG725.FontSize=Enum.FontSize.Size10 NG725.Text=dCD([=[Nyybjf lbh gb ebgngr cnegf.]=])NG725.TextColor3=Color3.new(1,1,1)NG725.TextWrapped=true NG725.TextXAlignment=Enum.TextXAlignment.Left
NG725.TextYAlignment=Enum.TextYAlignment.Top NG725.Parent=NG717
NG726=Instance.new("TextLabel") NG726.BackgroundTransparency=1
NG726.BorderSizePixel=0
NG726.Name=dCD([=[GbbyAnzr]=]) NG726.Position=UDim2.new(0,10,0,0)NG726.Size=UDim2.new(0,50,0,25) NG726.Font=Enum.Font.ArialBold
NG726.FontSize=Enum.FontSize.Size10 NG726.Text=dCD([=[EBGNGR GBBY]=])NG726.TextColor3=Color3.new(1,1,1) NG726.TextXAlignment=Enum.TextXAlignment.Left
NG726.Parent=NG717
NG727=Instance.new("Frame") NG727.BackgroundTransparency=1
NG727.BorderSizePixel=0
NG727.Name=dCD([=[VaperzragVasb]=]) NG727.Position=UDim2.new(0,0,0,395)NG727.Size=UDim2.new(1,0,0,130)NG727.Parent=NG717 NG728=Instance.new("TextLabel")NG728.BackgroundTransparency=1
NG728.BorderSizePixel=0 NG728.Position=UDim2.new(0,10,0,15)NG728.Size=UDim2.new(0,80,0,60) NG728.Font=Enum.Font.Arial
NG728.FontSize=Enum.FontSize.Size10 NG728.Text=dCD([=[Yrgf lbh pubbfr ubj znal qrterrf gb ebgngr gur cnegf.]=])NG728.TextColor3=Color3.new(1,1,1)NG728.TextWrapped=true NG728.TextXAlignment=Enum.TextXAlignment.Left
NG728.TextYAlignment=Enum.TextYAlignment.Top NG728.Parent=NG727
NG729=Instance.new("TextLabel") NG729.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG729.BackgroundTransparency=1
NG729.BorderSizePixel=0 NG729.Position=UDim2.new(0,10,0,0)NG729.Size=UDim2.new(0,80,0,12) NG729.Font=Enum.Font.ArialBold
NG729.FontSize=Enum.FontSize.Size10 NG729.Text=dCD([=[Vaperzrag]=])NG729.TextColor3=Color3.new(1,1,1)NG729.TextWrapped=true NG729.TextXAlignment=Enum.TextXAlignment.Left
NG729.TextYAlignment=Enum.TextYAlignment.Top NG729.Parent=NG727
NG730=Instance.new("TextLabel") NG730.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG730.BackgroundTransparency=1
NG730.BorderSizePixel=0 NG730.Position=UDim2.new(0,10,0,70)NG730.Size=UDim2.new(0,80,0,50) NG730.Font=Enum.Font.Arial
NG730.FontSize=Enum.FontSize.Size10 NG730.Text=dCD([=[GVC: Hfr gur - xrl gb sbphf ba gur vaperzrag vachg.]=])NG730.TextColor3=Color3.new(1,1,1)NG730.TextWrapped=true NG730.TextXAlignment=Enum.TextXAlignment.Left
NG730.TextYAlignment=Enum.TextYAlignment.Top NG730.Parent=NG727
NG731=Instance.new("Frame") NG731.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG731.BackgroundTransparency=0.20000000298023
NG731.BorderSizePixel=0 NG731.Name=dCD([=[ErfvmrVasb]=])NG731.Size=UDim2.new(1,0,1,0)NG731.Visible=false NG731.Parent=NG650
NG732=Instance.new("Frame")NG732.BackgroundTransparency=1 NG732.BorderSizePixel=0
NG732.Name=dCD([=[Pbagrag]=])NG732.Size=UDim2.new(1,0,0,330) NG732.Parent=NG731
NG733=Instance.new("Frame")NG733.BackgroundTransparency=1 NG733.BorderSizePixel=0
NG733.Name=dCD([=[QverpgvbafVasb]=]) NG733.Position=UDim2.new(0,0,0,60)NG733.Size=UDim2.new(1,0,0,300)NG733.Parent=NG732 NG734=Instance.new("TextLabel")NG734.BackgroundTransparency=1
NG734.BorderSizePixel=0 NG734.Position=UDim2.new(0,10,0,15)NG734.Size=UDim2.new(0,80,0,120) NG734.Font=Enum.Font.Arial
NG734.FontSize=Enum.FontSize.Size10 NG734.Text=dCD([=[Yrgf lbh pubbfr va juvpu qverpgvbaf gb erfvmr gur cneg.  GVC: Lbh pna fjvgpu juvpu cneg unf gur unaqyrf ol evtug-pyvpxvat.]=])NG734.TextColor3=Color3.new(1,1,1)NG734.TextWrapped=true NG734.TextXAlignment=Enum.TextXAlignment.Left
NG734.TextYAlignment=Enum.TextYAlignment.Top NG734.Parent=NG733
NG735=Instance.new("TextLabel") NG735.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG735.BackgroundTransparency=1
NG735.BorderSizePixel=0 NG735.Position=UDim2.new(0,10,0,0)NG735.Size=UDim2.new(0,80,0,12) NG735.Font=Enum.Font.ArialBold
NG735.FontSize=Enum.FontSize.Size10 NG735.Text=dCD([=[Qverpgvbaf]=])NG735.TextColor3=Color3.new(1,1,1)NG735.TextWrapped=true NG735.TextXAlignment=Enum.TextXAlignment.Left
NG735.TextYAlignment=Enum.TextYAlignment.Top NG735.Parent=NG733
NG736=Instance.new("Frame") NG736.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG736.BorderSizePixel=0
NG736.Name=dCD([=[PbybeOne]=]) NG736.Size=UDim2.new(1,0,0,2)NG736.Parent=NG732
NG737=Instance.new("TextLabel") NG737.BackgroundTransparency=1
NG737.BorderSizePixel=0
NG737.Name=dCD([=[GbbyQrfpevcgvba]=]) NG737.Position=UDim2.new(0,10,0,25)NG737.Size=UDim2.new(0,80,0,50) NG737.Font=Enum.Font.Arial
NG737.FontSize=Enum.FontSize.Size10 NG737.Text=dCD([=[Nyybjf lbh gb erfvmr cnegf.]=])NG737.TextColor3=Color3.new(1,1,1)NG737.TextWrapped=true NG737.TextXAlignment=Enum.TextXAlignment.Left
NG737.TextYAlignment=Enum.TextYAlignment.Top NG737.Parent=NG732
NG738=Instance.new("TextLabel") NG738.BackgroundTransparency=1
NG738.BorderSizePixel=0
NG738.Name=dCD([=[GbbyAnzr]=]) NG738.Position=UDim2.new(0,10,0,0)NG738.Size=UDim2.new(0,50,0,25) NG738.Font=Enum.Font.ArialBold
NG738.FontSize=Enum.FontSize.Size10 NG738.Text=dCD([=[ERFVMR GBBY]=])NG738.TextColor3=Color3.new(1,1,1) NG738.TextXAlignment=Enum.TextXAlignment.Left
NG738.Parent=NG732
NG739=Instance.new("Frame") NG739.BackgroundTransparency=1
NG739.BorderSizePixel=0
NG739.Name=dCD([=[VaperzragVasb]=]) NG739.Position=UDim2.new(0,0,0,200)NG739.Size=UDim2.new(1,0,0,140)NG739.Parent=NG732 NG740=Instance.new("TextLabel")NG740.BackgroundTransparency=1
NG740.BorderSizePixel=0 NG740.Position=UDim2.new(0,10,0,15)NG740.Size=UDim2.new(0,80,0,60) NG740.Font=Enum.Font.Arial
NG740.FontSize=Enum.FontSize.Size10 NG740.Text=dCD([=[Yrgf lbh pubbfr ubj znal fghqf gb erfvmr gur cnegf.]=])NG740.TextColor3=Color3.new(1,1,1)NG740.TextWrapped=true NG740.TextXAlignment=Enum.TextXAlignment.Left
NG740.TextYAlignment=Enum.TextYAlignment.Top NG740.Parent=NG739
NG741=Instance.new("TextLabel") NG741.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG741.BackgroundTransparency=1
NG741.BorderSizePixel=0 NG741.Position=UDim2.new(0,10,0,0)NG741.Size=UDim2.new(0,80,0,12) NG741.Font=Enum.Font.ArialBold
NG741.FontSize=Enum.FontSize.Size10 NG741.Text=dCD([=[Vaperzrag]=])NG741.TextColor3=Color3.new(1,1,1)NG741.TextWrapped=true NG741.TextXAlignment=Enum.TextXAlignment.Left
NG741.TextYAlignment=Enum.TextYAlignment.Top NG741.Parent=NG739
NG742=Instance.new("TextLabel") NG742.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG742.BackgroundTransparency=1
NG742.BorderSizePixel=0 NG742.Position=UDim2.new(0,10,0,70)NG742.Size=UDim2.new(0,80,0,50) NG742.Font=Enum.Font.Arial
NG742.FontSize=Enum.FontSize.Size10 NG742.Text=dCD([=[GVC: Hfr gur - xrl gb sbphf ba gur vaperzrag vachg.]=])NG742.TextColor3=Color3.new(1,1,1)NG742.TextWrapped=true NG742.TextXAlignment=Enum.TextXAlignment.Left
NG742.TextYAlignment=Enum.TextYAlignment.Top NG742.Parent=NG739
NG743=Instance.new("Frame") NG743.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG743.BackgroundTransparency=0.20000000298023
NG743.BorderSizePixel=0 NG743.Name=dCD([=[JryqVasb]=])NG743.Size=UDim2.new(1,0,1,0)NG743.Visible=false NG743.Parent=NG650
NG744=Instance.new("Frame")NG744.BackgroundTransparency=1 NG744.BorderSizePixel=0
NG744.Name=dCD([=[Pbagrag]=])NG744.Size=UDim2.new(1,0,0,310) NG744.Parent=NG743
NG745=Instance.new("Frame") NG745.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG745.BorderSizePixel=0
NG745.Name=dCD([=[PbybeOne]=]) NG745.Size=UDim2.new(1,0,0,2)NG745.Parent=NG744
NG746=Instance.new("TextLabel") NG746.BackgroundTransparency=1
NG746.BorderSizePixel=0
NG746.Name=dCD([=[GbbyQrfpevcgvba]=]) NG746.Position=UDim2.new(0,10,0,25)NG746.Size=UDim2.new(0,80,0,300) NG746.Font=Enum.Font.Arial
NG746.FontSize=Enum.FontSize.Size10 NG746.Text=dCD([=[Nyybjf lbh gb jryq cnegf gbtrgure fb gung gurl'yy zbir gbtrgure.  ABGR: Gur jryqf orgjrra cnegf znl oernx vs lbh bayl zbir bar bs gur cnegf (zbir nyy bs gur cnegf gung ner pbaarpgrq ol jryqf gb cerirag guvf).  ABGR: Guvf gbby qbrfa'g jbex va EBOYBK Fghqvb (vg'f xvaq bs hfryrff va gung pbagrkg).]=])NG746.TextColor3=Color3.new(1,1,1)NG746.TextWrapped=true NG746.TextXAlignment=Enum.TextXAlignment.Left
NG746.TextYAlignment=Enum.TextYAlignment.Top NG746.Parent=NG744
NG747=Instance.new("TextLabel") NG747.BackgroundTransparency=1
NG747.BorderSizePixel=0
NG747.Name=dCD([=[GbbyAnzr]=]) NG747.Position=UDim2.new(0,10,0,0)NG747.Size=UDim2.new(0,50,0,25) NG747.Font=Enum.Font.ArialBold
NG747.FontSize=Enum.FontSize.Size10 NG747.Text=dCD([=[JRYQ GBBY]=])NG747.TextColor3=Color3.new(1,1,1) NG747.TextXAlignment=Enum.TextXAlignment.Left
NG747.Parent=NG744
NG748=Instance.new("Frame") NG748.BackgroundColor3=Color3.new(0,0,0)NG748.BackgroundTransparency=0.75
NG748.BorderSizePixel=0 NG748.Name=dCD([=[VasbOhggbaf]=])NG748.Position=UDim2.new(0,0,0,350) NG748.Size=UDim2.new(1,0,0,32)NG748.Parent=NG649
NG749=Instance.new("TextLabel") NG749.BackgroundTransparency=1
NG749.BorderSizePixel=0
NG749.Name=dCD([=[S3KFvtangher]=]) NG749.Position=UDim2.new(0,0,0,7)NG749.Size=UDim2.new(1,-28,0,17) NG749.Font=Enum.Font.ArialBold
NG749.FontSize=Enum.FontSize.Size14
NG749.Text=dCD([=[S3K]=]) NG749.TextColor3=Color3.new(1,1,1)NG749.TextScaled=true
NG749.TextStrokeTransparency=0.89999997615814 NG749.TextWrapped=true
NG749.Parent=NG748
NG750=Instance.new("ImageButton") NG750.BackgroundColor3=Color3.new(0.333333,0.666667,1)NG750.BackgroundTransparency=1
NG750.BorderSizePixel=0 NG750.Name=dCD([=[UrycOhggba]=])NG750.Position=UDim2.new(1,-32,0,0) NG750.Size=UDim2.new(0,32,0,32)NG750.Style=Enum.ButtonStyle.Custom NG750.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141911973]=])NG750.Parent=NG748
NG751=Instance.new("Frame") NG751.BackgroundTransparency=1
NG751.BorderSizePixel=0
NG751.Name=dCD([=[Gbbygvc]=]) NG751.Position=UDim2.new(-0.300000012,0,1,0)NG751.Size=UDim2.new(1.60000002,0,0,0)NG751.Visible=false NG751.Parent=NG750
NG752=Instance.new("TextLabel") NG752.BackgroundColor3=Color3.new(0,0,0)NG752.BackgroundTransparency=0.5
NG752.BorderSizePixel=0 NG752.Name=dCD([=[Grkg]=])NG752.Size=UDim2.new(1,0,0,20) NG752.Font=Enum.Font.ArialBold
NG752.FontSize=Enum.FontSize.Size10
NG752.Text=dCD([=[URYC]=]) NG752.TextColor3=Color3.new(1,1,1)NG752.Parent=NG751
NG753=Instance.new("Frame") NG753.BackgroundColor3=Color3.new(0,0,0)NG753.BackgroundTransparency=0.69999998807907
NG753.BorderSizePixel=0 NG753.Name=dCD([=[Funqbj]=])NG753.Position=UDim2.new(0,0,1,-2) NG753.Size=UDim2.new(1,0,0,2)NG753.Parent=NG748
NG754=Instance.new("Frame") NG754.BackgroundColor3=Color3.new(0,0,0)NG754.BackgroundTransparency=0.5
NG754.BorderSizePixel=0 NG754.Name=dCD([=[FryrpgvbaOhggbaf]=])NG754.Position=UDim2.new(0,0,0,245) NG754.Size=UDim2.new(1,0,0,105)NG754.Parent=NG649
NG755=Instance.new("ImageButton") NG755.BackgroundColor3=Color3.new(0.333333,0.666667,1)NG755.BackgroundTransparency=1
NG755.BorderSizePixel=0 NG755.Name=dCD([=[QryrgrOhggba]=])NG755.Position=UDim2.new(0,0,0,35) NG755.Size=UDim2.new(0,35,0,35)NG755.Style=Enum.ButtonStyle.Custom NG755.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=142074644]=])NG755.Parent=NG754
NG756=Instance.new("Frame") NG756.BackgroundTransparency=1
NG756.BorderSizePixel=0
NG756.Name=dCD([=[Gbbygvc]=]) NG756.Position=UDim2.new(-0.300000012,0,1,0)NG756.Size=UDim2.new(1.60000002,0,0,0)NG756.Visible=false NG756.Parent=NG755
NG757=Instance.new("TextLabel") NG757.BackgroundColor3=Color3.new(0,0,0)NG757.BackgroundTransparency=0.5
NG757.BorderSizePixel=0 NG757.Name=dCD([=[Grkg]=])NG757.Size=UDim2.new(1,0,0,28) NG757.Font=Enum.Font.ArialBold
NG757.FontSize=Enum.FontSize.Size10 NG757.Text=dCD([=[QRYRGR (Fuvsg + K)]=])NG757.TextColor3=Color3.new(1,1,1)NG757.Parent=NG756 NG758=Instance.new("ImageButton")NG758.BackgroundColor3=Color3.new(0.333333,0.666667,1) NG758.BackgroundTransparency=1
NG758.BorderSizePixel=0
NG758.Name=dCD([=[RkcbegOhggba]=]) NG758.Position=UDim2.new(0,35,0,35)NG758.Size=UDim2.new(0,35,0,35) NG758.Style=Enum.ButtonStyle.Custom
NG758.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=142074569]=]) NG758.Parent=NG754
NG759=Instance.new("Frame")NG759.BackgroundTransparency=1 NG759.BorderSizePixel=0
NG759.Name=dCD([=[Gbbygvc]=]) NG759.Position=UDim2.new(-0.300000012,0,1,0)NG759.Size=UDim2.new(1.60000002,0,0,0)NG759.Visible=false NG759.Parent=NG758
NG760=Instance.new("TextLabel") NG760.BackgroundColor3=Color3.new(0,0,0)NG760.BackgroundTransparency=0.5
NG760.BorderSizePixel=0 NG760.Name=dCD([=[Grkg]=])NG760.Size=UDim2.new(1,0,0,28) NG760.Font=Enum.Font.ArialBold
NG760.FontSize=Enum.FontSize.Size10 NG760.Text=dCD([=[RKCBEG (Fuvsg + C)]=])NG760.TextColor3=Color3.new(1,1,1)NG760.Parent=NG759 NG761=Instance.new("ImageButton")NG761.BackgroundColor3=Color3.new(0.333333,0.666667,1) NG761.BackgroundTransparency=1
NG761.BorderSizePixel=0
NG761.Name=dCD([=[ErqbOhggba]=]) NG761.Position=UDim2.new(0,35,0,0)NG761.Size=UDim2.new(0,35,0,35) NG761.Style=Enum.ButtonStyle.Custom
NG761.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=142074553]=]) NG761.Parent=NG754
NG762=Instance.new("Frame")NG762.BackgroundTransparency=1 NG762.BorderSizePixel=0
NG762.Name=dCD([=[Gbbygvc]=]) NG762.Position=UDim2.new(-0.300000012,0,1,0)NG762.Size=UDim2.new(1.60000002,0,0,0)NG762.Visible=false NG762.Parent=NG761
NG763=Instance.new("TextLabel") NG763.BackgroundColor3=Color3.new(0,0,0)NG763.BackgroundTransparency=0.5
NG763.BorderSizePixel=0 NG763.Name=dCD([=[Grkg]=])NG763.Size=UDim2.new(1,0,0,28) NG763.Font=Enum.Font.ArialBold
NG763.FontSize=Enum.FontSize.Size10 NG763.Text=dCD([=[ERQB (Fuvsg + L)]=])NG763.TextColor3=Color3.new(1,1,1)NG763.Parent=NG762 NG764=Instance.new("ImageButton")NG764.BackgroundColor3=Color3.new(0.333333,0.666667,1) NG764.BackgroundTransparency=1
NG764.BorderSizePixel=0
NG764.Name=dCD([=[HaqbOhggba]=]) NG764.Size=UDim2.new(0,35,0,35)NG764.Style=Enum.ButtonStyle.Custom NG764.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=142074557]=])NG764.Parent=NG754
NG765=Instance.new("Frame") NG765.BackgroundTransparency=1
NG765.BorderSizePixel=0
NG765.Name=dCD([=[Gbbygvc]=]) NG765.Position=UDim2.new(-0.300000012,0,1,0)NG765.Size=UDim2.new(1.60000002,0,0,0)NG765.Visible=false NG765.Parent=NG764
NG766=Instance.new("TextLabel") NG766.BackgroundColor3=Color3.new(0,0,0)NG766.BackgroundTransparency=0.5
NG766.BorderSizePixel=0 NG766.Name=dCD([=[Grkg]=])NG766.Size=UDim2.new(1,0,0,28) NG766.Font=Enum.Font.ArialBold
NG766.FontSize=Enum.FontSize.Size10 NG766.Text=dCD([=[HAQB (Fuvsg + M)]=])NG766.TextColor3=Color3.new(1,1,1)NG766.Parent=NG765 NG767=Instance.new("ImageButton")NG767.BackgroundColor3=Color3.new(0.333333,0.666667,1) NG767.BackgroundTransparency=1
NG767.BorderSizePixel=0
NG767.Name=dCD([=[PybarOhggba]=]) NG767.Position=UDim2.new(0,0,0,70)NG767.Size=UDim2.new(0,35,0,35) NG767.Style=Enum.ButtonStyle.Custom
NG767.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=142074563]=]) NG767.Parent=NG754
NG768=Instance.new("Frame")NG768.BackgroundTransparency=1 NG768.BorderSizePixel=0
NG768.Name=dCD([=[Gbbygvc]=]) NG768.Position=UDim2.new(-0.300000012,0,1,0)NG768.Size=UDim2.new(1.60000002,0,0,0)NG768.Visible=false NG768.Parent=NG767
NG769=Instance.new("TextLabel") NG769.BackgroundColor3=Color3.new(0,0,0)NG769.BackgroundTransparency=0.5
NG769.BorderSizePixel=0 NG769.Name=dCD([=[Grkg]=])NG769.Size=UDim2.new(1,0,0,28) NG769.Font=Enum.Font.ArialBold
NG769.FontSize=Enum.FontSize.Size10 NG769.Text=dCD([=[PYBAR (Fuvsg + P)]=])NG769.TextColor3=Color3.new(1,1,1)NG769.Parent=NG768 NG770=Instance.new("ImageButton")NG770.BackgroundColor3=Color3.new(0.333333,0.666667,1) NG770.BackgroundTransparency=1
NG770.BorderSizePixel=0
NG770.Name=dCD([=[TebhcfOhggba]=]) NG770.Position=UDim2.new(0,35,0,70)NG770.Size=UDim2.new(0,35,0,35) NG770.Style=Enum.ButtonStyle.Custom
NG770.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=160378203]=]) NG770.Parent=NG754
NG771=Instance.new("Frame")NG771.BackgroundTransparency=1 NG771.BorderSizePixel=0
NG771.Name=dCD([=[Gbbygvc]=]) NG771.Position=UDim2.new(-0.300000012,0,1,0)NG771.Size=UDim2.new(1.60000002,0,0,0)NG771.Visible=false NG771.Parent=NG770
NG772=Instance.new("TextLabel") NG772.BackgroundColor3=Color3.new(0,0,0)NG772.BackgroundTransparency=0.5
NG772.BorderSizePixel=0 NG772.Name=dCD([=[Grkg]=])NG772.Size=UDim2.new(1,0,0,28) NG772.Font=Enum.Font.ArialBold
NG772.FontSize=Enum.FontSize.Size10 NG772.Text=dCD([=[TEBHCF (Fuvsg + T)]=])NG772.TextColor3=Color3.new(1,1,1)NG772.TextWrapped=true NG772.Parent=NG771
NG773=Instance.new("Frame") NG773.BackgroundColor3=Color3.new(0,0,0)NG773.BackgroundTransparency=0.60000002384186
NG773.BorderSizePixel=0 NG773.Name=dCD([=[GbbyOhggbaf]=])NG773.Size=UDim2.new(0,70,0,245)NG773.Parent=NG649 NG774=Instance.new("ImageButton")NG774.AutoButtonColor=false NG774.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG774.BackgroundTransparency=1
NG774.BorderSizePixel=0 NG774.Name=dCD([=[QrpbengrOhggba]=])NG774.Position=UDim2.new(0,35,0,210) NG774.Size=UDim2.new(0,35,0,35)NG774.Style=Enum.ButtonStyle.Custom NG774.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141741412]=])NG774.Parent=NG773
NG775=Instance.new("TextLabel") NG775.BackgroundColor3=Color3.new(0,0,0)NG775.BackgroundTransparency=1
NG775.BorderSizePixel=0 NG775.Name=dCD([=[Fubegphg]=])NG775.Size=UDim2.new(0,13,0,13) NG775.Font=Enum.Font.ArialBold
NG775.FontSize=Enum.FontSize.Size10
NG775.Text=dCD([=[C]=]) NG775.TextColor3=Color3.new(1,1,1)NG775.Parent=NG774
NG776=Instance.new("ImageButton") NG776.AutoButtonColor=false NG776.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG776.BackgroundTransparency=1
NG776.BorderSizePixel=0 NG776.Name=dCD([=[JryqOhggba]=])NG776.Position=UDim2.new(0,35,0,175) NG776.Size=UDim2.new(0,35,0,35)NG776.Style=Enum.ButtonStyle.Custom NG776.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141741418]=])NG776.Parent=NG773
NG777=Instance.new("TextLabel") NG777.BackgroundColor3=Color3.new(0,0,0)NG777.BackgroundTransparency=1
NG777.BorderSizePixel=0 NG777.Name=dCD([=[Fubegphg]=])NG777.Size=UDim2.new(0,13,0,13) NG777.Font=Enum.Font.ArialBold
NG777.FontSize=Enum.FontSize.Size10
NG777.Text=dCD([=[S]=]) NG777.TextColor3=Color3.new(1,1,1)NG777.Parent=NG776
NG778=Instance.new("ImageButton") NG778.AutoButtonColor=false NG778.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG778.BackgroundTransparency=1
NG778.BorderSizePixel=0 NG778.Name=dCD([=[YvtugvatOhggba]=])NG778.Position=UDim2.new(0,0,0,210) NG778.Size=UDim2.new(0,35,0,35)NG778.Style=Enum.ButtonStyle.Custom NG778.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141741341]=])NG778.Parent=NG773
NG779=Instance.new("TextLabel") NG779.BackgroundColor3=Color3.new(0,0,0)NG779.BackgroundTransparency=1
NG779.BorderSizePixel=0 NG779.Name=dCD([=[Fubegphg]=])NG779.Size=UDim2.new(0,13,0,13) NG779.Font=Enum.Font.ArialBold
NG779.FontSize=Enum.FontSize.Size10
NG779.Text=dCD([=[H]=]) NG779.TextColor3=Color3.new(1,1,1)NG779.Parent=NG778
NG780=Instance.new("ImageButton") NG780.AutoButtonColor=false NG780.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG780.BackgroundTransparency=1
NG780.BorderSizePixel=0 NG780.Name=dCD([=[ZrfuOhggba]=])NG780.Position=UDim2.new(0,35,0,140) NG780.Size=UDim2.new(0,35,0,35)NG780.Style=Enum.ButtonStyle.Custom NG780.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141806786]=])NG780.Parent=NG773
NG781=Instance.new("TextLabel") NG781.BackgroundColor3=Color3.new(0,0,0)NG781.BackgroundTransparency=1
NG781.BorderSizePixel=0 NG781.Name=dCD([=[Fubegphg]=])NG781.Size=UDim2.new(0,13,0,13) NG781.Font=Enum.Font.ArialBold
NG781.FontSize=Enum.FontSize.Size10
NG781.Text=dCD([=[U]=]) NG781.TextColor3=Color3.new(1,1,1)NG781.Parent=NG780
NG782=Instance.new("ImageButton") NG782.AutoButtonColor=false NG782.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG782.BackgroundTransparency=1
NG782.BorderSizePixel=0 NG782.Name=dCD([=[PbyyvfvbaOhggba]=])NG782.Position=UDim2.new(0,35,0,105) NG782.Size=UDim2.new(0,35,0,35)NG782.Style=Enum.ButtonStyle.Custom NG782.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141809596]=])NG782.Parent=NG773
NG783=Instance.new("TextLabel") NG783.BackgroundColor3=Color3.new(0,0,0)NG783.BackgroundTransparency=1
NG783.BorderSizePixel=0 NG783.Name=dCD([=[Fubegphg]=])NG783.Size=UDim2.new(0,13,0,13) NG783.Font=Enum.Font.ArialBold
NG783.FontSize=Enum.FontSize.Size10
NG783.Text=dCD([=[X]=]) NG783.TextColor3=Color3.new(1,1,1)NG783.Parent=NG782
NG784=Instance.new("ImageButton") NG784.AutoButtonColor=false NG784.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG784.BackgroundTransparency=1
NG784.BorderSizePixel=0 NG784.Name=dCD([=[ZngrevnyOhggba]=])NG784.Position=UDim2.new(0,35,0,70) NG784.Size=UDim2.new(0,35,0,35)NG784.Style=Enum.ButtonStyle.Custom NG784.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141809090]=])NG784.Parent=NG773
NG785=Instance.new("TextLabel") NG785.BackgroundColor3=Color3.new(0,0,0)NG785.BackgroundTransparency=1
NG785.BorderSizePixel=0 NG785.Name=dCD([=[Fubegphg]=])NG785.Size=UDim2.new(0,13,0,13) NG785.Font=Enum.Font.ArialBold
NG785.FontSize=Enum.FontSize.Size10
NG785.Text=dCD([=[A]=]) NG785.TextColor3=Color3.new(1,1,1)NG785.Parent=NG784
NG786=Instance.new("ImageButton") NG786.AutoButtonColor=false
NG786.BackgroundColor3=Color3.new(1,0,0) NG786.BackgroundTransparency=1
NG786.BorderSizePixel=0
NG786.Name=dCD([=[CnvagOhggba]=]) NG786.Position=UDim2.new(0,35,0,35)NG786.Size=UDim2.new(0,35,0,35) NG786.Style=Enum.ButtonStyle.Custom
NG786.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141741444]=]) NG786.Parent=NG773
NG787=Instance.new("TextLabel") NG787.BackgroundColor3=Color3.new(0,0,0)NG787.BackgroundTransparency=1
NG787.BorderSizePixel=0 NG787.Name=dCD([=[Fubegphg]=])NG787.Size=UDim2.new(0,13,0,13) NG787.Font=Enum.Font.ArialBold
NG787.FontSize=Enum.FontSize.Size10
NG787.Text=dCD([=[I]=]) NG787.TextColor3=Color3.new(1,1,1)NG787.Parent=NG786
NG788=Instance.new("ImageButton") NG788.AutoButtonColor=false NG788.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG788.BackgroundTransparency=1
NG788.BorderSizePixel=0 NG788.Name=dCD([=[ArjCnegOhggba]=])NG788.Position=UDim2.new(0,0,0,140) NG788.Size=UDim2.new(0,35,0,35)NG788.Style=Enum.ButtonStyle.Custom NG788.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141741393]=])NG788.Parent=NG773
NG789=Instance.new("TextLabel") NG789.BackgroundColor3=Color3.new(0,0,0)NG789.BackgroundTransparency=1
NG789.BorderSizePixel=0 NG789.Name=dCD([=[Fubegphg]=])NG789.Size=UDim2.new(0,13,0,13) NG789.Font=Enum.Font.ArialBold
NG789.FontSize=Enum.FontSize.Size10
NG789.Text=dCD([=[W]=]) NG789.TextColor3=Color3.new(1,1,1)NG789.Parent=NG788
NG790=Instance.new("ImageButton") NG790.AutoButtonColor=false
NG790.BackgroundColor3=Color3.new(1,0.686275,0) NG790.BackgroundTransparency=1
NG790.BorderSizePixel=0
NG790.Name=dCD([=[ZbirOhggba]=]) NG790.Size=UDim2.new(0,35,0,35)NG790.Style=Enum.ButtonStyle.Custom NG790.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141741366]=])NG790.Parent=NG773
NG791=Instance.new("TextLabel") NG791.BackgroundColor3=Color3.new(0,0,0)NG791.BackgroundTransparency=1
NG791.BorderSizePixel=0 NG791.Name=dCD([=[Fubegphg]=])NG791.Size=UDim2.new(0,13,0,13) NG791.Font=Enum.Font.ArialBold
NG791.FontSize=Enum.FontSize.Size10
NG791.Text=dCD([=[M]=]) NG791.TextColor3=Color3.new(1,1,1)NG791.Parent=NG790
NG792=Instance.new("ImageButton") NG792.AutoButtonColor=false NG792.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG792.BackgroundTransparency=1
NG792.BorderSizePixel=0 NG792.Name=dCD([=[ErfvmrOhggba]=])NG792.Position=UDim2.new(0,35,0,0) NG792.Size=UDim2.new(0,35,0,35)NG792.Style=Enum.ButtonStyle.Custom NG792.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141794324]=])NG792.Parent=NG773
NG793=Instance.new("TextLabel") NG793.BackgroundColor3=Color3.new(0,0,0)NG793.BackgroundTransparency=1
NG793.BorderSizePixel=0 NG793.Name=dCD([=[Fubegphg]=])NG793.Size=UDim2.new(0,13,0,13) NG793.Font=Enum.Font.ArialBold
NG793.FontSize=Enum.FontSize.Size10
NG793.Text=dCD([=[K]=]) NG793.TextColor3=Color3.new(1,1,1)NG793.Parent=NG792
NG794=Instance.new("ImageButton") NG794.AutoButtonColor=false NG794.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG794.BackgroundTransparency=1
NG794.BorderSizePixel=0 NG794.Name=dCD([=[EbgngrOhggba]=])NG794.Position=UDim2.new(0,0,0,35) NG794.Size=UDim2.new(0,35,0,35)NG794.Style=Enum.ButtonStyle.Custom NG794.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141807775]=])NG794.Parent=NG773
NG795=Instance.new("TextLabel") NG795.BackgroundColor3=Color3.new(0,0,0)NG795.BackgroundTransparency=1
NG795.BorderSizePixel=0 NG795.Name=dCD([=[Fubegphg]=])NG795.Size=UDim2.new(0,13,0,13) NG795.Font=Enum.Font.ArialBold
NG795.FontSize=Enum.FontSize.Size10
NG795.Text=dCD([=[P]=]) NG795.TextColor3=Color3.new(1,1,1)NG795.Parent=NG794
NG796=Instance.new("ImageButton") NG796.AutoButtonColor=false NG796.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG796.BackgroundTransparency=1
NG796.BorderSizePixel=0 NG796.Name=dCD([=[FhesnprOhggba]=])NG796.Position=UDim2.new(0,0,0,70) NG796.Size=UDim2.new(0,35,0,35)NG796.Style=Enum.ButtonStyle.Custom NG796.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141803491]=])NG796.Parent=NG773
NG797=Instance.new("TextLabel") NG797.BackgroundColor3=Color3.new(0,0,0)NG797.BackgroundTransparency=1
NG797.BorderSizePixel=0 NG797.Name=dCD([=[Fubegphg]=])NG797.Size=UDim2.new(0,13,0,13) NG797.Font=Enum.Font.ArialBold
NG797.FontSize=Enum.FontSize.Size10
NG797.Text=dCD([=[O]=]) NG797.TextColor3=Color3.new(1,1,1)NG797.Parent=NG796
NG798=Instance.new("ImageButton") NG798.AutoButtonColor=false NG798.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG798.BackgroundTransparency=1
NG798.BorderSizePixel=0 NG798.Name=dCD([=[GrkgherOhggba]=])NG798.Position=UDim2.new(0,0,0,175) NG798.Size=UDim2.new(0,35,0,35)NG798.Style=Enum.ButtonStyle.Custom NG798.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141805275]=])NG798.Parent=NG773
NG799=Instance.new("TextLabel") NG799.BackgroundColor3=Color3.new(0,0,0)NG799.BackgroundTransparency=1
NG799.BorderSizePixel=0 NG799.Name=dCD([=[Fubegphg]=])NG799.Size=UDim2.new(0,13,0,13) NG799.Font=Enum.Font.ArialBold
NG799.FontSize=Enum.FontSize.Size10
NG799.Text=dCD([=[T]=]) NG799.TextColor3=Color3.new(1,1,1)NG799.Parent=NG798
NG800=Instance.new("ImageButton") NG800.AutoButtonColor=false NG800.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG800.BackgroundTransparency=1
NG800.BorderSizePixel=0 NG800.Name=dCD([=[NapubeOhggba]=])NG800.Position=UDim2.new(0,0,0,105) NG800.Size=UDim2.new(0,35,0,35)NG800.Style=Enum.ButtonStyle.Custom NG800.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141741323]=])NG800.Parent=NG773
NG801=Instance.new("TextLabel") NG801.BackgroundColor3=Color3.new(0,0,0)NG801.BackgroundTransparency=1
NG801.BorderSizePixel=0 NG801.Name=dCD([=[Fubegphg]=])NG801.Size=UDim2.new(0,13,0,13) NG801.Font=Enum.Font.ArialBold
NG801.FontSize=Enum.FontSize.Size10
NG801.Text=dCD([=[Z]=]) NG801.TextColor3=Color3.new(1,1,1)NG801.Parent=NG800
NG802=Instance.new("Frame") NG802.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG802.BackgroundTransparency=0.20000000298023
NG802.BorderSizePixel=0 NG802.Name=dCD([=[UrycVasb]=])NG802.Position=UDim2.new(0,-120,0,0) NG802.Size=UDim2.new(0,120,0,380)NG802.Visible=false
NG802.ClipsDescendants=true
NG802.Parent=NG649 NG803=Instance.new("Frame")NG803.BackgroundTransparency=1
NG803.BorderSizePixel=0 NG803.Name=dCD([=[ObggbzPbybeOne]=])NG803.Position=UDim2.new(0,0,1,0)NG803.Rotation=180 NG803.Size=UDim2.new(1,0,0,3)NG803.Parent=NG802
NG804=Instance.new("Frame") NG804.BackgroundColor3=Color3.new(1,0.686275,0)NG804.BackgroundTransparency=0.25
NG804.BorderSizePixel=0 NG804.Name=dCD([=[Lryybj]=])NG804.Size=UDim2.new(0.200000003,0,1,0)NG804.Parent=NG803 NG805=Instance.new("Frame") NG805.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG805.BackgroundTransparency=0.25
NG805.BorderSizePixel=0 NG805.Name=dCD([=[Terra]=])NG805.Position=UDim2.new(0.200000003,0,0,0) NG805.Size=UDim2.new(0.200000003,0,1,0)NG805.Parent=NG803
NG806=Instance.new("Frame") NG806.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG806.BackgroundTransparency=0.25
NG806.BorderSizePixel=0 NG806.Name=dCD([=[Oyhr]=])NG806.Position=UDim2.new(0.400000006,0,0,0) NG806.Size=UDim2.new(0.200000003,0,1,0)NG806.Parent=NG803
NG807=Instance.new("Frame") NG807.BackgroundColor3=Color3.new(1,0,0)NG807.BackgroundTransparency=0.25
NG807.BorderSizePixel=0 NG807.Name=dCD([=[Erq]=])NG807.Position=UDim2.new(0.600000024,0,0,0) NG807.Size=UDim2.new(0.200000003,0,1,0)NG807.Parent=NG803
NG808=Instance.new("Frame") NG808.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG808.BackgroundTransparency=0.25
NG808.BorderSizePixel=0 NG808.Name=dCD([=[Checyr]=])NG808.Position=UDim2.new(0.800000012,0,0,0) NG808.Size=UDim2.new(0.200000003,0,1,0)NG808.Parent=NG803
NG809=Instance.new("Frame") NG809.BackgroundTransparency=1
NG809.BorderSizePixel=0
NG809.Name=dCD([=[Pbagrag]=]) NG809.Size=UDim2.new(1,0,0,680)NG809.Parent=NG802
NG810=Instance.new("TextLabel") NG810.BackgroundTransparency=1
NG810.BorderSizePixel=0
NG810.Name=dCD([=[GbbyQrfpevcgvba]=]) NG810.Position=UDim2.new(0,10,0,80)NG810.Size=UDim2.new(0,85,0,85) NG810.Font=Enum.Font.Arial
NG810.FontSize=Enum.FontSize.Size10 NG810.Text=dCD([=[Sbe zber vasbezngvba ba nal gbby, ubire lbhe zbhfr bire vgf vpba naq vg'yy erirny zber qrgnvyf.]=])NG810.TextColor3=Color3.new(1,1,1)NG810.TextWrapped=true NG810.TextXAlignment=Enum.TextXAlignment.Left
NG810.TextYAlignment=Enum.TextYAlignment.Top NG810.Parent=NG809
NG811=Instance.new("Frame")NG811.BackgroundTransparency=1 NG811.BorderSizePixel=0
NG811.Name=dCD([=[PbybeOne]=])NG811.Size=UDim2.new(1,0,0,3) NG811.Parent=NG809
NG812=Instance.new("Frame") NG812.BackgroundColor3=Color3.new(1,0.686275,0)NG812.BackgroundTransparency=0.25
NG812.BorderSizePixel=0 NG812.Name=dCD([=[Lryybj]=])NG812.Size=UDim2.new(0.200000003,0,1,0)NG812.Parent=NG811 NG813=Instance.new("Frame") NG813.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG813.BackgroundTransparency=0.25
NG813.BorderSizePixel=0 NG813.Name=dCD([=[Terra]=])NG813.Position=UDim2.new(0.200000003,0,0,0) NG813.Size=UDim2.new(0.200000003,0,1,0)NG813.Parent=NG811
NG814=Instance.new("Frame") NG814.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG814.BackgroundTransparency=0.25
NG814.BorderSizePixel=0 NG814.Name=dCD([=[Oyhr]=])NG814.Position=UDim2.new(0.400000006,0,0,0) NG814.Size=UDim2.new(0.200000003,0,1,0)NG814.Parent=NG811
NG815=Instance.new("Frame") NG815.BackgroundColor3=Color3.new(1,0,0)NG815.BackgroundTransparency=0.25
NG815.BorderSizePixel=0 NG815.Name=dCD([=[Erq]=])NG815.Position=UDim2.new(0.600000024,0,0,0) NG815.Size=UDim2.new(0.200000003,0,1,0)NG815.Parent=NG811
NG816=Instance.new("Frame") NG816.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG816.BackgroundTransparency=0.25
NG816.BorderSizePixel=0 NG816.Name=dCD([=[Checyr]=])NG816.Position=UDim2.new(0.800000012,0,0,0) NG816.Size=UDim2.new(0.200000003,0,1,0)NG816.Parent=NG811
NG817=Instance.new("TextLabel") NG817.BackgroundTransparency=1
NG817.BorderSizePixel=0
NG817.Name=dCD([=[GbbyAnzr]=]) NG817.Position=UDim2.new(0,10,0,4)NG817.Size=UDim2.new(0,80,0,80) NG817.Font=Enum.Font.ArialBold
NG817.FontSize=Enum.FontSize.Size10 NG817.Text=dCD([=[OHVYQVAT GBBYF OL S3K ZBQVSVRQ GB JBEX NF BAR FPEVCG OL AVPXBNXM]=])NG817.TextColor3=Color3.new(1,1,1)NG817.TextWrapped=true NG817.TextXAlignment=Enum.TextXAlignment.Left
NG817.Parent=NG809
NG818=Instance.new("Frame") NG818.BackgroundTransparency=1
NG818.BorderSizePixel=0
NG818.Name=dCD([=[FryrpgvbaVasb]=]) NG818.Position=UDim2.new(0,0,0,170)NG818.Size=UDim2.new(1,0,0,150)NG818.Parent=NG809 NG819=Instance.new("TextLabel")NG819.BackgroundTransparency=1
NG819.BorderSizePixel=0 NG819.Position=UDim2.new(0,10,0,15)NG819.Size=UDim2.new(0,82,0,240) NG819.Font=Enum.Font.Arial
NG819.FontSize=Enum.FontSize.Size10 NG819.Text=dCD([=[Lbh pna fryrpg zhygvcyr cnegf ol ubyqvat [Fuvsg] naq pyvpxvat ba rnpu cneg.  Lbh pna nyfb ubyq [Fuvsg], pyvpx, naq qent gb fryrpg cnegf va gung nern.  Cerff [Fuvsg + X] gb fryrpg cnegf vafvqr bs gur fryrpgrq cnegf.  Cerff [Fuvsg + E] gb pyrne lbhe fryrpgvba.]=])NG819.TextColor3=Color3.new(1,1,1)NG819.TextWrapped=true NG819.TextXAlignment=Enum.TextXAlignment.Left
NG819.TextYAlignment=Enum.TextYAlignment.Top NG819.Parent=NG818
NG820=Instance.new("TextLabel") NG820.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG820.BackgroundTransparency=1
NG820.BorderSizePixel=0 NG820.Position=UDim2.new(0,10,0,0)NG820.Size=UDim2.new(0,80,0,12) NG820.Font=Enum.Font.ArialBold
NG820.FontSize=Enum.FontSize.Size10 NG820.Text=dCD([=[Fryrpgvat]=])NG820.TextColor3=Color3.new(1,1,1)NG820.TextWrapped=true NG820.TextXAlignment=Enum.TextXAlignment.Left
NG820.TextYAlignment=Enum.TextYAlignment.Top NG820.Parent=NG818
NG821=Instance.new("Frame")NG821.BackgroundTransparency=1 NG821.BorderSizePixel=0
NG821.Name=dCD([=[RkcbegvatVasb]=]) NG821.Position=UDim2.new(0,0,0,420)NG821.Size=UDim2.new(1,0,0,220)NG821.Parent=NG809 NG822=Instance.new("TextLabel")NG822.BackgroundTransparency=1
NG822.BorderSizePixel=0 NG822.Position=UDim2.new(0,10,0,30)NG822.Size=UDim2.new(0,82,0,200) NG822.Font=Enum.Font.Arial
NG822.FontSize=Enum.FontSize.Size10 NG822.Text=dCD([=[Lbh pna rkcbeg nal perngvbaf lbh ohvyg jvgu Ohvyqvat Gbbyf ol S3K ol hfvat gur rkcbeg ohggba ba gur qbpx (be cerffvat fuvsg + C).  Vafgnyy guvf cyhtva (eboybk.pbz/vgrz.nfck?vq=142485815) va EBOYBK Fghqvb gb vzcbeg lbhe perngvba.]=])NG822.TextColor3=Color3.new(1,1,1)NG822.TextWrapped=true NG822.TextXAlignment=Enum.TextXAlignment.Left
NG822.TextYAlignment=Enum.TextYAlignment.Top NG822.Parent=NG821
NG823=Instance.new("TextLabel") NG823.BackgroundColor3=Color3.new(0.239216,0.239216,0.239216)NG823.BackgroundTransparency=1
NG823.BorderSizePixel=0 NG823.Position=UDim2.new(0,10,0,0)NG823.Size=UDim2.new(0,80,0,24) NG823.Font=Enum.Font.ArialBold
NG823.FontSize=Enum.FontSize.Size10 NG823.Text=dCD([=[Rkcbegvat lbhe perngvbaf]=])NG823.TextColor3=Color3.new(1,1,1)NG823.TextWrapped=true NG823.TextXAlignment=Enum.TextXAlignment.Left
NG823.TextYAlignment=Enum.TextYAlignment.Top NG823.Parent=NG821
NG824=Instance.new("Frame")NG824.Active=true NG824.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG824.BackgroundTransparency=1
NG824.BorderSizePixel=0 NG824.Name=dCD([=[OGTebhcfTHV]=])NG824.Position=UDim2.new(0,-210,0,0) NG824.Size=UDim2.new(0,200,0,100)NG824.Parent=NG1
NG825=Instance.new("Frame") NG825.BackgroundTransparency=1
NG825.BorderSizePixel=0
NG825.Name=dCD([=[Grzcyngrf]=]) NG825.Visible=false
NG825.Parent=NG824
NG826=Instance.new("Frame") NG826.BackgroundColor3=Color3.new(0.266667,0.266667,0.266667)NG826.BackgroundTransparency=0.64999997615814
NG826.BorderSizePixel=0 NG826.Name=dCD([=[TebhcOhggba]=])NG826.Size=UDim2.new(1,-5,0,25)NG826.Parent=NG825 NG827=Instance.new("ImageButton")NG827.BackgroundColor3=Color3.new(0,0,0) NG827.BackgroundTransparency=1
NG827.BorderSizePixel=0
NG827.Name=dCD([=[RqvgOhggba]=]) NG827.Position=UDim2.new(1,-50,0,5)NG827.Size=UDim2.new(0,16,0,16) NG827.Style=Enum.ButtonStyle.Custom
NG827.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=160400465]=]) NG827.ImageTransparency=0.25
NG827.Parent=NG826
NG828=Instance.new("Frame") NG828.BackgroundColor3=Color3.new(0,0,0)NG828.BorderSizePixel=0
NG828.Name=dCD([=[EvtugGbbygvc]=])NG828.Position=UDim2.new(0,- 50,0,0)NG828.Size=UDim2.new(0,40,0,16) NG828.Visible=false
NG828.ZIndex=2
NG828.Parent=NG827 NG829=Instance.new("Frame")NG829.BackgroundColor3=Color3.new(0,0,0) NG829.BorderSizePixel=0
NG829.Name=dCD([=[Gvc]=])NG829.Position=UDim2.new(1,-6,0,2) NG829.Rotation=45
NG829.Size=UDim2.new(0,12,0,12)NG829.ZIndex=2 NG829.Parent=NG828
NG830=Instance.new("TextLabel") NG830.BackgroundColor3=Color3.new(0,0,0)NG830.BackgroundTransparency=1
NG830.BorderSizePixel=0 NG830.Name=dCD([=[Grkg]=])NG830.Size=UDim2.new(1,4,1,0)NG830.ZIndex=3 NG830.Font=Enum.Font.ArialBold
NG830.FontSize=Enum.FontSize.Size10
NG830.Text=dCD([=[ERANZR]=]) NG830.TextColor3=Color3.new(1,1,1)NG830.Parent=NG828
NG831=Instance.new("ImageButton") NG831.BackgroundColor3=Color3.new(0,0,0)NG831.BackgroundTransparency=1
NG831.BorderSizePixel=0 NG831.Name=dCD([=[VtaberOhggba]=])NG831.Position=UDim2.new(1,-25,0,5) NG831.Size=UDim2.new(0,16,0,16)NG831.Style=Enum.ButtonStyle.Custom NG831.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=160408836]=])NG831.ImageTransparency=0.25
NG831.Parent=NG826 NG832=Instance.new("Frame")NG832.BackgroundColor3=Color3.new(0,0,0) NG832.BorderSizePixel=0
NG832.Name=dCD([=[EvtugGbbygvc]=]) NG832.Position=UDim2.new(0,-58,0,0)NG832.Size=UDim2.new(0,48,0,16)NG832.Visible=false NG832.ZIndex=2
NG832.Parent=NG831
NG833=Instance.new("Frame") NG833.BackgroundColor3=Color3.new(0,0,0)NG833.BorderSizePixel=0
NG833.Name=dCD([=[Gvc]=]) NG833.Position=UDim2.new(1,-6,0,2)NG833.Rotation=45
NG833.Size=UDim2.new(0,12,0,12) NG833.ZIndex=2
NG833.Parent=NG832
NG834=Instance.new("TextLabel") NG834.BackgroundColor3=Color3.new(0,0,0)NG834.BackgroundTransparency=1
NG834.BorderSizePixel=0 NG834.Name=dCD([=[Grkg]=])NG834.Size=UDim2.new(1,4,1,0)NG834.ZIndex=3 NG834.Font=Enum.Font.ArialBold
NG834.FontSize=Enum.FontSize.Size10
NG834.Text=dCD([=[HAVTABER]=]) NG834.TextColor3=Color3.new(1,1,1)NG834.Parent=NG832
NG835=Instance.new("ImageButton") NG835.BackgroundColor3=Color3.new(0,0,0)NG835.BackgroundTransparency=1
NG835.BorderSizePixel=0 NG835.Name=dCD([=[HcqngrOhggba]=])NG835.Position=UDim2.new(0,12,0,5) NG835.Size=UDim2.new(0,16,0,16)NG835.Style=Enum.ButtonStyle.Custom NG835.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=160402908]=])NG835.ImageTransparency=0.25
NG835.Parent=NG826 NG836=Instance.new("Frame")NG836.BackgroundColor3=Color3.new(0,0,0) NG836.BorderSizePixel=0
NG836.Name=dCD([=[YrsgGbbygvc]=]) NG836.Position=UDim2.new(1,12,0,0)NG836.Size=UDim2.new(0,38,0,16)NG836.Visible=false NG836.ZIndex=3
NG836.Parent=NG835
NG837=Instance.new("Frame") NG837.BackgroundColor3=Color3.new(0,0,0)NG837.BorderSizePixel=0
NG837.Name=dCD([=[Gvc]=]) NG837.Position=UDim2.new(0,-6,0,2)NG837.Rotation=45
NG837.Size=UDim2.new(0,12,0,12) NG837.ZIndex=3
NG837.Parent=NG836
NG838=Instance.new("TextLabel") NG838.BackgroundColor3=Color3.new(0,0,0)NG838.BackgroundTransparency=1
NG838.BorderSizePixel=0 NG838.Name=dCD([=[Grkg]=])NG838.Position=UDim2.new(0,-4,0,0) NG838.Size=UDim2.new(1,4,1,0)NG838.ZIndex=3
NG838.Font=Enum.Font.ArialBold NG838.FontSize=Enum.FontSize.Size10
NG838.Text=dCD([=[HCQNGR]=])NG838.TextColor3=Color3.new(1,1,1) NG838.Parent=NG836
NG839=Instance.new("Frame")NG839.BackgroundTransparency=1 NG839.BorderSizePixel=0
NG839.Name=dCD([=[TebhcAnzrNern]=]) NG839.Position=UDim2.new(0,35,0,0)NG839.Size=UDim2.new(0,90,0,25)NG839.Parent=NG826 NG840=Instance.new("Frame")NG840.BackgroundColor3=Color3.new(0,0,0) NG840.BorderSizePixel=0
NG840.Name=dCD([=[YrsgGbbygvc]=]) NG840.Position=UDim2.new(1,12,0,5)NG840.Size=UDim2.new(0,38,0,16)NG840.Visible=false NG840.ZIndex=2
NG840.Parent=NG839
NG841=Instance.new("Frame") NG841.BackgroundColor3=Color3.new(0,0,0)NG841.BorderSizePixel=0
NG841.Name=dCD([=[Gvc]=]) NG841.Position=UDim2.new(0,-6,0,2)NG841.Rotation=45
NG841.Size=UDim2.new(0,12,0,12) NG841.ZIndex=2
NG841.Parent=NG840
NG842=Instance.new("TextLabel") NG842.BackgroundColor3=Color3.new(0,0,0)NG842.BackgroundTransparency=1
NG842.BorderSizePixel=0 NG842.Name=dCD([=[Grkg]=])NG842.Position=UDim2.new(0,-4,0,0) NG842.Size=UDim2.new(1,4,1,0)NG842.ZIndex=3
NG842.Font=Enum.Font.ArialBold NG842.FontSize=Enum.FontSize.Size10
NG842.Text=dCD([=[FRYRPG]=])NG842.TextColor3=Color3.new(1,1,1) NG842.Parent=NG840
NG843=Instance.new("TextButton")NG843.Active=true NG843.BackgroundTransparency=1
NG843.BorderSizePixel=0
NG843.Name=dCD([=[TebhcAnzr]=]) NG843.Position=UDim2.new(0,35,0,0)NG843.Selectable=true
NG843.Size=UDim2.new(0,90,0,25) NG843.Style=Enum.ButtonStyle.Custom
NG843.ZIndex=2
NG843.Font=Enum.Font.ArialBold NG843.FontSize=Enum.FontSize.Size10
NG843.Text=dCD([=[Tebhc 1]=])NG843.TextColor3=Color3.new(1,1,1) NG843.TextStrokeTransparency=0.80000001192093
NG843.TextXAlignment=Enum.TextXAlignment.Left NG843.ClipsDescendants=true
NG843.Parent=NG826
NG844=Instance.new("TextBox") NG844.BackgroundTransparency=1
NG844.BorderSizePixel=0
NG844.Name=dCD([=[TebhcAnzre]=]) NG844.Position=UDim2.new(0,35,0,0)NG844.Size=UDim2.new(0,90,0,25)NG844.Visible=false NG844.ZIndex=2
NG844.Font=Enum.Font.ArialBold NG844.FontSize=Enum.FontSize.Size10
NG844.Text=dCD([=[Tebhc 1]=])NG844.TextColor3=Color3.new(1,1,1) NG844.TextStrokeTransparency=0.80000001192093
NG844.TextXAlignment=Enum.TextXAlignment.Left NG844.ClipsDescendants=true
NG844.Parent=NG826
NG845=Instance.new("ScrollingFrame") NG845.BackgroundTransparency=1
NG845.BorderSizePixel=0
NG845.Name=dCD([=[TebhcYvfg]=]) NG845.Position=UDim2.new(0,10,0,30)NG845.Selectable=true
NG845.Size=UDim2.new(1,-10,0,70) NG845.BottomImage=dCD([=[eoknffrg://grkgherf/oynpxOxt_fdhner.cat]=])NG845.CanvasSize=UDim2.new(1,-10,0,0) NG845.MidImage=dCD([=[eoknffrg://grkgherf/oynpxOxt_fdhner.cat]=])NG845.ScrollBarThickness=3 NG845.TopImage=dCD([=[eoknffrg://grkgherf/oynpxOxt_fdhner.cat]=])NG845.ClipsDescendants=true
NG845.Parent=NG824 NG846=Instance.new("TextLabel")NG846.BackgroundTransparency=1
NG846.BorderSizePixel=0 NG846.Name=dCD([=[FryrpgAbgr]=])NG846.Position=UDim2.new(0,10,0,27) NG846.Size=UDim2.new(1,-10,0,15)NG846.Visible=false
NG846.FontSize=Enum.FontSize.Size14 NG846.Text=dCD([=[Fryrpg fbzrguvat gb hfr guvf gbby.]=])NG846.TextColor3=Color3.new(1,1,1)NG846.TextScaled=true NG846.TextStrokeTransparency=0.5
NG846.TextWrapped=true NG846.TextXAlignment=Enum.TextXAlignment.Left
NG846.Parent=NG824
NG847=Instance.new("Frame") NG847.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG847.BackgroundTransparency=1
NG847.BorderSizePixel=0 NG847.Name=dCD([=[Gvgyr]=])NG847.Size=UDim2.new(1,0,0,20)NG847.Parent=NG824 NG848=Instance.new("TextButton")NG848.Active=true NG848.BackgroundColor3=Color3.new(0.223529,0.223529,0.223529)NG848.BackgroundTransparency=0.5
NG848.BorderSizePixel=0 NG848.Name=dCD([=[PerngrOhggba]=])NG848.Position=UDim2.new(1,-40,0,3)NG848.Selectable=true NG848.Size=UDim2.new(0,40,0,16)NG848.Style=Enum.ButtonStyle.Custom NG848.Font=Enum.Font.ArialBold
NG848.FontSize=Enum.FontSize.Size10
NG848.Text=dCD([=[ARJ]=]) NG848.TextColor3=Color3.new(1,1,1)NG848.Parent=NG847
NG849=Instance.new("Frame") NG849.BackgroundColor3=Color3.new(0,0,0)NG849.BorderSizePixel=0
NG849.Name=dCD([=[PbybeOne]=]) NG849.Position=UDim2.new(0,7,0,-3)NG849.Size=UDim2.new(1,-5,0,2)NG849.Parent=NG847 NG850=Instance.new("TextLabel") NG850.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG850.BackgroundTransparency=1
NG850.BorderSizePixel=0 NG850.Name=dCD([=[Ynory]=])NG850.Position=UDim2.new(0,10,0,1) NG850.Size=UDim2.new(1,-10,1,0)NG850.Font=Enum.Font.ArialBold NG850.FontSize=Enum.FontSize.Size10
NG850.Text=dCD([=[FRYRPGVBA TEBHCF]=]) NG850.TextColor3=Color3.new(1,1,1)NG850.TextStrokeTransparency=0
NG850.TextWrapped=true NG850.TextXAlignment=Enum.TextXAlignment.Left
NG850.Parent=NG847
NG851=Instance.new("Frame") NG851.Active=true
NG851.BackgroundColor3=Color3.new(0,0,0) NG851.BackgroundTransparency=1
NG851.BorderSizePixel=0
NG851.Name=dCD([=[OGRkcbegQvnybt]=]) NG851.Position=UDim2.new(0,100,0,128)NG851.Size=UDim2.new(0,200,0,110)NG851.Draggable=true NG851.Parent=NG1
NG852=Instance.new("Frame")NG852.BackgroundTransparency=1 NG852.BorderSizePixel=0
NG852.Name=dCD([=[Vasb]=])NG852.Size=UDim2.new(1,0,0,75) NG852.Visible=false
NG852.ClipsDescendants=true
NG852.Parent=NG851 NG853=Instance.new("TextLabel")NG853.BackgroundTransparency=1
NG853.BorderSizePixel=0 NG853.Name=dCD([=[PerngvbaVQYnory]=])NG853.Position=UDim2.new(0,0,0,5) NG853.Size=UDim2.new(1,0,0,40)NG853.Font=Enum.Font.SourceSansBold NG853.FontSize=Enum.FontSize.Size18
NG853.Text=dCD([=[Lbhe perngvba'f VQ:]=]) NG853.TextColor3=Color3.new(1,1,1)NG853.TextStrokeTransparency=0.75
NG853.Parent=NG852 NG854=Instance.new("TextLabel")NG854.BackgroundTransparency=1
NG854.BorderSizePixel=0 NG854.Name=dCD([=[PerngvbaVQ]=])NG854.Position=UDim2.new(0,0,0,30) NG854.Size=UDim2.new(1,0,0,40)NG854.Font=Enum.Font.SourceSansBold NG854.FontSize=Enum.FontSize.Size24
NG854.Text=dCD([=[w5bs0]=]) NG854.TextColor3=Color3.new(0.439216,0.439216,0.439216)NG854.TextStrokeColor3=Color3.new(1,1,1) NG854.TextStrokeTransparency=0
NG854.Parent=NG852
NG855=Instance.new("Frame") NG855.BackgroundTransparency=1
NG855.BorderSizePixel=0
NG855.Name=dCD([=[PbybeOne]=]) NG855.Size=UDim2.new(1,0,0,3)NG855.Parent=NG852
NG856=Instance.new("Frame") NG856.BackgroundColor3=Color3.new(1,0.686275,0)NG856.BorderSizePixel=0
NG856.Name=dCD([=[Lryybj]=]) NG856.Size=UDim2.new(0.200000003,0,1,0)NG856.Parent=NG855
NG857=Instance.new("Frame") NG857.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG857.BorderSizePixel=0
NG857.Name=dCD([=[Terra]=]) NG857.Position=UDim2.new(0.200000003,0,0,0)NG857.Size=UDim2.new(0.200000003,0,1,0)NG857.Parent=NG855 NG858=Instance.new("Frame") NG858.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG858.BorderSizePixel=0
NG858.Name=dCD([=[Oyhr]=]) NG858.Position=UDim2.new(0.400000006,0,0,0)NG858.Size=UDim2.new(0.200000003,0,1,0)NG858.Parent=NG855 NG859=Instance.new("Frame")NG859.BackgroundColor3=Color3.new(1,0,0) NG859.BorderSizePixel=0
NG859.Name=dCD([=[Erq]=]) NG859.Position=UDim2.new(0.600000024,0,0,0)NG859.Size=UDim2.new(0.200000003,0,1,0)NG859.Parent=NG855 NG860=Instance.new("Frame") NG860.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG860.BorderSizePixel=0
NG860.Name=dCD([=[Checyr]=]) NG860.Position=UDim2.new(0.800000012,0,0,0)NG860.Size=UDim2.new(0.200000003,0,1,0)NG860.Parent=NG855 NG861=Instance.new("Frame")NG861.BackgroundTransparency=1
NG861.BorderSizePixel=0 NG861.Name=dCD([=[Gvc]=])NG861.Position=UDim2.new(0,0,0,75) NG861.Size=UDim2.new(1,0,0,30)NG861.Visible=false
NG861.Parent=NG851 NG862=Instance.new("TextLabel")NG862.BackgroundTransparency=1
NG862.BorderSizePixel=0 NG862.Name=dCD([=[Gvc]=])NG862.Position=UDim2.new(0,0,0,7) NG862.Size=UDim2.new(1,0,0,30)NG862.Font=Enum.Font.SourceSansBold NG862.FontSize=Enum.FontSize.Size12 NG862.Text=dCD([=[Hfr gur VQ nobir gb vzcbeg lbhe perngvba hfvat gur cyhtva.]=])NG862.TextColor3=Color3.new(1,1,1) NG862.TextStrokeTransparency=0.75
NG862.TextWrapped=true NG862.TextXAlignment=Enum.TextXAlignment.Left
NG862.TextYAlignment=Enum.TextYAlignment.Top NG862.Parent=NG861
NG863=Instance.new("Frame")NG863.BackgroundTransparency=1 NG863.BorderSizePixel=0
NG863.Name=dCD([=[PbybeOne]=])NG863.Rotation=180 NG863.Size=UDim2.new(1,0,0,3)NG863.Parent=NG861
NG864=Instance.new("Frame") NG864.BackgroundColor3=Color3.new(1,0.686275,0)NG864.BorderSizePixel=0
NG864.Name=dCD([=[Lryybj]=]) NG864.Size=UDim2.new(0.200000003,0,1,0)NG864.Parent=NG863
NG865=Instance.new("Frame") NG865.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG865.BorderSizePixel=0
NG865.Name=dCD([=[Terra]=]) NG865.Position=UDim2.new(0.200000003,0,0,0)NG865.Size=UDim2.new(0.200000003,0,1,0)NG865.Parent=NG863 NG866=Instance.new("Frame") NG866.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG866.BorderSizePixel=0
NG866.Name=dCD([=[Oyhr]=]) NG866.Position=UDim2.new(0.400000006,0,0,0)NG866.Size=UDim2.new(0.200000003,0,1,0)NG866.Parent=NG863 NG867=Instance.new("Frame")NG867.BackgroundColor3=Color3.new(1,0,0) NG867.BorderSizePixel=0
NG867.Name=dCD([=[Erq]=]) NG867.Position=UDim2.new(0.600000024,0,0,0)NG867.Size=UDim2.new(0.200000003,0,1,0)NG867.Parent=NG863 NG868=Instance.new("Frame") NG868.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG868.BorderSizePixel=0
NG868.Name=dCD([=[Checyr]=]) NG868.Position=UDim2.new(0.800000012,0,0,0)NG868.Size=UDim2.new(0.200000003,0,1,0)NG868.Parent=NG863 NG869=Instance.new("Frame")NG869.BackgroundColor3=Color3.new(0,0,0) NG869.BackgroundTransparency=1
NG869.BorderSizePixel=0
NG869.Name=dCD([=[Pybfr]=]) NG869.Position=UDim2.new(0,0,1,5)NG869.Size=UDim2.new(1,0,0,20)NG869.Visible=false NG869.Parent=NG851
NG870=Instance.new("TextButton")NG870.Active=true NG870.BackgroundColor3=Color3.new(0,0,0)NG870.BackgroundTransparency=0.5
NG870.BorderSizePixel=0 NG870.Name=dCD([=[Ohggba]=])NG870.Selectable=true
NG870.Size=UDim2.new(1,0,1,0) NG870.Style=Enum.ButtonStyle.Custom
NG870.FontSize=Enum.FontSize.Size14
NG870.Text=dCD([=[Tbg vg]=]) NG870.TextColor3=Color3.new(1,1,1)NG870.TextStrokeTransparency=0.80000001192093
NG870.Parent=NG869 NG871=Instance.new("Frame")NG871.BackgroundColor3=Color3.new(0,0,0) NG871.BackgroundTransparency=0.30000001192093
NG871.BorderSizePixel=0
NG871.Name=dCD([=[Funqbj]=]) NG871.Position=UDim2.new(0,0,1,0)NG871.Size=UDim2.new(1,0,0,2)NG871.ZIndex=2 NG871.Parent=NG869
NG872=Instance.new("Frame")NG872.BackgroundTransparency=1 NG872.BorderSizePixel=0
NG872.Name=dCD([=[Ybnqvat]=])NG872.Size=UDim2.new(1,0,0,80) NG872.ClipsDescendants=true
NG872.Parent=NG851
NG873=Instance.new("Frame") NG873.BackgroundTransparency=1
NG873.BorderSizePixel=0
NG873.Name=dCD([=[PbybeOne]=]) NG873.Size=UDim2.new(1,0,0,3)NG873.Parent=NG872
NG874=Instance.new("Frame") NG874.BackgroundColor3=Color3.new(1,0.686275,0)NG874.BackgroundTransparency=0.25
NG874.BorderSizePixel=0 NG874.Name=dCD([=[Lryybj]=])NG874.Size=UDim2.new(0.200000003,0,1,0)NG874.Parent=NG873 NG875=Instance.new("Frame") NG875.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG875.BackgroundTransparency=0.25
NG875.BorderSizePixel=0 NG875.Name=dCD([=[Terra]=])NG875.Position=UDim2.new(0.200000003,0,0,0) NG875.Size=UDim2.new(0.200000003,0,1,0)NG875.Parent=NG873
NG876=Instance.new("Frame") NG876.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG876.BackgroundTransparency=0.25
NG876.BorderSizePixel=0 NG876.Name=dCD([=[Oyhr]=])NG876.Position=UDim2.new(0.400000006,0,0,0) NG876.Size=UDim2.new(0.200000003,0,1,0)NG876.Parent=NG873
NG877=Instance.new("Frame") NG877.BackgroundColor3=Color3.new(1,0,0)NG877.BackgroundTransparency=0.25
NG877.BorderSizePixel=0 NG877.Name=dCD([=[Erq]=])NG877.Position=UDim2.new(0.600000024,0,0,0) NG877.Size=UDim2.new(0.200000003,0,1,0)NG877.Parent=NG873
NG878=Instance.new("Frame") NG878.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG878.BackgroundTransparency=0.25
NG878.BorderSizePixel=0 NG878.Name=dCD([=[Checyr]=])NG878.Position=UDim2.new(0.800000012,0,0,0) NG878.Size=UDim2.new(0.200000003,0,1,0)NG878.Parent=NG873
NG879=Instance.new("TextLabel") NG879.BackgroundTransparency=1
NG879.BorderSizePixel=0
NG879.Size=UDim2.new(1,0,0,50) NG879.Font=Enum.Font.SourceSansBold
NG879.FontSize=Enum.FontSize.Size18 NG879.Text=dCD([=[Hcybnqvat lbhe perngvba...]=])NG879.TextColor3=Color3.new(1,1,1) NG879.TextStrokeTransparency=0.80000001192093
NG879.TextWrapped=true
NG879.Parent=NG872 NG880=Instance.new("Frame")NG880.BackgroundTransparency=1
NG880.BorderSizePixel=0 NG880.Name=dCD([=[ObggbzPbybeOne]=])NG880.Position=UDim2.new(0,0,1,0)NG880.Rotation=180 NG880.Size=UDim2.new(1,0,0,3)NG880.Parent=NG872
NG881=Instance.new("Frame") NG881.BackgroundColor3=Color3.new(1,0.686275,0)NG881.BackgroundTransparency=0.25
NG881.BorderSizePixel=0 NG881.Name=dCD([=[Lryybj]=])NG881.Size=UDim2.new(0.200000003,0,1,0)NG881.Parent=NG880 NG882=Instance.new("Frame") NG882.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG882.BackgroundTransparency=0.25
NG882.BorderSizePixel=0 NG882.Name=dCD([=[Terra]=])NG882.Position=UDim2.new(0.200000003,0,0,0) NG882.Size=UDim2.new(0.200000003,0,1,0)NG882.Parent=NG880
NG883=Instance.new("Frame") NG883.BackgroundColor3=Color3.new(0.0156863,0.686275,0.92549)NG883.BackgroundTransparency=0.25
NG883.BorderSizePixel=0 NG883.Name=dCD([=[Oyhr]=])NG883.Position=UDim2.new(0.400000006,0,0,0) NG883.Size=UDim2.new(0.200000003,0,1,0)NG883.Parent=NG880
NG884=Instance.new("Frame") NG884.BackgroundColor3=Color3.new(1,0,0)NG884.BackgroundTransparency=0.25
NG884.BorderSizePixel=0 NG884.Name=dCD([=[Erq]=])NG884.Position=UDim2.new(0.600000024,0,0,0) NG884.Size=UDim2.new(0.200000003,0,1,0)NG884.Parent=NG880
NG885=Instance.new("Frame") NG885.BackgroundColor3=Color3.new(0.419608,0.196078,0.486275)NG885.BackgroundTransparency=0.25
NG885.BorderSizePixel=0 NG885.Name=dCD([=[Checyr]=])NG885.Position=UDim2.new(0.800000012,0,0,0) NG885.Size=UDim2.new(0.200000003,0,1,0)NG885.Parent=NG880
NG886=Instance.new("TextButton") NG886.Active=true
NG886.BackgroundColor3=Color3.new(0,0,0) NG886.BackgroundTransparency=0.5
NG886.BorderSizePixel=0
NG886.Name=dCD([=[PybfrOhggba]=])NG886.Position=UDim2.new(0,0,1,- 30)NG886.Selectable=true NG886.Size=UDim2.new(1,0,0,25)NG886.Style=Enum.ButtonStyle.Custom NG886.Font=Enum.Font.SourceSansBold
NG886.FontSize=Enum.FontSize.Size14
NG886.Text=dCD([=[Pybfr]=]) NG886.TextColor3=Color3.new(1,1,1)NG886.TextStrokeTransparency=0.85000002384186
NG886.Parent=NG872 NG887=Instance.new("Frame")NG887.BackgroundColor3=Color3.new(0,0,0) NG887.BackgroundTransparency=0.69999998807907
NG887.BorderSizePixel=0
NG887.Name=dCD([=[Funqbj]=]) NG887.Position=UDim2.new(0,0,1,-2)NG887.Size=UDim2.new(1,0,0,2)NG887.Parent=NG886 NG888=Instance.new("Frame")NG888.Active=true NG888.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG888.BackgroundTransparency=1
NG888.BorderSizePixel=0 NG888.Name=dCD([=[OGQrpbengrGbbyTHV]=])NG888.Position=UDim2.new(0,0,0,172) NG888.Size=UDim2.new(0,200,0,125)NG888.Draggable=true
NG888.Parent=NG1 NG889=Instance.new("Frame")NG889.BackgroundColor3=Color3.new(0,0,0) NG889.BorderSizePixel=0
NG889.Name=dCD([=[ObggbzPbybeOne]=]) NG889.Position=UDim2.new(0,5,1,-2)NG889.Size=UDim2.new(1,0,0,2)NG889.Parent=NG888 NG890=Instance.new("Frame") NG890.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG890.BackgroundTransparency=1
NG890.BorderSizePixel=0 NG890.Name=dCD([=[Gvgyr]=])NG890.Size=UDim2.new(1,0,0,20)NG890.Parent=NG888 NG891=Instance.new("Frame")NG891.BackgroundColor3=Color3.new(0,0,0) NG891.BorderSizePixel=0
NG891.Name=dCD([=[PbybeOne]=])NG891.Position=UDim2.new(0,5,0,-3)NG891.Size=UDim2.new(1, -5,0,2)NG891.Parent=NG890 NG892=Instance.new("TextLabel") NG892.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG892.BackgroundTransparency=1
NG892.BorderSizePixel=0 NG892.Name=dCD([=[Ynory]=])NG892.Position=UDim2.new(0,10,0,1) NG892.Size=UDim2.new(1,-10,1,0)NG892.Font=Enum.Font.ArialBold NG892.FontSize=Enum.FontSize.Size10
NG892.Text=dCD([=[QRPBENGR GBBY]=]) NG892.TextColor3=Color3.new(1,1,1)NG892.TextStrokeTransparency=0
NG892.TextWrapped=true NG892.TextXAlignment=Enum.TextXAlignment.Left
NG892.Parent=NG890
NG893=Instance.new("TextLabel") NG893.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG893.BackgroundTransparency=1
NG893.BorderSizePixel=0 NG893.Name=dCD([=[S3KFvtangher]=])NG893.Position=UDim2.new(0,10,0,1) NG893.Size=UDim2.new(1,-10,1,0)NG893.Font=Enum.Font.ArialBold NG893.FontSize=Enum.FontSize.Size14
NG893.Text=dCD([=[S3K]=])NG893.TextColor3=Color3.new(1,1,1) NG893.TextStrokeTransparency=0.89999997615814
NG893.TextWrapped=true NG893.TextXAlignment=Enum.TextXAlignment.Right
NG893.Parent=NG890
NG894=Instance.new("Frame") NG894.BackgroundColor3=Color3.new(0,0,0)NG894.BackgroundTransparency=0.67500001192093
NG894.BorderSizePixel=0 NG894.Name=dCD([=[Fzbxr]=])NG894.Position=UDim2.new(0,10,0,30) NG894.Size=UDim2.new(1,-10,0,25)NG894.Parent=NG888
NG895=Instance.new("TextLabel") NG895.BackgroundTransparency=1
NG895.BorderSizePixel=0
NG895.Name=dCD([=[Ynory]=]) NG895.Position=UDim2.new(0,35,0,0)NG895.Size=UDim2.new(0,60,0,25) NG895.Font=Enum.Font.ArialBold
NG895.FontSize=Enum.FontSize.Size10
NG895.Text=dCD([=[Fzbxr]=]) NG895.TextColor3=Color3.new(1,1,1)NG895.TextStrokeTransparency=0.5
NG895.TextWrapped=true NG895.TextXAlignment=Enum.TextXAlignment.Left
NG895.Parent=NG894
NG896=Instance.new("ImageButton") NG896.BackgroundTransparency=1
NG896.BorderSizePixel=0
NG896.Name=dCD([=[NeebjOhggba]=]) NG896.Position=UDim2.new(0,10,0,3)NG896.Size=UDim2.new(0,20,0,20) NG896.Style=Enum.ButtonStyle.Custom
NG896.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=134367382]=]) NG896.Parent=NG894
NG897=Instance.new("Frame") NG897.BackgroundColor3=Color3.new(1,0.682353,0.235294)NG897.BorderSizePixel=0
NG897.Name=dCD([=[PbybeOne]=]) NG897.Size=UDim2.new(0,3,1,0)NG897.Parent=NG894
NG898=Instance.new("TextButton") NG898.Active=true
NG898.BackgroundColor3=Color3.new(0,0,0) NG898.BackgroundTransparency=0.75
NG898.BorderColor3=Color3.new(0,0,0)NG898.BorderSizePixel=0 NG898.Name=dCD([=[NqqOhggba]=])NG898.Position=UDim2.new(1,-40,0,3)NG898.Selectable=true NG898.Size=UDim2.new(0,35,0,19)NG898.Style=Enum.ButtonStyle.Custom NG898.Font=Enum.Font.ArialBold
NG898.FontSize=Enum.FontSize.Size10
NG898.Text=dCD([=[NQQ]=]) NG898.TextColor3=Color3.new(1,1,1)NG898.Parent=NG894
NG899=Instance.new("TextButton") NG899.Active=true
NG899.BackgroundColor3=Color3.new(0,0,0) NG899.BackgroundTransparency=0.75
NG899.BorderColor3=Color3.new(0,0,0)NG899.BorderSizePixel=0 NG899.Name=dCD([=[ErzbirOhggba]=])NG899.Position=UDim2.new(0,127,0,3)NG899.Selectable=true NG899.Size=UDim2.new(0,58,0,19)NG899.Style=Enum.ButtonStyle.Custom
NG899.Visible=false NG899.Font=Enum.Font.ArialBold
NG899.FontSize=Enum.FontSize.Size10
NG899.Text=dCD([=[ERZBIR]=]) NG899.TextColor3=Color3.new(1,1,1)NG899.Parent=NG894
NG900=Instance.new("Frame") NG900.BackgroundColor3=Color3.new(0,0,0)NG900.BackgroundTransparency=0.75
NG900.BorderSizePixel=0 NG900.Name=dCD([=[Funqbj]=])NG900.Position=UDim2.new(0,0,1,-1) NG900.Size=UDim2.new(1,0,0,1)NG900.Parent=NG894
NG901=Instance.new("Frame") NG901.BackgroundTransparency=1
NG901.BorderSizePixel=0
NG901.Name=dCD([=[Bcgvbaf]=]) NG901.Position=UDim2.new(0,3,1,0)NG901.Size=UDim2.new(1,-3,0,0)NG901.ClipsDescendants=true NG901.Parent=NG894
NG902=Instance.new("Frame") NG902.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG902.BackgroundTransparency=1
NG902.BorderSizePixel=0 NG902.Name=dCD([=[PbybeBcgvba]=])NG902.Position=UDim2.new(0,0,0,10) NG902.Size=UDim2.new(1,0,0,25)NG902.Parent=NG901
NG903=Instance.new("TextLabel") NG903.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG903.BackgroundTransparency=1
NG903.BorderSizePixel=0 NG903.Name=dCD([=[Ynory]=])NG903.Size=UDim2.new(0,70,0,25) NG903.Font=Enum.Font.ArialBold
NG903.FontSize=Enum.FontSize.Size10
NG903.Text=dCD([=[Pbybe]=]) NG903.TextColor3=Color3.new(1,1,1)NG903.TextStrokeTransparency=0
NG903.TextWrapped=true NG903.TextXAlignment=Enum.TextXAlignment.Left
NG903.Parent=NG902
NG904=Instance.new("Frame") NG904.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG904.BackgroundTransparency=1
NG904.BorderSizePixel=0 NG904.Name=dCD([=[EVachg]=])NG904.Position=UDim2.new(0,35,0,0) NG904.Size=UDim2.new(0,38,0,25)NG904.Parent=NG902
NG905=Instance.new("TextButton") NG905.Active=true
NG905.AutoButtonColor=false NG905.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG905.BackgroundTransparency=1
NG905.BorderSizePixel=0 NG905.Selectable=true
NG905.Size=UDim2.new(1,0,1,0) NG905.Style=Enum.ButtonStyle.Custom
NG905.ZIndex=2
NG905.Font=Enum.Font.Legacy NG905.FontSize=Enum.FontSize.Size8
NG905.Text=dCD([=[]=])NG905.Parent=NG904 NG906=Instance.new("ImageLabel")NG906.Active=false NG906.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG906.BackgroundTransparency=1
NG906.BorderSizePixel=0 NG906.Name=dCD([=[Onpxtebhaq]=])NG906.Selectable=false
NG906.Size=UDim2.new(1,0,1,0) NG906.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG906.Parent=NG904
NG907=Instance.new("Frame") NG907.BackgroundColor3=Color3.new(1,0,0)NG907.BorderSizePixel=0
NG907.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG907.Position=UDim2.new(0,3,0, -2)NG907.Size=UDim2.new(1,-3,0,2) NG907.Parent=NG904
NG908=Instance.new("TextBox") NG908.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG908.BackgroundTransparency=1
NG908.BorderSizePixel=0 NG908.Position=UDim2.new(0,5,0,0)NG908.Size=UDim2.new(1,-10,1,0) NG908.Font=Enum.Font.ArialBold
NG908.FontSize=Enum.FontSize.Size10
NG908.Text=dCD([=[255]=]) NG908.TextColor3=Color3.new(1,1,1)NG908.Parent=NG904
NG909=Instance.new("Frame") NG909.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG909.BackgroundTransparency=1
NG909.BorderSizePixel=0 NG909.Name=dCD([=[TVachg]=])NG909.Position=UDim2.new(0,72,0,0) NG909.Size=UDim2.new(0,38,0,25)NG909.Parent=NG902
NG910=Instance.new("TextButton") NG910.Active=true
NG910.AutoButtonColor=false NG910.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG910.BackgroundTransparency=1
NG910.BorderSizePixel=0 NG910.Selectable=true
NG910.Size=UDim2.new(1,0,1,0) NG910.Style=Enum.ButtonStyle.Custom
NG910.ZIndex=2
NG910.Font=Enum.Font.Legacy NG910.FontSize=Enum.FontSize.Size8
NG910.Text=dCD([=[]=])NG910.Parent=NG909 NG911=Instance.new("ImageLabel")NG911.Active=false NG911.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG911.BackgroundTransparency=1
NG911.BorderSizePixel=0 NG911.Name=dCD([=[Onpxtebhaq]=])NG911.Selectable=false
NG911.Size=UDim2.new(1,0,1,0) NG911.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG911.Parent=NG909
NG912=Instance.new("Frame") NG912.BackgroundColor3=Color3.new(0,1,0)NG912.BorderSizePixel=0
NG912.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG912.Position=UDim2.new(0,3,0, -2)NG912.Size=UDim2.new(1,-3,0,2) NG912.Parent=NG909
NG913=Instance.new("TextBox") NG913.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG913.BackgroundTransparency=1
NG913.BorderSizePixel=0 NG913.Position=UDim2.new(0,5,0,0)NG913.Size=UDim2.new(1,-10,1,0) NG913.Font=Enum.Font.ArialBold
NG913.FontSize=Enum.FontSize.Size10
NG913.Text=dCD([=[255]=]) NG913.TextColor3=Color3.new(1,1,1)NG913.Parent=NG909
NG914=Instance.new("Frame") NG914.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG914.BackgroundTransparency=1
NG914.BorderSizePixel=0 NG914.Name=dCD([=[OVachg]=])NG914.Position=UDim2.new(0,109,0,0) NG914.Size=UDim2.new(0,38,0,25)NG914.Parent=NG902
NG915=Instance.new("TextButton") NG915.Active=true
NG915.AutoButtonColor=false NG915.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG915.BackgroundTransparency=1
NG915.BorderSizePixel=0 NG915.Selectable=true
NG915.Size=UDim2.new(1,0,1,0) NG915.Style=Enum.ButtonStyle.Custom
NG915.ZIndex=2
NG915.Font=Enum.Font.Legacy NG915.FontSize=Enum.FontSize.Size8
NG915.Text=dCD([=[]=])NG915.Parent=NG914 NG916=Instance.new("ImageLabel")NG916.Active=false NG916.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG916.BackgroundTransparency=1
NG916.BorderSizePixel=0 NG916.Name=dCD([=[Onpxtebhaq]=])NG916.Selectable=false
NG916.Size=UDim2.new(1,0,1,0) NG916.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG916.Parent=NG914
NG917=Instance.new("Frame") NG917.BackgroundColor3=Color3.new(0,0,1)NG917.BorderSizePixel=0
NG917.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG917.Position=UDim2.new(0,3,0, -2)NG917.Size=UDim2.new(1,-3,0,2) NG917.Parent=NG914
NG918=Instance.new("TextBox") NG918.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG918.BackgroundTransparency=1
NG918.BorderSizePixel=0 NG918.Position=UDim2.new(0,5,0,0)NG918.Size=UDim2.new(1,-10,1,0) NG918.Font=Enum.Font.ArialBold
NG918.FontSize=Enum.FontSize.Size10
NG918.Text=dCD([=[255]=]) NG918.TextColor3=Color3.new(1,1,1)NG918.Parent=NG914
NG919=Instance.new("ImageButton") NG919.BackgroundColor3=Color3.new(0,0,0)NG919.BackgroundTransparency=0.40000000596046
NG919.BorderSizePixel=0 NG919.Name=dCD([=[UFICvpxre]=])NG919.Position=UDim2.new(0,160,0,-2) NG919.Size=UDim2.new(0,27,0,27)NG919.Style=Enum.ButtonStyle.Custom NG919.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141313631]=])NG919.Parent=NG902
NG920=Instance.new("Frame") NG920.BackgroundColor3=Color3.new(0,0,0)NG920.BackgroundTransparency=0.75
NG920.BorderSizePixel=0 NG920.Name=dCD([=[Funqbj]=])NG920.Position=UDim2.new(0,0,1,-2) NG920.Size=UDim2.new(1,0,0,2)NG920.Parent=NG919
NG921=Instance.new("Frame") NG921.BackgroundColor3=Color3.new(0,0,0)NG921.BackgroundTransparency=0.5 NG921.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG921.BorderSizePixel=0
NG921.Name=dCD([=[Frcnengbe]=]) NG921.Position=UDim2.new(0,151,0,4)NG921.Size=UDim2.new(0,4,0,4)NG921.Parent=NG902 NG922=Instance.new("Frame")NG922.BackgroundColor3=Color3.new(0,0,0) NG922.BackgroundTransparency=0.5 NG922.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG922.BorderSizePixel=0
NG922.Name=dCD([=[Frcnengbe]=]) NG922.Position=UDim2.new(0,151,0,16)NG922.Size=UDim2.new(0,4,0,4)NG922.Parent=NG902 NG923=Instance.new("Frame")NG923.BackgroundColor3=Color3.new(0,0,0) NG923.BackgroundTransparency=0.5 NG923.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG923.BorderSizePixel=0
NG923.Name=dCD([=[Frcnengbe]=]) NG923.Position=UDim2.new(0,151,0,10)NG923.Size=UDim2.new(0,4,0,4)NG923.Parent=NG902 NG924=Instance.new("Frame") NG924.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG924.BackgroundTransparency=1
NG924.BorderSizePixel=0 NG924.Name=dCD([=[BcnpvglBcgvba]=])NG924.Position=UDim2.new(0,0,0,45) NG924.Size=UDim2.new(1,0,0,25)NG924.Parent=NG901
NG925=Instance.new("TextLabel") NG925.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG925.BackgroundTransparency=1
NG925.BorderSizePixel=0 NG925.Name=dCD([=[Ynory]=])NG925.Size=UDim2.new(0,70,0,25) NG925.Font=Enum.Font.ArialBold
NG925.FontSize=Enum.FontSize.Size10
NG925.Text=dCD([=[Bcnpvgl]=]) NG925.TextColor3=Color3.new(1,1,1)NG925.TextStrokeTransparency=0
NG925.TextWrapped=true NG925.TextXAlignment=Enum.TextXAlignment.Left
NG925.Parent=NG924
NG926=Instance.new("Frame") NG926.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG926.BackgroundTransparency=1
NG926.BorderSizePixel=0 NG926.Name=dCD([=[Vachg]=])NG926.Position=UDim2.new(0,45,0,0) NG926.Size=UDim2.new(0,38,0,25)NG926.Parent=NG924
NG927=Instance.new("TextButton") NG927.Active=true
NG927.AutoButtonColor=false NG927.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG927.BackgroundTransparency=1
NG927.BorderSizePixel=0 NG927.Selectable=true
NG927.Size=UDim2.new(1,0,1,0) NG927.Style=Enum.ButtonStyle.Custom
NG927.ZIndex=2
NG927.Font=Enum.Font.Legacy NG927.FontSize=Enum.FontSize.Size8
NG927.Text=dCD([=[]=])NG927.Parent=NG926 NG928=Instance.new("ImageLabel")NG928.Active=false NG928.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG928.BackgroundTransparency=1
NG928.BorderSizePixel=0 NG928.Name=dCD([=[Onpxtebhaq]=])NG928.Selectable=false
NG928.Size=UDim2.new(1,0,1,0) NG928.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG928.Parent=NG926
NG929=Instance.new("Frame") NG929.BorderSizePixel=0
NG929.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG929.Position=UDim2.new(0,3,0,-2)NG929.Size=UDim2.new(1,-3,0,2)NG929.Parent=NG926 NG930=Instance.new("TextBox") NG930.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG930.BackgroundTransparency=1
NG930.BorderSizePixel=0 NG930.Position=UDim2.new(0,5,0,0)NG930.Size=UDim2.new(1,-10,1,0) NG930.Font=Enum.Font.ArialBold
NG930.FontSize=Enum.FontSize.Size10
NG930.Text=dCD([=[1]=]) NG930.TextColor3=Color3.new(1,1,1)NG930.Parent=NG926
NG931=Instance.new("Frame") NG931.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG931.BackgroundTransparency=1
NG931.BorderSizePixel=0 NG931.Name=dCD([=[IrybpvglBcgvba]=])NG931.Position=UDim2.new(0,100,0,45) NG931.Size=UDim2.new(1,-115,0,25)NG931.Parent=NG901
NG932=Instance.new("TextLabel") NG932.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG932.BackgroundTransparency=1
NG932.BorderSizePixel=0 NG932.Name=dCD([=[Ynory]=])NG932.Size=UDim2.new(0,70,0,25) NG932.Font=Enum.Font.ArialBold
NG932.FontSize=Enum.FontSize.Size10
NG932.Text=dCD([=[Irybpvgl]=]) NG932.TextColor3=Color3.new(1,1,1)NG932.TextStrokeTransparency=0
NG932.TextWrapped=true NG932.TextXAlignment=Enum.TextXAlignment.Left
NG932.Parent=NG931
NG933=Instance.new("Frame") NG933.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG933.BackgroundTransparency=1
NG933.BorderSizePixel=0 NG933.Name=dCD([=[Vachg]=])NG933.Position=UDim2.new(0,45,0,0) NG933.Size=UDim2.new(0,38,0,25)NG933.Parent=NG931
NG934=Instance.new("TextButton") NG934.Active=true
NG934.AutoButtonColor=false NG934.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG934.BackgroundTransparency=1
NG934.BorderSizePixel=0 NG934.Selectable=true
NG934.Size=UDim2.new(1,0,1,0) NG934.Style=Enum.ButtonStyle.Custom
NG934.ZIndex=2
NG934.Font=Enum.Font.Legacy NG934.FontSize=Enum.FontSize.Size8
NG934.Text=dCD([=[]=])NG934.Parent=NG933 NG935=Instance.new("ImageLabel")NG935.Active=false NG935.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG935.BackgroundTransparency=1
NG935.BorderSizePixel=0 NG935.Name=dCD([=[Onpxtebhaq]=])NG935.Selectable=false
NG935.Size=UDim2.new(1,0,1,0) NG935.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG935.Parent=NG933
NG936=Instance.new("Frame") NG936.BorderSizePixel=0
NG936.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG936.Position=UDim2.new(0,3,0,-2)NG936.Size=UDim2.new(1,-3,0,2)NG936.Parent=NG933 NG937=Instance.new("TextBox") NG937.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG937.BackgroundTransparency=1
NG937.BorderSizePixel=0 NG937.Position=UDim2.new(0,5,0,0)NG937.Size=UDim2.new(1,-10,1,0) NG937.Font=Enum.Font.ArialBold
NG937.FontSize=Enum.FontSize.Size10
NG937.Text=dCD([=[90]=]) NG937.TextColor3=Color3.new(1,1,1)NG937.Parent=NG933
NG938=Instance.new("Frame") NG938.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG938.BackgroundTransparency=1
NG938.BorderSizePixel=0 NG938.Name=dCD([=[FvmrBcgvba]=])NG938.Position=UDim2.new(0,0,0,80) NG938.Size=UDim2.new(1,0,0,25)NG938.Parent=NG901
NG939=Instance.new("TextLabel") NG939.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG939.BackgroundTransparency=1
NG939.BorderSizePixel=0 NG939.Name=dCD([=[Ynory]=])NG939.Size=UDim2.new(0,70,0,25) NG939.Font=Enum.Font.ArialBold
NG939.FontSize=Enum.FontSize.Size10
NG939.Text=dCD([=[Fvmr]=]) NG939.TextColor3=Color3.new(1,1,1)NG939.TextStrokeTransparency=0
NG939.TextWrapped=true NG939.TextXAlignment=Enum.TextXAlignment.Left
NG939.Parent=NG938
NG940=Instance.new("Frame") NG940.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG940.BackgroundTransparency=1
NG940.BorderSizePixel=0 NG940.Name=dCD([=[Vachg]=])NG940.Position=UDim2.new(0,30,0,0) NG940.Size=UDim2.new(0,38,0,25)NG940.Parent=NG938
NG941=Instance.new("TextButton") NG941.Active=true
NG941.AutoButtonColor=false NG941.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG941.BackgroundTransparency=1
NG941.BorderSizePixel=0 NG941.Selectable=true
NG941.Size=UDim2.new(1,0,1,0) NG941.Style=Enum.ButtonStyle.Custom
NG941.ZIndex=2
NG941.Font=Enum.Font.Legacy NG941.FontSize=Enum.FontSize.Size8
NG941.Text=dCD([=[]=])NG941.Parent=NG940 NG942=Instance.new("ImageLabel")NG942.Active=false NG942.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG942.BackgroundTransparency=1
NG942.BorderSizePixel=0 NG942.Name=dCD([=[Onpxtebhaq]=])NG942.Selectable=false
NG942.Size=UDim2.new(1,0,1,0) NG942.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG942.Parent=NG940
NG943=Instance.new("Frame") NG943.BorderSizePixel=0
NG943.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG943.Position=UDim2.new(0,3,0,-2)NG943.Size=UDim2.new(1,-3,0,2)NG943.Parent=NG940 NG944=Instance.new("TextBox") NG944.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG944.BackgroundTransparency=1
NG944.BorderSizePixel=0 NG944.Position=UDim2.new(0,5,0,0)NG944.Size=UDim2.new(1,-10,1,0) NG944.Font=Enum.Font.ArialBold
NG944.FontSize=Enum.FontSize.Size10
NG944.Text=dCD([=[16]=]) NG944.TextColor3=Color3.new(1,1,1)NG944.Parent=NG940
NG945=Instance.new("TextLabel") NG945.BackgroundTransparency=1
NG945.BorderSizePixel=0
NG945.Name=dCD([=[FryrpgAbgr]=]) NG945.Position=UDim2.new(0,10,0,27)NG945.Size=UDim2.new(1,-10,0,15)NG945.Visible=false NG945.FontSize=Enum.FontSize.Size14
NG945.Text=dCD([=[Fryrpg fbzrguvat gb hfr guvf gbby.]=]) NG945.TextColor3=Color3.new(1,1,1)NG945.TextScaled=true
NG945.TextStrokeTransparency=0.5 NG945.TextWrapped=true
NG945.TextXAlignment=Enum.TextXAlignment.Left NG945.Parent=NG888
NG946=Instance.new("Frame") NG946.BackgroundColor3=Color3.new(0,0,0)NG946.BackgroundTransparency=0.67500001192093
NG946.BorderSizePixel=0 NG946.Name=dCD([=[Sver]=])NG946.Position=UDim2.new(0,10,0,60) NG946.Size=UDim2.new(1,-10,0,25)NG946.Parent=NG888
NG947=Instance.new("TextLabel") NG947.BackgroundTransparency=1
NG947.BorderSizePixel=0
NG947.Name=dCD([=[Ynory]=]) NG947.Position=UDim2.new(0,35,0,0)NG947.Size=UDim2.new(0,60,0,25) NG947.Font=Enum.Font.ArialBold
NG947.FontSize=Enum.FontSize.Size10
NG947.Text=dCD([=[Sver]=]) NG947.TextColor3=Color3.new(1,1,1)NG947.TextStrokeTransparency=0.5
NG947.TextWrapped=true NG947.TextXAlignment=Enum.TextXAlignment.Left
NG947.Parent=NG946
NG948=Instance.new("ImageButton") NG948.BackgroundTransparency=1
NG948.BorderSizePixel=0
NG948.Name=dCD([=[NeebjOhggba]=]) NG948.Position=UDim2.new(0,10,0,3)NG948.Size=UDim2.new(0,20,0,20) NG948.Style=Enum.ButtonStyle.Custom
NG948.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=134367382]=]) NG948.Parent=NG946
NG949=Instance.new("Frame") NG949.BackgroundColor3=Color3.new(0.85098,0,1)NG949.BorderSizePixel=0
NG949.Name=dCD([=[PbybeOne]=]) NG949.Size=UDim2.new(0,3,1,0)NG949.Parent=NG946
NG950=Instance.new("TextButton") NG950.Active=true
NG950.BackgroundColor3=Color3.new(0,0,0) NG950.BackgroundTransparency=0.75
NG950.BorderColor3=Color3.new(0,0,0)NG950.BorderSizePixel=0 NG950.Name=dCD([=[NqqOhggba]=])NG950.Position=UDim2.new(1,-40,0,3)NG950.Selectable=true NG950.Size=UDim2.new(0,35,0,19)NG950.Style=Enum.ButtonStyle.Custom NG950.Font=Enum.Font.ArialBold
NG950.FontSize=Enum.FontSize.Size10
NG950.Text=dCD([=[NQQ]=]) NG950.TextColor3=Color3.new(1,1,1)NG950.Parent=NG946
NG951=Instance.new("TextButton") NG951.Active=true
NG951.BackgroundColor3=Color3.new(0,0,0) NG951.BackgroundTransparency=0.75
NG951.BorderColor3=Color3.new(0,0,0)NG951.BorderSizePixel=0 NG951.Name=dCD([=[ErzbirOhggba]=])NG951.Position=UDim2.new(0,90,0,3)NG951.Selectable=true NG951.Size=UDim2.new(0,58,0,19)NG951.Style=Enum.ButtonStyle.Custom
NG951.Visible=false NG951.Font=Enum.Font.ArialBold
NG951.FontSize=Enum.FontSize.Size10
NG951.Text=dCD([=[ERZBIR]=]) NG951.TextColor3=Color3.new(1,1,1)NG951.Parent=NG946
NG952=Instance.new("Frame") NG952.BackgroundColor3=Color3.new(0,0,0)NG952.BackgroundTransparency=0.75
NG952.BorderSizePixel=0 NG952.Name=dCD([=[Funqbj]=])NG952.Position=UDim2.new(0,0,1,-1) NG952.Size=UDim2.new(1,0,0,1)NG952.Parent=NG946
NG953=Instance.new("Frame") NG953.BackgroundTransparency=1
NG953.BorderSizePixel=0
NG953.Name=dCD([=[Bcgvbaf]=]) NG953.Position=UDim2.new(0,3,1,0)NG953.Size=UDim2.new(1,-3,0,0)NG953.ClipsDescendants=true NG953.Parent=NG946
NG954=Instance.new("Frame") NG954.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG954.BackgroundTransparency=1
NG954.BorderSizePixel=0 NG954.Name=dCD([=[PbybeBcgvba]=])NG954.Position=UDim2.new(0,0,0,10) NG954.Size=UDim2.new(1,0,0,25)NG954.Parent=NG953
NG955=Instance.new("TextLabel") NG955.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG955.BackgroundTransparency=1
NG955.BorderSizePixel=0 NG955.Name=dCD([=[Ynory]=])NG955.Size=UDim2.new(0,70,0,25) NG955.Font=Enum.Font.ArialBold
NG955.FontSize=Enum.FontSize.Size10
NG955.Text=dCD([=[Pbybe]=]) NG955.TextColor3=Color3.new(1,1,1)NG955.TextStrokeTransparency=0
NG955.TextWrapped=true NG955.TextXAlignment=Enum.TextXAlignment.Left
NG955.Parent=NG954
NG956=Instance.new("Frame") NG956.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG956.BackgroundTransparency=1
NG956.BorderSizePixel=0 NG956.Name=dCD([=[EVachg]=])NG956.Position=UDim2.new(0,35,0,0) NG956.Size=UDim2.new(0,38,0,25)NG956.Parent=NG954
NG957=Instance.new("TextButton") NG957.Active=true
NG957.AutoButtonColor=false NG957.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG957.BackgroundTransparency=1
NG957.BorderSizePixel=0 NG957.Selectable=true
NG957.Size=UDim2.new(1,0,1,0) NG957.Style=Enum.ButtonStyle.Custom
NG957.ZIndex=2
NG957.Font=Enum.Font.Legacy NG957.FontSize=Enum.FontSize.Size8
NG957.Text=dCD([=[]=])NG957.Parent=NG956 NG958=Instance.new("ImageLabel")NG958.Active=false NG958.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG958.BackgroundTransparency=1
NG958.BorderSizePixel=0 NG958.Name=dCD([=[Onpxtebhaq]=])NG958.Selectable=false
NG958.Size=UDim2.new(1,0,1,0) NG958.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG958.Parent=NG956
NG959=Instance.new("Frame") NG959.BackgroundColor3=Color3.new(1,0,0)NG959.BorderSizePixel=0
NG959.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG959.Position=UDim2.new(0,3,0, -2)NG959.Size=UDim2.new(1,-3,0,2) NG959.Parent=NG956
NG960=Instance.new("TextBox") NG960.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG960.BackgroundTransparency=1
NG960.BorderSizePixel=0 NG960.Position=UDim2.new(0,5,0,0)NG960.Size=UDim2.new(1,-10,1,0) NG960.Font=Enum.Font.ArialBold
NG960.FontSize=Enum.FontSize.Size10
NG960.Text=dCD([=[255]=]) NG960.TextColor3=Color3.new(1,1,1)NG960.Parent=NG956
NG961=Instance.new("Frame") NG961.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG961.BackgroundTransparency=1
NG961.BorderSizePixel=0 NG961.Name=dCD([=[TVachg]=])NG961.Position=UDim2.new(0,72,0,0) NG961.Size=UDim2.new(0,38,0,25)NG961.Parent=NG954
NG962=Instance.new("TextButton") NG962.Active=true
NG962.AutoButtonColor=false NG962.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG962.BackgroundTransparency=1
NG962.BorderSizePixel=0 NG962.Selectable=true
NG962.Size=UDim2.new(1,0,1,0) NG962.Style=Enum.ButtonStyle.Custom
NG962.ZIndex=2
NG962.Font=Enum.Font.Legacy NG962.FontSize=Enum.FontSize.Size8
NG962.Text=dCD([=[]=])NG962.Parent=NG961 NG963=Instance.new("ImageLabel")NG963.Active=false NG963.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG963.BackgroundTransparency=1
NG963.BorderSizePixel=0 NG963.Name=dCD([=[Onpxtebhaq]=])NG963.Selectable=false
NG963.Size=UDim2.new(1,0,1,0) NG963.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG963.Parent=NG961
NG964=Instance.new("Frame") NG964.BackgroundColor3=Color3.new(0,1,0)NG964.BorderSizePixel=0
NG964.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG964.Position=UDim2.new(0,3,0, -2)NG964.Size=UDim2.new(1,-3,0,2) NG964.Parent=NG961
NG965=Instance.new("TextBox") NG965.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG965.BackgroundTransparency=1
NG965.BorderSizePixel=0 NG965.Position=UDim2.new(0,5,0,0)NG965.Size=UDim2.new(1,-10,1,0) NG965.Font=Enum.Font.ArialBold
NG965.FontSize=Enum.FontSize.Size10
NG965.Text=dCD([=[255]=]) NG965.TextColor3=Color3.new(1,1,1)NG965.Parent=NG961
NG966=Instance.new("Frame") NG966.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG966.BackgroundTransparency=1
NG966.BorderSizePixel=0 NG966.Name=dCD([=[OVachg]=])NG966.Position=UDim2.new(0,109,0,0) NG966.Size=UDim2.new(0,38,0,25)NG966.Parent=NG954
NG967=Instance.new("TextButton") NG967.Active=true
NG967.AutoButtonColor=false NG967.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG967.BackgroundTransparency=1
NG967.BorderSizePixel=0 NG967.Selectable=true
NG967.Size=UDim2.new(1,0,1,0) NG967.Style=Enum.ButtonStyle.Custom
NG967.ZIndex=2
NG967.Font=Enum.Font.Legacy NG967.FontSize=Enum.FontSize.Size8
NG967.Text=dCD([=[]=])NG967.Parent=NG966 NG968=Instance.new("ImageLabel")NG968.Active=false NG968.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG968.BackgroundTransparency=1
NG968.BorderSizePixel=0 NG968.Name=dCD([=[Onpxtebhaq]=])NG968.Selectable=false
NG968.Size=UDim2.new(1,0,1,0) NG968.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG968.Parent=NG966
NG969=Instance.new("Frame") NG969.BackgroundColor3=Color3.new(0,0,1)NG969.BorderSizePixel=0
NG969.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG969.Position=UDim2.new(0,3,0, -2)NG969.Size=UDim2.new(1,-3,0,2) NG969.Parent=NG966
NG970=Instance.new("TextBox") NG970.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG970.BackgroundTransparency=1
NG970.BorderSizePixel=0 NG970.Position=UDim2.new(0,5,0,0)NG970.Size=UDim2.new(1,-10,1,0) NG970.Font=Enum.Font.ArialBold
NG970.FontSize=Enum.FontSize.Size10
NG970.Text=dCD([=[255]=]) NG970.TextColor3=Color3.new(1,1,1)NG970.Parent=NG966
NG971=Instance.new("ImageButton") NG971.BackgroundColor3=Color3.new(0,0,0)NG971.BackgroundTransparency=0.40000000596046
NG971.BorderSizePixel=0 NG971.Name=dCD([=[UFICvpxre]=])NG971.Position=UDim2.new(0,160,0,-2) NG971.Size=UDim2.new(0,27,0,27)NG971.Style=Enum.ButtonStyle.Custom
NG971.ZIndex=2 NG971.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141313631]=])NG971.Parent=NG954
NG972=Instance.new("Frame") NG972.BackgroundColor3=Color3.new(0,0,0)NG972.BackgroundTransparency=0.75
NG972.BorderSizePixel=0 NG972.Name=dCD([=[Funqbj]=])NG972.Position=UDim2.new(0,0,1,-2) NG972.Size=UDim2.new(1,0,0,2)NG972.Parent=NG971
NG973=Instance.new("Frame") NG973.BackgroundColor3=Color3.new(0,0,0)NG973.BackgroundTransparency=0.5 NG973.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG973.BorderSizePixel=0
NG973.Name=dCD([=[Frcnengbe]=]) NG973.Position=UDim2.new(0,151,0,4)NG973.Size=UDim2.new(0,4,0,4)NG973.Parent=NG954 NG974=Instance.new("Frame")NG974.BackgroundColor3=Color3.new(0,0,0) NG974.BackgroundTransparency=0.5 NG974.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG974.BorderSizePixel=0
NG974.Name=dCD([=[Frcnengbe]=]) NG974.Position=UDim2.new(0,151,0,16)NG974.Size=UDim2.new(0,4,0,4)NG974.Parent=NG954 NG975=Instance.new("Frame")NG975.BackgroundColor3=Color3.new(0,0,0) NG975.BackgroundTransparency=0.5 NG975.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG975.BorderSizePixel=0
NG975.Name=dCD([=[Frcnengbe]=]) NG975.Position=UDim2.new(0,151,0,10)NG975.Size=UDim2.new(0,4,0,4)NG975.Parent=NG954 NG976=Instance.new("Frame") NG976.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG976.BackgroundTransparency=1
NG976.BorderSizePixel=0 NG976.Name=dCD([=[UrngBcgvba]=])NG976.Position=UDim2.new(0,0,0,80) NG976.Size=UDim2.new(1,0,0,25)NG976.Parent=NG953
NG977=Instance.new("TextLabel") NG977.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG977.BackgroundTransparency=1
NG977.BorderSizePixel=0 NG977.Name=dCD([=[Ynory]=])NG977.Size=UDim2.new(0,70,0,25) NG977.Font=Enum.Font.ArialBold
NG977.FontSize=Enum.FontSize.Size10
NG977.Text=dCD([=[Urng]=]) NG977.TextColor3=Color3.new(1,1,1)NG977.TextStrokeTransparency=0
NG977.TextWrapped=true NG977.TextXAlignment=Enum.TextXAlignment.Left
NG977.Parent=NG976
NG978=Instance.new("Frame") NG978.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG978.BackgroundTransparency=1
NG978.BorderSizePixel=0 NG978.Name=dCD([=[Vachg]=])NG978.Position=UDim2.new(0,34,0,0) NG978.Size=UDim2.new(0,38,0,25)NG978.Parent=NG976
NG979=Instance.new("TextButton") NG979.Active=true
NG979.AutoButtonColor=false NG979.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG979.BackgroundTransparency=1
NG979.BorderSizePixel=0 NG979.Selectable=true
NG979.Size=UDim2.new(1,0,1,0) NG979.Style=Enum.ButtonStyle.Custom
NG979.ZIndex=2
NG979.Font=Enum.Font.Legacy NG979.FontSize=Enum.FontSize.Size8
NG979.Text=dCD([=[]=])NG979.Parent=NG978 NG980=Instance.new("ImageLabel")NG980.Active=false NG980.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG980.BackgroundTransparency=1
NG980.BorderSizePixel=0 NG980.Name=dCD([=[Onpxtebhaq]=])NG980.Selectable=false
NG980.Size=UDim2.new(1,0,1,0) NG980.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG980.Parent=NG978
NG981=Instance.new("Frame") NG981.BorderSizePixel=0
NG981.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG981.Position=UDim2.new(0,3,0,-2)NG981.Size=UDim2.new(1,-3,0,2)NG981.Parent=NG978 NG982=Instance.new("TextBox") NG982.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG982.BackgroundTransparency=1
NG982.BorderSizePixel=0 NG982.Position=UDim2.new(0,5,0,0)NG982.Size=UDim2.new(1,-10,1,0) NG982.Font=Enum.Font.ArialBold
NG982.FontSize=Enum.FontSize.Size10
NG982.Text=dCD([=[1]=]) NG982.TextColor3=Color3.new(1,1,1)NG982.Parent=NG978
NG983=Instance.new("Frame") NG983.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG983.BackgroundTransparency=1
NG983.BorderSizePixel=0 NG983.Name=dCD([=[FvmrBcgvba]=])NG983.Position=UDim2.new(0,90,0,80) NG983.Size=UDim2.new(1,0,0,25)NG983.Parent=NG953
NG984=Instance.new("TextLabel") NG984.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG984.BackgroundTransparency=1
NG984.BorderSizePixel=0 NG984.Name=dCD([=[Ynory]=])NG984.Size=UDim2.new(0,70,0,25) NG984.Font=Enum.Font.ArialBold
NG984.FontSize=Enum.FontSize.Size10
NG984.Text=dCD([=[Fvmr]=]) NG984.TextColor3=Color3.new(1,1,1)NG984.TextStrokeTransparency=0
NG984.TextWrapped=true NG984.TextXAlignment=Enum.TextXAlignment.Left
NG984.Parent=NG983
NG985=Instance.new("Frame") NG985.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG985.BackgroundTransparency=1
NG985.BorderSizePixel=0 NG985.Name=dCD([=[Vachg]=])NG985.Position=UDim2.new(0,30,0,0) NG985.Size=UDim2.new(0,38,0,25)NG985.Parent=NG983
NG986=Instance.new("TextButton") NG986.Active=true
NG986.AutoButtonColor=false NG986.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG986.BackgroundTransparency=1
NG986.BorderSizePixel=0 NG986.Selectable=true
NG986.Size=UDim2.new(1,0,1,0) NG986.Style=Enum.ButtonStyle.Custom
NG986.ZIndex=2
NG986.Font=Enum.Font.Legacy NG986.FontSize=Enum.FontSize.Size8
NG986.Text=dCD([=[]=])NG986.Parent=NG985 NG987=Instance.new("ImageLabel")NG987.Active=false NG987.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG987.BackgroundTransparency=1
NG987.BorderSizePixel=0 NG987.Name=dCD([=[Onpxtebhaq]=])NG987.Selectable=false
NG987.Size=UDim2.new(1,0,1,0) NG987.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG987.Parent=NG985
NG988=Instance.new("Frame") NG988.BorderSizePixel=0
NG988.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG988.Position=UDim2.new(0,3,0,-2)NG988.Size=UDim2.new(1,-3,0,2)NG988.Parent=NG985 NG989=Instance.new("TextBox") NG989.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG989.BackgroundTransparency=1
NG989.BorderSizePixel=0 NG989.Position=UDim2.new(0,5,0,0)NG989.Size=UDim2.new(1,-10,1,0) NG989.Font=Enum.Font.ArialBold
NG989.FontSize=Enum.FontSize.Size10
NG989.Text=dCD([=[16]=]) NG989.TextColor3=Color3.new(1,1,1)NG989.Parent=NG985
NG990=Instance.new("Frame") NG990.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG990.BackgroundTransparency=1
NG990.BorderSizePixel=0 NG990.Name=dCD([=[FrpbaqPbybeBcgvba]=])NG990.Position=UDim2.new(0,0,0,45) NG990.Size=UDim2.new(1,0,0,25)NG990.Parent=NG953
NG991=Instance.new("TextLabel") NG991.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG991.BackgroundTransparency=1
NG991.BorderSizePixel=0 NG991.Name=dCD([=[Ynory]=])NG991.Size=UDim2.new(0,40,0,25) NG991.Font=Enum.Font.ArialBold
NG991.FontSize=Enum.FontSize.Size10 NG991.Text=dCD([=[2aq Pbybe]=])NG991.TextColor3=Color3.new(1,1,1) NG991.TextStrokeTransparency=0
NG991.TextWrapped=true NG991.TextXAlignment=Enum.TextXAlignment.Left
NG991.Parent=NG990
NG992=Instance.new("Frame") NG992.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG992.BackgroundTransparency=1
NG992.BorderSizePixel=0 NG992.Name=dCD([=[EVachg]=])NG992.Position=UDim2.new(0,35,0,0) NG992.Size=UDim2.new(0,38,0,25)NG992.Parent=NG990
NG993=Instance.new("TextButton") NG993.Active=true
NG993.AutoButtonColor=false NG993.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG993.BackgroundTransparency=1
NG993.BorderSizePixel=0 NG993.Selectable=true
NG993.Size=UDim2.new(1,0,1,0) NG993.Style=Enum.ButtonStyle.Custom
NG993.ZIndex=2
NG993.Font=Enum.Font.Legacy NG993.FontSize=Enum.FontSize.Size8
NG993.Text=dCD([=[]=])NG993.Parent=NG992 NG994=Instance.new("ImageLabel")NG994.Active=false NG994.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG994.BackgroundTransparency=1
NG994.BorderSizePixel=0 NG994.Name=dCD([=[Onpxtebhaq]=])NG994.Selectable=false
NG994.Size=UDim2.new(1,0,1,0) NG994.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG994.Parent=NG992
NG995=Instance.new("Frame") NG995.BackgroundColor3=Color3.new(1,0,0)NG995.BorderSizePixel=0
NG995.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG995.Position=UDim2.new(0,3,0, -2)NG995.Size=UDim2.new(1,-3,0,2) NG995.Parent=NG992
NG996=Instance.new("TextBox") NG996.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG996.BackgroundTransparency=1
NG996.BorderSizePixel=0 NG996.Position=UDim2.new(0,5,0,0)NG996.Size=UDim2.new(1,-10,1,0) NG996.Font=Enum.Font.ArialBold
NG996.FontSize=Enum.FontSize.Size10
NG996.Text=dCD([=[255]=]) NG996.TextColor3=Color3.new(1,1,1)NG996.Parent=NG992
NG997=Instance.new("Frame") NG997.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG997.BackgroundTransparency=1
NG997.BorderSizePixel=0 NG997.Name=dCD([=[TVachg]=])NG997.Position=UDim2.new(0,72,0,0) NG997.Size=UDim2.new(0,38,0,25)NG997.Parent=NG990
NG998=Instance.new("TextButton") NG998.Active=true
NG998.AutoButtonColor=false NG998.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG998.BackgroundTransparency=1
NG998.BorderSizePixel=0 NG998.Selectable=true
NG998.Size=UDim2.new(1,0,1,0) NG998.Style=Enum.ButtonStyle.Custom
NG998.ZIndex=2
NG998.Font=Enum.Font.Legacy NG998.FontSize=Enum.FontSize.Size8
NG998.Text=dCD([=[]=])NG998.Parent=NG997 NG999=Instance.new("ImageLabel")NG999.Active=false NG999.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG999.BackgroundTransparency=1
NG999.BorderSizePixel=0 NG999.Name=dCD([=[Onpxtebhaq]=])NG999.Selectable=false
NG999.Size=UDim2.new(1,0,1,0) NG999.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG999.Parent=NG997
NG1000=Instance.new("Frame") NG1000.BackgroundColor3=Color3.new(0,1,0)NG1000.BorderSizePixel=0
NG1000.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1000.Position=UDim2.new(0,3,0, -2)NG1000.Size=UDim2.new(1,-3,0,2) NG1000.Parent=NG997
NG1001=Instance.new("TextBox") NG1001.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1001.BackgroundTransparency=1
NG1001.BorderSizePixel=0 NG1001.Position=UDim2.new(0,5,0,0)NG1001.Size=UDim2.new(1,-10,1,0) NG1001.Font=Enum.Font.ArialBold
NG1001.FontSize=Enum.FontSize.Size10
NG1001.Text=dCD([=[255]=]) NG1001.TextColor3=Color3.new(1,1,1)NG1001.Parent=NG997
NG1002=Instance.new("Frame") NG1002.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1002.BackgroundTransparency=1
NG1002.BorderSizePixel=0 NG1002.Name=dCD([=[OVachg]=])NG1002.Position=UDim2.new(0,109,0,0) NG1002.Size=UDim2.new(0,38,0,25)NG1002.Parent=NG990
NG1003=Instance.new("TextButton") NG1003.Active=true
NG1003.AutoButtonColor=false NG1003.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1003.BackgroundTransparency=1
NG1003.BorderSizePixel=0 NG1003.Selectable=true
NG1003.Size=UDim2.new(1,0,1,0) NG1003.Style=Enum.ButtonStyle.Custom
NG1003.ZIndex=2
NG1003.Font=Enum.Font.Legacy NG1003.FontSize=Enum.FontSize.Size8
NG1003.Text=dCD([=[]=])NG1003.Parent=NG1002 NG1004=Instance.new("ImageLabel")NG1004.Active=false NG1004.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1004.BackgroundTransparency=1
NG1004.BorderSizePixel=0 NG1004.Name=dCD([=[Onpxtebhaq]=])NG1004.Selectable=false
NG1004.Size=UDim2.new(1,0,1,0) NG1004.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1004.Parent=NG1002
NG1005=Instance.new("Frame") NG1005.BackgroundColor3=Color3.new(0,0,1)NG1005.BorderSizePixel=0
NG1005.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1005.Position=UDim2.new(0,3,0, -2)NG1005.Size=UDim2.new(1,-3,0,2) NG1005.Parent=NG1002
NG1006=Instance.new("TextBox") NG1006.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1006.BackgroundTransparency=1
NG1006.BorderSizePixel=0 NG1006.Position=UDim2.new(0,5,0,0)NG1006.Size=UDim2.new(1,-10,1,0) NG1006.Font=Enum.Font.ArialBold
NG1006.FontSize=Enum.FontSize.Size10
NG1006.Text=dCD([=[255]=]) NG1006.TextColor3=Color3.new(1,1,1)NG1006.Parent=NG1002
NG1007=Instance.new("ImageButton") NG1007.BackgroundColor3=Color3.new(0,0,0)NG1007.BackgroundTransparency=0.40000000596046
NG1007.BorderSizePixel=0 NG1007.Name=dCD([=[UFICvpxre]=])NG1007.Position=UDim2.new(0,160,0,-2) NG1007.Size=UDim2.new(0,27,0,27)NG1007.Style=Enum.ButtonStyle.Custom
NG1007.ZIndex=2 NG1007.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141313631]=])NG1007.Parent=NG990
NG1008=Instance.new("Frame") NG1008.BackgroundColor3=Color3.new(0,0,0)NG1008.BackgroundTransparency=0.75
NG1008.BorderSizePixel=0 NG1008.Name=dCD([=[Funqbj]=])NG1008.Position=UDim2.new(0,0,1,-2) NG1008.Size=UDim2.new(1,0,0,2)NG1008.Parent=NG1007
NG1009=Instance.new("Frame") NG1009.BackgroundColor3=Color3.new(0,0,0)NG1009.BackgroundTransparency=0.5 NG1009.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1009.BorderSizePixel=0
NG1009.Name=dCD([=[Frcnengbe]=]) NG1009.Position=UDim2.new(0,151,0,4)NG1009.Size=UDim2.new(0,4,0,4)NG1009.Parent=NG990 NG1010=Instance.new("Frame")NG1010.BackgroundColor3=Color3.new(0,0,0) NG1010.BackgroundTransparency=0.5 NG1010.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1010.BorderSizePixel=0
NG1010.Name=dCD([=[Frcnengbe]=]) NG1010.Position=UDim2.new(0,151,0,16)NG1010.Size=UDim2.new(0,4,0,4)NG1010.Parent=NG990 NG1011=Instance.new("Frame")NG1011.BackgroundColor3=Color3.new(0,0,0) NG1011.BackgroundTransparency=0.5 NG1011.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1011.BorderSizePixel=0
NG1011.Name=dCD([=[Frcnengbe]=]) NG1011.Position=UDim2.new(0,151,0,10)NG1011.Size=UDim2.new(0,4,0,4)NG1011.Parent=NG990 NG1012=Instance.new("Frame")NG1012.BackgroundColor3=Color3.new(0,0,0) NG1012.BackgroundTransparency=0.67500001192093
NG1012.BorderSizePixel=0
NG1012.Name=dCD([=[Fcnexyrf]=]) NG1012.Position=UDim2.new(0,10,0,90)NG1012.Size=UDim2.new(1,-10,0,25)NG1012.Parent=NG888 NG1013=Instance.new("TextLabel")NG1013.BackgroundTransparency=1
NG1013.BorderSizePixel=0 NG1013.Name=dCD([=[Ynory]=])NG1013.Position=UDim2.new(0,35,0,0) NG1013.Size=UDim2.new(0,60,0,25)NG1013.Font=Enum.Font.ArialBold NG1013.FontSize=Enum.FontSize.Size10
NG1013.Text=dCD([=[Fcnexyrf]=]) NG1013.TextColor3=Color3.new(1,1,1)NG1013.TextStrokeTransparency=0.5
NG1013.TextWrapped=true NG1013.TextXAlignment=Enum.TextXAlignment.Left
NG1013.Parent=NG1012
NG1014=Instance.new("ImageButton") NG1014.BackgroundTransparency=1
NG1014.BorderSizePixel=0
NG1014.Name=dCD([=[NeebjOhggba]=]) NG1014.Position=UDim2.new(0,10,0,3)NG1014.Size=UDim2.new(0,20,0,20) NG1014.Style=Enum.ButtonStyle.Custom
NG1014.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=134367382]=]) NG1014.Parent=NG1012
NG1015=Instance.new("Frame") NG1015.BackgroundColor3=Color3.new(0.0196078,0.396078,1)NG1015.BorderSizePixel=0
NG1015.Name=dCD([=[PbybeOne]=]) NG1015.Size=UDim2.new(0,3,1,0)NG1015.Parent=NG1012
NG1016=Instance.new("TextButton") NG1016.Active=true
NG1016.BackgroundColor3=Color3.new(0,0,0) NG1016.BackgroundTransparency=0.75
NG1016.BorderColor3=Color3.new(0,0,0) NG1016.BorderSizePixel=0
NG1016.Name=dCD([=[NqqOhggba]=]) NG1016.Position=UDim2.new(1,-40,0,3)NG1016.Selectable=true
NG1016.Size=UDim2.new(0,35,0,19) NG1016.Style=Enum.ButtonStyle.Custom
NG1016.ZIndex=2
NG1016.Font=Enum.Font.ArialBold NG1016.FontSize=Enum.FontSize.Size10
NG1016.Text=dCD([=[NQQ]=])NG1016.TextColor3=Color3.new(1,1,1) NG1016.Parent=NG1012
NG1017=Instance.new("TextButton")NG1017.Active=true NG1017.BackgroundColor3=Color3.new(0,0,0)NG1017.BackgroundTransparency=0.75 NG1017.BorderColor3=Color3.new(0,0,0)NG1017.BorderSizePixel=0
NG1017.Name=dCD([=[ErzbirOhggba]=]) NG1017.Position=UDim2.new(0,90,0,3)NG1017.Selectable=true
NG1017.Size=UDim2.new(0,58,0,19) NG1017.Style=Enum.ButtonStyle.Custom
NG1017.Visible=false
NG1017.ZIndex=2 NG1017.Font=Enum.Font.ArialBold
NG1017.FontSize=Enum.FontSize.Size10 NG1017.Text=dCD([=[ERZBIR]=])NG1017.TextColor3=Color3.new(1,1,1)NG1017.Parent=NG1012 NG1018=Instance.new("Frame")NG1018.BackgroundColor3=Color3.new(0,0,0) NG1018.BackgroundTransparency=0.75
NG1018.BorderSizePixel=0
NG1018.Name=dCD([=[Funqbj]=]) NG1018.Position=UDim2.new(0,0,1,-1)NG1018.Size=UDim2.new(1,0,0,1)NG1018.Parent=NG1012 NG1019=Instance.new("Frame")NG1019.BackgroundTransparency=1
NG1019.BorderSizePixel=0 NG1019.Name=dCD([=[Bcgvbaf]=])NG1019.Position=UDim2.new(0,3,1,0) NG1019.Size=UDim2.new(1,-3,0,0)NG1019.ClipsDescendants=true
NG1019.Parent=NG1012 NG1020=Instance.new("Frame") NG1020.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1020.BackgroundTransparency=1
NG1020.BorderSizePixel=0 NG1020.Name=dCD([=[PbybeBcgvba]=])NG1020.Position=UDim2.new(0,0,0,10) NG1020.Size=UDim2.new(1,0,0,25)NG1020.Parent=NG1019
NG1021=Instance.new("TextLabel") NG1021.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1021.BackgroundTransparency=1
NG1021.BorderSizePixel=0 NG1021.Name=dCD([=[Ynory]=])NG1021.Size=UDim2.new(0,70,0,25) NG1021.Font=Enum.Font.ArialBold
NG1021.FontSize=Enum.FontSize.Size10
NG1021.Text=dCD([=[Pbybe]=]) NG1021.TextColor3=Color3.new(1,1,1)NG1021.TextStrokeTransparency=0
NG1021.TextWrapped=true NG1021.TextXAlignment=Enum.TextXAlignment.Left
NG1021.Parent=NG1020
NG1022=Instance.new("Frame") NG1022.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1022.BackgroundTransparency=1
NG1022.BorderSizePixel=0 NG1022.Name=dCD([=[EVachg]=])NG1022.Position=UDim2.new(0,35,0,0) NG1022.Size=UDim2.new(0,38,0,25)NG1022.Parent=NG1020
NG1023=Instance.new("TextButton") NG1023.Active=true
NG1023.AutoButtonColor=false NG1023.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1023.BackgroundTransparency=1
NG1023.BorderSizePixel=0 NG1023.Selectable=true
NG1023.Size=UDim2.new(1,0,1,0) NG1023.Style=Enum.ButtonStyle.Custom
NG1023.ZIndex=2
NG1023.Font=Enum.Font.Legacy NG1023.FontSize=Enum.FontSize.Size8
NG1023.Text=dCD([=[]=])NG1023.Parent=NG1022 NG1024=Instance.new("ImageLabel")NG1024.Active=false NG1024.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1024.BackgroundTransparency=1
NG1024.BorderSizePixel=0 NG1024.Name=dCD([=[Onpxtebhaq]=])NG1024.Selectable=false
NG1024.Size=UDim2.new(1,0,1,0) NG1024.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1024.Parent=NG1022
NG1025=Instance.new("Frame") NG1025.BackgroundColor3=Color3.new(1,0,0)NG1025.BorderSizePixel=0
NG1025.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1025.Position=UDim2.new(0,3,0, -2)NG1025.Size=UDim2.new(1,-3,0,2) NG1025.Parent=NG1022
NG1026=Instance.new("TextBox") NG1026.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1026.BackgroundTransparency=1
NG1026.BorderSizePixel=0 NG1026.Position=UDim2.new(0,5,0,0)NG1026.Size=UDim2.new(1,-10,1,0) NG1026.Font=Enum.Font.ArialBold
NG1026.FontSize=Enum.FontSize.Size10
NG1026.Text=dCD([=[255]=]) NG1026.TextColor3=Color3.new(1,1,1)NG1026.Parent=NG1022
NG1027=Instance.new("Frame") NG1027.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1027.BackgroundTransparency=1
NG1027.BorderSizePixel=0 NG1027.Name=dCD([=[TVachg]=])NG1027.Position=UDim2.new(0,72,0,0) NG1027.Size=UDim2.new(0,38,0,25)NG1027.Parent=NG1020
NG1028=Instance.new("TextButton") NG1028.Active=true
NG1028.AutoButtonColor=false NG1028.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1028.BackgroundTransparency=1
NG1028.BorderSizePixel=0 NG1028.Selectable=true
NG1028.Size=UDim2.new(1,0,1,0) NG1028.Style=Enum.ButtonStyle.Custom
NG1028.ZIndex=2
NG1028.Font=Enum.Font.Legacy NG1028.FontSize=Enum.FontSize.Size8
NG1028.Text=dCD([=[]=])NG1028.Parent=NG1027 NG1029=Instance.new("ImageLabel")NG1029.Active=false NG1029.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1029.BackgroundTransparency=1
NG1029.BorderSizePixel=0 NG1029.Name=dCD([=[Onpxtebhaq]=])NG1029.Selectable=false
NG1029.Size=UDim2.new(1,0,1,0) NG1029.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1029.Parent=NG1027
NG1030=Instance.new("Frame") NG1030.BackgroundColor3=Color3.new(0,1,0)NG1030.BorderSizePixel=0
NG1030.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1030.Position=UDim2.new(0,3,0, -2)NG1030.Size=UDim2.new(1,-3,0,2) NG1030.Parent=NG1027
NG1031=Instance.new("TextBox") NG1031.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1031.BackgroundTransparency=1
NG1031.BorderSizePixel=0 NG1031.Position=UDim2.new(0,5,0,0)NG1031.Size=UDim2.new(1,-10,1,0) NG1031.Font=Enum.Font.ArialBold
NG1031.FontSize=Enum.FontSize.Size10
NG1031.Text=dCD([=[255]=]) NG1031.TextColor3=Color3.new(1,1,1)NG1031.Parent=NG1027
NG1032=Instance.new("Frame") NG1032.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1032.BackgroundTransparency=1
NG1032.BorderSizePixel=0 NG1032.Name=dCD([=[OVachg]=])NG1032.Position=UDim2.new(0,109,0,0) NG1032.Size=UDim2.new(0,38,0,25)NG1032.Parent=NG1020
NG1033=Instance.new("TextButton") NG1033.Active=true
NG1033.AutoButtonColor=false NG1033.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1033.BackgroundTransparency=1
NG1033.BorderSizePixel=0 NG1033.Selectable=true
NG1033.Size=UDim2.new(1,0,1,0) NG1033.Style=Enum.ButtonStyle.Custom
NG1033.ZIndex=2
NG1033.Font=Enum.Font.Legacy NG1033.FontSize=Enum.FontSize.Size8
NG1033.Text=dCD([=[]=])NG1033.Parent=NG1032 NG1034=Instance.new("ImageLabel")NG1034.Active=false NG1034.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1034.BackgroundTransparency=1
NG1034.BorderSizePixel=0 NG1034.Name=dCD([=[Onpxtebhaq]=])NG1034.Selectable=false
NG1034.Size=UDim2.new(1,0,1,0) NG1034.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1034.Parent=NG1032
NG1035=Instance.new("Frame") NG1035.BackgroundColor3=Color3.new(0,0,1)NG1035.BorderSizePixel=0
NG1035.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1035.Position=UDim2.new(0,3,0, -2)NG1035.Size=UDim2.new(1,-3,0,2) NG1035.Parent=NG1032
NG1036=Instance.new("TextBox") NG1036.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1036.BackgroundTransparency=1
NG1036.BorderSizePixel=0 NG1036.Position=UDim2.new(0,5,0,0)NG1036.Size=UDim2.new(1,-10,1,0) NG1036.Font=Enum.Font.ArialBold
NG1036.FontSize=Enum.FontSize.Size10
NG1036.Text=dCD([=[255]=]) NG1036.TextColor3=Color3.new(1,1,1)NG1036.Parent=NG1032
NG1037=Instance.new("ImageButton") NG1037.BackgroundColor3=Color3.new(0,0,0)NG1037.BackgroundTransparency=0.40000000596046
NG1037.BorderSizePixel=0 NG1037.Name=dCD([=[UFICvpxre]=])NG1037.Position=UDim2.new(0,160,0,-2) NG1037.Size=UDim2.new(0,27,0,27)NG1037.Style=Enum.ButtonStyle.Custom
NG1037.ZIndex=2 NG1037.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141313631]=])NG1037.Parent=NG1020
NG1038=Instance.new("Frame") NG1038.BackgroundColor3=Color3.new(0,0,0)NG1038.BackgroundTransparency=0.75
NG1038.BorderSizePixel=0 NG1038.Name=dCD([=[Funqbj]=])NG1038.Position=UDim2.new(0,0,1,-2) NG1038.Size=UDim2.new(1,0,0,2)NG1038.Parent=NG1037
NG1039=Instance.new("Frame") NG1039.BackgroundColor3=Color3.new(0,0,0)NG1039.BackgroundTransparency=0.5 NG1039.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1039.BorderSizePixel=0
NG1039.Name=dCD([=[Frcnengbe]=]) NG1039.Position=UDim2.new(0,151,0,4)NG1039.Size=UDim2.new(0,4,0,4)NG1039.Parent=NG1020 NG1040=Instance.new("Frame")NG1040.BackgroundColor3=Color3.new(0,0,0) NG1040.BackgroundTransparency=0.5 NG1040.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1040.BorderSizePixel=0
NG1040.Name=dCD([=[Frcnengbe]=]) NG1040.Position=UDim2.new(0,151,0,16)NG1040.Size=UDim2.new(0,4,0,4)NG1040.Parent=NG1020 NG1041=Instance.new("Frame")NG1041.BackgroundColor3=Color3.new(0,0,0) NG1041.BackgroundTransparency=0.5 NG1041.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1041.BorderSizePixel=0
NG1041.Name=dCD([=[Frcnengbe]=]) NG1041.Position=UDim2.new(0,151,0,10)NG1041.Size=UDim2.new(0,4,0,4)NG1041.Parent=NG1020 NG1042=Instance.new("Frame")NG1042.Active=true NG1042.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1042.BackgroundTransparency=1
NG1042.BorderSizePixel=0 NG1042.Name=dCD([=[OGNapubeGbbyTHV]=])NG1042.Position=UDim2.new(0,0,0,280) NG1042.Size=UDim2.new(0,245,0,90)NG1042.Draggable=true
NG1042.Parent=NG1 NG1043=Instance.new("Frame") NG1043.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1043.BackgroundTransparency=1
NG1043.BorderSizePixel=0 NG1043.Name=dCD([=[Gvgyr]=])NG1043.Size=UDim2.new(1,0,0,20)NG1043.Parent=NG1042 NG1044=Instance.new("Frame") NG1044.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG1044.BorderSizePixel=0
NG1044.Name=dCD([=[PbybeOne]=])NG1044.Position=UDim2.new(0,5,0, -3)NG1044.Size=UDim2.new(1,-5,0,2) NG1044.Parent=NG1043
NG1045=Instance.new("TextLabel") NG1045.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1045.BackgroundTransparency=1
NG1045.BorderSizePixel=0 NG1045.Name=dCD([=[Ynory]=])NG1045.Position=UDim2.new(0,10,0,1) NG1045.Size=UDim2.new(1,-10,1,0)NG1045.Font=Enum.Font.ArialBold NG1045.FontSize=Enum.FontSize.Size10
NG1045.Text=dCD([=[NAPUBE GBBY]=]) NG1045.TextColor3=Color3.new(1,1,1)NG1045.TextStrokeTransparency=0
NG1045.TextWrapped=true NG1045.TextXAlignment=Enum.TextXAlignment.Left
NG1045.Parent=NG1043
NG1046=Instance.new("TextLabel") NG1046.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1046.BackgroundTransparency=1
NG1046.BorderSizePixel=0 NG1046.Name=dCD([=[S3KFvtangher]=])NG1046.Position=UDim2.new(0,10,0,1) NG1046.Size=UDim2.new(1,-10,1,0)NG1046.Font=Enum.Font.ArialBold NG1046.FontSize=Enum.FontSize.Size14
NG1046.Text=dCD([=[S3K]=])NG1046.TextColor3=Color3.new(1,1,1) NG1046.TextStrokeTransparency=0.89999997615814
NG1046.TextWrapped=true NG1046.TextXAlignment=Enum.TextXAlignment.Right
NG1046.Parent=NG1043
NG1047=Instance.new("Frame") NG1047.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1047.BackgroundTransparency=1
NG1047.BorderSizePixel=0 NG1047.Name=dCD([=[Fgnghf]=])NG1047.Position=UDim2.new(0,0,0,30) NG1047.Size=UDim2.new(0,0,0,0)NG1047.Parent=NG1042
NG1048=Instance.new("TextLabel") NG1048.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1048.BackgroundTransparency=1
NG1048.BorderSizePixel=0 NG1048.Name=dCD([=[Ynory]=])NG1048.Position=UDim2.new(0,14,0,0) NG1048.Size=UDim2.new(0,40,0,25)NG1048.Font=Enum.Font.ArialBold NG1048.FontSize=Enum.FontSize.Size10
NG1048.Text=dCD([=[Fgnghf]=]) NG1048.TextColor3=Color3.new(1,1,1)NG1048.TextStrokeTransparency=0
NG1048.TextWrapped=true NG1048.TextXAlignment=Enum.TextXAlignment.Left
NG1048.Parent=NG1047
NG1049=Instance.new("Frame") NG1049.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1049.BackgroundTransparency=1
NG1049.BorderSizePixel=0 NG1049.Name=dCD([=[Napuberq]=])NG1049.Position=UDim2.new(0,55,0,0) NG1049.Size=UDim2.new(0,90,0,25)NG1049.Parent=NG1047
NG1050=Instance.new("Frame") NG1050.BackgroundTransparency=1
NG1050.BorderSizePixel=0
NG1050.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1050.Position=UDim2.new(0,9,0, -2)NG1050.Size=UDim2.new(1,-9,0,2) NG1050.Parent=NG1049
NG1051=Instance.new("TextButton")NG1051.Active=true NG1051.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1051.BackgroundTransparency=1
NG1051.BorderSizePixel=0 NG1051.Name=dCD([=[Ohggba]=])NG1051.Position=UDim2.new(0,5,0,0)NG1051.Selectable=true
NG1051.Size=UDim2.new(1, -10,1,0) NG1051.Style=Enum.ButtonStyle.Custom
NG1051.ZIndex=2
NG1051.Font=Enum.Font.Legacy NG1051.FontSize=Enum.FontSize.Size8
NG1051.Text=dCD([=[]=])NG1051.TextTransparency=1
NG1051.Parent=NG1049 NG1052=Instance.new("ImageLabel")NG1052.Active=false NG1052.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1052.BackgroundTransparency=1
NG1052.BorderSizePixel=0 NG1052.Name=dCD([=[Onpxtebhaq]=])NG1052.Selectable=false
NG1052.Size=UDim2.new(1,0,1,0) NG1052.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1052.Parent=NG1049
NG1053=Instance.new("TextLabel") NG1053.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1053.BackgroundTransparency=1
NG1053.BorderSizePixel=0 NG1053.Name=dCD([=[Ynory]=])NG1053.Size=UDim2.new(1,0,1,0) NG1053.Font=Enum.Font.ArialBold
NG1053.FontSize=Enum.FontSize.Size10 NG1053.Text=dCD([=[NAPUBERQ]=])NG1053.TextColor3=Color3.new(1,1,1)NG1053.Parent=NG1049 NG1054=Instance.new("Frame") NG1054.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1054.BackgroundTransparency=1
NG1054.BorderSizePixel=0 NG1054.Name=dCD([=[Hanapuberq]=])NG1054.Position=UDim2.new(0,140,0,0) NG1054.Size=UDim2.new(0,90,0,25)NG1054.Parent=NG1047
NG1055=Instance.new("Frame") NG1055.BackgroundTransparency=1
NG1055.BorderSizePixel=0
NG1055.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1055.Position=UDim2.new(0,9,0, -2)NG1055.Size=UDim2.new(1,-9,0,2) NG1055.Parent=NG1054
NG1056=Instance.new("TextButton")NG1056.Active=true NG1056.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1056.BackgroundTransparency=1
NG1056.BorderSizePixel=0 NG1056.Name=dCD([=[Ohggba]=])NG1056.Position=UDim2.new(0,5,0,0)NG1056.Selectable=true
NG1056.Size=UDim2.new(1, -10,1,0) NG1056.Style=Enum.ButtonStyle.Custom
NG1056.ZIndex=2
NG1056.Font=Enum.Font.ArialBold NG1056.FontSize=Enum.FontSize.Size8
NG1056.Text=dCD([=[]=])NG1056.TextTransparency=1
NG1056.Parent=NG1054 NG1057=Instance.new("ImageLabel")NG1057.Active=false NG1057.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1057.BackgroundTransparency=1
NG1057.BorderSizePixel=0 NG1057.Name=dCD([=[Onpxtebhaq]=])NG1057.Selectable=false
NG1057.Size=UDim2.new(1,0,1,0) NG1057.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1057.Parent=NG1054
NG1058=Instance.new("TextLabel") NG1058.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1058.BackgroundTransparency=1
NG1058.BorderSizePixel=0 NG1058.Name=dCD([=[Ynory]=])NG1058.Size=UDim2.new(1,0,1,0) NG1058.Font=Enum.Font.ArialBold
NG1058.FontSize=Enum.FontSize.Size10 NG1058.Text=dCD([=[HANAPUBERQ]=])NG1058.TextColor3=Color3.new(1,1,1)NG1058.Parent=NG1054 NG1059=Instance.new("Frame") NG1059.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1059.BackgroundTransparency=1
NG1059.BorderSizePixel=0 NG1059.Name=dCD([=[Gvc]=])NG1059.Position=UDim2.new(0,5,0,70) NG1059.Size=UDim2.new(1,-5,0,20)NG1059.Parent=NG1042
NG1060=Instance.new("Frame") NG1060.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG1060.BorderSizePixel=0
NG1060.Name=dCD([=[PbybeOne]=]) NG1060.Size=UDim2.new(1,0,0,2)NG1060.Parent=NG1059
NG1061=Instance.new("TextLabel") NG1061.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1061.BackgroundTransparency=1
NG1061.BorderSizePixel=0 NG1061.Name=dCD([=[Grkg]=])NG1061.Position=UDim2.new(0,0,0,2) NG1061.Size=UDim2.new(1,0,0,20)NG1061.Font=Enum.Font.ArialBold NG1061.FontSize=Enum.FontSize.Size10
NG1061.Text=dCD([=[GVC: Cerff Ragre gb dhvpxyl gbttyr gur napube.]=]) NG1061.TextColor3=Color3.new(1,1,1)NG1061.TextStrokeTransparency=0.5
NG1061.TextWrapped=true NG1061.Parent=NG1059
NG1062=Instance.new("Frame")NG1062.Active=true NG1062.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1062.BackgroundTransparency=1
NG1062.BorderSizePixel=0 NG1062.Name=dCD([=[OGPbyyvfvbaGbbyTHV]=])NG1062.Position=UDim2.new(0,0,0,280) NG1062.Size=UDim2.new(0,200,0,90)NG1062.Draggable=true
NG1062.Parent=NG1 NG1063=Instance.new("Frame") NG1063.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1063.BackgroundTransparency=1
NG1063.BorderSizePixel=0 NG1063.Name=dCD([=[Gvgyr]=])NG1063.Size=UDim2.new(1,0,0,20)NG1063.Parent=NG1062 NG1064=Instance.new("Frame") NG1064.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG1064.BorderSizePixel=0
NG1064.Name=dCD([=[PbybeOne]=])NG1064.Position=UDim2.new(0,5,0, -3)NG1064.Size=UDim2.new(1,-5,0,2) NG1064.Parent=NG1063
NG1065=Instance.new("TextLabel") NG1065.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1065.BackgroundTransparency=1
NG1065.BorderSizePixel=0 NG1065.Name=dCD([=[Ynory]=])NG1065.Position=UDim2.new(0,10,0,1) NG1065.Size=UDim2.new(1,-10,1,0)NG1065.Font=Enum.Font.ArialBold NG1065.FontSize=Enum.FontSize.Size10
NG1065.Text=dCD([=[PBYYVFVBA GBBY]=]) NG1065.TextColor3=Color3.new(1,1,1)NG1065.TextStrokeTransparency=0
NG1065.TextWrapped=true NG1065.TextXAlignment=Enum.TextXAlignment.Left
NG1065.Parent=NG1063
NG1066=Instance.new("TextLabel") NG1066.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1066.BackgroundTransparency=1
NG1066.BorderSizePixel=0 NG1066.Name=dCD([=[S3KFvtangher]=])NG1066.Position=UDim2.new(0,10,0,1) NG1066.Size=UDim2.new(1,-10,1,0)NG1066.Font=Enum.Font.ArialBold NG1066.FontSize=Enum.FontSize.Size14
NG1066.Text=dCD([=[S3K]=])NG1066.TextColor3=Color3.new(1,1,1) NG1066.TextStrokeTransparency=0.89999997615814
NG1066.TextWrapped=true NG1066.TextXAlignment=Enum.TextXAlignment.Right
NG1066.Parent=NG1063
NG1067=Instance.new("Frame") NG1067.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1067.BackgroundTransparency=1
NG1067.BorderSizePixel=0 NG1067.Name=dCD([=[Fgnghf]=])NG1067.Position=UDim2.new(0,0,0,30) NG1067.Size=UDim2.new(0,0,0,0)NG1067.Parent=NG1062
NG1068=Instance.new("TextLabel") NG1068.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1068.BackgroundTransparency=1
NG1068.BorderSizePixel=0 NG1068.Name=dCD([=[Ynory]=])NG1068.Position=UDim2.new(0,14,0,0) NG1068.Size=UDim2.new(0,50,0,25)NG1068.Font=Enum.Font.ArialBold NG1068.FontSize=Enum.FontSize.Size10
NG1068.Text=dCD([=[Pbyyvfvba]=]) NG1068.TextColor3=Color3.new(1,1,1)NG1068.TextStrokeTransparency=0
NG1068.TextWrapped=true NG1068.TextXAlignment=Enum.TextXAlignment.Left
NG1068.Parent=NG1067
NG1069=Instance.new("Frame") NG1069.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1069.BackgroundTransparency=1
NG1069.BorderSizePixel=0 NG1069.Name=dCD([=[Ba]=])NG1069.Position=UDim2.new(0,70,0,0) NG1069.Size=UDim2.new(0,50,0,25)NG1069.Parent=NG1067
NG1070=Instance.new("Frame") NG1070.BackgroundTransparency=1
NG1070.BorderSizePixel=0
NG1070.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1070.Position=UDim2.new(0,5,0, -2)NG1070.Size=UDim2.new(1,-5,0,2) NG1070.Parent=NG1069
NG1071=Instance.new("TextButton")NG1071.Active=true NG1071.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1071.BackgroundTransparency=1
NG1071.BorderSizePixel=0 NG1071.Name=dCD([=[Ohggba]=])NG1071.Position=UDim2.new(0,5,0,0)NG1071.Selectable=true
NG1071.Size=UDim2.new(1, -10,1,0) NG1071.Style=Enum.ButtonStyle.Custom
NG1071.ZIndex=2
NG1071.Font=Enum.Font.Legacy NG1071.FontSize=Enum.FontSize.Size8
NG1071.Text=dCD([=[]=])NG1071.TextTransparency=1
NG1071.Parent=NG1069 NG1072=Instance.new("ImageLabel")NG1072.Active=false NG1072.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1072.BackgroundTransparency=1
NG1072.BorderSizePixel=0 NG1072.Name=dCD([=[Onpxtebhaq]=])NG1072.Selectable=false
NG1072.Size=UDim2.new(1,0,1,0) NG1072.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1072.Parent=NG1069
NG1073=Instance.new("TextLabel") NG1073.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1073.BackgroundTransparency=1
NG1073.BorderSizePixel=0 NG1073.Name=dCD([=[Ynory]=])NG1073.Size=UDim2.new(1,0,1,0) NG1073.Font=Enum.Font.ArialBold
NG1073.FontSize=Enum.FontSize.Size10
NG1073.Text=dCD([=[BA]=]) NG1073.TextColor3=Color3.new(1,1,1)NG1073.Parent=NG1069
NG1074=Instance.new("Frame") NG1074.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1074.BackgroundTransparency=1
NG1074.BorderSizePixel=0 NG1074.Name=dCD([=[Bss]=])NG1074.Position=UDim2.new(0,118,0,0) NG1074.Size=UDim2.new(0,50,0,25)NG1074.Parent=NG1067
NG1075=Instance.new("Frame") NG1075.BackgroundTransparency=1
NG1075.BorderSizePixel=0
NG1075.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1075.Position=UDim2.new(0,5,0, -2)NG1075.Size=UDim2.new(1,-5,0,2) NG1075.Parent=NG1074
NG1076=Instance.new("TextButton")NG1076.Active=true NG1076.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1076.BackgroundTransparency=1
NG1076.BorderSizePixel=0 NG1076.Name=dCD([=[Ohggba]=])NG1076.Position=UDim2.new(0,5,0,0)NG1076.Selectable=true
NG1076.Size=UDim2.new(1, -10,1,0) NG1076.Style=Enum.ButtonStyle.Custom
NG1076.ZIndex=2
NG1076.Font=Enum.Font.Legacy NG1076.FontSize=Enum.FontSize.Size8
NG1076.Text=dCD([=[]=])NG1076.TextTransparency=1
NG1076.Parent=NG1074 NG1077=Instance.new("ImageLabel")NG1077.Active=false NG1077.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1077.BackgroundTransparency=1
NG1077.BorderSizePixel=0 NG1077.Name=dCD([=[Onpxtebhaq]=])NG1077.Selectable=false
NG1077.Size=UDim2.new(1,0,1,0) NG1077.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1077.Parent=NG1074
NG1078=Instance.new("TextLabel") NG1078.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1078.BackgroundTransparency=1
NG1078.BorderSizePixel=0 NG1078.Name=dCD([=[Ynory]=])NG1078.Size=UDim2.new(1,0,1,0) NG1078.Font=Enum.Font.ArialBold
NG1078.FontSize=Enum.FontSize.Size10
NG1078.Text=dCD([=[BSS]=]) NG1078.TextColor3=Color3.new(1,1,1)NG1078.Parent=NG1074
NG1079=Instance.new("Frame") NG1079.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1079.BackgroundTransparency=1
NG1079.BorderSizePixel=0 NG1079.Name=dCD([=[Gvc]=])NG1079.Position=UDim2.new(0,5,0,70) NG1079.Size=UDim2.new(1,-5,0,20)NG1079.Parent=NG1062
NG1080=Instance.new("Frame") NG1080.BackgroundColor3=Color3.new(0.0666667,0.0666667,0.0666667)NG1080.BorderSizePixel=0
NG1080.Name=dCD([=[PbybeOne]=]) NG1080.Size=UDim2.new(1,0,0,2)NG1080.Parent=NG1079
NG1081=Instance.new("TextLabel") NG1081.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1081.BackgroundTransparency=1
NG1081.BorderSizePixel=0 NG1081.Name=dCD([=[Grkg]=])NG1081.Position=UDim2.new(0,0,0,2) NG1081.Size=UDim2.new(1,0,0,20)NG1081.Font=Enum.Font.ArialBold NG1081.FontSize=Enum.FontSize.Size10
NG1081.Text=dCD([=[GVC: Cerff Ragre gb gbttyr pbyyvfvba.]=]) NG1081.TextColor3=Color3.new(1,1,1)NG1081.TextStrokeTransparency=0.5
NG1081.TextWrapped=true NG1081.Parent=NG1079
NG1082=Instance.new("Frame")NG1082.Active=true NG1082.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1082.BackgroundTransparency=1
NG1082.BorderSizePixel=0 NG1082.Name=dCD([=[OGQrpbengrGbbyTHV]=])NG1082.Position=UDim2.new(0,0,0,172) NG1082.Size=UDim2.new(0,200,0,125)NG1082.Draggable=true
NG1082.Parent=NG1 NG1083=Instance.new("Frame")NG1083.BackgroundColor3=Color3.new(0,0,0) NG1083.BorderSizePixel=0
NG1083.Name=dCD([=[ObggbzPbybeOne]=]) NG1083.Position=UDim2.new(0,5,1,-2)NG1083.Size=UDim2.new(1,0,0,2)NG1083.Parent=NG1082 NG1084=Instance.new("Frame") NG1084.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1084.BackgroundTransparency=1
NG1084.BorderSizePixel=0 NG1084.Name=dCD([=[Gvgyr]=])NG1084.Size=UDim2.new(1,0,0,20)NG1084.Parent=NG1082 NG1085=Instance.new("Frame")NG1085.BackgroundColor3=Color3.new(0,0,0) NG1085.BorderSizePixel=0
NG1085.Name=dCD([=[PbybeOne]=]) NG1085.Position=UDim2.new(0,5,0,-3)NG1085.Size=UDim2.new(1,-5,0,2)NG1085.Parent=NG1084 NG1086=Instance.new("TextLabel") NG1086.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1086.BackgroundTransparency=1
NG1086.BorderSizePixel=0 NG1086.Name=dCD([=[Ynory]=])NG1086.Position=UDim2.new(0,10,0,1) NG1086.Size=UDim2.new(1,-10,1,0)NG1086.Font=Enum.Font.ArialBold NG1086.FontSize=Enum.FontSize.Size10
NG1086.Text=dCD([=[QRPBENGR GBBY]=]) NG1086.TextColor3=Color3.new(1,1,1)NG1086.TextStrokeTransparency=0
NG1086.TextWrapped=true NG1086.TextXAlignment=Enum.TextXAlignment.Left
NG1086.Parent=NG1084
NG1087=Instance.new("TextLabel") NG1087.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1087.BackgroundTransparency=1
NG1087.BorderSizePixel=0 NG1087.Name=dCD([=[S3KFvtangher]=])NG1087.Position=UDim2.new(0,10,0,1) NG1087.Size=UDim2.new(1,-10,1,0)NG1087.Font=Enum.Font.ArialBold NG1087.FontSize=Enum.FontSize.Size14
NG1087.Text=dCD([=[S3K]=])NG1087.TextColor3=Color3.new(1,1,1) NG1087.TextStrokeTransparency=0.89999997615814
NG1087.TextWrapped=true NG1087.TextXAlignment=Enum.TextXAlignment.Right
NG1087.Parent=NG1084
NG1088=Instance.new("Frame") NG1088.BackgroundColor3=Color3.new(0,0,0)NG1088.BackgroundTransparency=0.67500001192093
NG1088.BorderSizePixel=0 NG1088.Name=dCD([=[Fzbxr]=])NG1088.Position=UDim2.new(0,10,0,30) NG1088.Size=UDim2.new(1,-10,0,25)NG1088.Parent=NG1082
NG1089=Instance.new("TextLabel") NG1089.BackgroundTransparency=1
NG1089.BorderSizePixel=0
NG1089.Name=dCD([=[Ynory]=]) NG1089.Position=UDim2.new(0,35,0,0)NG1089.Size=UDim2.new(0,60,0,25) NG1089.Font=Enum.Font.ArialBold
NG1089.FontSize=Enum.FontSize.Size10
NG1089.Text=dCD([=[Fzbxr]=]) NG1089.TextColor3=Color3.new(1,1,1)NG1089.TextStrokeTransparency=0.5
NG1089.TextWrapped=true NG1089.TextXAlignment=Enum.TextXAlignment.Left
NG1089.Parent=NG1088
NG1090=Instance.new("ImageButton") NG1090.BackgroundTransparency=1
NG1090.BorderSizePixel=0
NG1090.Name=dCD([=[NeebjOhggba]=]) NG1090.Position=UDim2.new(0,10,0,3)NG1090.Size=UDim2.new(0,20,0,20) NG1090.Style=Enum.ButtonStyle.Custom
NG1090.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=134367382]=]) NG1090.Parent=NG1088
NG1091=Instance.new("Frame") NG1091.BackgroundColor3=Color3.new(1,0.682353,0.235294)NG1091.BorderSizePixel=0
NG1091.Name=dCD([=[PbybeOne]=]) NG1091.Size=UDim2.new(0,3,1,0)NG1091.Parent=NG1088
NG1092=Instance.new("TextButton") NG1092.Active=true
NG1092.BackgroundColor3=Color3.new(0,0,0) NG1092.BackgroundTransparency=0.75
NG1092.BorderColor3=Color3.new(0,0,0) NG1092.BorderSizePixel=0
NG1092.Name=dCD([=[NqqOhggba]=]) NG1092.Position=UDim2.new(1,-40,0,3)NG1092.Selectable=true
NG1092.Size=UDim2.new(0,35,0,19) NG1092.Style=Enum.ButtonStyle.Custom
NG1092.Font=Enum.Font.ArialBold NG1092.FontSize=Enum.FontSize.Size10
NG1092.Text=dCD([=[NQQ]=])NG1092.TextColor3=Color3.new(1,1,1) NG1092.Parent=NG1088
NG1093=Instance.new("TextButton")NG1093.Active=true NG1093.BackgroundColor3=Color3.new(0,0,0)NG1093.BackgroundTransparency=0.75 NG1093.BorderColor3=Color3.new(0,0,0)NG1093.BorderSizePixel=0
NG1093.Name=dCD([=[ErzbirOhggba]=]) NG1093.Position=UDim2.new(0,127,0,3)NG1093.Selectable=true
NG1093.Size=UDim2.new(0,58,0,19) NG1093.Style=Enum.ButtonStyle.Custom
NG1093.Visible=false
NG1093.Font=Enum.Font.ArialBold NG1093.FontSize=Enum.FontSize.Size10
NG1093.Text=dCD([=[ERZBIR]=]) NG1093.TextColor3=Color3.new(1,1,1)NG1093.Parent=NG1088
NG1094=Instance.new("Frame") NG1094.BackgroundColor3=Color3.new(0,0,0)NG1094.BackgroundTransparency=0.75
NG1094.BorderSizePixel=0 NG1094.Name=dCD([=[Funqbj]=])NG1094.Position=UDim2.new(0,0,1,-1) NG1094.Size=UDim2.new(1,0,0,1)NG1094.Parent=NG1088
NG1095=Instance.new("Frame") NG1095.BackgroundTransparency=1
NG1095.BorderSizePixel=0
NG1095.Name=dCD([=[Bcgvbaf]=]) NG1095.Position=UDim2.new(0,3,1,0)NG1095.Size=UDim2.new(1,-3,0,0)NG1095.ClipsDescendants=true NG1095.Parent=NG1088
NG1096=Instance.new("Frame") NG1096.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1096.BackgroundTransparency=1
NG1096.BorderSizePixel=0 NG1096.Name=dCD([=[PbybeBcgvba]=])NG1096.Position=UDim2.new(0,0,0,10) NG1096.Size=UDim2.new(1,0,0,25)NG1096.Parent=NG1095
NG1097=Instance.new("TextLabel") NG1097.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1097.BackgroundTransparency=1
NG1097.BorderSizePixel=0 NG1097.Name=dCD([=[Ynory]=])NG1097.Size=UDim2.new(0,70,0,25) NG1097.Font=Enum.Font.ArialBold
NG1097.FontSize=Enum.FontSize.Size10
NG1097.Text=dCD([=[Pbybe]=]) NG1097.TextColor3=Color3.new(1,1,1)NG1097.TextStrokeTransparency=0
NG1097.TextWrapped=true NG1097.TextXAlignment=Enum.TextXAlignment.Left
NG1097.Parent=NG1096
NG1098=Instance.new("Frame") NG1098.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1098.BackgroundTransparency=1
NG1098.BorderSizePixel=0 NG1098.Name=dCD([=[EVachg]=])NG1098.Position=UDim2.new(0,35,0,0) NG1098.Size=UDim2.new(0,38,0,25)NG1098.Parent=NG1096
NG1099=Instance.new("TextButton") NG1099.Active=true
NG1099.AutoButtonColor=false NG1099.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1099.BackgroundTransparency=1
NG1099.BorderSizePixel=0 NG1099.Selectable=true
NG1099.Size=UDim2.new(1,0,1,0) NG1099.Style=Enum.ButtonStyle.Custom
NG1099.ZIndex=2
NG1099.Font=Enum.Font.Legacy NG1099.FontSize=Enum.FontSize.Size8
NG1099.Text=dCD([=[]=])NG1099.Parent=NG1098 NG1100=Instance.new("ImageLabel")NG1100.Active=false NG1100.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1100.BackgroundTransparency=1
NG1100.BorderSizePixel=0 NG1100.Name=dCD([=[Onpxtebhaq]=])NG1100.Selectable=false
NG1100.Size=UDim2.new(1,0,1,0) NG1100.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1100.Parent=NG1098
NG1101=Instance.new("Frame") NG1101.BackgroundColor3=Color3.new(1,0,0)NG1101.BorderSizePixel=0
NG1101.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1101.Position=UDim2.new(0,3,0, -2)NG1101.Size=UDim2.new(1,-3,0,2) NG1101.Parent=NG1098
NG1102=Instance.new("TextBox") NG1102.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1102.BackgroundTransparency=1
NG1102.BorderSizePixel=0 NG1102.Position=UDim2.new(0,5,0,0)NG1102.Size=UDim2.new(1,-10,1,0) NG1102.Font=Enum.Font.ArialBold
NG1102.FontSize=Enum.FontSize.Size10
NG1102.Text=dCD([=[255]=]) NG1102.TextColor3=Color3.new(1,1,1)NG1102.Parent=NG1098
NG1103=Instance.new("Frame") NG1103.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1103.BackgroundTransparency=1
NG1103.BorderSizePixel=0 NG1103.Name=dCD([=[TVachg]=])NG1103.Position=UDim2.new(0,72,0,0) NG1103.Size=UDim2.new(0,38,0,25)NG1103.Parent=NG1096
NG1104=Instance.new("TextButton") NG1104.Active=true
NG1104.AutoButtonColor=false NG1104.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1104.BackgroundTransparency=1
NG1104.BorderSizePixel=0 NG1104.Selectable=true
NG1104.Size=UDim2.new(1,0,1,0) NG1104.Style=Enum.ButtonStyle.Custom
NG1104.ZIndex=2
NG1104.Font=Enum.Font.Legacy NG1104.FontSize=Enum.FontSize.Size8
NG1104.Text=dCD([=[]=])NG1104.Parent=NG1103 NG1105=Instance.new("ImageLabel")NG1105.Active=false NG1105.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1105.BackgroundTransparency=1
NG1105.BorderSizePixel=0 NG1105.Name=dCD([=[Onpxtebhaq]=])NG1105.Selectable=false
NG1105.Size=UDim2.new(1,0,1,0) NG1105.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1105.Parent=NG1103
NG1106=Instance.new("Frame") NG1106.BackgroundColor3=Color3.new(0,1,0)NG1106.BorderSizePixel=0
NG1106.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1106.Position=UDim2.new(0,3,0, -2)NG1106.Size=UDim2.new(1,-3,0,2) NG1106.Parent=NG1103
NG1107=Instance.new("TextBox") NG1107.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1107.BackgroundTransparency=1
NG1107.BorderSizePixel=0 NG1107.Position=UDim2.new(0,5,0,0)NG1107.Size=UDim2.new(1,-10,1,0) NG1107.Font=Enum.Font.ArialBold
NG1107.FontSize=Enum.FontSize.Size10
NG1107.Text=dCD([=[255]=]) NG1107.TextColor3=Color3.new(1,1,1)NG1107.Parent=NG1103
NG1108=Instance.new("Frame") NG1108.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1108.BackgroundTransparency=1
NG1108.BorderSizePixel=0 NG1108.Name=dCD([=[OVachg]=])NG1108.Position=UDim2.new(0,109,0,0) NG1108.Size=UDim2.new(0,38,0,25)NG1108.Parent=NG1096
NG1109=Instance.new("TextButton") NG1109.Active=true
NG1109.AutoButtonColor=false NG1109.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1109.BackgroundTransparency=1
NG1109.BorderSizePixel=0 NG1109.Selectable=true
NG1109.Size=UDim2.new(1,0,1,0) NG1109.Style=Enum.ButtonStyle.Custom
NG1109.ZIndex=2
NG1109.Font=Enum.Font.Legacy NG1109.FontSize=Enum.FontSize.Size8
NG1109.Text=dCD([=[]=])NG1109.Parent=NG1108 NG1110=Instance.new("ImageLabel")NG1110.Active=false NG1110.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1110.BackgroundTransparency=1
NG1110.BorderSizePixel=0 NG1110.Name=dCD([=[Onpxtebhaq]=])NG1110.Selectable=false
NG1110.Size=UDim2.new(1,0,1,0) NG1110.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1110.Parent=NG1108
NG1111=Instance.new("Frame") NG1111.BackgroundColor3=Color3.new(0,0,1)NG1111.BorderSizePixel=0
NG1111.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1111.Position=UDim2.new(0,3,0, -2)NG1111.Size=UDim2.new(1,-3,0,2) NG1111.Parent=NG1108
NG1112=Instance.new("TextBox") NG1112.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1112.BackgroundTransparency=1
NG1112.BorderSizePixel=0 NG1112.Position=UDim2.new(0,5,0,0)NG1112.Size=UDim2.new(1,-10,1,0) NG1112.Font=Enum.Font.ArialBold
NG1112.FontSize=Enum.FontSize.Size10
NG1112.Text=dCD([=[255]=]) NG1112.TextColor3=Color3.new(1,1,1)NG1112.Parent=NG1108
NG1113=Instance.new("ImageButton") NG1113.BackgroundColor3=Color3.new(0,0,0)NG1113.BackgroundTransparency=0.40000000596046
NG1113.BorderSizePixel=0 NG1113.Name=dCD([=[UFICvpxre]=])NG1113.Position=UDim2.new(0,160,0,-2) NG1113.Size=UDim2.new(0,27,0,27)NG1113.Style=Enum.ButtonStyle.Custom NG1113.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141313631]=])NG1113.Parent=NG1096
NG1114=Instance.new("Frame") NG1114.BackgroundColor3=Color3.new(0,0,0)NG1114.BackgroundTransparency=0.75
NG1114.BorderSizePixel=0 NG1114.Name=dCD([=[Funqbj]=])NG1114.Position=UDim2.new(0,0,1,-2) NG1114.Size=UDim2.new(1,0,0,2)NG1114.Parent=NG1113
NG1115=Instance.new("Frame") NG1115.BackgroundColor3=Color3.new(0,0,0)NG1115.BackgroundTransparency=0.5 NG1115.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1115.BorderSizePixel=0
NG1115.Name=dCD([=[Frcnengbe]=]) NG1115.Position=UDim2.new(0,151,0,4)NG1115.Size=UDim2.new(0,4,0,4)NG1115.Parent=NG1096 NG1116=Instance.new("Frame")NG1116.BackgroundColor3=Color3.new(0,0,0) NG1116.BackgroundTransparency=0.5 NG1116.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1116.BorderSizePixel=0
NG1116.Name=dCD([=[Frcnengbe]=]) NG1116.Position=UDim2.new(0,151,0,16)NG1116.Size=UDim2.new(0,4,0,4)NG1116.Parent=NG1096 NG1117=Instance.new("Frame")NG1117.BackgroundColor3=Color3.new(0,0,0) NG1117.BackgroundTransparency=0.5 NG1117.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1117.BorderSizePixel=0
NG1117.Name=dCD([=[Frcnengbe]=]) NG1117.Position=UDim2.new(0,151,0,10)NG1117.Size=UDim2.new(0,4,0,4)NG1117.Parent=NG1096 NG1118=Instance.new("Frame") NG1118.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1118.BackgroundTransparency=1
NG1118.BorderSizePixel=0 NG1118.Name=dCD([=[BcnpvglBcgvba]=])NG1118.Position=UDim2.new(0,0,0,45) NG1118.Size=UDim2.new(1,0,0,25)NG1118.Parent=NG1095
NG1119=Instance.new("TextLabel") NG1119.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1119.BackgroundTransparency=1
NG1119.BorderSizePixel=0 NG1119.Name=dCD([=[Ynory]=])NG1119.Size=UDim2.new(0,70,0,25) NG1119.Font=Enum.Font.ArialBold
NG1119.FontSize=Enum.FontSize.Size10 NG1119.Text=dCD([=[Bcnpvgl]=])NG1119.TextColor3=Color3.new(1,1,1) NG1119.TextStrokeTransparency=0
NG1119.TextWrapped=true NG1119.TextXAlignment=Enum.TextXAlignment.Left
NG1119.Parent=NG1118
NG1120=Instance.new("Frame") NG1120.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1120.BackgroundTransparency=1
NG1120.BorderSizePixel=0 NG1120.Name=dCD([=[Vachg]=])NG1120.Position=UDim2.new(0,45,0,0) NG1120.Size=UDim2.new(0,38,0,25)NG1120.Parent=NG1118
NG1121=Instance.new("TextButton") NG1121.Active=true
NG1121.AutoButtonColor=false NG1121.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1121.BackgroundTransparency=1
NG1121.BorderSizePixel=0 NG1121.Selectable=true
NG1121.Size=UDim2.new(1,0,1,0) NG1121.Style=Enum.ButtonStyle.Custom
NG1121.ZIndex=2
NG1121.Font=Enum.Font.Legacy NG1121.FontSize=Enum.FontSize.Size8
NG1121.Text=dCD([=[]=])NG1121.Parent=NG1120 NG1122=Instance.new("ImageLabel")NG1122.Active=false NG1122.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1122.BackgroundTransparency=1
NG1122.BorderSizePixel=0 NG1122.Name=dCD([=[Onpxtebhaq]=])NG1122.Selectable=false
NG1122.Size=UDim2.new(1,0,1,0) NG1122.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1122.Parent=NG1120
NG1123=Instance.new("Frame") NG1123.BorderSizePixel=0
NG1123.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG1123.Position=UDim2.new(0,3,0,-2)NG1123.Size=UDim2.new(1,-3,0,2)NG1123.Parent=NG1120 NG1124=Instance.new("TextBox") NG1124.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1124.BackgroundTransparency=1
NG1124.BorderSizePixel=0 NG1124.Position=UDim2.new(0,5,0,0)NG1124.Size=UDim2.new(1,-10,1,0) NG1124.Font=Enum.Font.ArialBold
NG1124.FontSize=Enum.FontSize.Size10
NG1124.Text=dCD([=[1]=]) NG1124.TextColor3=Color3.new(1,1,1)NG1124.Parent=NG1120
NG1125=Instance.new("Frame") NG1125.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1125.BackgroundTransparency=1
NG1125.BorderSizePixel=0 NG1125.Name=dCD([=[IrybpvglBcgvba]=])NG1125.Position=UDim2.new(0,100,0,45) NG1125.Size=UDim2.new(1,-115,0,25)NG1125.Parent=NG1095
NG1126=Instance.new("TextLabel") NG1126.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1126.BackgroundTransparency=1
NG1126.BorderSizePixel=0 NG1126.Name=dCD([=[Ynory]=])NG1126.Size=UDim2.new(0,70,0,25) NG1126.Font=Enum.Font.ArialBold
NG1126.FontSize=Enum.FontSize.Size10 NG1126.Text=dCD([=[Irybpvgl]=])NG1126.TextColor3=Color3.new(1,1,1) NG1126.TextStrokeTransparency=0
NG1126.TextWrapped=true NG1126.TextXAlignment=Enum.TextXAlignment.Left
NG1126.Parent=NG1125
NG1127=Instance.new("Frame") NG1127.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1127.BackgroundTransparency=1
NG1127.BorderSizePixel=0 NG1127.Name=dCD([=[Vachg]=])NG1127.Position=UDim2.new(0,45,0,0) NG1127.Size=UDim2.new(0,38,0,25)NG1127.Parent=NG1125
NG1128=Instance.new("TextButton") NG1128.Active=true
NG1128.AutoButtonColor=false NG1128.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1128.BackgroundTransparency=1
NG1128.BorderSizePixel=0 NG1128.Selectable=true
NG1128.Size=UDim2.new(1,0,1,0) NG1128.Style=Enum.ButtonStyle.Custom
NG1128.ZIndex=2
NG1128.Font=Enum.Font.Legacy NG1128.FontSize=Enum.FontSize.Size8
NG1128.Text=dCD([=[]=])NG1128.Parent=NG1127 NG1129=Instance.new("ImageLabel")NG1129.Active=false NG1129.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1129.BackgroundTransparency=1
NG1129.BorderSizePixel=0 NG1129.Name=dCD([=[Onpxtebhaq]=])NG1129.Selectable=false
NG1129.Size=UDim2.new(1,0,1,0) NG1129.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1129.Parent=NG1127
NG1130=Instance.new("Frame") NG1130.BorderSizePixel=0
NG1130.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG1130.Position=UDim2.new(0,3,0,-2)NG1130.Size=UDim2.new(1,-3,0,2)NG1130.Parent=NG1127 NG1131=Instance.new("TextBox") NG1131.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1131.BackgroundTransparency=1
NG1131.BorderSizePixel=0 NG1131.Position=UDim2.new(0,5,0,0)NG1131.Size=UDim2.new(1,-10,1,0) NG1131.Font=Enum.Font.ArialBold
NG1131.FontSize=Enum.FontSize.Size10
NG1131.Text=dCD([=[90]=]) NG1131.TextColor3=Color3.new(1,1,1)NG1131.Parent=NG1127
NG1132=Instance.new("Frame") NG1132.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1132.BackgroundTransparency=1
NG1132.BorderSizePixel=0 NG1132.Name=dCD([=[FvmrBcgvba]=])NG1132.Position=UDim2.new(0,0,0,80) NG1132.Size=UDim2.new(1,0,0,25)NG1132.Parent=NG1095
NG1133=Instance.new("TextLabel") NG1133.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1133.BackgroundTransparency=1
NG1133.BorderSizePixel=0 NG1133.Name=dCD([=[Ynory]=])NG1133.Size=UDim2.new(0,70,0,25) NG1133.Font=Enum.Font.ArialBold
NG1133.FontSize=Enum.FontSize.Size10
NG1133.Text=dCD([=[Fvmr]=]) NG1133.TextColor3=Color3.new(1,1,1)NG1133.TextStrokeTransparency=0
NG1133.TextWrapped=true NG1133.TextXAlignment=Enum.TextXAlignment.Left
NG1133.Parent=NG1132
NG1134=Instance.new("Frame") NG1134.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1134.BackgroundTransparency=1
NG1134.BorderSizePixel=0 NG1134.Name=dCD([=[Vachg]=])NG1134.Position=UDim2.new(0,30,0,0) NG1134.Size=UDim2.new(0,38,0,25)NG1134.Parent=NG1132
NG1135=Instance.new("TextButton") NG1135.Active=true
NG1135.AutoButtonColor=false NG1135.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1135.BackgroundTransparency=1
NG1135.BorderSizePixel=0 NG1135.Selectable=true
NG1135.Size=UDim2.new(1,0,1,0) NG1135.Style=Enum.ButtonStyle.Custom
NG1135.ZIndex=2
NG1135.Font=Enum.Font.Legacy NG1135.FontSize=Enum.FontSize.Size8
NG1135.Text=dCD([=[]=])NG1135.Parent=NG1134 NG1136=Instance.new("ImageLabel")NG1136.Active=false NG1136.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1136.BackgroundTransparency=1
NG1136.BorderSizePixel=0 NG1136.Name=dCD([=[Onpxtebhaq]=])NG1136.Selectable=false
NG1136.Size=UDim2.new(1,0,1,0) NG1136.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1136.Parent=NG1134
NG1137=Instance.new("Frame") NG1137.BorderSizePixel=0
NG1137.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG1137.Position=UDim2.new(0,3,0,-2)NG1137.Size=UDim2.new(1,-3,0,2)NG1137.Parent=NG1134 NG1138=Instance.new("TextBox") NG1138.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1138.BackgroundTransparency=1
NG1138.BorderSizePixel=0 NG1138.Position=UDim2.new(0,5,0,0)NG1138.Size=UDim2.new(1,-10,1,0) NG1138.Font=Enum.Font.ArialBold
NG1138.FontSize=Enum.FontSize.Size10
NG1138.Text=dCD([=[16]=]) NG1138.TextColor3=Color3.new(1,1,1)NG1138.Parent=NG1134
NG1139=Instance.new("TextLabel") NG1139.BackgroundTransparency=1
NG1139.BorderSizePixel=0
NG1139.Name=dCD([=[FryrpgAbgr]=]) NG1139.Position=UDim2.new(0,10,0,27)NG1139.Size=UDim2.new(1,-10,0,15)NG1139.Visible=false NG1139.FontSize=Enum.FontSize.Size14
NG1139.Text=dCD([=[Fryrpg fbzrguvat gb hfr guvf gbby.]=]) NG1139.TextColor3=Color3.new(1,1,1)NG1139.TextScaled=true
NG1139.TextStrokeTransparency=0.5 NG1139.TextWrapped=true
NG1139.TextXAlignment=Enum.TextXAlignment.Left NG1139.Parent=NG1082
NG1140=Instance.new("Frame") NG1140.BackgroundColor3=Color3.new(0,0,0)NG1140.BackgroundTransparency=0.67500001192093
NG1140.BorderSizePixel=0 NG1140.Name=dCD([=[Sver]=])NG1140.Position=UDim2.new(0,10,0,60) NG1140.Size=UDim2.new(1,-10,0,25)NG1140.Parent=NG1082
NG1141=Instance.new("TextLabel") NG1141.BackgroundTransparency=1
NG1141.BorderSizePixel=0
NG1141.Name=dCD([=[Ynory]=]) NG1141.Position=UDim2.new(0,35,0,0)NG1141.Size=UDim2.new(0,60,0,25) NG1141.Font=Enum.Font.ArialBold
NG1141.FontSize=Enum.FontSize.Size10
NG1141.Text=dCD([=[Sver]=]) NG1141.TextColor3=Color3.new(1,1,1)NG1141.TextStrokeTransparency=0.5
NG1141.TextWrapped=true NG1141.TextXAlignment=Enum.TextXAlignment.Left
NG1141.Parent=NG1140
NG1142=Instance.new("ImageButton") NG1142.BackgroundTransparency=1
NG1142.BorderSizePixel=0
NG1142.Name=dCD([=[NeebjOhggba]=]) NG1142.Position=UDim2.new(0,10,0,3)NG1142.Size=UDim2.new(0,20,0,20) NG1142.Style=Enum.ButtonStyle.Custom
NG1142.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=134367382]=]) NG1142.Parent=NG1140
NG1143=Instance.new("Frame") NG1143.BackgroundColor3=Color3.new(0.85098,0,1)NG1143.BorderSizePixel=0
NG1143.Name=dCD([=[PbybeOne]=]) NG1143.Size=UDim2.new(0,3,1,0)NG1143.Parent=NG1140
NG1144=Instance.new("TextButton") NG1144.Active=true
NG1144.BackgroundColor3=Color3.new(0,0,0) NG1144.BackgroundTransparency=0.75
NG1144.BorderColor3=Color3.new(0,0,0) NG1144.BorderSizePixel=0
NG1144.Name=dCD([=[NqqOhggba]=]) NG1144.Position=UDim2.new(1,-40,0,3)NG1144.Selectable=true
NG1144.Size=UDim2.new(0,35,0,19) NG1144.Style=Enum.ButtonStyle.Custom
NG1144.Font=Enum.Font.ArialBold NG1144.FontSize=Enum.FontSize.Size10
NG1144.Text=dCD([=[NQQ]=])NG1144.TextColor3=Color3.new(1,1,1) NG1144.Parent=NG1140
NG1145=Instance.new("TextButton")NG1145.Active=true NG1145.BackgroundColor3=Color3.new(0,0,0)NG1145.BackgroundTransparency=0.75 NG1145.BorderColor3=Color3.new(0,0,0)NG1145.BorderSizePixel=0
NG1145.Name=dCD([=[ErzbirOhggba]=]) NG1145.Position=UDim2.new(0,90,0,3)NG1145.Selectable=true
NG1145.Size=UDim2.new(0,58,0,19) NG1145.Style=Enum.ButtonStyle.Custom
NG1145.Visible=false
NG1145.Font=Enum.Font.ArialBold NG1145.FontSize=Enum.FontSize.Size10
NG1145.Text=dCD([=[ERZBIR]=]) NG1145.TextColor3=Color3.new(1,1,1)NG1145.Parent=NG1140
NG1146=Instance.new("Frame") NG1146.BackgroundColor3=Color3.new(0,0,0)NG1146.BackgroundTransparency=0.75
NG1146.BorderSizePixel=0 NG1146.Name=dCD([=[Funqbj]=])NG1146.Position=UDim2.new(0,0,1,-1) NG1146.Size=UDim2.new(1,0,0,1)NG1146.Parent=NG1140
NG1147=Instance.new("Frame") NG1147.BackgroundTransparency=1
NG1147.BorderSizePixel=0
NG1147.Name=dCD([=[Bcgvbaf]=]) NG1147.Position=UDim2.new(0,3,1,0)NG1147.Size=UDim2.new(1,-3,0,0)NG1147.ClipsDescendants=true NG1147.Parent=NG1140
NG1148=Instance.new("Frame") NG1148.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1148.BackgroundTransparency=1
NG1148.BorderSizePixel=0 NG1148.Name=dCD([=[PbybeBcgvba]=])NG1148.Position=UDim2.new(0,0,0,10) NG1148.Size=UDim2.new(1,0,0,25)NG1148.Parent=NG1147
NG1149=Instance.new("TextLabel") NG1149.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1149.BackgroundTransparency=1
NG1149.BorderSizePixel=0 NG1149.Name=dCD([=[Ynory]=])NG1149.Size=UDim2.new(0,70,0,25) NG1149.Font=Enum.Font.ArialBold
NG1149.FontSize=Enum.FontSize.Size10
NG1149.Text=dCD([=[Pbybe]=]) NG1149.TextColor3=Color3.new(1,1,1)NG1149.TextStrokeTransparency=0
NG1149.TextWrapped=true NG1149.TextXAlignment=Enum.TextXAlignment.Left
NG1149.Parent=NG1148
NG1150=Instance.new("Frame") NG1150.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1150.BackgroundTransparency=1
NG1150.BorderSizePixel=0 NG1150.Name=dCD([=[EVachg]=])NG1150.Position=UDim2.new(0,35,0,0) NG1150.Size=UDim2.new(0,38,0,25)NG1150.Parent=NG1148
NG1151=Instance.new("TextButton") NG1151.Active=true
NG1151.AutoButtonColor=false NG1151.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1151.BackgroundTransparency=1
NG1151.BorderSizePixel=0 NG1151.Selectable=true
NG1151.Size=UDim2.new(1,0,1,0) NG1151.Style=Enum.ButtonStyle.Custom
NG1151.ZIndex=2
NG1151.Font=Enum.Font.Legacy NG1151.FontSize=Enum.FontSize.Size8
NG1151.Text=dCD([=[]=])NG1151.Parent=NG1150 NG1152=Instance.new("ImageLabel")NG1152.Active=false NG1152.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1152.BackgroundTransparency=1
NG1152.BorderSizePixel=0 NG1152.Name=dCD([=[Onpxtebhaq]=])NG1152.Selectable=false
NG1152.Size=UDim2.new(1,0,1,0) NG1152.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1152.Parent=NG1150
NG1153=Instance.new("Frame") NG1153.BackgroundColor3=Color3.new(1,0,0)NG1153.BorderSizePixel=0
NG1153.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1153.Position=UDim2.new(0,3,0, -2)NG1153.Size=UDim2.new(1,-3,0,2) NG1153.Parent=NG1150
NG1154=Instance.new("TextBox") NG1154.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1154.BackgroundTransparency=1
NG1154.BorderSizePixel=0 NG1154.Position=UDim2.new(0,5,0,0)NG1154.Size=UDim2.new(1,-10,1,0) NG1154.Font=Enum.Font.ArialBold
NG1154.FontSize=Enum.FontSize.Size10
NG1154.Text=dCD([=[255]=]) NG1154.TextColor3=Color3.new(1,1,1)NG1154.Parent=NG1150
NG1155=Instance.new("Frame") NG1155.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1155.BackgroundTransparency=1
NG1155.BorderSizePixel=0 NG1155.Name=dCD([=[TVachg]=])NG1155.Position=UDim2.new(0,72,0,0) NG1155.Size=UDim2.new(0,38,0,25)NG1155.Parent=NG1148
NG1156=Instance.new("TextButton") NG1156.Active=true
NG1156.AutoButtonColor=false NG1156.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1156.BackgroundTransparency=1
NG1156.BorderSizePixel=0 NG1156.Selectable=true
NG1156.Size=UDim2.new(1,0,1,0) NG1156.Style=Enum.ButtonStyle.Custom
NG1156.ZIndex=2
NG1156.Font=Enum.Font.Legacy NG1156.FontSize=Enum.FontSize.Size8
NG1156.Text=dCD([=[]=])NG1156.Parent=NG1155 NG1157=Instance.new("ImageLabel")NG1157.Active=false NG1157.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1157.BackgroundTransparency=1
NG1157.BorderSizePixel=0 NG1157.Name=dCD([=[Onpxtebhaq]=])NG1157.Selectable=false
NG1157.Size=UDim2.new(1,0,1,0) NG1157.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1157.Parent=NG1155
NG1158=Instance.new("Frame") NG1158.BackgroundColor3=Color3.new(0,1,0)NG1158.BorderSizePixel=0
NG1158.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1158.Position=UDim2.new(0,3,0, -2)NG1158.Size=UDim2.new(1,-3,0,2) NG1158.Parent=NG1155
NG1159=Instance.new("TextBox") NG1159.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1159.BackgroundTransparency=1
NG1159.BorderSizePixel=0 NG1159.Position=UDim2.new(0,5,0,0)NG1159.Size=UDim2.new(1,-10,1,0) NG1159.Font=Enum.Font.ArialBold
NG1159.FontSize=Enum.FontSize.Size10
NG1159.Text=dCD([=[255]=]) NG1159.TextColor3=Color3.new(1,1,1)NG1159.Parent=NG1155
NG1160=Instance.new("Frame") NG1160.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1160.BackgroundTransparency=1
NG1160.BorderSizePixel=0 NG1160.Name=dCD([=[OVachg]=])NG1160.Position=UDim2.new(0,109,0,0) NG1160.Size=UDim2.new(0,38,0,25)NG1160.Parent=NG1148
NG1161=Instance.new("TextButton") NG1161.Active=true
NG1161.AutoButtonColor=false NG1161.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1161.BackgroundTransparency=1
NG1161.BorderSizePixel=0 NG1161.Selectable=true
NG1161.Size=UDim2.new(1,0,1,0) NG1161.Style=Enum.ButtonStyle.Custom
NG1161.ZIndex=2
NG1161.Font=Enum.Font.Legacy NG1161.FontSize=Enum.FontSize.Size8
NG1161.Text=dCD([=[]=])NG1161.Parent=NG1160 NG1162=Instance.new("ImageLabel")NG1162.Active=false NG1162.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1162.BackgroundTransparency=1
NG1162.BorderSizePixel=0 NG1162.Name=dCD([=[Onpxtebhaq]=])NG1162.Selectable=false
NG1162.Size=UDim2.new(1,0,1,0) NG1162.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1162.Parent=NG1160
NG1163=Instance.new("Frame") NG1163.BackgroundColor3=Color3.new(0,0,1)NG1163.BorderSizePixel=0
NG1163.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1163.Position=UDim2.new(0,3,0, -2)NG1163.Size=UDim2.new(1,-3,0,2) NG1163.Parent=NG1160
NG1164=Instance.new("TextBox") NG1164.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1164.BackgroundTransparency=1
NG1164.BorderSizePixel=0 NG1164.Position=UDim2.new(0,5,0,0)NG1164.Size=UDim2.new(1,-10,1,0) NG1164.Font=Enum.Font.ArialBold
NG1164.FontSize=Enum.FontSize.Size10
NG1164.Text=dCD([=[255]=]) NG1164.TextColor3=Color3.new(1,1,1)NG1164.Parent=NG1160
NG1165=Instance.new("ImageButton") NG1165.BackgroundColor3=Color3.new(0,0,0)NG1165.BackgroundTransparency=0.40000000596046
NG1165.BorderSizePixel=0 NG1165.Name=dCD([=[UFICvpxre]=])NG1165.Position=UDim2.new(0,160,0,-2) NG1165.Size=UDim2.new(0,27,0,27)NG1165.Style=Enum.ButtonStyle.Custom
NG1165.ZIndex=2 NG1165.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141313631]=])NG1165.Parent=NG1148
NG1166=Instance.new("Frame") NG1166.BackgroundColor3=Color3.new(0,0,0)NG1166.BackgroundTransparency=0.75
NG1166.BorderSizePixel=0 NG1166.Name=dCD([=[Funqbj]=])NG1166.Position=UDim2.new(0,0,1,-2) NG1166.Size=UDim2.new(1,0,0,2)NG1166.Parent=NG1165
NG1167=Instance.new("Frame") NG1167.BackgroundColor3=Color3.new(0,0,0)NG1167.BackgroundTransparency=0.5 NG1167.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1167.BorderSizePixel=0
NG1167.Name=dCD([=[Frcnengbe]=]) NG1167.Position=UDim2.new(0,151,0,4)NG1167.Size=UDim2.new(0,4,0,4)NG1167.Parent=NG1148 NG1168=Instance.new("Frame")NG1168.BackgroundColor3=Color3.new(0,0,0) NG1168.BackgroundTransparency=0.5 NG1168.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1168.BorderSizePixel=0
NG1168.Name=dCD([=[Frcnengbe]=]) NG1168.Position=UDim2.new(0,151,0,16)NG1168.Size=UDim2.new(0,4,0,4)NG1168.Parent=NG1148 NG1169=Instance.new("Frame")NG1169.BackgroundColor3=Color3.new(0,0,0) NG1169.BackgroundTransparency=0.5 NG1169.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1169.BorderSizePixel=0
NG1169.Name=dCD([=[Frcnengbe]=]) NG1169.Position=UDim2.new(0,151,0,10)NG1169.Size=UDim2.new(0,4,0,4)NG1169.Parent=NG1148 NG1170=Instance.new("Frame") NG1170.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1170.BackgroundTransparency=1
NG1170.BorderSizePixel=0 NG1170.Name=dCD([=[UrngBcgvba]=])NG1170.Position=UDim2.new(0,0,0,80) NG1170.Size=UDim2.new(1,0,0,25)NG1170.Parent=NG1147
NG1171=Instance.new("TextLabel") NG1171.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1171.BackgroundTransparency=1
NG1171.BorderSizePixel=0 NG1171.Name=dCD([=[Ynory]=])NG1171.Size=UDim2.new(0,70,0,25) NG1171.Font=Enum.Font.ArialBold
NG1171.FontSize=Enum.FontSize.Size10
NG1171.Text=dCD([=[Urng]=]) NG1171.TextColor3=Color3.new(1,1,1)NG1171.TextStrokeTransparency=0
NG1171.TextWrapped=true NG1171.TextXAlignment=Enum.TextXAlignment.Left
NG1171.Parent=NG1170
NG1172=Instance.new("Frame") NG1172.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1172.BackgroundTransparency=1
NG1172.BorderSizePixel=0 NG1172.Name=dCD([=[Vachg]=])NG1172.Position=UDim2.new(0,34,0,0) NG1172.Size=UDim2.new(0,38,0,25)NG1172.Parent=NG1170
NG1173=Instance.new("TextButton") NG1173.Active=true
NG1173.AutoButtonColor=false NG1173.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1173.BackgroundTransparency=1
NG1173.BorderSizePixel=0 NG1173.Selectable=true
NG1173.Size=UDim2.new(1,0,1,0) NG1173.Style=Enum.ButtonStyle.Custom
NG1173.ZIndex=2
NG1173.Font=Enum.Font.Legacy NG1173.FontSize=Enum.FontSize.Size8
NG1173.Text=dCD([=[]=])NG1173.Parent=NG1172 NG1174=Instance.new("ImageLabel")NG1174.Active=false NG1174.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1174.BackgroundTransparency=1
NG1174.BorderSizePixel=0 NG1174.Name=dCD([=[Onpxtebhaq]=])NG1174.Selectable=false
NG1174.Size=UDim2.new(1,0,1,0) NG1174.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1174.Parent=NG1172
NG1175=Instance.new("Frame") NG1175.BorderSizePixel=0
NG1175.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG1175.Position=UDim2.new(0,3,0,-2)NG1175.Size=UDim2.new(1,-3,0,2)NG1175.Parent=NG1172 NG1176=Instance.new("TextBox") NG1176.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1176.BackgroundTransparency=1
NG1176.BorderSizePixel=0 NG1176.Position=UDim2.new(0,5,0,0)NG1176.Size=UDim2.new(1,-10,1,0) NG1176.Font=Enum.Font.ArialBold
NG1176.FontSize=Enum.FontSize.Size10
NG1176.Text=dCD([=[1]=]) NG1176.TextColor3=Color3.new(1,1,1)NG1176.Parent=NG1172
NG1177=Instance.new("Frame") NG1177.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1177.BackgroundTransparency=1
NG1177.BorderSizePixel=0 NG1177.Name=dCD([=[FvmrBcgvba]=])NG1177.Position=UDim2.new(0,90,0,80) NG1177.Size=UDim2.new(1,0,0,25)NG1177.Parent=NG1147
NG1178=Instance.new("TextLabel") NG1178.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1178.BackgroundTransparency=1
NG1178.BorderSizePixel=0 NG1178.Name=dCD([=[Ynory]=])NG1178.Size=UDim2.new(0,70,0,25) NG1178.Font=Enum.Font.ArialBold
NG1178.FontSize=Enum.FontSize.Size10
NG1178.Text=dCD([=[Fvmr]=]) NG1178.TextColor3=Color3.new(1,1,1)NG1178.TextStrokeTransparency=0
NG1178.TextWrapped=true NG1178.TextXAlignment=Enum.TextXAlignment.Left
NG1178.Parent=NG1177
NG1179=Instance.new("Frame") NG1179.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1179.BackgroundTransparency=1
NG1179.BorderSizePixel=0 NG1179.Name=dCD([=[Vachg]=])NG1179.Position=UDim2.new(0,30,0,0) NG1179.Size=UDim2.new(0,38,0,25)NG1179.Parent=NG1177
NG1180=Instance.new("TextButton") NG1180.Active=true
NG1180.AutoButtonColor=false NG1180.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1180.BackgroundTransparency=1
NG1180.BorderSizePixel=0 NG1180.Selectable=true
NG1180.Size=UDim2.new(1,0,1,0) NG1180.Style=Enum.ButtonStyle.Custom
NG1180.ZIndex=2
NG1180.Font=Enum.Font.Legacy NG1180.FontSize=Enum.FontSize.Size8
NG1180.Text=dCD([=[]=])NG1180.Parent=NG1179 NG1181=Instance.new("ImageLabel")NG1181.Active=false NG1181.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1181.BackgroundTransparency=1
NG1181.BorderSizePixel=0 NG1181.Name=dCD([=[Onpxtebhaq]=])NG1181.Selectable=false
NG1181.Size=UDim2.new(1,0,1,0) NG1181.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1181.Parent=NG1179
NG1182=Instance.new("Frame") NG1182.BorderSizePixel=0
NG1182.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG1182.Position=UDim2.new(0,3,0,-2)NG1182.Size=UDim2.new(1,-3,0,2)NG1182.Parent=NG1179 NG1183=Instance.new("TextBox") NG1183.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1183.BackgroundTransparency=1
NG1183.BorderSizePixel=0 NG1183.Position=UDim2.new(0,5,0,0)NG1183.Size=UDim2.new(1,-10,1,0) NG1183.Font=Enum.Font.ArialBold
NG1183.FontSize=Enum.FontSize.Size10
NG1183.Text=dCD([=[16]=]) NG1183.TextColor3=Color3.new(1,1,1)NG1183.Parent=NG1179
NG1184=Instance.new("Frame") NG1184.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1184.BackgroundTransparency=1
NG1184.BorderSizePixel=0 NG1184.Name=dCD([=[FrpbaqPbybeBcgvba]=])NG1184.Position=UDim2.new(0,0,0,45) NG1184.Size=UDim2.new(1,0,0,25)NG1184.Parent=NG1147
NG1185=Instance.new("TextLabel") NG1185.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1185.BackgroundTransparency=1
NG1185.BorderSizePixel=0 NG1185.Name=dCD([=[Ynory]=])NG1185.Size=UDim2.new(0,40,0,25) NG1185.Font=Enum.Font.ArialBold
NG1185.FontSize=Enum.FontSize.Size10 NG1185.Text=dCD([=[2aq Pbybe]=])NG1185.TextColor3=Color3.new(1,1,1) NG1185.TextStrokeTransparency=0
NG1185.TextWrapped=true NG1185.TextXAlignment=Enum.TextXAlignment.Left
NG1185.Parent=NG1184
NG1186=Instance.new("Frame") NG1186.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1186.BackgroundTransparency=1
NG1186.BorderSizePixel=0 NG1186.Name=dCD([=[EVachg]=])NG1186.Position=UDim2.new(0,35,0,0) NG1186.Size=UDim2.new(0,38,0,25)NG1186.Parent=NG1184
NG1187=Instance.new("TextButton") NG1187.Active=true
NG1187.AutoButtonColor=false NG1187.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1187.BackgroundTransparency=1
NG1187.BorderSizePixel=0 NG1187.Selectable=true
NG1187.Size=UDim2.new(1,0,1,0) NG1187.Style=Enum.ButtonStyle.Custom
NG1187.ZIndex=2
NG1187.Font=Enum.Font.Legacy NG1187.FontSize=Enum.FontSize.Size8
NG1187.Text=dCD([=[]=])NG1187.Parent=NG1186 NG1188=Instance.new("ImageLabel")NG1188.Active=false NG1188.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1188.BackgroundTransparency=1
NG1188.BorderSizePixel=0 NG1188.Name=dCD([=[Onpxtebhaq]=])NG1188.Selectable=false
NG1188.Size=UDim2.new(1,0,1,0) NG1188.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1188.Parent=NG1186
NG1189=Instance.new("Frame") NG1189.BackgroundColor3=Color3.new(1,0,0)NG1189.BorderSizePixel=0
NG1189.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1189.Position=UDim2.new(0,3,0, -2)NG1189.Size=UDim2.new(1,-3,0,2) NG1189.Parent=NG1186
NG1190=Instance.new("TextBox") NG1190.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1190.BackgroundTransparency=1
NG1190.BorderSizePixel=0 NG1190.Position=UDim2.new(0,5,0,0)NG1190.Size=UDim2.new(1,-10,1,0) NG1190.Font=Enum.Font.ArialBold
NG1190.FontSize=Enum.FontSize.Size10
NG1190.Text=dCD([=[255]=]) NG1190.TextColor3=Color3.new(1,1,1)NG1190.Parent=NG1186
NG1191=Instance.new("Frame") NG1191.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1191.BackgroundTransparency=1
NG1191.BorderSizePixel=0 NG1191.Name=dCD([=[TVachg]=])NG1191.Position=UDim2.new(0,72,0,0) NG1191.Size=UDim2.new(0,38,0,25)NG1191.Parent=NG1184
NG1192=Instance.new("TextButton") NG1192.Active=true
NG1192.AutoButtonColor=false NG1192.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1192.BackgroundTransparency=1
NG1192.BorderSizePixel=0 NG1192.Selectable=true
NG1192.Size=UDim2.new(1,0,1,0) NG1192.Style=Enum.ButtonStyle.Custom
NG1192.ZIndex=2
NG1192.Font=Enum.Font.Legacy NG1192.FontSize=Enum.FontSize.Size8
NG1192.Text=dCD([=[]=])NG1192.Parent=NG1191 NG1193=Instance.new("ImageLabel")NG1193.Active=false NG1193.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1193.BackgroundTransparency=1
NG1193.BorderSizePixel=0 NG1193.Name=dCD([=[Onpxtebhaq]=])NG1193.Selectable=false
NG1193.Size=UDim2.new(1,0,1,0) NG1193.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1193.Parent=NG1191
NG1194=Instance.new("Frame") NG1194.BackgroundColor3=Color3.new(0,1,0)NG1194.BorderSizePixel=0
NG1194.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1194.Position=UDim2.new(0,3,0, -2)NG1194.Size=UDim2.new(1,-3,0,2) NG1194.Parent=NG1191
NG1195=Instance.new("TextBox") NG1195.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1195.BackgroundTransparency=1
NG1195.BorderSizePixel=0 NG1195.Position=UDim2.new(0,5,0,0)NG1195.Size=UDim2.new(1,-10,1,0) NG1195.Font=Enum.Font.ArialBold
NG1195.FontSize=Enum.FontSize.Size10
NG1195.Text=dCD([=[255]=]) NG1195.TextColor3=Color3.new(1,1,1)NG1195.Parent=NG1191
NG1196=Instance.new("Frame") NG1196.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1196.BackgroundTransparency=1
NG1196.BorderSizePixel=0 NG1196.Name=dCD([=[OVachg]=])NG1196.Position=UDim2.new(0,109,0,0) NG1196.Size=UDim2.new(0,38,0,25)NG1196.Parent=NG1184
NG1197=Instance.new("TextButton") NG1197.Active=true
NG1197.AutoButtonColor=false NG1197.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1197.BackgroundTransparency=1
NG1197.BorderSizePixel=0 NG1197.Selectable=true
NG1197.Size=UDim2.new(1,0,1,0) NG1197.Style=Enum.ButtonStyle.Custom
NG1197.ZIndex=2
NG1197.Font=Enum.Font.Legacy NG1197.FontSize=Enum.FontSize.Size8
NG1197.Text=dCD([=[]=])NG1197.Parent=NG1196 NG1198=Instance.new("ImageLabel")NG1198.Active=false NG1198.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1198.BackgroundTransparency=1
NG1198.BorderSizePixel=0 NG1198.Name=dCD([=[Onpxtebhaq]=])NG1198.Selectable=false
NG1198.Size=UDim2.new(1,0,1,0) NG1198.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1198.Parent=NG1196
NG1199=Instance.new("Frame") NG1199.BackgroundColor3=Color3.new(0,0,1)NG1199.BorderSizePixel=0
NG1199.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1199.Position=UDim2.new(0,3,0, -2)NG1199.Size=UDim2.new(1,-3,0,2) NG1199.Parent=NG1196
NG1200=Instance.new("TextBox") NG1200.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1200.BackgroundTransparency=1
NG1200.BorderSizePixel=0 NG1200.Position=UDim2.new(0,5,0,0)NG1200.Size=UDim2.new(1,-10,1,0) NG1200.Font=Enum.Font.ArialBold
NG1200.FontSize=Enum.FontSize.Size10
NG1200.Text=dCD([=[255]=]) NG1200.TextColor3=Color3.new(1,1,1)NG1200.Parent=NG1196
NG1201=Instance.new("ImageButton") NG1201.BackgroundColor3=Color3.new(0,0,0)NG1201.BackgroundTransparency=0.40000000596046
NG1201.BorderSizePixel=0 NG1201.Name=dCD([=[UFICvpxre]=])NG1201.Position=UDim2.new(0,160,0,-2) NG1201.Size=UDim2.new(0,27,0,27)NG1201.Style=Enum.ButtonStyle.Custom
NG1201.ZIndex=2 NG1201.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141313631]=])NG1201.Parent=NG1184
NG1202=Instance.new("Frame") NG1202.BackgroundColor3=Color3.new(0,0,0)NG1202.BackgroundTransparency=0.75
NG1202.BorderSizePixel=0 NG1202.Name=dCD([=[Funqbj]=])NG1202.Position=UDim2.new(0,0,1,-2) NG1202.Size=UDim2.new(1,0,0,2)NG1202.Parent=NG1201
NG1203=Instance.new("Frame") NG1203.BackgroundColor3=Color3.new(0,0,0)NG1203.BackgroundTransparency=0.5 NG1203.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1203.BorderSizePixel=0
NG1203.Name=dCD([=[Frcnengbe]=]) NG1203.Position=UDim2.new(0,151,0,4)NG1203.Size=UDim2.new(0,4,0,4)NG1203.Parent=NG1184 NG1204=Instance.new("Frame")NG1204.BackgroundColor3=Color3.new(0,0,0) NG1204.BackgroundTransparency=0.5 NG1204.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1204.BorderSizePixel=0
NG1204.Name=dCD([=[Frcnengbe]=]) NG1204.Position=UDim2.new(0,151,0,16)NG1204.Size=UDim2.new(0,4,0,4)NG1204.Parent=NG1184 NG1205=Instance.new("Frame")NG1205.BackgroundColor3=Color3.new(0,0,0) NG1205.BackgroundTransparency=0.5 NG1205.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1205.BorderSizePixel=0
NG1205.Name=dCD([=[Frcnengbe]=]) NG1205.Position=UDim2.new(0,151,0,10)NG1205.Size=UDim2.new(0,4,0,4)NG1205.Parent=NG1184 NG1206=Instance.new("Frame")NG1206.BackgroundColor3=Color3.new(0,0,0) NG1206.BackgroundTransparency=0.67500001192093
NG1206.BorderSizePixel=0
NG1206.Name=dCD([=[Fcnexyrf]=]) NG1206.Position=UDim2.new(0,10,0,90)NG1206.Size=UDim2.new(1,-10,0,25)NG1206.Parent=NG1082 NG1207=Instance.new("TextLabel")NG1207.BackgroundTransparency=1
NG1207.BorderSizePixel=0 NG1207.Name=dCD([=[Ynory]=])NG1207.Position=UDim2.new(0,35,0,0) NG1207.Size=UDim2.new(0,60,0,25)NG1207.Font=Enum.Font.ArialBold NG1207.FontSize=Enum.FontSize.Size10
NG1207.Text=dCD([=[Fcnexyrf]=]) NG1207.TextColor3=Color3.new(1,1,1)NG1207.TextStrokeTransparency=0.5
NG1207.TextWrapped=true NG1207.TextXAlignment=Enum.TextXAlignment.Left
NG1207.Parent=NG1206
NG1208=Instance.new("ImageButton") NG1208.BackgroundTransparency=1
NG1208.BorderSizePixel=0
NG1208.Name=dCD([=[NeebjOhggba]=]) NG1208.Position=UDim2.new(0,10,0,3)NG1208.Size=UDim2.new(0,20,0,20) NG1208.Style=Enum.ButtonStyle.Custom
NG1208.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=134367382]=]) NG1208.Parent=NG1206
NG1209=Instance.new("Frame") NG1209.BackgroundColor3=Color3.new(0.0196078,0.396078,1)NG1209.BorderSizePixel=0
NG1209.Name=dCD([=[PbybeOne]=]) NG1209.Size=UDim2.new(0,3,1,0)NG1209.Parent=NG1206
NG1210=Instance.new("TextButton") NG1210.Active=true
NG1210.BackgroundColor3=Color3.new(0,0,0) NG1210.BackgroundTransparency=0.75
NG1210.BorderColor3=Color3.new(0,0,0) NG1210.BorderSizePixel=0
NG1210.Name=dCD([=[NqqOhggba]=]) NG1210.Position=UDim2.new(1,-40,0,3)NG1210.Selectable=true
NG1210.Size=UDim2.new(0,35,0,19) NG1210.Style=Enum.ButtonStyle.Custom
NG1210.ZIndex=2
NG1210.Font=Enum.Font.ArialBold NG1210.FontSize=Enum.FontSize.Size10
NG1210.Text=dCD([=[NQQ]=])NG1210.TextColor3=Color3.new(1,1,1) NG1210.Parent=NG1206
NG1211=Instance.new("TextButton")NG1211.Active=true NG1211.BackgroundColor3=Color3.new(0,0,0)NG1211.BackgroundTransparency=0.75 NG1211.BorderColor3=Color3.new(0,0,0)NG1211.BorderSizePixel=0
NG1211.Name=dCD([=[ErzbirOhggba]=]) NG1211.Position=UDim2.new(0,90,0,3)NG1211.Selectable=true
NG1211.Size=UDim2.new(0,58,0,19) NG1211.Style=Enum.ButtonStyle.Custom
NG1211.Visible=false
NG1211.ZIndex=2 NG1211.Font=Enum.Font.ArialBold
NG1211.FontSize=Enum.FontSize.Size10 NG1211.Text=dCD([=[ERZBIR]=])NG1211.TextColor3=Color3.new(1,1,1)NG1211.Parent=NG1206 NG1212=Instance.new("Frame")NG1212.BackgroundColor3=Color3.new(0,0,0) NG1212.BackgroundTransparency=0.75
NG1212.BorderSizePixel=0
NG1212.Name=dCD([=[Funqbj]=]) NG1212.Position=UDim2.new(0,0,1,-1)NG1212.Size=UDim2.new(1,0,0,1)NG1212.Parent=NG1206 NG1213=Instance.new("Frame")NG1213.BackgroundTransparency=1
NG1213.BorderSizePixel=0 NG1213.Name=dCD([=[Bcgvbaf]=])NG1213.Position=UDim2.new(0,3,1,0) NG1213.Size=UDim2.new(1,-3,0,0)NG1213.ClipsDescendants=true
NG1213.Parent=NG1206 NG1214=Instance.new("Frame") NG1214.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1214.BackgroundTransparency=1
NG1214.BorderSizePixel=0 NG1214.Name=dCD([=[PbybeBcgvba]=])NG1214.Position=UDim2.new(0,0,0,10) NG1214.Size=UDim2.new(1,0,0,25)NG1214.Parent=NG1213
NG1215=Instance.new("TextLabel") NG1215.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1215.BackgroundTransparency=1
NG1215.BorderSizePixel=0 NG1215.Name=dCD([=[Ynory]=])NG1215.Size=UDim2.new(0,70,0,25) NG1215.Font=Enum.Font.ArialBold
NG1215.FontSize=Enum.FontSize.Size10
NG1215.Text=dCD([=[Pbybe]=]) NG1215.TextColor3=Color3.new(1,1,1)NG1215.TextStrokeTransparency=0
NG1215.TextWrapped=true NG1215.TextXAlignment=Enum.TextXAlignment.Left
NG1215.Parent=NG1214
NG1216=Instance.new("Frame") NG1216.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1216.BackgroundTransparency=1
NG1216.BorderSizePixel=0 NG1216.Name=dCD([=[EVachg]=])NG1216.Position=UDim2.new(0,35,0,0) NG1216.Size=UDim2.new(0,38,0,25)NG1216.Parent=NG1214
NG1217=Instance.new("TextButton") NG1217.Active=true
NG1217.AutoButtonColor=false NG1217.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1217.BackgroundTransparency=1
NG1217.BorderSizePixel=0 NG1217.Selectable=true
NG1217.Size=UDim2.new(1,0,1,0) NG1217.Style=Enum.ButtonStyle.Custom
NG1217.ZIndex=2
NG1217.Font=Enum.Font.Legacy NG1217.FontSize=Enum.FontSize.Size8
NG1217.Text=dCD([=[]=])NG1217.Parent=NG1216 NG1218=Instance.new("ImageLabel")NG1218.Active=false NG1218.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1218.BackgroundTransparency=1
NG1218.BorderSizePixel=0 NG1218.Name=dCD([=[Onpxtebhaq]=])NG1218.Selectable=false
NG1218.Size=UDim2.new(1,0,1,0) NG1218.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1218.Parent=NG1216
NG1219=Instance.new("Frame") NG1219.BackgroundColor3=Color3.new(1,0,0)NG1219.BorderSizePixel=0
NG1219.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1219.Position=UDim2.new(0,3,0, -2)NG1219.Size=UDim2.new(1,-3,0,2) NG1219.Parent=NG1216
NG1220=Instance.new("TextBox") NG1220.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1220.BackgroundTransparency=1
NG1220.BorderSizePixel=0 NG1220.Position=UDim2.new(0,5,0,0)NG1220.Size=UDim2.new(1,-10,1,0) NG1220.Font=Enum.Font.ArialBold
NG1220.FontSize=Enum.FontSize.Size10
NG1220.Text=dCD([=[255]=]) NG1220.TextColor3=Color3.new(1,1,1)NG1220.Parent=NG1216
NG1221=Instance.new("Frame") NG1221.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1221.BackgroundTransparency=1
NG1221.BorderSizePixel=0 NG1221.Name=dCD([=[TVachg]=])NG1221.Position=UDim2.new(0,72,0,0) NG1221.Size=UDim2.new(0,38,0,25)NG1221.Parent=NG1214
NG1222=Instance.new("TextButton") NG1222.Active=true
NG1222.AutoButtonColor=false NG1222.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1222.BackgroundTransparency=1
NG1222.BorderSizePixel=0 NG1222.Selectable=true
NG1222.Size=UDim2.new(1,0,1,0) NG1222.Style=Enum.ButtonStyle.Custom
NG1222.ZIndex=2
NG1222.Font=Enum.Font.Legacy NG1222.FontSize=Enum.FontSize.Size8
NG1222.Text=dCD([=[]=])NG1222.Parent=NG1221 NG1223=Instance.new("ImageLabel")NG1223.Active=false NG1223.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1223.BackgroundTransparency=1
NG1223.BorderSizePixel=0 NG1223.Name=dCD([=[Onpxtebhaq]=])NG1223.Selectable=false
NG1223.Size=UDim2.new(1,0,1,0) NG1223.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1223.Parent=NG1221
NG1224=Instance.new("Frame") NG1224.BackgroundColor3=Color3.new(0,1,0)NG1224.BorderSizePixel=0
NG1224.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1224.Position=UDim2.new(0,3,0, -2)NG1224.Size=UDim2.new(1,-3,0,2) NG1224.Parent=NG1221
NG1225=Instance.new("TextBox") NG1225.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1225.BackgroundTransparency=1
NG1225.BorderSizePixel=0 NG1225.Position=UDim2.new(0,5,0,0)NG1225.Size=UDim2.new(1,-10,1,0) NG1225.Font=Enum.Font.ArialBold
NG1225.FontSize=Enum.FontSize.Size10
NG1225.Text=dCD([=[255]=]) NG1225.TextColor3=Color3.new(1,1,1)NG1225.Parent=NG1221
NG1226=Instance.new("Frame") NG1226.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1226.BackgroundTransparency=1
NG1226.BorderSizePixel=0 NG1226.Name=dCD([=[OVachg]=])NG1226.Position=UDim2.new(0,109,0,0) NG1226.Size=UDim2.new(0,38,0,25)NG1226.Parent=NG1214
NG1227=Instance.new("TextButton") NG1227.Active=true
NG1227.AutoButtonColor=false NG1227.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1227.BackgroundTransparency=1
NG1227.BorderSizePixel=0 NG1227.Selectable=true
NG1227.Size=UDim2.new(1,0,1,0) NG1227.Style=Enum.ButtonStyle.Custom
NG1227.ZIndex=2
NG1227.Font=Enum.Font.Legacy NG1227.FontSize=Enum.FontSize.Size8
NG1227.Text=dCD([=[]=])NG1227.Parent=NG1226 NG1228=Instance.new("ImageLabel")NG1228.Active=false NG1228.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1228.BackgroundTransparency=1
NG1228.BorderSizePixel=0 NG1228.Name=dCD([=[Onpxtebhaq]=])NG1228.Selectable=false
NG1228.Size=UDim2.new(1,0,1,0) NG1228.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1228.Parent=NG1226
NG1229=Instance.new("Frame") NG1229.BackgroundColor3=Color3.new(0,0,1)NG1229.BorderSizePixel=0
NG1229.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1229.Position=UDim2.new(0,3,0, -2)NG1229.Size=UDim2.new(1,-3,0,2) NG1229.Parent=NG1226
NG1230=Instance.new("TextBox") NG1230.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1230.BackgroundTransparency=1
NG1230.BorderSizePixel=0 NG1230.Position=UDim2.new(0,5,0,0)NG1230.Size=UDim2.new(1,-10,1,0) NG1230.Font=Enum.Font.ArialBold
NG1230.FontSize=Enum.FontSize.Size10
NG1230.Text=dCD([=[255]=]) NG1230.TextColor3=Color3.new(1,1,1)NG1230.Parent=NG1226
NG1231=Instance.new("ImageButton") NG1231.BackgroundColor3=Color3.new(0,0,0)NG1231.BackgroundTransparency=0.40000000596046
NG1231.BorderSizePixel=0 NG1231.Name=dCD([=[UFICvpxre]=])NG1231.Position=UDim2.new(0,160,0,-2) NG1231.Size=UDim2.new(0,27,0,27)NG1231.Style=Enum.ButtonStyle.Custom
NG1231.ZIndex=2 NG1231.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=141313631]=])NG1231.Parent=NG1214
NG1232=Instance.new("Frame") NG1232.BackgroundColor3=Color3.new(0,0,0)NG1232.BackgroundTransparency=0.75
NG1232.BorderSizePixel=0 NG1232.Name=dCD([=[Funqbj]=])NG1232.Position=UDim2.new(0,0,1,-2) NG1232.Size=UDim2.new(1,0,0,2)NG1232.Parent=NG1231
NG1233=Instance.new("Frame") NG1233.BackgroundColor3=Color3.new(0,0,0)NG1233.BackgroundTransparency=0.5 NG1233.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1233.BorderSizePixel=0
NG1233.Name=dCD([=[Frcnengbe]=]) NG1233.Position=UDim2.new(0,151,0,4)NG1233.Size=UDim2.new(0,4,0,4)NG1233.Parent=NG1214 NG1234=Instance.new("Frame")NG1234.BackgroundColor3=Color3.new(0,0,0) NG1234.BackgroundTransparency=0.5 NG1234.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1234.BorderSizePixel=0
NG1234.Name=dCD([=[Frcnengbe]=]) NG1234.Position=UDim2.new(0,151,0,16)NG1234.Size=UDim2.new(0,4,0,4)NG1234.Parent=NG1214 NG1235=Instance.new("Frame")NG1235.BackgroundColor3=Color3.new(0,0,0) NG1235.BackgroundTransparency=0.5 NG1235.BorderColor3=Color3.new(0.380392,0.380392,0.380392)NG1235.BorderSizePixel=0
NG1235.Name=dCD([=[Frcnengbe]=]) NG1235.Position=UDim2.new(0,151,0,10)NG1235.Size=UDim2.new(0,4,0,4)NG1235.Parent=NG1214 NG1236=Instance.new("Frame")NG1236.Active=true NG1236.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1236.BackgroundTransparency=1
NG1236.BorderSizePixel=0 NG1236.Name=dCD([=[OGEbgngrGbbyTHV]=])NG1236.Position=UDim2.new(0,0,0,280) NG1236.Size=UDim2.new(0,245,0,90)NG1236.Draggable=true
NG1236.Parent=NG1 NG1237=Instance.new("Frame") NG1237.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1237.BackgroundTransparency=1
NG1237.BorderSizePixel=0 NG1237.Name=dCD([=[CvibgBcgvba]=])NG1237.Position=UDim2.new(0,0,0,30) NG1237.Size=UDim2.new(0,0,0,0)NG1237.Parent=NG1236
NG1238=Instance.new("Frame") NG1238.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1238.BackgroundTransparency=1
NG1238.BorderSizePixel=0 NG1238.Name=dCD([=[Pragre]=])NG1238.Position=UDim2.new(0,50,0,0) NG1238.Size=UDim2.new(0,70,0,25)NG1238.Parent=NG1237
NG1239=Instance.new("Frame") NG1239.BorderSizePixel=0
NG1239.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG1239.Position=UDim2.new(0,6,0,-2)NG1239.Size=UDim2.new(1,-5,0,2)NG1239.Parent=NG1238 NG1240=Instance.new("TextButton")NG1240.Active=true NG1240.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1240.BackgroundTransparency=1
NG1240.BorderSizePixel=0 NG1240.Name=dCD([=[Ohggba]=])NG1240.Position=UDim2.new(0,5,0,0)NG1240.Selectable=true
NG1240.Size=UDim2.new(1, -10,1,0) NG1240.Style=Enum.ButtonStyle.Custom
NG1240.ZIndex=2
NG1240.Font=Enum.Font.Legacy NG1240.FontSize=Enum.FontSize.Size8
NG1240.Text=dCD([=[]=])NG1240.TextTransparency=1
NG1240.Parent=NG1238 NG1241=Instance.new("ImageLabel")NG1241.Active=false NG1241.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1241.BackgroundTransparency=1
NG1241.BorderSizePixel=0 NG1241.Name=dCD([=[Onpxtebhaq]=])NG1241.Selectable=false
NG1241.Size=UDim2.new(1,0,1,0) NG1241.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127774197]=])NG1241.Parent=NG1238
NG1242=Instance.new("TextLabel") NG1242.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1242.BackgroundTransparency=1
NG1242.BorderSizePixel=0 NG1242.Name=dCD([=[Ynory]=])NG1242.Size=UDim2.new(1,0,1,0) NG1242.Font=Enum.Font.ArialBold
NG1242.FontSize=Enum.FontSize.Size10 NG1242.Text=dCD([=[PRAGRE]=])NG1242.TextColor3=Color3.new(1,1,1)NG1242.Parent=NG1238 NG1243=Instance.new("Frame") NG1243.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1243.BackgroundTransparency=1
NG1243.BorderSizePixel=0 NG1243.Name=dCD([=[Ybpny]=])NG1243.Position=UDim2.new(0,115,0,0) NG1243.Size=UDim2.new(0,70,0,25)NG1243.Parent=NG1237
NG1244=Instance.new("Frame") NG1244.BackgroundTransparency=1
NG1244.BorderSizePixel=0
NG1244.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1244.Position=UDim2.new(0,6,0, -2)NG1244.Size=UDim2.new(1,-5,0,2) NG1244.Parent=NG1243
NG1245=Instance.new("TextButton")NG1245.Active=true NG1245.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1245.BackgroundTransparency=1
NG1245.BorderSizePixel=0 NG1245.Name=dCD([=[Ohggba]=])NG1245.Position=UDim2.new(0,5,0,0)NG1245.Selectable=true
NG1245.Size=UDim2.new(1, -10,1,0) NG1245.Style=Enum.ButtonStyle.Custom
NG1245.ZIndex=2
NG1245.Font=Enum.Font.Legacy NG1245.FontSize=Enum.FontSize.Size8
NG1245.Text=dCD([=[]=])NG1245.TextTransparency=1
NG1245.Parent=NG1243 NG1246=Instance.new("ImageLabel")NG1246.Active=false NG1246.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1246.BackgroundTransparency=1
NG1246.BorderSizePixel=0 NG1246.Name=dCD([=[Onpxtebhaq]=])NG1246.Selectable=false
NG1246.Size=UDim2.new(1,0,1,0) NG1246.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1246.Parent=NG1243
NG1247=Instance.new("TextLabel") NG1247.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1247.BackgroundTransparency=1
NG1247.BorderSizePixel=0 NG1247.Name=dCD([=[Ynory]=])NG1247.Size=UDim2.new(1,0,1,0) NG1247.Font=Enum.Font.ArialBold
NG1247.FontSize=Enum.FontSize.Size10
NG1247.Text=dCD([=[YBPNY]=]) NG1247.TextColor3=Color3.new(1,1,1)NG1247.Parent=NG1243
NG1248=Instance.new("Frame") NG1248.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1248.BackgroundTransparency=1
NG1248.BorderSizePixel=0 NG1248.Name=dCD([=[Ynfg]=])NG1248.Position=UDim2.new(0,180,0,0) NG1248.Size=UDim2.new(0,70,0,25)NG1248.Parent=NG1237
NG1249=Instance.new("Frame") NG1249.BackgroundTransparency=1
NG1249.BorderSizePixel=0
NG1249.Name=dCD([=[FryrpgrqVaqvpngbe]=])NG1249.Position=UDim2.new(0,6,0, -2)NG1249.Size=UDim2.new(1,-5,0,2) NG1249.Parent=NG1248
NG1250=Instance.new("TextButton")NG1250.Active=true NG1250.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1250.BackgroundTransparency=1
NG1250.BorderSizePixel=0 NG1250.Name=dCD([=[Ohggba]=])NG1250.Position=UDim2.new(0,5,0,0)NG1250.Selectable=true
NG1250.Size=UDim2.new(1, -10,1,0) NG1250.Style=Enum.ButtonStyle.Custom
NG1250.ZIndex=2
NG1250.Font=Enum.Font.Legacy NG1250.FontSize=Enum.FontSize.Size8
NG1250.Text=dCD([=[]=])NG1250.TextTransparency=1
NG1250.Parent=NG1248 NG1251=Instance.new("ImageLabel")NG1251.Active=false NG1251.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1251.BackgroundTransparency=1
NG1251.BorderSizePixel=0 NG1251.Name=dCD([=[Onpxtebhaq]=])NG1251.Selectable=false
NG1251.Size=UDim2.new(1,0,1,0) NG1251.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1251.Parent=NG1248
NG1252=Instance.new("TextLabel") NG1252.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1252.BackgroundTransparency=1
NG1252.BorderSizePixel=0 NG1252.Name=dCD([=[Ynory]=])NG1252.Size=UDim2.new(1,0,1,0) NG1252.Font=Enum.Font.ArialBold
NG1252.FontSize=Enum.FontSize.Size10
NG1252.Text=dCD([=[YNFG]=]) NG1252.TextColor3=Color3.new(1,1,1)NG1252.Parent=NG1248
NG1253=Instance.new("Frame") NG1253.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1253.BackgroundTransparency=1
NG1253.BorderSizePixel=0 NG1253.Name=dCD([=[Ynory]=])NG1253.Size=UDim2.new(0,50,0,25)NG1253.Parent=NG1237 NG1254=Instance.new("TextLabel") NG1254.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1254.BackgroundTransparency=1
NG1254.BorderSizePixel=0 NG1254.Size=UDim2.new(1,0,1,0)NG1254.Font=Enum.Font.ArialBold NG1254.FontSize=Enum.FontSize.Size10
NG1254.Text=dCD([=[Cvibg]=])NG1254.TextColor3=Color3.new(1,1,1) NG1254.TextStrokeTransparency=0
NG1254.TextWrapped=true
NG1254.Parent=NG1253 NG1255=Instance.new("Frame") NG1255.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1255.BackgroundTransparency=1
NG1255.BorderSizePixel=0 NG1255.Name=dCD([=[Gvgyr]=])NG1255.Size=UDim2.new(1,0,0,20)NG1255.Parent=NG1236 NG1256=Instance.new("Frame") NG1256.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG1256.BorderSizePixel=0
NG1256.Name=dCD([=[PbybeOne]=])NG1256.Position=UDim2.new(0,5,0, -3)NG1256.Size=UDim2.new(1,-5,0,2) NG1256.Parent=NG1255
NG1257=Instance.new("TextLabel") NG1257.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1257.BackgroundTransparency=1
NG1257.BorderSizePixel=0 NG1257.Name=dCD([=[Ynory]=])NG1257.Position=UDim2.new(0,10,0,1) NG1257.Size=UDim2.new(1,-10,1,0)NG1257.Font=Enum.Font.ArialBold NG1257.FontSize=Enum.FontSize.Size10
NG1257.Text=dCD([=[EBGNGR GBBY]=]) NG1257.TextColor3=Color3.new(1,1,1)NG1257.TextStrokeTransparency=0
NG1257.TextWrapped=true NG1257.TextXAlignment=Enum.TextXAlignment.Left
NG1257.Parent=NG1255
NG1258=Instance.new("TextLabel") NG1258.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1258.BackgroundTransparency=1
NG1258.BorderSizePixel=0 NG1258.Name=dCD([=[S3KFvtangher]=])NG1258.Position=UDim2.new(0,10,0,1) NG1258.Size=UDim2.new(1,-10,1,0)NG1258.Font=Enum.Font.ArialBold NG1258.FontSize=Enum.FontSize.Size14
NG1258.Text=dCD([=[S3K]=])NG1258.TextColor3=Color3.new(1,1,1) NG1258.TextStrokeTransparency=0.89999997615814
NG1258.TextWrapped=true NG1258.TextXAlignment=Enum.TextXAlignment.Right
NG1258.Parent=NG1255
NG1259=Instance.new("Frame") NG1259.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1259.BackgroundTransparency=1
NG1259.BorderSizePixel=0 NG1259.Name=dCD([=[VaperzragBcgvba]=])NG1259.Position=UDim2.new(0,0,0,65) NG1259.Size=UDim2.new(0,0,0,0)NG1259.Parent=NG1236
NG1260=Instance.new("Frame") NG1260.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1260.BackgroundTransparency=1
NG1260.BorderSizePixel=0 NG1260.Name=dCD([=[Vaperzrag]=])NG1260.Position=UDim2.new(0,70,0,0) NG1260.Size=UDim2.new(0,50,0,25)NG1260.Parent=NG1259
NG1261=Instance.new("Frame") NG1261.BorderSizePixel=0
NG1261.Name=dCD([=[FryrpgrqVaqvpngbe]=]) NG1261.Position=UDim2.new(0,5,0,-2)NG1261.Size=UDim2.new(1,-4,0,2)NG1261.Parent=NG1260 NG1262=Instance.new("TextBox") NG1262.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1262.BackgroundTransparency=1
NG1262.BorderSizePixel=0 NG1262.Position=UDim2.new(0,5,0,0)NG1262.Size=UDim2.new(1,-10,1,0)NG1262.ZIndex=2 NG1262.Font=Enum.Font.ArialBold
NG1262.FontSize=Enum.FontSize.Size10
NG1262.Text=dCD([=[15]=]) NG1262.TextColor3=Color3.new(1,1,1)NG1262.Parent=NG1260
NG1263=Instance.new("ImageLabel") NG1263.Active=false NG1263.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1263.BackgroundTransparency=1
NG1263.BorderSizePixel=0 NG1263.Name=dCD([=[Onpxtebhaq]=])NG1263.Selectable=false
NG1263.Size=UDim2.new(1,0,1,0) NG1263.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1263.Parent=NG1260
NG1264=Instance.new("Frame") NG1264.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1264.BackgroundTransparency=1
NG1264.BorderSizePixel=0 NG1264.Name=dCD([=[Ynory]=])NG1264.Size=UDim2.new(0,75,0,25)NG1264.Parent=NG1259 NG1265=Instance.new("TextLabel") NG1265.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1265.BackgroundTransparency=1
NG1265.BorderSizePixel=0 NG1265.Size=UDim2.new(1,0,1,0)NG1265.Font=Enum.Font.ArialBold NG1265.FontSize=Enum.FontSize.Size10
NG1265.Text=dCD([=[Vaperzrag]=]) NG1265.TextColor3=Color3.new(1,1,1)NG1265.TextStrokeTransparency=0
NG1265.TextWrapped=true NG1265.Parent=NG1264
NG1266=Instance.new("Frame") NG1266.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1266.BackgroundTransparency=1
NG1266.BorderSizePixel=0 NG1266.Name=dCD([=[Vasb]=])NG1266.Position=UDim2.new(0,5,0,100) NG1266.Size=UDim2.new(1,-5,0,60)NG1266.Visible=false
NG1266.Parent=NG1236 NG1267=Instance.new("Frame") NG1267.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG1267.BorderSizePixel=0
NG1267.Name=dCD([=[PbybeOne]=]) NG1267.Size=UDim2.new(1,0,0,2)NG1267.Parent=NG1266
NG1268=Instance.new("TextLabel") NG1268.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1268.BackgroundTransparency=1
NG1268.BorderSizePixel=0 NG1268.Name=dCD([=[Ynory]=])NG1268.Position=UDim2.new(0,10,0,2) NG1268.Size=UDim2.new(1,-10,0,20)NG1268.Font=Enum.Font.ArialBold NG1268.FontSize=Enum.FontSize.Size10
NG1268.Text=dCD([=[FRYRPGVBA VASB]=]) NG1268.TextColor3=Color3.new(1,1,1)NG1268.TextStrokeTransparency=0
NG1268.TextWrapped=true NG1268.TextXAlignment=Enum.TextXAlignment.Left
NG1268.Parent=NG1266
NG1269=Instance.new("Frame") NG1269.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1269.BackgroundTransparency=1
NG1269.BorderSizePixel=0 NG1269.Name=dCD([=[EbgngvbaVasb]=])NG1269.Position=UDim2.new(0,0,0,30) NG1269.Size=UDim2.new(0,0,0,0)NG1269.Parent=NG1266
NG1270=Instance.new("TextLabel") NG1270.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1270.BackgroundTransparency=1
NG1270.BorderSizePixel=0 NG1270.Size=UDim2.new(0,75,0,25)NG1270.Font=Enum.Font.ArialBold NG1270.FontSize=Enum.FontSize.Size10
NG1270.Text=dCD([=[Ebgngvba]=]) NG1270.TextColor3=Color3.new(1,1,1)NG1270.TextStrokeTransparency=0
NG1270.TextWrapped=true NG1270.Parent=NG1269
NG1271=Instance.new("Frame") NG1271.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1271.BackgroundTransparency=1
NG1271.BorderSizePixel=0 NG1271.Name=dCD([=[K]=])NG1271.Position=UDim2.new(0,70,0,0) NG1271.Size=UDim2.new(0,50,0,25)NG1271.Parent=NG1269
NG1272=Instance.new("TextBox") NG1272.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1272.BackgroundTransparency=1
NG1272.BorderSizePixel=0 NG1272.Position=UDim2.new(0,5,0,0)NG1272.Size=UDim2.new(1,-10,1,0)NG1272.ZIndex=2 NG1272.Font=Enum.Font.ArialBold
NG1272.FontSize=Enum.FontSize.Size10
NG1272.Text=dCD([=[]=]) NG1272.TextColor3=Color3.new(1,1,1)NG1272.Parent=NG1271
NG1273=Instance.new("TextButton") NG1273.Active=true
NG1273.AutoButtonColor=false NG1273.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1273.BackgroundTransparency=1
NG1273.BorderSizePixel=0 NG1273.Selectable=true
NG1273.Size=UDim2.new(1,0,1,0) NG1273.Style=Enum.ButtonStyle.Custom
NG1273.ZIndex=3
NG1273.Font=Enum.Font.Legacy NG1273.FontSize=Enum.FontSize.Size8
NG1273.Text=dCD([=[]=])NG1273.Parent=NG1271 NG1274=Instance.new("ImageLabel")NG1274.Active=false NG1274.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1274.BackgroundTransparency=1
NG1274.BorderSizePixel=0 NG1274.Name=dCD([=[Onpxtebhaq]=])NG1274.Selectable=false
NG1274.Size=UDim2.new(1,0,1,0) NG1274.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1274.Parent=NG1271
NG1275=Instance.new("Frame") NG1275.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1275.BackgroundTransparency=1
NG1275.BorderSizePixel=0 NG1275.Name=dCD([=[L]=])NG1275.Position=UDim2.new(0,117,0,0) NG1275.Size=UDim2.new(0,50,0,25)NG1275.Parent=NG1269
NG1276=Instance.new("TextBox") NG1276.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1276.BackgroundTransparency=1
NG1276.BorderSizePixel=0 NG1276.Position=UDim2.new(0,5,0,0)NG1276.Size=UDim2.new(1,-10,1,0)NG1276.ZIndex=2 NG1276.Font=Enum.Font.ArialBold
NG1276.FontSize=Enum.FontSize.Size10
NG1276.Text=dCD([=[]=]) NG1276.TextColor3=Color3.new(1,1,1)NG1276.Parent=NG1275
NG1277=Instance.new("TextButton") NG1277.Active=true
NG1277.AutoButtonColor=false NG1277.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1277.BackgroundTransparency=1
NG1277.BorderSizePixel=0 NG1277.Selectable=true
NG1277.Size=UDim2.new(1,0,1,0) NG1277.Style=Enum.ButtonStyle.Custom
NG1277.ZIndex=3
NG1277.Font=Enum.Font.Legacy NG1277.FontSize=Enum.FontSize.Size8
NG1277.Text=dCD([=[]=])NG1277.Parent=NG1275 NG1278=Instance.new("ImageLabel")NG1278.Active=false NG1278.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1278.BackgroundTransparency=1
NG1278.BorderSizePixel=0 NG1278.Name=dCD([=[Onpxtebhaq]=])NG1278.Selectable=false
NG1278.Size=UDim2.new(1,0,1,0) NG1278.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1278.Parent=NG1275
NG1279=Instance.new("Frame") NG1279.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1279.BackgroundTransparency=1
NG1279.BorderSizePixel=0 NG1279.Name=dCD([=[M]=])NG1279.Position=UDim2.new(0,164,0,0) NG1279.Size=UDim2.new(0,50,0,25)NG1279.Parent=NG1269
NG1280=Instance.new("TextBox") NG1280.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1280.BackgroundTransparency=1
NG1280.BorderSizePixel=0 NG1280.Position=UDim2.new(0,5,0,0)NG1280.Size=UDim2.new(1,-10,1,0)NG1280.ZIndex=2 NG1280.Font=Enum.Font.ArialBold
NG1280.FontSize=Enum.FontSize.Size10
NG1280.Text=dCD([=[]=]) NG1280.TextColor3=Color3.new(1,1,1)NG1280.Parent=NG1279
NG1281=Instance.new("TextButton") NG1281.Active=true
NG1281.AutoButtonColor=false NG1281.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1281.BackgroundTransparency=1
NG1281.BorderSizePixel=0 NG1281.Selectable=true
NG1281.Size=UDim2.new(1,0,1,0) NG1281.Style=Enum.ButtonStyle.Custom
NG1281.ZIndex=3
NG1281.Font=Enum.Font.Legacy NG1281.FontSize=Enum.FontSize.Size8
NG1281.Text=dCD([=[]=])NG1281.Parent=NG1279 NG1282=Instance.new("ImageLabel")NG1282.Active=false NG1282.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1282.BackgroundTransparency=1
NG1282.BorderSizePixel=0 NG1282.Name=dCD([=[Onpxtebhaq]=])NG1282.Selectable=false
NG1282.Size=UDim2.new(1,0,1,0) NG1282.Image=dCD([=[uggc://jjj.eboybk.pbz/nffrg/?vq=127772502]=])NG1282.Parent=NG1279
NG1283=Instance.new("Frame") NG1283.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1283.BackgroundTransparency=1
NG1283.BorderSizePixel=0 NG1283.Name=dCD([=[Punatrf]=])NG1283.Position=UDim2.new(0,5,0,100) NG1283.Size=UDim2.new(1,-5,0,20)NG1283.Parent=NG1236
NG1284=Instance.new("Frame") NG1284.BackgroundColor3=Color3.new(0.294118,0.592157,0.294118)NG1284.BorderSizePixel=0
NG1284.Name=dCD([=[PbybeOne]=]) NG1284.Size=UDim2.new(1,0,0,2)NG1284.Parent=NG1283
NG1285=Instance.new("TextLabel") NG1285.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1285.BackgroundTransparency=1
NG1285.BorderSizePixel=0 NG1285.Name=dCD([=[Grkg]=])NG1285.Position=UDim2.new(0,10,0,2) NG1285.Size=UDim2.new(1,-10,0,20)NG1285.Font=Enum.Font.ArialBold NG1285.FontSize=Enum.FontSize.Size10
NG1285.Text=dCD([=[ebgngrq 0 qrterrf]=]) NG1285.TextColor3=Color3.new(1,1,1)NG1285.TextStrokeTransparency=0.5
NG1285.TextWrapped=true NG1285.TextXAlignment=Enum.TextXAlignment.Right
NG1285.Parent=NG1283
NG1286=Instance.new("TextLabel") NG1286.BackgroundColor3=Color3.new(0.639216,0.635294,0.647059)NG1286.BackgroundTransparency=1
NG1286.BorderSizePixel=0 NG1286.Name=dCD([=[RqtrFryrpgvbaGvc]=])NG1286.Position=UDim2.new(0,10,0,2) NG1286.Size=UDim2.new(1,-10,0,20)NG1286.Font=Enum.Font.ArialBold NG1286.FontSize=Enum.FontSize.Size10
NG1286.Text=dCD([=[Cerff G sbe rqtr fryrpgvba.]=]) NG1286.TextColor3=Color3.new(1,1,1)NG1286.TextStrokeTransparency=0.5
NG1286.TextWrapped=true NG1286.TextXAlignment=Enum.TextXAlignment.Left
NG1286.Parent=NG1283
DFb100j=NG1 end
wait(.1)ActiveKeys={}CurrentTool=nil function equipTool(Enu) if CurrentTool~=Enu then if CurrentTool and CurrentTool.Listeners.Unequipped then CurrentTool.Listeners.Unequipped()end
CurrentTool=Enu
if ToolType=='tool'then Tool.Handle.BrickColor=Enu.Color end for fChy5,DNPo4Wqt in pairs(Dock.ToolButtons:GetChildren())do DNPo4Wqt.BackgroundTransparency=1 end local YJ31A6_=Dock.ToolButtons:FindFirstChild(getToolName(Enu).."Button")if YJ31A6_ then YJ31A6_.BackgroundTransparency=0 end
if Enu.Listeners.Equipped then Enu.Listeners.Equipped()end end end function cloneSelection() if#Selection.Items>0 then local S8Kb={} for P32,xj1 in pairs(Selection.Items)do local rd=xj1:Clone()rd.Parent=Workspace
table.insert(S8Kb,rd)end
Selection:clear() for wtX,Y in pairs(S8Kb)do Selection:add(Y)end local UMeQ={copies=S8Kb,unapply=function(EHSv) for Ati7Oq,Tqo2jko in pairs(EHSv.copies)do if Tqo2jko then Tqo2jko.Parent=nil end end end,apply=function(uJz) Selection:clear()for qVvlt,aGkESg in pairs(uJz.copies)do if aGkESg then aGkESg.Parent=Workspace aGkESg:MakeJoints()Selection:add(aGkESg)end end end}History:add(UMeQ) local AGhdl3=RbxUtility.Create"Sound"{Name="BTActionCompletionSound",Pitch=1.5,SoundId=Assets.ActionCompletionSound,Volume=1,Parent= Player or SoundService}AGhdl3:Play()AGhdl3:Destroy() coroutine.wrap(function() for KXnNMI7S=1,0.5,-0.1 do for fL,Oj in pairs(SelectionBoxes)do Oj.Transparency=KXnNMI7S end
wait(0.1)end end)()end end function deleteSelection()if#Selection.Items==0 then return end local pGR0Ig=Support.CloneTable(Selection.Items) local bBq={targets=pGR0Ig,parents={},apply=function(i) for yCkt,irs579 in pairs(i.targets)do if irs579 then irs579.Parent=nil end end end,unapply=function(ptD) Selection:clear() for mj_P,w in pairs(ptD.targets)do if w then w.Parent=ptD.parents[w]w:MakeJoints() Selection:add(w)end end end}for Nge6L,aWnFL1 in pairs(pGR0Ig)do bBq.parents[aWnFL1]=aWnFL1.Parent aWnFL1.Parent=nil end
History:add(bBq)end function prismSelect()if#Selection.Items==0 then return end
local D={}local R={} local u51=Support.GetAllDescendants(Workspace) for WSlpP,xSMd in pairs(u51)do if xSMd:IsA('BasePart')and not Selection:find(xSMd)then table.insert(R,xSMd)end end
local O0NUxa={} for vYmD9ed,Cez in pairs(R)do O0NUxa[Cez]=0 for vYmD9ed,NvSMm in pairs(Selection.Items)do local wRpQf=NvSMm.CFrame:toObjectSpace(Cez.CFrame)local ed9P=NvSMm.Size/2 if   (math.abs(wRpQf.x)<=ed9P.x)and(math.abs(wRpQf.y)<=ed9P.y)and(math.abs(wRpQf.z)<=ed9P.z)then O0NUxa[Cez]=O0NUxa[Cez]+1 end end end
local RngfRQ6g=Support.CloneTable(Selection.Items)local F={} for NJ5,bpAJ in pairs(RngfRQ6g)do F[bpAJ]=bpAJ.Parent
bpAJ.Parent=nil end
for UdPyHc,SciVUxEq in pairs(R)do if O0NUxa[SciVUxEq]>0 then Selection:add(SciVUxEq)end end History:add({selection_parts=RngfRQ6g,selection_part_parents=F,new_selection=Support.CloneTable(Selection.Items),apply=function(Te) Selection:clear()for WN,f in pairs(Te.selection_parts)do f.Parent=nil end
for FleDs3,LP in pairs(Te.new_selection)do Selection:add(LP)end end,unapply=function(RLovoVo) Selection:clear() for Je6Srpf8,p in pairs(RLovoVo.selection_parts)do p.Parent=RLovoVo.selection_part_parents[p]Selection:add(p)end end})end
function toggleHelp()if not Dock then return end Dock.HelpInfo.Visible=not Dock.HelpInfo.Visible end function getToolName(Z0RFr5F) local _Myb=Support.FindTableOccurrences(Tools,Z0RFr5F)if#_Myb>0 then return _Myb[1]end end function isSelectable(Zq) if   not Zq or not Zq.Parent or not Zq:IsA("BasePart")or Zq.Locked or Selection:find(Zq)or Groups:IsPartIgnored(Zq)then return false end
return true end function IsVersionOutdated() local TKS=MarketplaceService:GetProductInfo(ToolAssetID,Enum.InfoType.Asset) local DUSiwPZm=TKS.Description:match('%[Version: (.+)%]')local QSjpjN5="1.4.5"if DUSiwPZm~=QSjpjN5 then return true end
return false end
HttpAvailable,HttpAvailabilityError=HttpInterface.Test() if ToolType== 'plugin'then HttpService.Changed:connect(function() HttpAvailable,HttpAvailabilityError=HttpInterface:WaitForChild('Test'):InvokeServer()end)end
local XL_=false function ShowStartupNotifications()if XL_ then return end
XL_=true local M3ptD1Cf=DFb100j.BTStartupNotificationContainer:Clone()M3ptD1Cf.WelcomeFex.Visible=true
if not HttpAvailable and HttpAvailabilityError== 'Http requests are not enabled'then M3ptD1Cf.HttpDisabledWarning.Visible=true end if  not HttpAvailable and HttpAvailabilityError=='Http requests can only be executed by game server'then M3ptD1Cf.SoloWarning.Visible=true end if HttpAvailable then M3ptD1Cf.HttpEnabledWarning.Visible=true end if IsVersionOutdated()then if ToolType=='tool'then M3ptD1Cf.ToolUpdateNotification.Visible=true elseif ToolType=='plugin'then M3ptD1Cf.PluginUpdateNotification.Visible=true end end local function B()local d=0
local z0=M3ptD1Cf:GetChildren() for I_bHR9bD,YJha in pairs(z0)do YJha.Position=UDim2.new(YJha.Position.X.Scale,YJha.Position.X.Offset,YJha.Position.Y.Scale,( d==0)and 0 or(d+10)) local g9QyV=YJha.Position.Y.Offset+YJha.Size.Y.Offset
if YJha.Visible and g9QyV>d then d=g9QyV end end M3ptD1Cf.Size=UDim2.new(M3ptD1Cf.Size.X.Scale,M3ptD1Cf.Size.X.Offset,0,d)end
B()local jv= (UI.AbsoluteSize.x-M3ptD1Cf.Size.X.Offset)/2
local oTpq=UI.AbsoluteSize.y+ M3ptD1Cf.Size.Y.Offset M3ptD1Cf.Position=UDim2.new(0,jv,0,oTpq)M3ptD1Cf.Parent=UI local function CjPV()local An_hQ3m= (UI.AbsoluteSize.y-M3ptD1Cf.Size.Y.Offset)/2 M3ptD1Cf:TweenPosition(UDim2.new(0,jv,0,An_hQ3m),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.2)end
CjPV() for S,eMj5b1DD in pairs(M3ptD1Cf:GetChildren())do if eMj5b1DD.Visible then eMj5b1DD.OKButton.MouseButton1Click:connect(function() eMj5b1DD:Destroy()B()CjPV()end) eMj5b1DD.HelpButton.MouseButton1Click:connect(function() eMj5b1DD.HelpButton:Destroy()eMj5b1DD.ButtonSeparator:Destroy() eMj5b1DD.OKButton:TweenSize(UDim2.new(1,0,0,22),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.2)eMj5b1DD.Notice:Destroy() eMj5b1DD.Help.Visible=true eMj5b1DD:TweenSize(UDim2.new(eMj5b1DD.Size.X.Scale,eMj5b1DD.Size.X.Offset,eMj5b1DD.Size.Y.Scale,eMj5b1DD.Help.NotificationSize.Value),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.2,true,function() B()CjPV()end)end)end end
if ToolType=='tool'then Tool.Unequipped:connect(function()if M3ptD1Cf.Visible then M3ptD1Cf.Visible=false M3ptD1Cf:Destroy()end end)end end
clicking=false
selecting=false
click_x,click_y=0,0
override_selection=false SelectionBoxes={}SelectionExistenceListeners={} SelectionBoxColor=BrickColor.new("Cyan")TargetBox=nil
Connections={} UI=RbxUtility.Create"ScreenGui"{Name="Building Tools by F3X (UI)"} if ToolType=='tool'then UI.Parent=GUIContainer elseif ToolType=='plugin'then UI.Parent=CoreGui end
Dragger=nil function updateSelectionBoxColor()for lDdmS,k1kp870h in pairs(SelectionBoxes)do k1kp870h.Color=SelectionBoxColor end end Selection={["Items"]={},["Changed"]=RbxUtility.CreateSignal(),["ItemAdded"]=RbxUtility.CreateSignal(),["ItemRemoved"]=RbxUtility.CreateSignal(),["Cleared"]=RbxUtility.CreateSignal(),["find"]=function(Xfv1_F,F74YQ) for SHlZ8Rw,FxP66 in pairs(Xfv1_F.Items)do if FxP66 ==F74YQ then return SHlZ8Rw end end end,["add"]=function(y,Ou)if not isSelectable(Ou)then return false end
if #Support.FindTableOccurrences(y.Items,Ou)>0 then return false end table.insert(y.Items,Ou) if ToolType=='tool'then SelectionBoxes[Ou]=Instance.new("SelectionBox",UI)SelectionBoxes[Ou].Name="BTSelectionBox" SelectionBoxes[Ou].Color=SelectionBoxColor
SelectionBoxes[Ou].Adornee=Ou SelectionBoxes[Ou].LineThickness=0.05
SelectionBoxes[Ou].Transparency=0.5 end if Ou==TargetBox.Adornee then TargetBox.Adornee=nil end SelectionExistenceListeners[Ou]=Ou.AncestryChanged:connect(function(AbN,lINgqxG1)if lINgqxG1 ==nil then Selection:remove(Ou)end end)y:focus(Ou)y.ItemAdded:fire(Ou) y.Changed:fire()end,["remove"]=function(Tz4j,vUctRT,ry0d9cxF)if not Tz4j:find(vUctRT)then return false end local fdMS0Bi=SelectionBoxes[vUctRT]if fdMS0Bi then fdMS0Bi:Destroy()end SelectionBoxes[vUctRT]=nil table.remove(Tz4j.Items,Tz4j:find(vUctRT))if Tz4j.Last==vUctRT then Tz4j:focus((#Tz4j.Items>0)and Tz4j.Items[#Tz4j.Items]or nil)end SelectionExistenceListeners[vUctRT]:disconnect()SelectionExistenceListeners[vUctRT]=nil Tz4j.ItemRemoved:fire(vUctRT,ry0d9cxF)Tz4j.Changed:fire()end,["clear"]=function(jUfRhXXt) for bncqpLFj,c9P3 in pairs(Support.CloneTable(jUfRhXXt.Items))do jUfRhXXt:remove(c9P3,true)end
jUfRhXXt.Cleared:fire()end,["focus"]=function(D,A) D.Last=A
D.Changed:fire()end}local WYdR=CFrame.new
local QKKks_zt=table.insert local Are7xU=CFrame.new().toWorldSpace
local yxjl=math.min
local ZG=math.max function calculateExtents(cO3SXQC,qiw,bQRP)local K5
local M=0 for gm,jwJufiF in pairs(cO3SXQC)do M=M+1
K5=jwJufiF end
if M==0 then return end local ZubW5sf=qiw and qiw['Minimum']or K5['Position'] local VLlBaUgt=qiw and qiw['Maximum']or K5['Position']local QniH,j,x_BU2=ZubW5sf['x'],ZubW5sf['y'],ZubW5sf['z'] local AFii,Au,fgK=VLlBaUgt['x'],VLlBaUgt['y'],VLlBaUgt['z'] for YogtAPf,q7h in pairs(cO3SXQC)do if not(q7h.Anchored and qiw)then local WS=q7h['CFrame']local Uee8Une=q7h['Size']/2 local UtI,L,qx27=Uee8Une['x'],Uee8Une['y'],Uee8Une['z']local whvO
local kpbY,m_gHw,RFOr={},{},{}whvO=Are7xU(WS,WYdR(UtI,L,qx27)) QKKks_zt(kpbY,whvO['x'])QKKks_zt(m_gHw,whvO['y']) QKKks_zt(RFOr,whvO['z'])whvO=Are7xU(WS,WYdR(-UtI,L,qx27)) QKKks_zt(kpbY,whvO['x'])QKKks_zt(m_gHw,whvO['y']) QKKks_zt(RFOr,whvO['z'])whvO=Are7xU(WS,WYdR(UtI,-L,qx27)) QKKks_zt(kpbY,whvO['x'])QKKks_zt(m_gHw,whvO['y']) QKKks_zt(RFOr,whvO['z'])whvO=Are7xU(WS,WYdR(UtI,L,-qx27)) QKKks_zt(kpbY,whvO['x'])QKKks_zt(m_gHw,whvO['y']) QKKks_zt(RFOr,whvO['z'])whvO=Are7xU(WS,WYdR(-UtI,L,-qx27)) QKKks_zt(kpbY,whvO['x'])QKKks_zt(m_gHw,whvO['y']) QKKks_zt(RFOr,whvO['z'])whvO=Are7xU(WS,WYdR(-UtI,-L,qx27)) QKKks_zt(kpbY,whvO['x'])QKKks_zt(m_gHw,whvO['y']) QKKks_zt(RFOr,whvO['z'])whvO=Are7xU(WS,WYdR(UtI,-L,-qx27)) QKKks_zt(kpbY,whvO['x'])QKKks_zt(m_gHw,whvO['y']) QKKks_zt(RFOr,whvO['z'])whvO=Are7xU(WS,WYdR(-UtI,-L,-qx27)) QKKks_zt(kpbY,whvO['x'])QKKks_zt(m_gHw,whvO['y']) QKKks_zt(RFOr,whvO['z'])QniH=yxjl(QniH,unpack(kpbY)) j=yxjl(j,unpack(m_gHw))x_BU2=yxjl(x_BU2,unpack(RFOr)) AFii=ZG(AFii,unpack(kpbY))Au=ZG(Au,unpack(m_gHw))fgK=ZG(fgK,unpack(RFOr))end end if bQRP then return{Minimum={x=QniH,y=j,z=x_BU2},Maximum={x=AFii,y=Au,z=fgK}}else local NL,g0d1ms_,Xmu5=AFii-QniH,Au-j,fgK-x_BU2 local lC3P=Vector3.new(NL,g0d1ms_,Xmu5) local QwHnJ1MC=CFrame.new(QniH+ (AFii-QniH)/2,j+ (Au-j)/2,x_BU2+ (fgK-x_BU2)/2)return lC3P,QwHnJ1MC end end
if ToolType=='plugin'then Selection.Changed:connect(function() SelectionService:Set(Selection.Items)end)end
Tools={} function createDropdown() local giqW=RbxUtility.Create"Frame"{Name="Dropdown",Size=UDim2.new(0,20,0,20),BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true} RbxUtility.Create"ImageLabel"{Parent=giqW,Name="Arrow",BackgroundTransparency=1,BorderSizePixel=0,Image=Assets.ExpandArrow,Position=UDim2.new(1,-21,0,3),Size=UDim2.new(0,20,0,20),ZIndex=3} local UJP9j={Frame=giqW,_options={},addOption=function(_nBsWM3x,D5)table.insert(_nBsWM3x._options,D5) local I=RbxUtility.Create"TextButton"{Parent=_nBsWM3x.Frame,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.3,BorderColor3=Color3.new( 27/255,42/255,53/255),BorderSizePixel=1,Name=D5,Position=UDim2.new( math.ceil(#_nBsWM3x._options/9)-1,0,0,25* ( (#_nBsWM3x._options%9 ==0)and 9 or(#_nBsWM3x._options%9))),Size=UDim2.new(1,0,0,25),ZIndex=3,Text=""} local rgZln=RbxUtility.Create"TextLabel"{Parent=I,BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(0,6,0,0),Size=UDim2.new(1,-30,1,0),ZIndex=3,Font=Enum.Font.ArialBold,FontSize=Enum.FontSize.Size10,Text=D5,TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center}return I end,selectOption=function(vB,vFea) vB.Frame.MainButton.CurrentOption.Text=vFea end,open=false,toggle=function(_T5) if _T5.open then _T5.Frame.MainButton.BackgroundTransparency=0.3
_T5.Frame.ClipsDescendants=true
_T5.open=false else _T5.Frame.MainButton.BackgroundTransparency=0
_T5.Frame.ClipsDescendants=false
_T5.open=true end end} local SObxoJk=RbxUtility.Create"TextButton"{Parent=giqW,Name="MainButton",BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.3,BorderColor3=Color3.new(27/255,42/255, 53/255),BorderSizePixel=1,Position=UDim2.new(0,0,0,0),Size=UDim2.new(1,0,0,25),ZIndex=2,Text="",[RbxUtility.Create.E"MouseButton1Up"]=function() UJP9j:toggle()end} RbxUtility.Create"TextLabel"{Parent=SObxoJk,Name="CurrentOption",BackgroundTransparency=1,BorderSizePixel=0,Position=UDim2.new(0,6,0,0),Size=UDim2.new(1,-30,1,0),ZIndex=3,Font=Enum.Font.ArialBold,FontSize=Enum.FontSize.Size10,Text="",TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center}return UJP9j end Select2D={["enabled"]=false,["GUI"]=nil,["Connections"]={},["start"]=function(fx)if fx.enabled then return end
fx.enabled=true fx.GUI=RbxUtility.Create"ScreenGui"{Name="BTSelectionRectangle",Parent=UI} local ZkXY=RbxUtility.Create"Frame"{Name="Rectangle",Active=false,Parent=fx.GUI,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=0.5,BorderSizePixel=0,Position=UDim2.new(0,math.min(click_x,Mouse.X),0,math.min(click_y,Mouse.Y)),Size=UDim2.new(0, math.max(click_x,Mouse.X)-math.min(click_x,Mouse.X),0, math.max(click_y,Mouse.Y)-math.min(click_y,Mouse.Y))} fx.Connections.SelectionResize=Mouse.Move:connect(function() ZkXY.Position=UDim2.new(0,math.min(click_x,Mouse.X),0,math.min(click_y,Mouse.Y)) ZkXY.Size=UDim2.new(0,math.max(click_x,Mouse.X)-math.min(click_x,Mouse.X),0, math.max(click_y,Mouse.Y)-math.min(click_y,Mouse.Y))end) fx.Connections.SelectionEnd=UserInputService.InputEnded:connect(function(sWJA) if sWJA.UserInputType== Enum.UserInputType.MouseButton1 then fx:select()fx:finish()end end)end,["select"]=function(NVvo)if not NVvo.enabled then return end for P2Kd8,asrUjwf in pairs(Support.GetAllDescendants(Workspace))do if isSelectable(asrUjwf)then local Q,ya253Ad=Workspace.CurrentCamera:WorldToScreenPoint(asrUjwf.Position) if Q and ya253Ad then local T49bAP=Q.x>=NVvo.GUI.Rectangle.AbsolutePosition.x local bS5Jz=Q.x<= (NVvo.GUI.Rectangle.AbsolutePosition.x+ NVvo.GUI.Rectangle.AbsoluteSize.x) local yl=Q.y>=NVvo.GUI.Rectangle.AbsolutePosition.y local srV=Q.y<= (NVvo.GUI.Rectangle.AbsolutePosition.y+ NVvo.GUI.Rectangle.AbsoluteSize.y)if T49bAP and bS5Jz and yl and srV then Selection:add(asrUjwf)end end end end end,["finish"]=function(tSO4)if not tSO4.enabled then return end for ALU1Lf,odzL_ in pairs(tSO4.Connections)do odzL_:disconnect()tSO4.Connections[ALU1Lf]=nil end
tSO4.GUI:Destroy()tSO4.GUI=nil
tSO4.enabled=false end} SelectEdge={["enabled"]=false,["started"]=false,["Marker"]=nil,["MarkerOutline"]=RbxUtility.Create"SelectionBox"{Color=BrickColor.new("Institutional white"),Parent=UI,Name="BTEdgeSelectionMarkerOutline"},["Connections"]={},["start"]=function(rHhv,DUv3)if rHhv.started then return end rHhv.Connections.KeyListener=Mouse.KeyDown:connect(function(qM23K) local qM23K=qM23K:lower()local HnNik4=qM23K:byte()if qM23K=="t"and#Selection.Items>0 then rHhv:enable(DUv3)end end)rHhv.started=true end,["enable"]=function(Tb,k)if Tb.enabled then return end Tb.Connections.MoveListener=Mouse.Move:connect(function()if not Selection:find(Mouse.Target)then return end
local g={}local mOxUSY={} local QKKks_zt=table.insert
local t=CFrame.new
local CY=Mouse.Target.CFrame
local Are7xU=CY.toWorldSpace
local EPz43s= Mouse.Target.Size/2
local zR,ZiGUK4j,X5xyw_Y=EPz43s.x,EPz43s.y,EPz43s.z QKKks_zt(mOxUSY,Are7xU(CY,t(zR,ZiGUK4j,X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(-zR,ZiGUK4j,X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(zR,-ZiGUK4j,X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(zR,ZiGUK4j,-X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(-zR,ZiGUK4j,-X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(-zR,-ZiGUK4j,X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(zR,-ZiGUK4j,-X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(-zR,-ZiGUK4j,-X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(zR,ZiGUK4j,0))) QKKks_zt(mOxUSY,Are7xU(CY,t(zR,0,X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(0,ZiGUK4j,X5xyw_Y)))QKKks_zt(mOxUSY,Are7xU(CY,t(zR,0,0))) QKKks_zt(mOxUSY,Are7xU(CY,t(0,ZiGUK4j,0))) QKKks_zt(mOxUSY,Are7xU(CY,t(0,0,X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(-zR,ZiGUK4j,0))) QKKks_zt(mOxUSY,Are7xU(CY,t(-zR,0,X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(0,-ZiGUK4j,X5xyw_Y)))QKKks_zt(mOxUSY,Are7xU(CY,t(-zR,0,0)))QKKks_zt(mOxUSY,Are7xU(CY,t(0, -ZiGUK4j,0)))QKKks_zt(mOxUSY,Are7xU(CY,t(0,0, -X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(zR, -ZiGUK4j,0))) QKKks_zt(mOxUSY,Are7xU(CY,t(zR,0,-X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(0,ZiGUK4j,-X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(-zR,-ZiGUK4j,0))) QKKks_zt(mOxUSY,Are7xU(CY,t(-zR,0,-X5xyw_Y))) QKKks_zt(mOxUSY,Are7xU(CY,t(0,-ZiGUK4j,-X5xyw_Y)))for y7AFV,BUtgk5wL in pairs(mOxUSY)do g[y7AFV]=(Mouse.Hit.p-BUtgk5wL.p).magnitude end
local Zb3oLBm1=1 for yvkTFEw,FPuu in pairs(g)do if FPuu<g[Zb3oLBm1]then Zb3oLBm1=yvkTFEw end end
local gVS=mOxUSY[Zb3oLBm1] if Tb.Marker then Tb.Marker:Destroy()end Tb.Marker=RbxUtility.Create"Part"{Name="BTEdgeSelectionMarker",Anchored=true,Locked=true,CanCollide=false,Transparency=1,FormFactor=Enum.FormFactor.Custom,Size=Vector3.new(0.2,0.2,0.2),CFrame=gVS}Tb.MarkerOutline.Adornee=Tb.Marker end) Tb.Connections.ClickListener=Mouse.Button1Up:connect(function()override_selection=true Tb:select(k)end)Tb.enabled=true end,["select"]=function(IM6lQ1nN,cdRq) if not IM6lQ1nN.enabled or not IM6lQ1nN.Marker then return end
IM6lQ1nN.MarkerOutline.Adornee=IM6lQ1nN.Marker cdRq(IM6lQ1nN.Marker)IM6lQ1nN.Marker=nil
IM6lQ1nN:disable()end,["disable"]=function(rk6C)if not rk6C.enabled then return end if rk6C.Connections.ClickListener then rk6C.Connections.ClickListener:disconnect()rk6C.Connections.ClickListener=nil end if rk6C.Connections.MoveListener then rk6C.Connections.MoveListener:disconnect()rk6C.Connections.MoveListener=nil end
if rk6C.Marker then rk6C.Marker:Destroy()end rk6C.Marker=nil
rk6C.MarkerOutline.Adornee=nil
rk6C.enabled=false end,["stop"]=function(a4EodrlS)if not a4EodrlS.started then return end
a4EodrlS:disable()for QDUH3,FZNkY in pairs(a4EodrlS.Connections)do FZNkY:disconnect() a4EodrlS.Connections[QDUH3]=nil end
if a4EodrlS.Marker then a4EodrlS.Marker:Destroy()end
a4EodrlS.started=false end} History={["Data"]={},["index"]=0,["Changed"]=RbxUtility.CreateSignal(),["undo"]=function(AMQfXns)if AMQfXns.index-1 <0 then return end
local N=AMQfXns.Data[AMQfXns.index] N:unapply()AMQfXns.index=AMQfXns.index-1 AMQfXns.Changed:fire()end,["redo"]=function(Zv1xWmbK)if Zv1xWmbK.index+1 >#Zv1xWmbK.Data then return end
Zv1xWmbK.index= Zv1xWmbK.index+1 local usLtv=Zv1xWmbK.Data[Zv1xWmbK.index]usLtv:apply()Zv1xWmbK.Changed:fire()end,["add"]=function(D0WSWx,fI4Jq_JC)D0WSWx.Data[ D0WSWx.index+1]=fI4Jq_JC D0WSWx.index=D0WSWx.index+1 for CK17=D0WSWx.index+1,#D0WSWx.Data do D0WSWx.Data[CK17]=nil end
D0WSWx.Changed:fire()end}if ToolType=='plugin'then History.Changed:connect(function() ChangeHistoryService:SetWaypoint'Building Tools by F3X'end)end ColorPicker={["enabled"]=false,["callback"]= nil,["track_mouse"]=nil,["hue"]=0,["saturation"]=1,["value"]=1,["GUI"]=nil,["Connections"]={},["start"]=function(EN6EGq,_Nz,Lsvt0Xp) if EN6EGq.enabled then EN6EGq:cancel()end
EN6EGq.enabled=true EN6EGq.GUI=DFb100j.BTHSVColorPicker:Clone()EN6EGq.GUI.Parent=UI
EN6EGq.callback=_Nz local Lsvt0Xp=Lsvt0Xp or Color3.new(1,0,0) EN6EGq:_changeColor(Support.RGBToHSV(Lsvt0Xp.r,Lsvt0Xp.g,Lsvt0Xp.b)) table.insert(EN6EGq.Connections,EN6EGq.GUI.HueSaturation.MouseButton1Down:connect(function(Js8fS1VE,nfU) EN6EGq.track_mouse='hue-saturation'EN6EGq:_onMouseMove(Js8fS1VE,nfU)end)) table.insert(EN6EGq.Connections,EN6EGq.GUI.HueSaturation.MouseButton1Up:connect(function()EN6EGq.track_mouse= nil end)) table.insert(EN6EGq.Connections,EN6EGq.GUI.MouseMoved:connect(function(Zt78U,B_tZsz) EN6EGq:_onMouseMove(Zt78U,B_tZsz)end)) table.insert(EN6EGq.Connections,EN6EGq.GUI.Value.MouseButton1Down:connect(function(NUeM,DiSdlMR3) EN6EGq.track_mouse='value'EN6EGq:_onMouseMove(NUeM,DiSdlMR3)end)) table.insert(EN6EGq.Connections,EN6EGq.GUI.Value.MouseButton1Up:connect(function()EN6EGq.track_mouse= nil end)) table.insert(EN6EGq.Connections,EN6EGq.GUI.OkButton.MouseButton1Up:connect(function() EN6EGq:finish()end)) table.insert(EN6EGq.Connections,EN6EGq.GUI.CancelButton.MouseButton1Up:connect(function() EN6EGq:cancel()end)) table.insert(EN6EGq.Connections,EN6EGq.GUI.HueOption.Input.TextButton.MouseButton1Down:connect(function() EN6EGq.GUI.HueOption.Input.TextBox:CaptureFocus()end)) table.insert(EN6EGq.Connections,EN6EGq.GUI.HueOption.Input.TextBox.FocusLost:connect(function(nE) local CIkqRkzw=tonumber(EN6EGq.GUI.HueOption.Input.TextBox.Text) if CIkqRkzw then if CIkqRkzw>360 then CIkqRkzw=360 elseif CIkqRkzw<0 then CIkqRkzw=0 end EN6EGq:_changeColor(CIkqRkzw,EN6EGq.saturation,EN6EGq.value)else EN6EGq:_updateGUI()end end)) table.insert(EN6EGq.Connections,EN6EGq.GUI.SaturationOption.Input.TextButton.MouseButton1Down:connect(function() EN6EGq.GUI.SaturationOption.Input.TextBox:CaptureFocus()end)) table.insert(EN6EGq.Connections,EN6EGq.GUI.SaturationOption.Input.TextBox.FocusLost:connect(function(sBI) local vyewX=tonumber((EN6EGq.GUI.SaturationOption.Input.TextBox.Text:gsub('%%',''))) if vyewX then if vyewX>100 then vyewX=100 elseif vyewX<0 then vyewX=0 end
EN6EGq:_changeColor(EN6EGq.hue, vyewX/100,EN6EGq.value)else EN6EGq:_updateGUI()end end)) table.insert(EN6EGq.Connections,EN6EGq.GUI.ValueOption.Input.TextButton.MouseButton1Down:connect(function() EN6EGq.GUI.ValueOption.Input.TextBox:CaptureFocus()end)) table.insert(EN6EGq.Connections,EN6EGq.GUI.ValueOption.Input.TextBox.FocusLost:connect(function(ZXMlRMR) local CCo8Y=tonumber((EN6EGq.GUI.ValueOption.Input.TextBox.Text:gsub('%%',''))) if CCo8Y then if CCo8Y<0 then CCo8Y=0 elseif CCo8Y>100 then CCo8Y=100 end
EN6EGq:_changeColor(EN6EGq.hue,EN6EGq.saturation, CCo8Y/100)else EN6EGq:_updateGUI()end end))end,["_onMouseMove"]=function(hx1fY90,dt7v,HBjl)if not hx1fY90.track_mouse then return end if hx1fY90.track_mouse=='hue-saturation'then local tcVr,r=dt7v-hx1fY90.GUI.HueSaturation.AbsolutePosition.x, HBjl-hx1fY90.GUI.HueSaturation.AbsolutePosition.y
if tcVr<0 then tcVr=0 elseif tcVr>hx1fY90.GUI.HueSaturation.AbsoluteSize.x then tcVr=hx1fY90.GUI.HueSaturation.AbsoluteSize.x end
if r<0 then r=0 elseif r> hx1fY90.GUI.HueSaturation.AbsoluteSize.y then r=hx1fY90.GUI.HueSaturation.AbsoluteSize.y end hx1fY90:_changeColor(359* tcVr/209,1-r/200,hx1fY90.value)elseif hx1fY90.track_mouse=='value'then local htj=HBjl- hx1fY90.GUI.Value.AbsolutePosition.y
if htj<0 then htj=0 elseif htj> hx1fY90.GUI.Value.AbsoluteSize.y then htj=hx1fY90.GUI.Value.AbsoluteSize.y end
hx1fY90:_changeColor(hx1fY90.hue,hx1fY90.saturation, 1-htj/200)end end,["_changeColor"]=function(Ltq_xgJ,Re,cG3HJLZ,LG)if Re~=Re then Re=359 end
Ltq_xgJ.hue=Re
Ltq_xgJ.saturation=cG3HJLZ==0 and 0.01 or cG3HJLZ
Ltq_xgJ.value=LG Ltq_xgJ:_updateGUI()end,["_updateGUI"]=function(x__e0OAv) x__e0OAv.GUI.HueSaturation.Cursor.Position=UDim2.new(0, 209*x__e0OAv.hue/360-8,0, (1-x__e0OAv.saturation)*200-8) x__e0OAv.GUI.Value.Cursor.Position=UDim2.new(0,-2,0, (1-x__e0OAv.value)*200-8) local F9=Color3.new(Support.HSVToRGB(x__e0OAv.hue,x__e0OAv.saturation,x__e0OAv.value))x__e0OAv.GUI.ColorDisplay.BackgroundColor3=F9 x__e0OAv.GUI.Value.ColorBG.BackgroundColor3=Color3.new(Support.HSVToRGB(x__e0OAv.hue,x__e0OAv.saturation,1)) x__e0OAv.GUI.HueOption.Bar.BackgroundColor3=F9 x__e0OAv.GUI.SaturationOption.Bar.BackgroundColor3=F9 x__e0OAv.GUI.ValueOption.Bar.BackgroundColor3=F9 x__e0OAv.GUI.HueOption.Input.TextBox.Text=math.floor(x__e0OAv.hue) x__e0OAv.GUI.SaturationOption.Input.TextBox.Text=math.floor( x__e0OAv.saturation*100).."%" x__e0OAv.GUI.ValueOption.Input.TextBox.Text=math.floor( x__e0OAv.value*100).."%"end,["finish"]=function(IbKWp)if not IbKWp.enabled then return end
if IbKWp.GUI then IbKWp.GUI:Destroy()end
IbKWp.GUI=nil
IbKWp.track_mouse=nil for j,nY4CweuF in pairs(IbKWp.Connections)do nY4CweuF:disconnect()IbKWp.Connections[j]=nil end IbKWp.callback(IbKWp.hue,IbKWp.saturation,IbKWp.value)IbKWp.callback=nil
IbKWp.enabled=false end,["cancel"]=function(Ttb)if not Ttb.enabled then return end if Ttb.GUI then Ttb.GUI:Destroy()end
Ttb.GUI=nil
Ttb.track_mouse=nil for wIat2P0,m7M in pairs(Ttb.Connections)do m7M:disconnect()Ttb.Connections[wIat2P0]=nil end
Ttb.callback()Ttb.callback=nil
Ttb.enabled=false end}ExportInterface={} ExportInterface.Export=function(J8) print("preforming ExportInterface.Export")local VchN={Workspace=game:GetService'Workspace'} local ws7lX6m_=game:GetService'HttpService'local cXif=script.Parent
local UV=script.Parent.Parent local o6kB=require(UV:WaitForChild'SupportLibrary') function _generateSerializationID() local la={"0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"}local W="" for Ihh6yjj=1,5 do W=W.. (la[math.random(#la)])end
return W end function _splitNumberListString(q5)local hgc6Q=o6kB.SplitString(q5,", ")for mIJ_kc4,J in pairs(hgc6Q)do hgc6Q[mIJ_kc4]=tonumber(J)end
return hgc6Q end function _getSerializationPartType(uUw95D) local KRLJOGI={Normal=1,Truss=2,Wedge=3,Corner=4,Cylinder=5,Ball=6,Seat=7,VehicleSeat=8,Spawn=9} if uUw95D.ClassName=="Part"then if uUw95D.Shape==Enum.PartType.Block then return KRLJOGI.Normal elseif uUw95D.Shape==Enum.PartType.Cylinder then return KRLJOGI.Cylinder elseif uUw95D.Shape==Enum.PartType.Ball then return KRLJOGI.Ball end elseif uUw95D.ClassName=="Seat"then return KRLJOGI.Seat elseif uUw95D.ClassName=="VehicleSeat"then return KRLJOGI.VehicleSeat elseif uUw95D.ClassName=="SpawnLocation"then return KRLJOGI.Spawn elseif uUw95D.ClassName=="WedgePart"then return KRLJOGI.Wedge elseif uUw95D.ClassName=="CornerWedgePart"then return KRLJOGI.Corner elseif uUw95D.ClassName=="TrussPart"then return KRLJOGI.Truss end end function _serializeParts(Gns3m_)local f={version=1,parts={}}local _zxBo={}local gN={}local oZs2khg=tick() for Bu1tX_x3,m0 in pairs(Gns3m_)do local n=_generateSerializationID() local Q={_getSerializationPartType(m0),_splitNumberListString(tostring(m0.Size)),_splitNumberListString(tostring(m0.CFrame)),m0.BrickColor.Number,m0.Material.Value,m0.Anchored,m0.CanCollide,m0.Reflectance,m0.Transparency,m0.TopSurface.Value,m0.BottomSurface.Value,m0.LeftSurface.Value,m0.RightSurface.Value,m0.FrontSurface.Value,m0.BackSurface.Value}f.parts[n]=Q
_zxBo[n]=m0
gN[m0]=n end
local pSEIak={} for CoiGQD,KR7 in pairs(_zxBo)do if KR7:IsA("BasePart")then for a,P5 in pairs(KR7:GetChildren())do if  P5.Name=='BTWeld'and P5:IsA'Weld'and gN[P5.Part0]and gN[P5.Part1]then table.insert(pSEIak,P5)end end end end if#pSEIak>0 then f.welds={} for h,TCVpKFp in pairs(pSEIak)do local NY=_generateSerializationID() local hEVRc={gN[TCVpKFp.Part0],gN[TCVpKFp.Part1],_splitNumberListString(tostring(TCVpKFp.C1))}f.welds[NY]=hEVRc
_zxBo[NY]=TCVpKFp
gN[TCVpKFp]=NY end end
local AkjIt={} for BA6zaoJ,Y7 in pairs(Gns3m_)do local g=o6kB.GetChildOfClass(Y7,"SpecialMesh")if g then table.insert(AkjIt,g)end end if#AkjIt>0 then f.meshes={} for jtL2,DA in pairs(AkjIt)do local d7K3=_generateSerializationID() local Ozih058u={gN[DA.Parent],DA.MeshType.Value,_splitNumberListString(tostring(DA.Scale)),DA.MeshId,DA.TextureId,_splitNumberListString(tostring(DA.VertexColor))}f.meshes[d7K3]=Ozih058u
_zxBo[d7K3]=DA
gN[DA]=d7K3 end end
local ox={} for oW9bf,u in pairs(Gns3m_)do local rZrrL=o6kB.GetChildrenOfClass(u,"Texture") for oW9bf,QXFNNY in pairs(rZrrL)do table.insert(ox,QXFNNY)end
local E4a=o6kB.GetChildrenOfClass(u,"Decal")for oW9bf,e in pairs(E4a)do table.insert(ox,e)end end if#ox>0 then f.textures={} for BH,xD in pairs(ox)do local fl
if xD.ClassName=="Decal"then fl=1 elseif xD.ClassName=="Texture"then fl=2 end local QCv=_generateSerializationID() local qd_HCf={gN[xD.Parent],fl,xD.Face.Value,xD.Texture,xD.Transparency,fl==2 and xD.StudsPerTileU or nil, fl==2 and xD.StudsPerTileV or nil}f.textures[QCv]=qd_HCf
_zxBo[QCv]=xD
gN[xD]=QCv end end
local y5FoBZ5={} for CU,M1ywSQ in pairs(Gns3m_)do local g=o6kB.GetChildrenOfClass(M1ywSQ,"Light",true) for CU,hPc4e3hn in pairs(g)do table.insert(y5FoBZ5,hPc4e3hn)end end if#y5FoBZ5 >0 then f.lights={} for m,Rlb in pairs(y5FoBZ5)do local KgX
if Rlb:IsA("PointLight")then KgX=1 elseif Rlb:IsA("SpotLight")then KgX=2 end local SXr=_generateSerializationID() local IZQg6shq={gN[Rlb.Parent],KgX,_splitNumberListString(tostring(Rlb.Color)),Rlb.Brightness,Rlb.Range,Rlb.Shadows, KgX==2 and Rlb.Angle or nil,KgX==2 and Rlb.Face.Value or nil}f.lights[SXr]=IZQg6shq
_zxBo[SXr]=Rlb
gN[Rlb]=SXr end end
local VXwusjUq={} for bz,wL in pairs(Gns3m_)do table.insert(VXwusjUq,o6kB.GetChildOfClass(wL,'Smoke')) table.insert(VXwusjUq,o6kB.GetChildOfClass(wL,'Fire')) table.insert(VXwusjUq,o6kB.GetChildOfClass(wL,'Sparkles'))end if#VXwusjUq>0 then f.decorations={} for BSDnLt_,vQ6pTDbn in pairs(VXwusjUq)do local P if vQ6pTDbn:IsA('Smoke')then P=1 elseif vQ6pTDbn:IsA('Fire')then P=2 elseif vQ6pTDbn:IsA('Sparkles')then P=3 end
local W=_generateSerializationID() local CDG3os={gN[vQ6pTDbn.Parent],P} if P==1 then CDG3os[3]=_splitNumberListString(tostring(vQ6pTDbn.Color))CDG3os[4]=vQ6pTDbn.Opacity
CDG3os[5]=vQ6pTDbn.RiseVelocity CDG3os[6]=vQ6pTDbn.Size elseif P==2 then CDG3os[3]=_splitNumberListString(tostring(vQ6pTDbn.Color)) CDG3os[4]=_splitNumberListString(tostring(vQ6pTDbn.SecondaryColor))CDG3os[5]=vQ6pTDbn.Heat
CDG3os[6]=vQ6pTDbn.Size elseif P==3 then CDG3os[3]=_splitNumberListString(tostring(vQ6pTDbn.SparkleColor))end
f.decorations[W]=CDG3os
_zxBo[W]=vQ6pTDbn
gN[vQ6pTDbn]=W end end
local xP7ck=ws7lX6m_:JSONEncode(f)return xP7ck end
local sdfJ=_serializeParts(J8)local uwuecWs local l,xhVT42E=ypcall(function() uwuecWs=ws7lX6m_:PostAsync('http://www.f3xteam.com/bt/export',sdfJ)end)local qX local A=ypcall(function()qX=ws7lX6m_:JSONDecode(uwuecWs)end)return l,xhVT42E,A,qX end IE={["export"]=function()if#Selection.Items==0 then return end local MOd9uwnL=DFb100j.BTExportDialog:Clone()MOd9uwnL.Loading.Size=UDim2.new(1,0,0,0) MOd9uwnL.Parent=UI MOd9uwnL.Loading:TweenSize(UDim2.new(1,0,0,80),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.25) MOd9uwnL.Loading.CloseButton.MouseButton1Up:connect(function() MOd9uwnL:Destroy()end) local JZDx8,_XR0EY1,z3J,ufXNV=ExportInterface.Export(Selection.Items) if not JZDx8 and (_XR0EY1 =='Http requests are not enabled'or _XR0EY1 == 'Http requests can only be executed by game server')then MOd9uwnL.Loading.TextLabel.Text='Upload failed, see message(s)'MOd9uwnL.Loading.CloseButton.Text='Okay!'XL_=false ShowStartupNotifications()elseif not JZDx8 then MOd9uwnL.Loading.TextLabel.Text='Upload failed (unknown request error)'MOd9uwnL.Loading.CloseButton.Text='Okay :(' XL_=false
ShowStartupNotifications()elseif JZDx8 and (not z3J or not ufXNV.success)then MOd9uwnL.Loading.TextLabel.Text='Upload failed (unknown processing error)'MOd9uwnL.Loading.CloseButton.Text='Okay :(' XL_=false
ShowStartupNotifications()elseif JZDx8 and z3J then print("[Building Tools by F3X] Uploaded Export: ".. ufXNV.id)MOd9uwnL.Loading.Visible=false MOd9uwnL.Info.Size=UDim2.new(1,0,0,0)MOd9uwnL.Info.CreationID.Text=ufXNV.id MOd9uwnL.Info.Visible=true MOd9uwnL.Info:TweenSize(UDim2.new(1,0,0,75),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.25)MOd9uwnL.Tip.Size=UDim2.new(1,0,0,0) MOd9uwnL.Tip.Visible=true MOd9uwnL.Tip:TweenSize(UDim2.new(1,0,0,30),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.25)MOd9uwnL.Close.Size=UDim2.new(1,0,0,0) MOd9uwnL.Close.Visible=true MOd9uwnL.Close:TweenSize(UDim2.new(1,0,0,20),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.25) MOd9uwnL.Close.Button.MouseButton1Up:connect(function() MOd9uwnL:Destroy()end) local Vum8=RbxUtility.Create"Sound"{Name="BTActionCompletionSound",Pitch=1.5,SoundId=Assets.ActionCompletionSound,Volume=1,Parent=Player or SoundService}Vum8:Play()Vum8:Destroy()end end}Tooltips={}Dock=DFb100j.BTDockGUI:Clone() Dock.Parent=UI
Dock.Visible=false function RegisterToolButton(NQSh) local Y1rSR=NQSh.Name:match("(.+)Button") if Y1rSR then NQSh.MouseButton1Up:connect(function()local aqQh=Tools[Y1rSR] if aqQh then equipTool(aqQh)end end) NQSh.MouseEnter:connect(function()local H_=Tooltips[Y1rSR] if H_ then H_:focus('button')end end) NQSh.MouseLeave:connect(function()local EQaFI0gZ=Tooltips[Y1rSR]if EQaFI0gZ then EQaFI0gZ:unfocus('button')end end)end end
for kKiLOav,XW8 in pairs(Dock.ToolButtons:GetChildren())do RegisterToolButton(XW8)end function RegisterTooltip(_8Ls) local t_t7=_8Ls.Name:match("(.+)Info") Tooltips[t_t7]={GUI=_8Ls,button_focus=false,tooltip_focus=false,focus=function(o,ogi5Usg)if Dock.HelpInfo.Visible then return end if ogi5Usg=='button'then o.button_focus=true elseif ogi5Usg=='tooltip'then o.tooltip_focus=true end for pA,_8Ls in pairs(Dock.Tooltips:GetChildren())do _8Ls.Visible=false end
o.GUI.Visible=true end,unfocus=function(DOIqPj09,RoKAkM)if RoKAkM=='button'then DOIqPj09.button_focus=false elseif RoKAkM=='tooltip'then DOIqPj09.tooltip_focus=false end
if not DOIqPj09.button_focus and not DOIqPj09.tooltip_focus then DOIqPj09.GUI.Visible=false end end} _8Ls.MouseEnter:connect(function() Tooltips[t_t7]:focus('tooltip')end) _8Ls.MouseLeave:connect(function() Tooltips[t_t7]:unfocus('tooltip')end)local A_oCK8=Gloo.ScrollingContainer(true,false,15) A_oCK8.GUI.Parent=_8Ls
for FETmJjQd,RK in pairs(_8Ls.Content:GetChildren())do RK.Parent=A_oCK8.Container end A_oCK8.GUI.Size=Dock.Tooltips.Size
A_oCK8.Container.Size=_8Ls.Content.Size A_oCK8.Boundary.Size=Dock.Tooltips.Size
A_oCK8.Boundary.BackgroundTransparency=1 _8Ls.Content:Destroy()end
for XAv,bdJvhbGA in pairs(Dock.Tooltips:GetChildren())do RegisterTooltip(bdJvhbGA)end local Vu0cCAf=Gloo.ScrollingContainer(true,false,15)Vu0cCAf.GUI.Parent=Dock.HelpInfo for c9M,bcYXd in pairs(Dock.HelpInfo.Content:GetChildren())do bcYXd.Parent=Vu0cCAf.Container end
Vu0cCAf.GUI.Size=Dock.HelpInfo.Size Vu0cCAf.Container.Size=Dock.HelpInfo.Content.Size
Vu0cCAf.Boundary.Size=Dock.HelpInfo.Size Vu0cCAf.Boundary.BackgroundTransparency=1
Dock.HelpInfo.Content:Destroy() Dock.SelectionButtons.UndoButton.MouseButton1Up:connect(function() History:undo()end) Dock.SelectionButtons.RedoButton.MouseButton1Up:connect(function() History:redo()end) Dock.SelectionButtons.DeleteButton.MouseButton1Up:connect(function() deleteSelection()end) Dock.SelectionButtons.CloneButton.MouseButton1Up:connect(function() cloneSelection()end) Dock.SelectionButtons.ExportButton.MouseButton1Up:connect(function() IE:export()end) Dock.SelectionButtons.GroupsButton.MouseButton1Up:connect(function() Groups:ToggleUI()end) Dock.InfoButtons.HelpButton.MouseButton1Up:connect(function() toggleHelp()end) Selection.Changed:connect(function() if#Selection.Items>0 then Dock.SelectionButtons.DeleteButton.Image=Assets.DeleteActiveDecal Dock.SelectionButtons.CloneButton.Image=Assets.CloneActiveDecal Dock.SelectionButtons.ExportButton.Image=Assets.ExportActiveDecal else Dock.SelectionButtons.DeleteButton.Image=Assets.DeleteInactiveDecal Dock.SelectionButtons.CloneButton.Image=Assets.CloneInactiveDecal Dock.SelectionButtons.ExportButton.Image=Assets.ExportInactiveDecal end end) for wbw9,jFg in pairs(Dock.SelectionButtons:GetChildren())do jFg.MouseEnter:connect(function()if jFg:FindFirstChild('Tooltip')then jFg.Tooltip.Visible=true end end) jFg.MouseLeave:connect(function()if jFg:FindFirstChild('Tooltip')then jFg.Tooltip.Visible=false end end)end Dock.InfoButtons.HelpButton.MouseEnter:connect(function() Dock.InfoButtons.HelpButton.Tooltip.Visible=true end) Dock.InfoButtons.HelpButton.MouseLeave:connect(function() Dock.InfoButtons.HelpButton.Tooltip.Visible=false end) History.Changed:connect(function() if#History.Data>0 then if History.index==0 then Dock.SelectionButtons.UndoButton.Image=Assets.UndoInactiveDecal Dock.SelectionButtons.RedoButton.Image=Assets.RedoActiveDecal elseif History.index==#History.Data then Dock.SelectionButtons.UndoButton.Image=Assets.UndoActiveDecal Dock.SelectionButtons.RedoButton.Image=Assets.RedoInactiveDecal else Dock.SelectionButtons.UndoButton.Image=Assets.UndoActiveDecal Dock.SelectionButtons.RedoButton.Image=Assets.RedoActiveDecal end else Dock.SelectionButtons.UndoButton.Image=Assets.UndoInactiveDecal Dock.SelectionButtons.RedoButton.Image=Assets.RedoInactiveDecal end end) Groups={Data={},UI=DFb100j.BTGroupsGUI:Clone(),GroupAdded=Support.CreateSignal(),NewGroup=function(_3BxMtBx) local j5rH={Name='Group '.. (# _3BxMtBx.Data+1),Items={},Ignoring=false,Changed=Support.CreateSignal(),Updated=Support.CreateSignal(),Rename=function(mKQv1MD,XvjCso) mKQv1MD.Name=XvjCso
mKQv1MD.Changed:Fire()end,SetIgnore=function(_R3NsF,I) _R3NsF.Ignoring=I
_R3NsF.Changed:Fire()end,Update=function(luJe,oJ) luJe.Items=Support.CloneTable(oJ)luJe.Updated:Fire()end,Select=function(XRK37sBn,W6W)if not W6W then Selection:clear()end
for HUwZ2ikl,trUgnCUz in pairs(XRK37sBn.Items)do Selection:add(trUgnCUz)end end}table.insert(_3BxMtBx.Data,j5rH) _3BxMtBx.GroupAdded:Fire(j5rH)return j5rH end,ToggleUI=function(CTJB)CTJB.UI.Visible= not CTJB.UI.Visible end,IsPartIgnored=function(PK9,hd)for l8vftvD,xb in pairs(PK9.Data)do if xb.Ignoring and #Support.FindTableOccurrences(xb.Items,hd)>0 then return true end end
return false end}Groups.UI.Visible=false
Groups.UI.Parent=Dock Groups.UI.Title.CreateButton.MouseButton1Click:connect(function() local KHB=Groups:NewGroup()KHB:Update(Selection.Items)end) Groups.GroupAdded:Connect(function(RZ8IqF) local FasBerA=Groups.UI.Templates.GroupButton:Clone() FasBerA.Position=UDim2.new(0,0,0,26* #Groups.UI.GroupList:GetChildren())FasBerA.Parent=Groups.UI.GroupList FasBerA.GroupName.Text=RZ8IqF.Name
FasBerA.GroupNamer.Text=RZ8IqF.Name Groups.UI.GroupList.CanvasSize=UDim2.new(1, -10,0,26*#Groups.UI.GroupList:GetChildren()) FasBerA.IgnoreButton.RightTooltip.Text.Text= RZ8IqF.Ignoring and'UNIGNORE'or'IGNORE' FasBerA.GroupName.MouseButton1Click:connect(function() RZ8IqF:Select(selecting)end) RZ8IqF.Changed:Connect(function()FasBerA.GroupName.Text=RZ8IqF.Name FasBerA.GroupNamer.Text=RZ8IqF.Name FasBerA.IgnoreButton.Image=RZ8IqF.Ignoring and Assets.GroupLockIcon or Assets.GroupUnlockIcon FasBerA.IgnoreButton.RightTooltip.Text.Text= RZ8IqF.Ignoring and'UNIGNORE'or'IGNORE'end) RZ8IqF.Updated:connect(function() FasBerA.UpdateButton.Image=Assets.GroupUpdateOKIcon coroutine.wrap(function()wait(1) FasBerA.UpdateButton.Image=Assets.GroupUpdateIcon end)()end) FasBerA.EditButton.MouseButton1Click:connect(function() FasBerA.GroupName.Visible=false
FasBerA.GroupNamer.Visible=true FasBerA.GroupNamer:CaptureFocus()end) FasBerA.GroupNamer.FocusLost:connect(function(ayR7Lua6)if ayR7Lua6 then RZ8IqF:Rename(FasBerA.GroupNamer.Text)end
FasBerA.GroupNamer.Visible=false FasBerA.GroupNamer.Text=RZ8IqF.Name
FasBerA.GroupName.Visible=true end) FasBerA.IgnoreButton.MouseButton1Click:connect(function()RZ8IqF:SetIgnore(not RZ8IqF.Ignoring)end) FasBerA.UpdateButton.MouseButton1Click:connect(function() RZ8IqF:Update(Selection.Items)end) local pf={FasBerA.UpdateButton,FasBerA.EditButton,FasBerA.IgnoreButton,FasBerA.GroupNameArea} for Ini5SE,PyZ2PUy0 in pairs(pf)do local ZiDK=PyZ2PUy0:FindFirstChild'LeftTooltip'or PyZ2PUy0:FindFirstChild'RightTooltip' if ZiDK then PyZ2PUy0.InputBegan:connect(function(HfV)if HfV.UserInputType==Enum.UserInputType.MouseMovement then ZiDK.Visible=true end end) PyZ2PUy0.InputEnded:connect(function(kYK3PhRd)if kYK3PhRd.UserInputType==Enum.UserInputType.MouseMovement then ZiDK.Visible=false end end)end end end) function equipBT(O)Mouse=O if not CurrentTool then equipTool(Tools.Move)end if not TargetBox then TargetBox=Instance.new("SelectionBox",UI) TargetBox.Name="BTTargetBox" TargetBox.Color=BrickColor.new("Institutional white")TargetBox.Transparency=0.5 end
for xme2_Bb,ccqzSAU in pairs(SelectionBoxes)do ccqzSAU.Parent=UI end if ToolType=='plugin'then for N,Rl1JVg in pairs(SelectionService:Get())do Selection:add(Rl1JVg)end end
if CurrentTool and CurrentTool.Listeners.Equipped then CurrentTool.Listeners.Equipped()end
Dock.Visible=true coroutine.wrap(ShowStartupNotifications)() Connections.SelectionModeStart=Support.AddUserInputListener('Began','Keyboard',false,function(h) if    h.KeyCode==Enum.KeyCode.LeftShift or h.KeyCode==Enum.KeyCode.RightShift or h.KeyCode==Enum.KeyCode.LeftControl or h.KeyCode==Enum.KeyCode.RightControl then selecting=true end end) Connections.SelectionModeEnd=Support.AddUserInputListener('Ended','Keyboard',true,function(nwlg80aZ) if   nwlg80aZ.KeyCode== Enum.KeyCode.LeftShift or nwlg80aZ.KeyCode==Enum.KeyCode.RightShift or nwlg80aZ.KeyCode==Enum.KeyCode.LeftControl or nwlg80aZ.KeyCode==Enum.KeyCode.RightControl then selecting=false end end) table.insert(Connections,Mouse.KeyDown:connect(function(B)local B=B:lower()local PDGF=B:byte() local x_gZS_6x=selecting
if B=="x"and x_gZS_6x then deleteSelection()return end if B=="c"and x_gZS_6x then wait(0)cloneSelection()return end
if B=="z"and x_gZS_6x then History:undo()return elseif B=="y"and x_gZS_6x then History:redo()return end
if B=="p"and x_gZS_6x then IE:export()return end if B=="k"and x_gZS_6x then prismSelect()return end if B=="r"and x_gZS_6x then Selection:clear()return end if B=="g"and x_gZS_6x then Groups:ToggleUI()return end if B=="["then local cG=Selection.Last
if not cG then return end if cG.Parent==Workspace then return end
if not(x_gZS_6x)then Selection:clear()end local L9PPA2e=Support.GetAllDescendants(cG.Parent) for JwAi,wjgKmwQJ in pairs(L9PPA2e)do Selection:add(wjgKmwQJ)end
Selection:add(cG)return end if B=="z"then equipTool(Tools.Move)elseif B=="x"then equipTool(Tools.Resize)elseif B=="c"then equipTool(Tools.Rotate)elseif B=="v"then equipTool(Tools.Paint)elseif B=="b"then equipTool(Tools.Surface)elseif B=="n"then equipTool(Tools.Material)elseif B=="m"then equipTool(Tools.Anchor)elseif B=="k"then equipTool(Tools.Collision)elseif B=="j"then equipTool(Tools.NewPart)elseif B=="h"then equipTool(Tools.Mesh)elseif B=="g"then equipTool(Tools.Texture)elseif B=="f"then equipTool(Tools.Weld)elseif B=="u"then equipTool(Tools.Lighting)elseif B=="p"then equipTool(Tools.Decorate)end
ActiveKeys[PDGF]=PDGF
ActiveKeys[B]=B end)) table.insert(Connections,Mouse.KeyUp:connect(function(Sq5Mc)local Sq5Mc=Sq5Mc:lower() local iAXm7_=Sq5Mc:byte()ActiveKeys[iAXm7_]=nil
ActiveKeys[Sq5Mc]=nil
if not selecting then if Select2D.enabled then Select2D:select()Select2D:finish()end end
if CurrentTool and CurrentTool.Listeners.KeyUp then CurrentTool.Listeners.KeyUp(Sq5Mc)end end)) table.insert(Connections,UserInputService.InputEnded:connect(function(fJ) if fJ.UserInputType== Enum.UserInputType.MouseButton1 then clicking=false
if Select2D.enabled then Select2D:select()Select2D:finish()end end end)) table.insert(Connections,Mouse.Button1Down:connect(function()clicking=true click_x,click_y=Mouse.X,Mouse.Y
if selecting then return end if CurrentTool and CurrentTool.Listeners.Button1Down then CurrentTool.Listeners.Button1Down()end end)) table.insert(Connections,Mouse.Move:connect(function() if   not override_selection and not Select2D.enabled and clicking and selecting and(click_x~=Mouse.X or click_y~=Mouse.Y)then Select2D:start()end
if not override_selection and isSelectable(Mouse.Target)and TargetBox.Adornee~=Mouse.Target then TargetBox.Adornee=Mouse.Target end
if not override_selection and not isSelectable(Mouse.Target)then TargetBox.Adornee= nil end
if CurrentTool and CurrentTool.Listeners.Move then CurrentTool.Listeners.Move()end if override_selection then override_selection=false end end)) table.insert(Connections,Mouse.Button1Up:connect(function()clicking=false
if not Select2D.enabled and( Mouse.X~=click_x or Mouse.Y~=click_y)then override_selection=true end if not override_selection and not selecting and not isSelectable(Mouse.Target)then Selection:clear()end if not override_selection and selecting then if not Selection:find(Mouse.Target)then if isSelectable(Mouse.Target)then Selection:add(Mouse.Target)end else if (Mouse.X==click_x and Mouse.Y==click_y)and Selection:find(Mouse.Target)then Selection:remove(Mouse.Target)end end else if not override_selection and isSelectable(Mouse.Target)then Selection:clear()Selection:add(Mouse.Target)end end
if CurrentTool and CurrentTool.Listeners.Button1Up then CurrentTool.Listeners.Button1Up()end
if override_selection then override_selection=false end end)) table.insert(Connections,Mouse.Button2Down:connect(function()if CurrentTool and CurrentTool.Listeners.Button2Down then CurrentTool.Listeners.Button2Down()end end)) table.insert(Connections,Mouse.Button2Up:connect(function() if CurrentTool and CurrentTool.Listeners.Button2Up then CurrentTool.Listeners.Button2Up()end end))end function unequipBT()Mouse=nil if TargetBox then TargetBox:Destroy()TargetBox=nil end
for aG3O,M6IbY in pairs(SelectionBoxes)do M6IbY.Parent=nil end Dock.Visible=false for vxWBA,is in pairs(Connections)do is:disconnect()Connections[vxWBA]=nil end
if CurrentTool and CurrentTool.Listeners.Unequipped then CurrentTool.Listeners.Unequipped()end end
print("Starting Tool List") local q={{"Anchor",function() repeat wait() print("I'm hooked")until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.Anchor={} Tools.Anchor.Connections={}Tools.Anchor.State={["anchored"]=nil} Tools.Anchor.Listeners={} Tools.Anchor.Color=BrickColor.new("Really black") Tools.Anchor.Listeners.Equipped=function()local _l=Tools.Anchor _l.State.PreviousSelectionBoxColor=SelectionBoxColor
SelectionBoxColor=_l.Color
updateSelectionBoxColor() _l:showGUI() coroutine.wrap(function()updater_on=true _l.Updater=function()updater_on=false end while wait(0.1)and updater_on do if CurrentTool==_l then local IVdNQHj=nil for l,icedjl in pairs(Selection.Items)do if l==1 then IVdNQHj=icedjl.Anchored else if IVdNQHj~=icedjl.Anchored then IVdNQHj=nil end end end
_l.State.anchored=IVdNQHj
if _l.GUI and _l.GUI.Visible then _l:updateGUI()end end end end)() _l.Connections.EnterButtonListener=Mouse.KeyDown:connect(function(H)local H=H:lower() local d1J=H:byte() if d1J==13 then if _l.State.anchored==true then _l:unanchor()elseif _l.State.anchored==false then _l:anchor()elseif _l.State.anchored==nil then _l:anchor()end end end)end Tools.Anchor.startHistoryRecord=function(zVUtED)if zVUtED.State.HistoryRecord then zVUtED.State.HistoryRecord=nil end zVUtED.State.HistoryRecord={targets=Support.CloneTable(Selection.Items),initial_positions={},terminal_positions={},initial_anchors={},terminal_anchors={},unapply=function(zVUtED) Selection:clear() for d_UB9,FysQC in pairs(zVUtED.targets)do if FysQC then FysQC.RotVelocity=Vector3.new(0,0,0) FysQC.Velocity=Vector3.new(0,0,0)FysQC.CFrame=zVUtED.initial_positions[FysQC] FysQC.Anchored=zVUtED.initial_anchors[FysQC]FysQC:MakeJoints()Selection:add(FysQC)end end end,apply=function(zVUtED) Selection:clear() for AnG,yV8C in pairs(zVUtED.targets)do if yV8C then yV8C.RotVelocity=Vector3.new(0,0,0) yV8C.Velocity=Vector3.new(0,0,0)yV8C.CFrame=zVUtED.terminal_positions[yV8C] yV8C.Anchored=zVUtED.terminal_anchors[yV8C]yV8C:MakeJoints()Selection:add(yV8C)end end end} for bt4Y,sZNR in pairs(zVUtED.State.HistoryRecord.targets)do if sZNR then zVUtED.State.HistoryRecord.initial_anchors[sZNR]=sZNR.Anchored zVUtED.State.HistoryRecord.initial_positions[sZNR]=sZNR.CFrame end end end Tools.Anchor.finishHistoryRecord=function(WAIOz7) if not WAIOz7.State.HistoryRecord then return end for ICLcYduB,oXFiMbj in pairs(WAIOz7.State.HistoryRecord.targets)do if oXFiMbj then WAIOz7.State.HistoryRecord.terminal_anchors[oXFiMbj]=oXFiMbj.Anchored WAIOz7.State.HistoryRecord.terminal_positions[oXFiMbj]=oXFiMbj.CFrame end end
History:add(WAIOz7.State.HistoryRecord)WAIOz7.State.HistoryRecord= nil end Tools.Anchor.anchor=function(i5L)i5L:startHistoryRecord() for vYC4bdrc,QAFVQu14 in pairs(Selection.Items)do QAFVQu14.Anchored=true
QAFVQu14:MakeJoints()end
i5L:finishHistoryRecord()end Tools.Anchor.unanchor=function(DVx)DVx:startHistoryRecord() for r,Knh56 in pairs(Selection.Items)do Knh56.Anchored=false
Knh56.Velocity=Vector3.new(0,0,0) Knh56.RotVelocity=Vector3.new(0,0,0)Knh56:MakeJoints()end
DVx:finishHistoryRecord()end Tools.Anchor.showGUI=function(DG90Rh) if not DG90Rh.GUI then local mBxSp8y2=DFb100j.BTAnchorToolGUI:Clone()mBxSp8y2.Parent=UI mBxSp8y2.Status.Anchored.Button.MouseButton1Down:connect(function() DG90Rh:anchor()end) mBxSp8y2.Status.Unanchored.Button.MouseButton1Down:connect(function() DG90Rh:unanchor()end)DG90Rh.GUI=mBxSp8y2 end
DG90Rh.GUI.Visible=true end Tools.Anchor.updateGUI=function(W09NOBin)if not W09NOBin.GUI then return end local Tek7X=W09NOBin.GUI if W09NOBin.State.anchored==nil then Tek7X.Status.Anchored.Background.Image=Assets.LightSlantedRectangle Tek7X.Status.Anchored.SelectedIndicator.BackgroundTransparency=1 Tek7X.Status.Unanchored.Background.Image=Assets.LightSlantedRectangle Tek7X.Status.Unanchored.SelectedIndicator.BackgroundTransparency=1 elseif W09NOBin.State.anchored==true then Tek7X.Status.Anchored.Background.Image=Assets.DarkSlantedRectangle Tek7X.Status.Anchored.SelectedIndicator.BackgroundTransparency=0 Tek7X.Status.Unanchored.Background.Image=Assets.LightSlantedRectangle Tek7X.Status.Unanchored.SelectedIndicator.BackgroundTransparency=1 elseif W09NOBin.State.anchored==false then Tek7X.Status.Anchored.Background.Image=Assets.LightSlantedRectangle Tek7X.Status.Anchored.SelectedIndicator.BackgroundTransparency=1 Tek7X.Status.Unanchored.Background.Image=Assets.DarkSlantedRectangle Tek7X.Status.Unanchored.SelectedIndicator.BackgroundTransparency=0 end end Tools.Anchor.hideGUI=function(Wzzgk) if Wzzgk.GUI then Wzzgk.GUI.Visible=false end end Tools.Anchor.Listeners.Unequipped=function()local anaV=Tools.Anchor
if anaV.Updater then anaV.Updater()anaV.Updater=nil end
anaV:hideGUI() for gwxp,Qf in pairs(anaV.Connections)do Qf:disconnect()anaV.Connections[gwxp]=nil end
SelectionBoxColor=anaV.State.PreviousSelectionBoxColor updateSelectionBoxColor()end
Tools.Anchor.Loaded=true end},{"Collision",function() repeat wait()until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.Collision={} Tools.Collision.Connections={}Tools.Collision.State={["colliding"]=nil} Tools.Collision.Listeners={} Tools.Collision.Color=BrickColor.new("Really black") Tools.Collision.Listeners.Equipped=function()local sRf=Tools.Collision sRf.State.PreviousSelectionBoxColor=SelectionBoxColor
SelectionBoxColor=sRf.Color
updateSelectionBoxColor() sRf:showGUI() coroutine.wrap(function()updater_on=true sRf.Updater=function()updater_on=false end while wait(0.1)and updater_on do if CurrentTool==sRf then local Ir=nil
for On7i,GAQjek in pairs(Selection.Items)do if On7i==1 then Ir=GAQjek.CanCollide else if Ir~=GAQjek.CanCollide then Ir=nil end end end sRf.State.colliding=Ir if sRf.GUI and sRf.GUI.Visible then sRf:updateGUI()end end end end)() sRf.Connections.EnterButtonListener=Mouse.KeyDown:connect(function(b)local b=b:lower() local t=b:byte() if t==13 then if sRf.State.colliding==true then sRf:disable()elseif sRf.State.colliding==false then sRf:enable()elseif sRf.State.colliding==nil then sRf:enable()end end end)end Tools.Collision.startHistoryRecord=function(nUqS)if nUqS.State.HistoryRecord then nUqS.State.HistoryRecord=nil end nUqS.State.HistoryRecord={targets=Support.CloneTable(Selection.Items),initial_collide={},terminal_collide={},initial_cframe={},terminal_cframe={},unapply=function(nUqS) Selection:clear() for wTVytu,VZjB in pairs(nUqS.targets)do if VZjB then VZjB.CanCollide=nUqS.initial_collide[VZjB]VZjB.CFrame=nUqS.initial_cframe[VZjB] VZjB:MakeJoints()Selection:add(VZjB)end end end,apply=function(nUqS) Selection:clear() for Qv_pumH,Rm in pairs(nUqS.targets)do if Rm then Rm.CanCollide=nUqS.terminal_collide[Rm] Rm.CFrame=nUqS.terminal_cframe[Rm]Rm:MakeJoints()Selection:add(Rm)end end end} for Wq2v,G in pairs(nUqS.State.HistoryRecord.targets)do if G then nUqS.State.HistoryRecord.initial_collide[G]=G.CanCollide nUqS.State.HistoryRecord.initial_cframe[G]=G.CFrame end end end Tools.Collision.finishHistoryRecord=function(e5kmv) if not e5kmv.State.HistoryRecord then return end for PSNhu,mAaO3eJ in pairs(e5kmv.State.HistoryRecord.targets)do if mAaO3eJ then e5kmv.State.HistoryRecord.terminal_collide[mAaO3eJ]=mAaO3eJ.CanCollide e5kmv.State.HistoryRecord.terminal_cframe[mAaO3eJ]=mAaO3eJ.CFrame end end
History:add(e5kmv.State.HistoryRecord)e5kmv.State.HistoryRecord= nil end Tools.Collision.enable=function(EO)EO:startHistoryRecord() for Qw9,GMgV5kh in pairs(Selection.Items)do GMgV5kh.CanCollide=true
GMgV5kh:MakeJoints()end
EO:finishHistoryRecord()end Tools.Collision.disable=function(Shm)Shm:startHistoryRecord() for iIKY5x,fLF in pairs(Selection.Items)do fLF.CanCollide=false
fLF:MakeJoints()end
Shm:finishHistoryRecord()end Tools.Collision.showGUI=function(eQ) if not eQ.GUI then local yGT7hv6=DFb100j.BTCollisionToolGUI:Clone()yGT7hv6.Parent=UI yGT7hv6.Status.On.Button.MouseButton1Down:connect(function() eQ:enable()end) yGT7hv6.Status.Off.Button.MouseButton1Down:connect(function() eQ:disable()end)eQ.GUI=yGT7hv6 end
eQ.GUI.Visible=true end Tools.Collision.updateGUI=function(qG4fWn4a)if not qG4fWn4a.GUI then return end local Zkf=qG4fWn4a.GUI if qG4fWn4a.State.colliding==nil then Zkf.Status.On.Background.Image=Assets.LightSlantedRectangle Zkf.Status.On.SelectedIndicator.BackgroundTransparency=1 Zkf.Status.Off.Background.Image=Assets.LightSlantedRectangle Zkf.Status.Off.SelectedIndicator.BackgroundTransparency=1 elseif qG4fWn4a.State.colliding==true then Zkf.Status.On.Background.Image=Assets.DarkSlantedRectangle Zkf.Status.On.SelectedIndicator.BackgroundTransparency=0 Zkf.Status.Off.Background.Image=Assets.LightSlantedRectangle Zkf.Status.Off.SelectedIndicator.BackgroundTransparency=1 elseif qG4fWn4a.State.colliding==false then Zkf.Status.On.Background.Image=Assets.LightSlantedRectangle Zkf.Status.On.SelectedIndicator.BackgroundTransparency=1 Zkf.Status.Off.Background.Image=Assets.DarkSlantedRectangle Zkf.Status.Off.SelectedIndicator.BackgroundTransparency=0 end end Tools.Collision.hideGUI=function(N)if N.GUI then N.GUI.Visible=false end end Tools.Collision.Listeners.Unequipped=function()local Bh=Tools.Collision
if Bh.Updater then Bh.Updater()Bh.Updater=nil end
Bh:hideGUI() for r42joJ,zl1g in pairs(Bh.Connections)do zl1g:disconnect()Bh.Connections[r42joJ]=nil end
SelectionBoxColor=Bh.State.PreviousSelectionBoxColor updateSelectionBoxColor()end
Tools.Collision.Loaded=true end},{"Material",function() repeat wait()until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.Material={} Tools.Material.Color=BrickColor.new("Bright violet")Tools.Material.Connections={} Tools.Material.State={["material"]=nil,["reflectance_focused"]=false,["transparency_focused"]=false}Tools.Material.Listeners={} Tools.Material.SpecialMaterialNames={CorrodedMetal="CORRODED METAL",DiamondPlate="DIAMOND PLATE",SmoothPlastic="SMOOTH PLASTIC",WoodPlanks="WOOD PLANKS"} Tools.Material.Listeners.Equipped=function()local Cx=Tools.Material Cx.State.PreviousSelectionBoxColor=SelectionBoxColor
SelectionBoxColor=Cx.Color
updateSelectionBoxColor() Cx:showGUI() coroutine.wrap(function()updater_on=true Cx.Updater=function()updater_on=false end while wait(0.1)and updater_on do if CurrentTool==Cx then local A6o,s2_,i6j=nil,nil,nil for oKC,Xzi2KU in pairs(Selection.Items)do if oKC==1 then A6o=Xzi2KU.Material
s2_=Xzi2KU.Transparency i6j=Xzi2KU.Reflectance else if A6o~=Xzi2KU.Material then A6o=nil end
if i6j~=Xzi2KU.Reflectance then i6j=nil end if s2_~=Xzi2KU.Transparency then s2_=nil end end end
Cx.State.material=A6o
Cx.State.transparency=s2_ Cx.State.reflectance=i6j
if Cx.GUI and Cx.GUI.Visible then Cx:updateGUI()end end end end)()end Tools.Material.Listeners.Unequipped=function()local _c=Tools.Material
if _c.Updater then _c.Updater()_c.Updater=nil end
_c:hideGUI() for S,pI1x in pairs(_c.Connections)do pI1x:disconnect()_c.Connections[S]=nil end
SelectionBoxColor=_c.State.PreviousSelectionBoxColor updateSelectionBoxColor()end Tools.Material.startHistoryRecord=function(NgDx9_)if NgDx9_.State.HistoryRecord then NgDx9_.State.HistoryRecord=nil end NgDx9_.State.HistoryRecord={targets=Support.CloneTable(Selection.Items),initial_material={},terminal_material={},initial_transparency={},terminal_transparency={},initial_reflectance={},terminal_reflectance={},unapply=function(NgDx9_) Selection:clear() for KzYaixt,i in pairs(NgDx9_.targets)do if i then i.Material=NgDx9_.initial_material[i]i.Transparency=NgDx9_.initial_transparency[i] i.Reflectance=NgDx9_.initial_reflectance[i]Selection:add(i)end end end,apply=function(NgDx9_) Selection:clear() for DM7,sBDh6v in pairs(NgDx9_.targets)do if sBDh6v then sBDh6v.Material=NgDx9_.terminal_material[sBDh6v] sBDh6v.Transparency=NgDx9_.terminal_transparency[sBDh6v] sBDh6v.Reflectance=NgDx9_.terminal_reflectance[sBDh6v]Selection:add(sBDh6v)end end end} for siy_21f,wkUEOv in pairs(NgDx9_.State.HistoryRecord.targets)do if wkUEOv then NgDx9_.State.HistoryRecord.initial_material[wkUEOv]=wkUEOv.Material NgDx9_.State.HistoryRecord.initial_transparency[wkUEOv]=wkUEOv.Transparency NgDx9_.State.HistoryRecord.initial_reflectance[wkUEOv]=wkUEOv.Reflectance end end end Tools.Material.finishHistoryRecord=function(b) if not b.State.HistoryRecord then return end for s1sExxI,qR in pairs(b.State.HistoryRecord.targets)do if qR then b.State.HistoryRecord.terminal_material[qR]=qR.Material b.State.HistoryRecord.terminal_transparency[qR]=qR.Transparency b.State.HistoryRecord.terminal_reflectance[qR]=qR.Reflectance end end
History:add(b.State.HistoryRecord) b.State.HistoryRecord=nil end Tools.Material.changeMaterial=function(KMeqP,y3tk)KMeqP:startHistoryRecord()for A,Iysi_9UF in pairs(Selection.Items)do Iysi_9UF.Material=y3tk end KMeqP:finishHistoryRecord()if KMeqP.MaterialDropdown.open then KMeqP.MaterialDropdown:toggle()end end Tools.Material.changeTransparency=function(joAA,w)joAA:startHistoryRecord()for ta59,b_knq in pairs(Selection.Items)do b_knq.Transparency=w end joAA:finishHistoryRecord()end Tools.Material.changeReflectance=function(J_AlR,_dqQ8fSw)J_AlR:startHistoryRecord()for onKnnPCx,WytqKWPI in pairs(Selection.Items)do WytqKWPI.Reflectance=_dqQ8fSw end J_AlR:finishHistoryRecord()end Tools.Material.updateGUI=function(M)if not M.GUI then return end if #Selection.Items>0 then M.GUI.Size=UDim2.new(0,200,0,145) M.GUI.MaterialOption.Visible=true
M.GUI.ReflectanceOption.Visible=true M.GUI.TransparencyOption.Visible=true
M.GUI.SelectNote.Visible=false M.MaterialDropdown:selectOption( M.State.material and (M.SpecialMaterialNames[M.State.material.Name]or M.State.material.Name:upper())or"*") if not M.State.transparency_focused then M.GUI.TransparencyOption.TransparencyInput.TextBox.Text=  M.State.transparency and tostring(Support.Round(M.State.transparency,2))or"*"end if not M.State.reflectance_focused then M.GUI.ReflectanceOption.ReflectanceInput.TextBox.Text=  M.State.reflectance and tostring(Support.Round(M.State.reflectance,2))or"*"end else M.GUI.Size=UDim2.new(0,200,0,62) M.GUI.MaterialOption.Visible=false
M.GUI.ReflectanceOption.Visible=false M.GUI.TransparencyOption.Visible=false
M.GUI.SelectNote.Visible=true M.MaterialDropdown:selectOption("") M.GUI.TransparencyOption.TransparencyInput.TextBox.Text="" M.GUI.ReflectanceOption.ReflectanceInput.TextBox.Text=""end end Tools.Material.showGUI=function(K4o_AriB) if not K4o_AriB.GUI then local MXcdGX=DFb100j.BTMaterialToolGUI:Clone()MXcdGX.Parent=UI
local R9=createDropdown() K4o_AriB.MaterialDropdown=R9
R9.Frame.Parent=MXcdGX.MaterialOption R9.Frame.Position=UDim2.new(0,50,0,0)R9.Frame.Size=UDim2.new(0,130,0,25) R9:addOption("SMOOTH PLASTIC").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.SmoothPlastic)end) R9:addOption("PLASTIC").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Plastic)end) R9:addOption("BRICK").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Brick)end) R9:addOption("COBBLESTONE").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Cobblestone)end) R9:addOption("CONCRETE").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Concrete)end) R9:addOption("CORRODED METAL").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.CorrodedMetal)end) R9:addOption("DIAMOND PLATE").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.DiamondPlate)end) R9:addOption("FABRIC").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Fabric)end) R9:addOption("FOIL").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Foil)end) R9:addOption("GRANITE").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Granite)end) R9:addOption("GRASS").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Grass)end) R9:addOption("ICE").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Ice)end) R9:addOption("MARBLE").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Marble)end) R9:addOption("METAL").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Metal)end) R9:addOption("NEON").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Neon)end) R9:addOption("PEBBLE").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Pebble)end) R9:addOption("SAND").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Sand)end) R9:addOption("SLATE").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Slate)end) R9:addOption("WOOD").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.Wood)end) R9:addOption("WOOD PLANKS").MouseButton1Up:connect(function() K4o_AriB:changeMaterial(Enum.Material.WoodPlanks)end) MXcdGX.TransparencyOption.TransparencyInput.TextButton.MouseButton1Down:connect(function() K4o_AriB.State.transparency_focused=true MXcdGX.TransparencyOption.TransparencyInput.TextBox:CaptureFocus()end) MXcdGX.TransparencyOption.TransparencyInput.TextBox.FocusLost:connect(function(n9zj) local sWU=tonumber(MXcdGX.TransparencyOption.TransparencyInput.TextBox.Text)if sWU then if sWU>1 then sWU=1 elseif sWU<0 then sWU=0 end K4o_AriB:changeTransparency(sWU)end K4o_AriB.State.transparency_focused=false end) MXcdGX.ReflectanceOption.ReflectanceInput.TextButton.MouseButton1Down:connect(function() K4o_AriB.State.reflectance_focused=true MXcdGX.ReflectanceOption.ReflectanceInput.TextBox:CaptureFocus()end) MXcdGX.ReflectanceOption.ReflectanceInput.TextBox.FocusLost:connect(function(JoZ28) local hBfySU=tonumber(MXcdGX.ReflectanceOption.ReflectanceInput.TextBox.Text)if hBfySU then if hBfySU>1 then hBfySU=1 elseif hBfySU<0 then hBfySU=0 end K4o_AriB:changeReflectance(hBfySU)end K4o_AriB.State.reflectance_focused=false end)K4o_AriB.GUI=MXcdGX end
K4o_AriB.GUI.Visible=true end
Tools.Material.hideGUI=function(Uvmu) if Uvmu.GUI then Uvmu.GUI.Visible=false end end Tools.Material.Loaded=true end},{"Mesh",function() repeat wait()until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.Mesh={} Tools.Mesh.Color=BrickColor.new("Bright violet")Tools.Mesh.State={}Tools.Mesh.Connections={} Tools.Mesh.Listeners={} Tools.Mesh.Listeners.Equipped=function()local _=Tools.Mesh _.State.PreviousSelectionBoxColor=SelectionBoxColor
SelectionBoxColor=_.Color
updateSelectionBoxColor() _:showGUI() coroutine.wrap(function()updater_on=true _.Updater=function()updater_on=false end while wait(0.1)and updater_on do if CurrentTool==_ then if _.GUI and _.GUI.Visible then _:updateGUI()end end end end)()end Tools.Mesh.Listeners.Unequipped=function()local SeHRNaX=Tools.Mesh
if SeHRNaX.Updater then SeHRNaX.Updater()SeHRNaX.Updater=nil end SeHRNaX:hideGUI()for kH7r,HOB in pairs(SeHRNaX.Connections)do HOB:disconnect()SeHRNaX.Connections[kH7r]= nil end SelectionBoxColor=SeHRNaX.State.PreviousSelectionBoxColor
updateSelectionBoxColor()end Tools.Mesh.TypeDropdownLabels={[Enum.MeshType.Brick]="BLOCK",[Enum.MeshType.Cylinder]="CYLINDER",[Enum.MeshType.FileMesh]="FILE",[Enum.MeshType.Head]="HEAD",[Enum.MeshType.Sphere]="SPHERE",[Enum.MeshType.Torso]="TRAPEZOID",[Enum.MeshType.Wedge]="WEDGE"} Tools.Mesh.changeType=function(RCc,vLr4f)local Pad5yPd={} for GAeGfl,TYRl in pairs(Selection.Items)do local uoRdE7k=Support.GetChildOfClass(TYRl,"SpecialMesh")if uoRdE7k then table.insert(Pad5yPd,uoRdE7k)end end
RCc:startHistoryRecord(Pad5yPd)for k5,F_cOghKV in pairs(Pad5yPd)do F_cOghKV.MeshType=vLr4f end
RCc:finishHistoryRecord()if RCc.TypeDropdown.open then RCc.TypeDropdown:toggle()end RCc:finishHistoryRecord()end Tools.Mesh.updateGUI=function(Ytf)if not Ytf.GUI then return end
local VAKgo=Ytf.GUI if #Selection.Items>0 then local QB={} for cMk1b62p,iAIf in pairs(Selection.Items)do local Am0WLx=Support.GetChildOfClass(iAIf,"SpecialMesh")if Am0WLx then table.insert(QB,Am0WLx)end end
local y8zF,T,fT1
local lMKfa,P25nFo1,MwI,t,rcbgP,nwoQ,pazH2Fh,GZ2PbO,y if#QB==#Selection.Items then y8zF=false
T=true elseif#QB==0 then y8zF=true
T=false else y8zF=true
T=true end if#QB>0 then show_type=true for TDJshmj,LTJy0 in pairs(QB)do if TDJshmj==1 then lMKfa=LTJy0.MeshType P25nFo1,MwI,t=LTJy0.Scale.x,LTJy0.Scale.y,LTJy0.Scale.z
rcbgP=LTJy0.MeshId:lower() nwoQ=LTJy0.TextureId:lower() pazH2Fh,GZ2PbO,y=LTJy0.VertexColor.x,LTJy0.VertexColor.y,LTJy0.VertexColor.z else if lMKfa~=LTJy0.MeshType then lMKfa=nil end
if P25nFo1 ~=LTJy0.Scale.x then P25nFo1=nil end if MwI~=LTJy0.Scale.y then MwI=nil end
if t~=LTJy0.Scale.z then t=nil end
if rcbgP~=LTJy0.MeshId:lower()then rcbgP=nil end
if nwoQ~=LTJy0.TextureId:lower()then nwoQ=nil end
if pazH2Fh~=LTJy0.VertexColor.x then pazH2Fh=nil end if GZ2PbO~=LTJy0.VertexColor.y then GZ2PbO=nil end
if y~=LTJy0.VertexColor.z then y=nil end end if LTJy0.MeshType==Enum.MeshType.FileMesh then fT1=true end end Ytf.State.mesh_tint=(pazH2Fh and GZ2PbO and y)and Color3.new(pazH2Fh,GZ2PbO,y)or nil if fT1 and y8zF and T then Ytf.GUI.AddButton.Visible=true Ytf.GUI.RemoveButton.Visible=true
Ytf.GUI.MeshIDOption.Visible=true Ytf.GUI.TextureIDOption.Visible=true
Ytf.GUI.ScaleOption.Visible=true Ytf.GUI.TintOption.Visible=true
Ytf.GUI.TypeOption.Visible=true Ytf.GUI.TypeOption.Position=UDim2.new(0,14,0,65)Ytf.GUI.ScaleOption.Position=UDim2.new(0,0,0,100) Ytf.GUI.MeshIDOption.Position=UDim2.new(0,14,0,135) Ytf.GUI.TextureIDOption.Position=UDim2.new(0,14,0,165)Ytf.GUI.TintOption.Position=UDim2.new(0,0,0,200) Ytf.GUI.Size=UDim2.new(0,200,0,265)elseif fT1 and not y8zF and T then Ytf.GUI.AddButton.Visible=false Ytf.GUI.RemoveButton.Visible=true
Ytf.GUI.MeshIDOption.Visible=true Ytf.GUI.TextureIDOption.Visible=true
Ytf.GUI.ScaleOption.Visible=true Ytf.GUI.TintOption.Visible=true
Ytf.GUI.TypeOption.Visible=true Ytf.GUI.TypeOption.Position=UDim2.new(0,14,0,30)Ytf.GUI.ScaleOption.Position=UDim2.new(0,0,0,65) Ytf.GUI.MeshIDOption.Position=UDim2.new(0,14,0,100) Ytf.GUI.TextureIDOption.Position=UDim2.new(0,14,0,130)Ytf.GUI.TintOption.Position=UDim2.new(0,0,0,165) Ytf.GUI.Size=UDim2.new(0,200,0,230)elseif not fT1 and y8zF and T then Ytf.GUI.AddButton.Visible=true Ytf.GUI.RemoveButton.Visible=true
Ytf.GUI.MeshIDOption.Visible=false Ytf.GUI.TextureIDOption.Visible=false
Ytf.GUI.ScaleOption.Visible=true Ytf.GUI.TintOption.Visible=false
Ytf.GUI.TypeOption.Visible=true Ytf.GUI.TypeOption.Position=UDim2.new(0,14,0,65)Ytf.GUI.ScaleOption.Position=UDim2.new(0,0,0,100) Ytf.GUI.Size=UDim2.new(0,200,0,165)elseif not fT1 and not y8zF and T then Ytf.GUI.AddButton.Visible=false
Ytf.GUI.RemoveButton.Visible=true Ytf.GUI.MeshIDOption.Visible=false
Ytf.GUI.TextureIDOption.Visible=false Ytf.GUI.ScaleOption.Visible=true
Ytf.GUI.TintOption.Visible=false Ytf.GUI.TypeOption.Visible=true
Ytf.GUI.TypeOption.Position=UDim2.new(0,14,0,30) Ytf.GUI.ScaleOption.Position=UDim2.new(0,0,0,65)Ytf.GUI.Size=UDim2.new(0,200,0,130)end if not Ytf.State.mesh_id_focused then Ytf.GUI.MeshIDOption.TextBox.Text=  rcbgP and(rcbgP:match("%?id=([0-9]+)")or"")or"*"end if not Ytf.State.texture_id_focused then Ytf.GUI.TextureIDOption.TextBox.Text=  nwoQ and(nwoQ:match("%?id=([0-9]+)")or"")or"*"end Ytf.TypeDropdown:selectOption( lMKfa and Ytf.TypeDropdownLabels[lMKfa]or"*")if not Ytf.State.scale_x_focused then Ytf.GUI.ScaleOption.XInput.TextBox.Text= P25nFo1 and Support.Round(P25nFo1,2)or"*"end
if not Ytf.State.scale_y_focused then Ytf.GUI.ScaleOption.YInput.TextBox.Text= MwI and Support.Round(MwI,2)or"*"end
if not Ytf.State.scale_z_focused then Ytf.GUI.ScaleOption.ZInput.TextBox.Text= t and Support.Round(t,2)or"*"end
if not Ytf.State.tint_r_focused then Ytf.GUI.TintOption.RInput.TextBox.Text=pazH2Fh and Support.Round( pazH2Fh*255,0)or"*"end
if not Ytf.State.tint_g_focused then Ytf.GUI.TintOption.GInput.TextBox.Text= GZ2PbO and Support.Round(GZ2PbO*255,0)or"*"end
if not Ytf.State.tint_b_focused then Ytf.GUI.TintOption.BInput.TextBox.Text= y and Support.Round(y*255,0)or"*"end else Ytf.GUI.AddButton.Visible=true
Ytf.GUI.RemoveButton.Visible=false Ytf.GUI.MeshIDOption.Visible=false
Ytf.GUI.TextureIDOption.Visible=false Ytf.GUI.ScaleOption.Visible=false
Ytf.GUI.TintOption.Visible=false Ytf.GUI.TypeOption.Visible=false
Ytf.GUI.Size=UDim2.new(0,200,0,62)end
Ytf.GUI.SelectNote.Visible=false else Ytf.GUI.AddButton.Visible=false
Ytf.GUI.RemoveButton.Visible=false Ytf.GUI.MeshIDOption.Visible=false
Ytf.GUI.TextureIDOption.Visible=false Ytf.GUI.ScaleOption.Visible=false
Ytf.GUI.TintOption.Visible=false Ytf.GUI.TypeOption.Visible=false
Ytf.GUI.SelectNote.Visible=true Ytf.GUI.Size=UDim2.new(0,200,0,55)end end Tools.Mesh.showGUI=function(N) if not N.GUI then local Ns=DFb100j.BTMeshToolGUI:Clone()Ns.Parent=UI Ns.AddButton.Button.MouseButton1Up:connect(function() N:addMesh()end) Ns.RemoveButton.Button.MouseButton1Up:connect(function() N:removeMesh()end)local ZOvR1=createDropdown()N.TypeDropdown=ZOvR1 ZOvR1.Frame.Parent=Ns.TypeOption
ZOvR1.Frame.Position=UDim2.new(0,40,0,0)ZOvR1.Frame.Size=UDim2.new(1, -40,0,25) ZOvR1:addOption("BLOCK").MouseButton1Up:connect(function() N:changeType(Enum.MeshType.Brick)end) ZOvR1:addOption("CYLINDER").MouseButton1Up:connect(function() N:changeType(Enum.MeshType.Cylinder)end) ZOvR1:addOption("FILE").MouseButton1Up:connect(function() N:changeType(Enum.MeshType.FileMesh)end) ZOvR1:addOption("HEAD").MouseButton1Up:connect(function() N:changeType(Enum.MeshType.Head)end) ZOvR1:addOption("SPHERE").MouseButton1Up:connect(function() N:changeType(Enum.MeshType.Sphere)end) ZOvR1:addOption("TRAPEZOID").MouseButton1Up:connect(function() N:changeType(Enum.MeshType.Torso)end) ZOvR1:addOption("WEDGE").MouseButton1Up:connect(function() N:changeType(Enum.MeshType.Wedge)end) Ns.ScaleOption.XInput.TextButton.MouseButton1Down:connect(function() N.State.scale_x_focused=true Ns.ScaleOption.XInput.TextBox:CaptureFocus()end) Ns.ScaleOption.XInput.TextBox.FocusLost:connect(function(L75) local zh=tonumber(Ns.ScaleOption.XInput.TextBox.Text)if zh then N:changeScale('x',zh)end N.State.scale_x_focused=false end) Ns.ScaleOption.YInput.TextButton.MouseButton1Down:connect(function() N.State.scale_y_focused=true Ns.ScaleOption.YInput.TextBox:CaptureFocus()end) Ns.ScaleOption.YInput.TextBox.FocusLost:connect(function(v) local Il05=tonumber(Ns.ScaleOption.YInput.TextBox.Text)if Il05 then N:changeScale('y',Il05)end N.State.scale_y_focused=false end) Ns.ScaleOption.ZInput.TextButton.MouseButton1Down:connect(function() N.State.scale_z_focused=true Ns.ScaleOption.ZInput.TextBox:CaptureFocus()end) Ns.ScaleOption.ZInput.TextBox.FocusLost:connect(function(d0W) local b=tonumber(Ns.ScaleOption.ZInput.TextBox.Text)if b then N:changeScale('z',b)end N.State.scale_z_focused=false end) Ns.MeshIDOption.TextButton.MouseButton1Down:connect(function() N.State.mesh_id_focused=true Ns.MeshIDOption.TextBox:CaptureFocus()end) Ns.MeshIDOption.TextBox.FocusLost:connect(function(dG) local wF9WF=Ns.MeshIDOption.TextBox.Text local b097=tonumber(wF9WF)or wF9WF:lower():match("%?id=([0-9]+)")if b097 then N:changeMesh(b097)end N.State.mesh_id_focused=false end) Ns.TextureIDOption.TextButton.MouseButton1Down:connect(function() N.State.texture_id_focused=true Ns.TextureIDOption.TextBox:CaptureFocus()end) Ns.TextureIDOption.TextBox.FocusLost:connect(function(Qu1) local r6=Ns.TextureIDOption.TextBox.Text local DOx=tonumber(r6)or r6:lower():match("%?id=([0-9]+)")if DOx then N:changeTexture(DOx)end N.State.texture_id_focused=false end) Ns.TintOption.RInput.TextButton.MouseButton1Down:connect(function() N.State.tint_r_focused=true Ns.TintOption.RInput.TextBox:CaptureFocus()end) Ns.TintOption.RInput.TextBox.FocusLost:connect(function(sQe35a) local p2=tonumber(Ns.TintOption.RInput.TextBox.Text)if p2 then if p2 >255 then p2=255 elseif p2 <0 then p2=0 end N:changeTint('r',p2/255)end N.State.tint_r_focused=false end) Ns.TintOption.GInput.TextButton.MouseButton1Down:connect(function() N.State.tint_g_focused=true Ns.TintOption.GInput.TextBox:CaptureFocus()end) Ns.TintOption.GInput.TextBox.FocusLost:connect(function(TN) local vtk=tonumber(Ns.TintOption.GInput.TextBox.Text)if vtk then if vtk>255 then vtk=255 elseif vtk<0 then vtk=0 end N:changeTint('g',vtk/255)end N.State.tint_g_focused=false end) Ns.TintOption.BInput.TextButton.MouseButton1Down:connect(function() N.State.tint_b_focused=true Ns.TintOption.BInput.TextBox:CaptureFocus()end) Ns.TintOption.BInput.TextBox.FocusLost:connect(function(ENKi) local HgWdXJXD=tonumber(Ns.TintOption.BInput.TextBox.Text) if HgWdXJXD then if HgWdXJXD>255 then HgWdXJXD=255 elseif HgWdXJXD<0 then HgWdXJXD=0 end
N:changeTint('b',HgWdXJXD/255)end
N.State.tint_b_focused=false end) Ns.TintOption.HSVPicker.MouseButton1Up:connect(function() ColorPicker:start(function(...) local wiugbQS={...} if#wiugbQS==3 then local Cz5={} for UfgAV,LO0nqS in pairs(Selection.Items)do local PIht9=Support.GetChildOfClass(LO0nqS,"SpecialMesh")if PIht9 then table.insert(Cz5,PIht9)end end
N:startHistoryRecord(Cz5)for bn,A666l08 in pairs(Cz5)do A666l08.VertexColor=Vector3.new(Support.HSVToRGB(...))end N:finishHistoryRecord()end end,N.State.mesh_tint)end)N.GUI=Ns end
N.GUI.Visible=true end Tools.Mesh.addMesh=function(R02tO) local oVO={apply=function(R02tO)Selection:clear() for r,sZyXLp in pairs(R02tO.meshes)do sZyXLp.Parent=R02tO.mesh_parents[sZyXLp]Selection:add(sZyXLp.Parent)end end,unapply=function(R02tO) Selection:clear()for nHUmh,VEw8 in pairs(R02tO.meshes)do Selection:add(VEw8.Parent) VEw8.Parent=nil end end}local X0NOlR5={}local drv={} for QAD,R6Ky in pairs(Selection.Items)do local vq5u9jrx=Support.GetChildOfClass(R6Ky,"SpecialMesh") if not vq5u9jrx then local vq5u9jrx=RbxUtility.Create"SpecialMesh"{Parent=R6Ky,MeshType=Enum.MeshType.Brick}table.insert(X0NOlR5,vq5u9jrx)drv[vq5u9jrx]=R6Ky end end
oVO.meshes=X0NOlR5
oVO.mesh_parents=drv
History:add(oVO)end Tools.Mesh.removeMesh=function(kNsSSMzG) local ZcV={apply=function(kNsSSMzG)Selection:clear()for y6z6ip,v in pairs(kNsSSMzG.meshes)do Selection:add(v.Parent)v.Parent=nil end end,unapply=function(kNsSSMzG) Selection:clear() for Bu,_TI in pairs(kNsSSMzG.meshes)do _TI.Parent=kNsSSMzG.mesh_parents[_TI]Selection:add(_TI.Parent)end end}local WiZA={}local K4SQ1h2e={} for YE7,Q2e in pairs(Selection.Items)do local z=Support.GetChildrenOfClass(Q2e,"SpecialMesh")for YE7,Cy in pairs(z)do table.insert(WiZA,Cy)K4SQ1h2e[Cy]=Cy.Parent Cy.Parent=nil end end
ZcV.meshes=WiZA
ZcV.mesh_parents=K4SQ1h2e
History:add(ZcV)end Tools.Mesh.startHistoryRecord=function(ZhG,ARBIKz) if ZhG.State.HistoryRecord then ZhG.State.HistoryRecord=nil end ZhG.State.HistoryRecord={targets=Support.CloneTable(ARBIKz),initial_type={},terminal_type={},initial_mesh={},terminal_mesh={},initial_texture={},terminal_texture={},initial_scale={},terminal_scale={},initial_tint={},terminal_tint={},unapply=function(ZhG) Selection:clear() for p7,j in pairs(ZhG.targets)do if j then Selection:add(j.Parent) j.MeshType=ZhG.initial_type[j]j.MeshId=ZhG.initial_mesh[j] j.TextureId=ZhG.initial_texture[j]j.Scale=ZhG.initial_scale[j] j.VertexColor=ZhG.initial_tint[j]end end end,apply=function(ZhG) Selection:clear() for zbC2yHd0,I in pairs(ZhG.targets)do if I then Selection:add(I.Parent) I.MeshType=ZhG.terminal_type[I]I.MeshId=ZhG.terminal_mesh[I] I.TextureId=ZhG.terminal_texture[I]I.Scale=ZhG.terminal_scale[I] I.VertexColor=ZhG.terminal_tint[I]end end end} for Jt,aUu in pairs(ZhG.State.HistoryRecord.targets)do if aUu then ZhG.State.HistoryRecord.initial_type[aUu]=aUu.MeshType ZhG.State.HistoryRecord.initial_mesh[aUu]=aUu.MeshId ZhG.State.HistoryRecord.initial_texture[aUu]=aUu.TextureId ZhG.State.HistoryRecord.initial_scale[aUu]=aUu.Scale ZhG.State.HistoryRecord.initial_tint[aUu]=aUu.VertexColor end end end Tools.Mesh.finishHistoryRecord=function(We1INxkk) if not We1INxkk.State.HistoryRecord then return end for X37Nsx,eE in pairs(We1INxkk.State.HistoryRecord.targets)do if eE then We1INxkk.State.HistoryRecord.terminal_type[eE]=eE.MeshType We1INxkk.State.HistoryRecord.terminal_mesh[eE]=eE.MeshId We1INxkk.State.HistoryRecord.terminal_texture[eE]=eE.TextureId We1INxkk.State.HistoryRecord.terminal_scale[eE]=eE.Scale We1INxkk.State.HistoryRecord.terminal_tint[eE]=eE.VertexColor end end
History:add(We1INxkk.State.HistoryRecord)We1INxkk.State.HistoryRecord= nil end Tools.Mesh.changeMesh=function(pCWPYYE,g)local kUNaj9={} for Ewt,TzK in pairs(Selection.Items)do local jjU=Support.GetChildOfClass(TzK,"SpecialMesh")if jjU then table.insert(kUNaj9,jjU)end end
local AiX,CzFcrl,X8Gpm3 if HttpAvailable then local DGflu='http://www.f3xteam.com/bt/getFirstMeshData/%s' local FF9q1AO=HttpInterface.GetAsync(DGflu:format(g)) if FF9q1AO and FF9q1AO:len()>0 then local FF9q1AO=RbxUtility.DecodeJSON(FF9q1AO) if FF9q1AO and FF9q1AO.success then if FF9q1AO.meshID then g=FF9q1AO.meshID end
if FF9q1AO.textureID then AiX=FF9q1AO.textureID end CzFcrl=Vector3.new(FF9q1AO.tint.x,FF9q1AO.tint.y,FF9q1AO.tint.z) X8Gpm3=Vector3.new(FF9q1AO.scale.x,FF9q1AO.scale.y,FF9q1AO.scale.z)end end end
pCWPYYE:startHistoryRecord(kUNaj9) for pJWQ,DZJXU in pairs(kUNaj9)do if g then DZJXU.MeshId= "http://www.roblox.com/asset/?id="..g end
if AiX then DZJXU.TextureId="http://www.roblox.com/asset/?id="..AiX end if CzFcrl then DZJXU.VertexColor=CzFcrl end
if X8Gpm3 then DZJXU.Scale=X8Gpm3 end end
pCWPYYE:finishHistoryRecord()end Tools.Mesh.changeTexture=function(Oo6w,hN)local jz1uXDx={} for vTRoD0X,oX9O28J in pairs(Selection.Items)do local sTbHW=Support.GetChildOfClass(oX9O28J,"SpecialMesh")if sTbHW then table.insert(jz1uXDx,sTbHW)end end if HttpAvailable then local upZW='http://www.f3xteam.com/bt/getDecalImageID/%s' local AWQPjyxs=HttpInterface.GetAsync(upZW:format(hN)) if AWQPjyxs and AWQPjyxs:len()>0 then hN=AWQPjyxs end end
Oo6w:startHistoryRecord(jz1uXDx) for V,M in pairs(jz1uXDx)do M.TextureId= "http://www.roblox.com/asset/?id="..hN end
Oo6w:finishHistoryRecord()end Tools.Mesh.changeScale=function(sPh,RKD_1r,hnrLmi)local Ea23={} for gdet,x in pairs(Selection.Items)do local KzXd=Support.GetChildOfClass(x,"SpecialMesh")if KzXd then table.insert(Ea23,KzXd)end end
sPh:startHistoryRecord(Ea23) for gqa3M1,Z in pairs(Ea23)do Z.Scale=Vector3.new( RKD_1r=='x'and hnrLmi or Z.Scale.x,RKD_1r=='y'and hnrLmi or Z.Scale.y, RKD_1r=='z'and hnrLmi or Z.Scale.z)end
sPh:finishHistoryRecord()end Tools.Mesh.changeTint=function(neYEY,H0,r)local JF4a={} for HeQL,AuacAxlc in pairs(Selection.Items)do local Bk=Support.GetChildOfClass(AuacAxlc,"SpecialMesh")if Bk then table.insert(JF4a,Bk)end end
neYEY:startHistoryRecord(JF4a) for IulFXIJ,b in pairs(JF4a)do b.VertexColor=Vector3.new( H0 =='r'and r or b.VertexColor.x,H0 =='g'and r or b.VertexColor.y, H0 =='b'and r or b.VertexColor.z)end
neYEY:finishHistoryRecord()end Tools.Mesh.hideGUI=function(xfxoXu) if xfxoXu.GUI then xfxoXu.GUI.Visible=false end end
Tools.Mesh.Loaded=true end},{"Move",function() repeat wait()until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.Move={} Tools.Move.Color=BrickColor.new("Deep orange")Tools.Move.Connections={} Tools.Move.Options={["increment"]=1,["axes"]="global"} Tools.Move.State={["distance_moved"]=0,["moving"]=false,["PreMove"]={}}Tools.Move.Listeners={} Tools.Move.Listeners.Equipped=function() local KJ0Y6=Tools.Move
if not Mouse then return end KJ0Y6.State.PreviousSelectionBoxColor=SelectionBoxColor
SelectionBoxColor=KJ0Y6.Color
updateSelectionBoxColor() KJ0Y6:showGUI()if not KJ0Y6.BoundingBox then KJ0Y6.BoundingBox=RbxUtility.Create"Part"{Name="BTBoundingBox",CanCollide=false,Transparency=1,Anchored=true}end Mouse.TargetFilter=KJ0Y6.BoundingBox
KJ0Y6:changeAxes(KJ0Y6.Options.axes) KJ0Y6.Connections.DraggerKeyListener=Mouse.KeyDown:connect(function(C) local C=C:lower()if not KJ0Y6.Dragger then return end if C=="r"then KJ0Y6.Dragger:AxisRotate(Enum.Axis.Z)elseif C=="t"then KJ0Y6.Dragger:AxisRotate(Enum.Axis.X)elseif C=="y"then KJ0Y6.Dragger:AxisRotate(Enum.Axis.Y)end
KJ0Y6.Dragger:MouseMove(Mouse.UnitRay)end)KJ0Y6.State.StaticItems={}KJ0Y6.State.StaticExtents=nil KJ0Y6.State.RecalculateStaticExtents=true
local KPlOw={} function AddStaticItem(BA) if# Support.FindTableOccurrences(KJ0Y6.State.StaticItems,BA)>0 then return end
table.insert(KJ0Y6.State.StaticItems,BA) KPlOw[BA]=BA.Changed:connect(function(ybxsK) if ybxsK=='CFrame'or ybxsK=='Size'then KJ0Y6.State.RecalculateStaticExtents=true elseif ybxsK=='Anchored'and not BA.Anchored then RemoveStaticItem(BA)end end)KJ0Y6.State.RecalculateStaticExtents=true end function RemoveStaticItem(_0fP) local l6=Support.FindTableOccurrences(KJ0Y6.State.StaticItems,_0fP)[1]if l6 then KJ0Y6.State.StaticItems[l6]=nil end if KPlOw[_0fP]then KPlOw[_0fP]:disconnect()KPlOw[_0fP]=nil end
KJ0Y6.State.RecalculateStaticExtents=true end
for rGOqO96U,odN0bo in pairs(Selection.Items)do if odN0bo.Anchored then AddStaticItem(odN0bo)end end table.insert(KJ0Y6.Connections,Selection.ItemAdded:connect(function(sn1BOCT5)if sn1BOCT5.Anchored then AddStaticItem(sn1BOCT5)end end)) table.insert(KJ0Y6.Connections,Selection.ItemRemoved:connect(function(k0iue,J5)if J5 or not KPlOw[k0iue]then return end
RemoveStaticItem(k0iue)end)) table.insert(KJ0Y6.Connections,Selection.Cleared:connect(function()for d3,DAeG in pairs(KPlOw)do DAeG:disconnect()KPlOw[d3]=nil end KJ0Y6.State.StaticExtents=nil
KJ0Y6.State.StaticItems={}end)) coroutine.wrap(function()updater_on=true KJ0Y6.Updater=function()updater_on=false end while wait(0.1)and updater_on do if CurrentTool==KJ0Y6 then if KJ0Y6.GUI and KJ0Y6.GUI.Visible then KJ0Y6:updateGUI()end if KJ0Y6.Options.axes== "global"then KJ0Y6:updateBoundingBox()end end end end)()end Tools.Move.Listeners.Unequipped=function()local eb6VK=Tools.Move
if eb6VK.Updater then eb6VK.Updater()eb6VK.Updater=nil end eb6VK:FinishDragging()eb6VK:hideGUI()eb6VK:hideHandles()for U8PPAC,bK92X9wQ in pairs(eb6VK.Connections)do bK92X9wQ:disconnect() eb6VK.Connections[U8PPAC]=nil end SelectionBoxColor=eb6VK.State.PreviousSelectionBoxColor
updateSelectionBoxColor()end Tools.Move.updateGUI=function(PZ) if PZ.GUI then local toG0=PZ.GUI if#Selection.Items>0 then local EZ3qRhLq,E7Q,qts06Ch3=nil,nil,nil for cBwDRgK,veqNhn in pairs(Selection.Items)do if cBwDRgK==1 then EZ3qRhLq,E7Q,qts06Ch3=Support.Round(veqNhn.Position.x,2),Support.Round(veqNhn.Position.y,2),Support.Round(veqNhn.Position.z,2)else if EZ3qRhLq~=Support.Round(veqNhn.Position.x,2)then EZ3qRhLq= nil end
if E7Q~= Support.Round(veqNhn.Position.y,2)then E7Q=nil end
if qts06Ch3 ~= Support.Round(veqNhn.Position.z,2)then qts06Ch3=nil end end end
if not PZ.State.pos_x_focused then toG0.Info.Center.X.TextBox.Text= EZ3qRhLq and tostring(EZ3qRhLq)or"*"end if not PZ.State.pos_y_focused then toG0.Info.Center.Y.TextBox.Text= E7Q and tostring(E7Q)or"*"end
if not PZ.State.pos_z_focused then toG0.Info.Center.Z.TextBox.Text= qts06Ch3 and tostring(qts06Ch3)or"*"end toG0.Info.Visible=true else toG0.Info.Visible=false end if PZ.State.distance_moved then toG0.Changes.Text.Text="moved ".. tostring(PZ.State.distance_moved).." studs" toG0.Changes.Position=toG0.Info.Visible and UDim2.new(0,5,0,165)or UDim2.new(0,5,0,100)toG0.Changes.Visible=true else toG0.Changes.Text.Text="" toG0.Changes.Visible=false end end end Tools.Move.changePosition=function(OiD,prw2Jl,oo)OiD:startHistoryRecord() for DYo,kcCL9hT in pairs(Selection.Items)do kcCL9hT.CFrame= CFrame.new(prw2Jl=='x'and oo or kcCL9hT.Position.x, prw2Jl=='y'and oo or kcCL9hT.Position.y, prw2Jl=='z'and oo or kcCL9hT.Position.z)* CFrame.Angles(kcCL9hT.CFrame:toEulerAnglesXYZ())end
OiD:finishHistoryRecord()end Tools.Move.startHistoryRecord=function(pvg) if pvg.State.HistoryRecord then pvg.State.HistoryRecord=nil end pvg.State.HistoryRecord={targets=Support.CloneTable(Selection.Items),initial_positions={},terminal_positions={},unapply=function(pvg) Selection:clear() for M,USR in pairs(pvg.targets)do if USR then USR.CFrame=pvg.initial_positions[USR] USR:MakeJoints()Selection:add(USR)end end end,apply=function(pvg) Selection:clear() for Wxk9CBfb,V in pairs(pvg.targets)do if V then V.CFrame=pvg.terminal_positions[V] V:MakeJoints()Selection:add(V)end end end} for jWPa,d in pairs(pvg.State.HistoryRecord.targets)do if d then pvg.State.HistoryRecord.initial_positions[d]=d.CFrame end end end Tools.Move.finishHistoryRecord=function(j3Fn) if not j3Fn.State.HistoryRecord then return end for oZ65m5,hQjlCjY in pairs(j3Fn.State.HistoryRecord.targets)do if hQjlCjY then j3Fn.State.HistoryRecord.terminal_positions[hQjlCjY]=hQjlCjY.CFrame end end
History:add(j3Fn.State.HistoryRecord)j3Fn.State.HistoryRecord= nil end Tools.Move.StartDragging=function(JDyNU5,cMv6ou) for HPZKRJ,cn in pairs(Selection.Items)do cn.RotVelocity=Vector3.new(0,0,0)cn.Velocity=Vector3.new(0,0,0)end
JDyNU5:startHistoryRecord() JDyNU5.State.dragging=true
override_selection=true JDyNU5.Dragger=Instance.new("Dragger") JDyNU5.Dragger:MouseDown(cMv6ou,cMv6ou.CFrame:toObjectSpace(CFrame.new(Mouse.Hit.p)).p,Selection.Items) JDyNU5.Connections.DraggerConnection=UserInputService.InputEnded:connect(function(_Yf)if _Yf.UserInputType==Enum.UserInputType.MouseButton1 then JDyNU5:FinishDragging()end end)end Tools.Move.FinishDragging=function(rl)override_selection=true if rl.Connections.DraggerConnection then rl.Connections.DraggerConnection:disconnect()rl.Connections.DraggerConnection=nil end
if not rl.Dragger then return end
rl.Dragger:MouseUp() rl.State.dragging=false
rl.Dragger:Destroy()rl.Dragger=nil rl:finishHistoryRecord()end Tools.Move.Listeners.Button1Down=function()local Z=Tools.Move local jOFP=Z.ManualTarget or Mouse.Target
Z.ManualTarget=nil if not Selection:find(jOFP)and isSelectable(jOFP)then Selection:clear()Selection:add(jOFP)end
if not Selection:find(jOFP)then return end Z:StartDragging(jOFP)end Tools.Move.Listeners.Move=function()local LCqNO=Tools.Move if not LCqNO.Dragger then return end
override_selection=true LCqNO.Dragger:MouseMove(Mouse.UnitRay)end Tools.Move.Listeners.KeyUp=function(jF4YoB)local nROZ=Tools.Move
if jF4YoB=='-'and nROZ.GUI then nROZ.GUI.IncrementOption.Increment.TextBox:CaptureFocus()end end Tools.Move.showGUI=function(_GVROa) if not _GVROa.GUI then local bO3YuZv=DFb100j.BTMoveToolGUI:Clone()bO3YuZv.Parent=UI bO3YuZv.AxesOption.Global.Button.MouseButton1Down:connect(function() _GVROa:changeAxes("global") bO3YuZv.AxesOption.Global.SelectedIndicator.BackgroundTransparency=0 bO3YuZv.AxesOption.Global.Background.Image=Assets.DarkSlantedRectangle bO3YuZv.AxesOption.Local.SelectedIndicator.BackgroundTransparency=1 bO3YuZv.AxesOption.Local.Background.Image=Assets.LightSlantedRectangle bO3YuZv.AxesOption.Last.SelectedIndicator.BackgroundTransparency=1 bO3YuZv.AxesOption.Last.Background.Image=Assets.LightSlantedRectangle end) bO3YuZv.AxesOption.Local.Button.MouseButton1Down:connect(function() _GVROa:changeAxes("local") bO3YuZv.AxesOption.Global.SelectedIndicator.BackgroundTransparency=1 bO3YuZv.AxesOption.Global.Background.Image=Assets.LightSlantedRectangle bO3YuZv.AxesOption.Local.SelectedIndicator.BackgroundTransparency=0 bO3YuZv.AxesOption.Local.Background.Image=Assets.DarkSlantedRectangle bO3YuZv.AxesOption.Last.SelectedIndicator.BackgroundTransparency=1 bO3YuZv.AxesOption.Last.Background.Image=Assets.LightSlantedRectangle end) bO3YuZv.AxesOption.Last.Button.MouseButton1Down:connect(function() _GVROa:changeAxes("last") bO3YuZv.AxesOption.Global.SelectedIndicator.BackgroundTransparency=1 bO3YuZv.AxesOption.Global.Background.Image=Assets.LightSlantedRectangle bO3YuZv.AxesOption.Local.SelectedIndicator.BackgroundTransparency=1 bO3YuZv.AxesOption.Local.Background.Image=Assets.LightSlantedRectangle bO3YuZv.AxesOption.Last.SelectedIndicator.BackgroundTransparency=0 bO3YuZv.AxesOption.Last.Background.Image=Assets.DarkSlantedRectangle end) bO3YuZv.IncrementOption.Increment.TextBox.FocusLost:connect(function(Vq) _GVROa.Options.increment= tonumber(bO3YuZv.IncrementOption.Increment.TextBox.Text)or _GVROa.Options.increment bO3YuZv.IncrementOption.Increment.TextBox.Text=tostring(_GVROa.Options.increment)end) bO3YuZv.Info.Center.X.TextButton.MouseButton1Down:connect(function() _GVROa.State.pos_x_focused=true bO3YuZv.Info.Center.X.TextBox:CaptureFocus()end) bO3YuZv.Info.Center.X.TextBox.FocusLost:connect(function(cW) local c7GfSrtA=tonumber(bO3YuZv.Info.Center.X.TextBox.Text) if c7GfSrtA then _GVROa:changePosition('x',c7GfSrtA)end
_GVROa.State.pos_x_focused=false end) bO3YuZv.Info.Center.Y.TextButton.MouseButton1Down:connect(function() _GVROa.State.pos_y_focused=true bO3YuZv.Info.Center.Y.TextBox:CaptureFocus()end) bO3YuZv.Info.Center.Y.TextBox.FocusLost:connect(function(lEP9VGU) local xpKd=tonumber(bO3YuZv.Info.Center.Y.TextBox.Text)if xpKd then _GVROa:changePosition('y',xpKd)end _GVROa.State.pos_y_focused=false end) bO3YuZv.Info.Center.Z.TextButton.MouseButton1Down:connect(function() _GVROa.State.pos_z_focused=true bO3YuZv.Info.Center.Z.TextBox:CaptureFocus()end) bO3YuZv.Info.Center.Z.TextBox.FocusLost:connect(function(r) local oa=tonumber(bO3YuZv.Info.Center.Z.TextBox.Text)if oa then _GVROa:changePosition('z',oa)end _GVROa.State.pos_z_focused=false end)_GVROa.GUI=bO3YuZv end
_GVROa.GUI.Visible=true end Tools.Move.hideGUI=function(dT)if dT.GUI then dT.GUI.Visible=false end end Tools.Move.showHandles=function(xa78yAit,s_CnSV) if not xa78yAit.Handles then xa78yAit.Handles=RbxUtility.Create"Handles"{Name="BTMovementHandles",Color=xa78yAit.Color,Parent=GUIContainer} xa78yAit.Handles.MouseButton1Down:connect(function()override_selection=true xa78yAit.State.moving=true
xa78yAit.State.distance_moved=0 xa78yAit:startHistoryRecord() for s,wqRzXIG7 in pairs(Selection.Items)do xa78yAit.State.PreMove[wqRzXIG7]=wqRzXIG7:Clone()wqRzXIG7.Anchored=true end xa78yAit.Connections.HandleReleaseListener=UserInputService.InputEnded:connect(function(w3nHh) if w3nHh.UserInputType~=Enum.UserInputType.MouseButton1 then return end
override_selection=true
xa78yAit.State.moving=false if xa78yAit.Connections.HandleReleaseListener then xa78yAit.Connections.HandleReleaseListener:disconnect()xa78yAit.Connections.HandleReleaseListener=nil end
xa78yAit:finishHistoryRecord() for bo0I,lK5ogD in pairs(xa78yAit.State.PreMove)do bo0I.Anchored=lK5ogD.Anchored xa78yAit.State.PreMove[bo0I]=nil
bo0I:MakeJoints()bo0I.Velocity=Vector3.new(0,0,0) bo0I.RotVelocity=Vector3.new(0,0,0)end end)end) xa78yAit.Handles.MouseDrag:connect(function(I8F,Y3NU) local Avel7IrZ=Y3NU%xa78yAit.Options.increment
local F=Y3NU-Avel7IrZ local _=Y3NU-Avel7IrZ+xa78yAit.Options.increment
local DpWpo7kA=math.abs(Y3NU-F)local LS=math.abs(Y3NU-_)if DpWpo7kA<=LS then Y3NU=F else Y3NU=_ end
local cQvh=Y3NU xa78yAit.State.distance_moved=Y3NU for llU3aki,HQrwQErj in pairs(Selection.Items)do HQrwQErj:BreakJoints() if I8F== Enum.NormalId.Top then if xa78yAit.Options.axes=="global"then HQrwQErj.CFrame= CFrame.new(xa78yAit.State.PreMove[HQrwQErj].CFrame.p):toWorldSpace(CFrame.new(0,cQvh,0))* CFrame.Angles(xa78yAit.State.PreMove[HQrwQErj].CFrame:toEulerAnglesXYZ())elseif xa78yAit.Options.axes=="local"then HQrwQErj.CFrame=xa78yAit.State.PreMove[HQrwQErj].CFrame:toWorldSpace(CFrame.new(0,cQvh,0))elseif xa78yAit.Options.axes=="last"then HQrwQErj.CFrame=xa78yAit.State.PreMove[Selection.Last].CFrame:toWorldSpace(CFrame.new(0,cQvh,0)):toWorldSpace(xa78yAit.State.PreMove[HQrwQErj].CFrame:toObjectSpace(xa78yAit.State.PreMove[Selection.Last].CFrame):inverse())end elseif I8F==Enum.NormalId.Bottom then if xa78yAit.Options.axes=="global"then HQrwQErj.CFrame=CFrame.new(xa78yAit.State.PreMove[HQrwQErj].CFrame.p):toWorldSpace(CFrame.new(0, -cQvh,0))* CFrame.Angles(xa78yAit.State.PreMove[HQrwQErj].CFrame:toEulerAnglesXYZ())elseif xa78yAit.Options.axes=="local"then HQrwQErj.CFrame=xa78yAit.State.PreMove[HQrwQErj].CFrame:toWorldSpace(CFrame.new(0, -cQvh,0))elseif xa78yAit.Options.axes=="last"then HQrwQErj.CFrame=xa78yAit.State.PreMove[Selection.Last].CFrame:toWorldSpace(CFrame.new(0, -cQvh,0)):toWorldSpace(xa78yAit.State.PreMove[HQrwQErj].CFrame:toObjectSpace(xa78yAit.State.PreMove[Selection.Last].CFrame):inverse())end elseif I8F==Enum.NormalId.Front then if xa78yAit.Options.axes=="global"then HQrwQErj.CFrame=CFrame.new(xa78yAit.State.PreMove[HQrwQErj].CFrame.p):toWorldSpace(CFrame.new(0,0, -cQvh))* CFrame.Angles(xa78yAit.State.PreMove[HQrwQErj].CFrame:toEulerAnglesXYZ())elseif xa78yAit.Options.axes=="local"then HQrwQErj.CFrame=xa78yAit.State.PreMove[HQrwQErj].CFrame:toWorldSpace(CFrame.new(0,0, -cQvh))elseif xa78yAit.Options.axes=="last"then HQrwQErj.CFrame=xa78yAit.State.PreMove[Selection.Last].CFrame:toWorldSpace(CFrame.new(0,0, -cQvh)):toWorldSpace(xa78yAit.State.PreMove[HQrwQErj].CFrame:toObjectSpace(xa78yAit.State.PreMove[Selection.Last].CFrame):inverse())end elseif I8F==Enum.NormalId.Back then if xa78yAit.Options.axes=="global"then HQrwQErj.CFrame= CFrame.new(xa78yAit.State.PreMove[HQrwQErj].CFrame.p):toWorldSpace(CFrame.new(0,0,cQvh))* CFrame.Angles(xa78yAit.State.PreMove[HQrwQErj].CFrame:toEulerAnglesXYZ())elseif xa78yAit.Options.axes=="local"then HQrwQErj.CFrame=xa78yAit.State.PreMove[HQrwQErj].CFrame:toWorldSpace(CFrame.new(0,0,cQvh))elseif xa78yAit.Options.axes=="last"then HQrwQErj.CFrame=xa78yAit.State.PreMove[Selection.Last].CFrame:toWorldSpace(CFrame.new(0,0,cQvh)):toWorldSpace(xa78yAit.State.PreMove[HQrwQErj].CFrame:toObjectSpace(xa78yAit.State.PreMove[Selection.Last].CFrame):inverse())end elseif I8F==Enum.NormalId.Right then if xa78yAit.Options.axes=="global"then HQrwQErj.CFrame= CFrame.new(xa78yAit.State.PreMove[HQrwQErj].CFrame.p):toWorldSpace(CFrame.new(cQvh,0,0))* CFrame.Angles(xa78yAit.State.PreMove[HQrwQErj].CFrame:toEulerAnglesXYZ())elseif xa78yAit.Options.axes=="local"then HQrwQErj.CFrame=xa78yAit.State.PreMove[HQrwQErj].CFrame:toWorldSpace(CFrame.new(cQvh,0,0))elseif xa78yAit.Options.axes=="last"then HQrwQErj.CFrame=xa78yAit.State.PreMove[Selection.Last].CFrame:toWorldSpace(CFrame.new(cQvh,0,0)):toWorldSpace(xa78yAit.State.PreMove[HQrwQErj].CFrame:toObjectSpace(xa78yAit.State.PreMove[Selection.Last].CFrame):inverse())end elseif I8F==Enum.NormalId.Left then if xa78yAit.Options.axes=="global"then HQrwQErj.CFrame=CFrame.new(xa78yAit.State.PreMove[HQrwQErj].CFrame.p):toWorldSpace(CFrame.new( -cQvh,0,0))* CFrame.Angles(xa78yAit.State.PreMove[HQrwQErj].CFrame:toEulerAnglesXYZ())elseif xa78yAit.Options.axes=="local"then HQrwQErj.CFrame=xa78yAit.State.PreMove[HQrwQErj].CFrame:toWorldSpace(CFrame.new( -cQvh,0,0))elseif xa78yAit.Options.axes=="last"then HQrwQErj.CFrame=xa78yAit.State.PreMove[Selection.Last].CFrame:toWorldSpace(CFrame.new( -cQvh,0,0)):toWorldSpace(xa78yAit.State.PreMove[HQrwQErj].CFrame:toObjectSpace(xa78yAit.State.PreMove[Selection.Last].CFrame):inverse())end end end end)end if xa78yAit.Connections.AdorneeExistenceListener then xa78yAit.Connections.AdorneeExistenceListener:disconnect()xa78yAit.Connections.AdorneeExistenceListener=nil end
xa78yAit.Handles.Adornee=s_CnSV xa78yAit.Connections.AdorneeExistenceListener=s_CnSV.AncestryChanged:connect(function(tu,XSuzlcm)if tu~=s_CnSV then return end
if XSuzlcm==nil then xa78yAit:hideHandles()else xa78yAit:showHandles(s_CnSV)end end)end Tools.Move.hideHandles=function(nbAjk49J) if nbAjk49J.Handles then nbAjk49J.Handles.Adornee=nil end end Tools.Move.updateBoundingBox=function(cB0vBn) if#Selection.Items>0 and not cB0vBn.State.dragging then if cB0vBn.State.RecalculateStaticExtents then cB0vBn.State.StaticExtents=calculateExtents(cB0vBn.State.StaticItems, nil,true) cB0vBn.State.RecalculateStaticExtents=false end local IccvGO,BNC=calculateExtents(Selection.Items,cB0vBn.State.StaticExtents)cB0vBn.BoundingBox.Size=IccvGO cB0vBn.BoundingBox.CFrame=BNC
cB0vBn:showHandles(cB0vBn.BoundingBox)else cB0vBn:hideHandles()end end Tools.Move.changeAxes=function(s3,QXOjuVP) local KOk=s3.GUI and s3.GUI.AxesOption or nil if s3.Connections.HandleFocusChangeListener then s3.Connections.HandleFocusChangeListener:disconnect()s3.Connections.HandleFocusChangeListener=nil end if s3.Connections.HandleSelectionChangeListener then s3.Connections.HandleSelectionChangeListener:disconnect()s3.Connections.HandleSelectionChangeListener=nil end if QXOjuVP=="global"then s3.Options.axes="global"s3:hideHandles() s3:showHandles(s3.BoundingBox) if s3.GUI then KOk.Global.SelectedIndicator.BackgroundTransparency=0
KOk.Global.Background.Image=Assets.DarkSlantedRectangle KOk.Local.SelectedIndicator.BackgroundTransparency=1
KOk.Local.Background.Image=Assets.LightSlantedRectangle KOk.Last.SelectedIndicator.BackgroundTransparency=1
KOk.Last.Background.Image=Assets.LightSlantedRectangle end end if QXOjuVP=="local"then s3.Options.axes="local" s3.Connections.HandleSelectionChangeListener=Selection.Changed:connect(function() s3:hideHandles() if Selection.Last then s3:showHandles(Selection.Last)end end) s3.Connections.HandleFocusChangeListener=Mouse.Button2Up:connect(function()override_selection=true
if Selection:find(Mouse.Target)then Selection:focus(Mouse.Target) s3:showHandles(Mouse.Target)end end) if Selection.Last then s3:showHandles(Selection.Last)end if s3.GUI then KOk.Global.SelectedIndicator.BackgroundTransparency=1 KOk.Global.Background.Image=Assets.LightSlantedRectangle
KOk.Local.SelectedIndicator.BackgroundTransparency=0 KOk.Local.Background.Image=Assets.DarkSlantedRectangle
KOk.Last.SelectedIndicator.BackgroundTransparency=1 KOk.Last.Background.Image=Assets.LightSlantedRectangle end end if QXOjuVP=="last"then s3.Options.axes="last" s3.Connections.HandleSelectionChangeListener=Selection.Changed:connect(function() s3:hideHandles() if Selection.Last then s3:showHandles(Selection.Last)end end) s3.Connections.HandleFocusChangeListener=Mouse.Button2Up:connect(function()override_selection=true
if Selection:find(Mouse.Target)then Selection:focus(Mouse.Target) s3:showHandles(Mouse.Target)end end) if Selection.Last then s3:showHandles(Selection.Last)end if s3.GUI then KOk.Global.SelectedIndicator.BackgroundTransparency=1 KOk.Global.Background.Image=Assets.LightSlantedRectangle
KOk.Local.SelectedIndicator.BackgroundTransparency=1 KOk.Local.Background.Image=Assets.LightSlantedRectangle
KOk.Last.SelectedIndicator.BackgroundTransparency=0 KOk.Last.Background.Image=Assets.DarkSlantedRectangle end end end
Tools.Move.Loaded=true end},{"NewPart",function() repeat wait()until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.NewPart={} Tools.NewPart.Color=BrickColor.new("Really black")Tools.NewPart.Connections={} Tools.NewPart.State={["Part"]=nil}Tools.NewPart.Options={["type"]="normal"} Tools.NewPart.Listeners={} Tools.NewPart.Listeners.Equipped=function()local GQ8QsA=Tools.NewPart GQ8QsA.State.PreviousSelectionBoxColor=SelectionBoxColor
SelectionBoxColor=GQ8QsA.Color
updateSelectionBoxColor() GQ8QsA:showGUI()GQ8QsA:changeType(GQ8QsA.Options.type)end Tools.NewPart.Listeners.Unequipped=function()local B=Tools.NewPart
B:hideGUI() for i,zmF in pairs(B.Connections)do zmF:disconnect()B.Connections[i]=nil end
SelectionBoxColor=B.State.PreviousSelectionBoxColor updateSelectionBoxColor()end Tools.NewPart.Listeners.Button1Down=function()local RKBSOvv=Tools.NewPart
local GxQqHPYH if RKBSOvv.Options.type=="normal"then GxQqHPYH=Instance.new("Part",Workspace)GxQqHPYH.FormFactor=Enum.FormFactor.Custom GxQqHPYH.Size=Vector3.new(4,1,2)elseif RKBSOvv.Options.type=="truss"then GxQqHPYH=Instance.new("TrussPart",Workspace)elseif RKBSOvv.Options.type=="wedge"then GxQqHPYH=Instance.new("WedgePart",Workspace)GxQqHPYH.FormFactor=Enum.FormFactor.Custom GxQqHPYH.Size=Vector3.new(4,1,2)elseif RKBSOvv.Options.type=="corner"then GxQqHPYH=Instance.new("CornerWedgePart",Workspace)elseif RKBSOvv.Options.type=="cylinder"then GxQqHPYH=Instance.new("Part",Workspace)GxQqHPYH.Shape="Cylinder" GxQqHPYH.FormFactor=Enum.FormFactor.Custom
GxQqHPYH.TopSurface=Enum.SurfaceType.Smooth GxQqHPYH.BottomSurface=Enum.SurfaceType.Smooth elseif RKBSOvv.Options.type=="ball"then GxQqHPYH=Instance.new("Part",Workspace)GxQqHPYH.Shape="Ball" GxQqHPYH.FormFactor=Enum.FormFactor.Custom
GxQqHPYH.TopSurface=Enum.SurfaceType.Smooth GxQqHPYH.BottomSurface=Enum.SurfaceType.Smooth elseif RKBSOvv.Options.type=="seat"then GxQqHPYH=Instance.new("Seat",Workspace)GxQqHPYH.FormFactor=Enum.FormFactor.Custom GxQqHPYH.Size=Vector3.new(4,1,2)elseif RKBSOvv.Options.type=="vehicle seat"then GxQqHPYH=Instance.new("VehicleSeat",Workspace)GxQqHPYH.Size=Vector3.new(4,1,2)elseif RKBSOvv.Options.type=="spawn"then GxQqHPYH=Instance.new("SpawnLocation",Workspace) GxQqHPYH.FormFactor=Enum.FormFactor.Custom
GxQqHPYH.Size=Vector3.new(4,1,2)end
GxQqHPYH.Anchored=true
Selection:clear() Selection:add(GxQqHPYH) local KEhfU={target=GxQqHPYH,apply=function(RKBSOvv)Selection:clear() if RKBSOvv.target then RKBSOvv.target.Parent=Workspace
Selection:add(RKBSOvv.target)end end,unapply=function(RKBSOvv)if RKBSOvv.target then RKBSOvv.target.Parent= nil end end}History:add(KEhfU)equipTool(Tools.Move) Tools.Move.ManualTarget=GxQqHPYH
GxQqHPYH.CFrame=CFrame.new(Mouse.Hit.p) Tools.Move.Listeners.Button1Down()Tools.Move.Listeners.Move()end Tools.NewPart.changeType=function(zufQE,QwSnT)zufQE.Options.type=QwSnT zufQE.TypeDropdown:selectOption(QwSnT:upper()) if zufQE.TypeDropdown.open then zufQE.TypeDropdown:toggle()end end Tools.NewPart.showGUI=function(WrvmQJ6) if not WrvmQJ6.GUI then local rOMAEo=DFb100j.BTNewPartToolGUI:Clone()rOMAEo.Parent=UI
local SFGo78=createDropdown() WrvmQJ6.TypeDropdown=SFGo78
SFGo78.Frame.Parent=rOMAEo.TypeOption SFGo78.Frame.Position=UDim2.new(0,70,0,0)SFGo78.Frame.Size=UDim2.new(0,140,0,25) SFGo78:addOption("NORMAL").MouseButton1Up:connect(function() WrvmQJ6:changeType("normal")end) SFGo78:addOption("TRUSS").MouseButton1Up:connect(function() WrvmQJ6:changeType("truss")end) SFGo78:addOption("WEDGE").MouseButton1Up:connect(function() WrvmQJ6:changeType("wedge")end) SFGo78:addOption("CORNER").MouseButton1Up:connect(function() WrvmQJ6:changeType("corner")end) SFGo78:addOption("CYLINDER").MouseButton1Up:connect(function() WrvmQJ6:changeType("cylinder")end) SFGo78:addOption("BALL").MouseButton1Up:connect(function() WrvmQJ6:changeType("ball")end) SFGo78:addOption("SEAT").MouseButton1Up:connect(function() WrvmQJ6:changeType("seat")end) SFGo78:addOption("VEHICLE SEAT").MouseButton1Up:connect(function() WrvmQJ6:changeType("vehicle seat")end) SFGo78:addOption("SPAWN").MouseButton1Up:connect(function() WrvmQJ6:changeType("spawn")end)WrvmQJ6.GUI=rOMAEo end
WrvmQJ6.GUI.Visible=true end Tools.NewPart.hideGUI=function(LTd5)if LTd5.GUI then LTd5.GUI.Visible=false end end
Tools.NewPart.Loaded=true end},{"Paint",function() repeat wait()until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.Paint={} Tools.Paint.Color=BrickColor.new("Really red")Tools.Paint.Options={["Color"]=nil}Tools.Paint.State={} Tools.Paint.Listeners={} Tools.Paint.Listeners.Equipped=function()local JmrwaH=Tools.Paint JmrwaH.State.PreviousSelectionBoxColor=SelectionBoxColor
SelectionBoxColor=JmrwaH.Color
updateSelectionBoxColor() JmrwaH:showGUI()JmrwaH:changeColor(JmrwaH.Options.Color)end Tools.Paint.Listeners.Unequipped=function()local qqciA=Tools.Paint qqciA:changeColor(nil)qqciA:hideGUI() SelectionBoxColor=qqciA.State.PreviousSelectionBoxColor
updateSelectionBoxColor()end Tools.Paint.startHistoryRecord=function(bgKb)if bgKb.State.HistoryRecord then bgKb.State.HistoryRecord=nil end bgKb.State.HistoryRecord={targets=Support.CloneTable(Selection.Items),initial_colors={},terminal_colors={},unapply=function(bgKb) Selection:clear()for b0q,MRluMhh in pairs(bgKb.targets)do if MRluMhh then MRluMhh.BrickColor=bgKb.initial_colors[MRluMhh]Selection:add(MRluMhh)end end end,apply=function(bgKb) Selection:clear() for n0R1Mj,a4j6 in pairs(bgKb.targets)do if a4j6 then a4j6.BrickColor=bgKb.terminal_colors[a4j6]Selection:add(a4j6)end end end} for lg6u,ubseU in pairs(bgKb.State.HistoryRecord.targets)do if ubseU then bgKb.State.HistoryRecord.initial_colors[ubseU]=ubseU.BrickColor end end end Tools.Paint.finishHistoryRecord=function(kfDX) if not kfDX.State.HistoryRecord then return end for g26,HDP in pairs(kfDX.State.HistoryRecord.targets)do if HDP then kfDX.State.HistoryRecord.terminal_colors[HDP]=HDP.BrickColor end end
History:add(kfDX.State.HistoryRecord)kfDX.State.HistoryRecord= nil end Tools.Paint.Listeners.Button1Up=function()local c6nlekUb=Tools.Paint if  Selection:find(Mouse.Target)and not selecting and not selecting then override_selection=true
c6nlekUb:startHistoryRecord() if c6nlekUb.Options.Color then for NJQ0,o_v3 in pairs(Selection.Items)do o_v3.BrickColor=c6nlekUb.Options.Color end end
c6nlekUb:finishHistoryRecord()end end Tools.Paint.changeColor=function(zI,ET) if ET then zI.Options.Color=ET zI:startHistoryRecord() for RPrsE2M,T2WO5I in pairs(Selection.Items)do T2WO5I.BrickColor=ET end
zI:finishHistoryRecord()if zI.GUI then for f7pL,bHs in pairs(zI.GUI.Palette:GetChildren())do bHs.Text=""end zI.GUI.Palette[ET.Name].Text="X"end else zI.Options.Color=nil if zI.GUI then for eThxHw,tJVrOA in pairs(zI.GUI.Palette:GetChildren())do tJVrOA.Text=""end end end end Tools.Paint.showGUI=function(tqJFy) if not tqJFy.GUI then local EoFG=DFb100j.BTPaintToolGUI:Clone()EoFG.Parent=UI
for DQsI,Cam in pairs(EoFG.Palette:GetChildren())do Cam.MouseButton1Click:connect(function() tqJFy:changeColor(BrickColor.new(Cam.Name))end)end tqJFy.GUI=EoFG end
tqJFy.GUI.Visible=true end Tools.Paint.hideGUI=function(wF77)if wF77.GUI then wF77.GUI.Visible=false end end
Tools.Paint.Loaded=true end},{"Resize",function() repeat wait()until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.Resize={} Tools.Resize.Connections={} Tools.Resize.Options={["increment"]=1,["directions"]="normal"} Tools.Resize.State={["PreResize"]={},["previous_distance"]=0,["resizing"]=false,["length_resized"]=0}Tools.Resize.Listeners={} Tools.Resize.Color=BrickColor.new("Cyan") Tools.Resize.Listeners.Equipped=function()local A5pk0=Tools.Resize A5pk0.State.PreviousSelectionBoxColor=SelectionBoxColor
SelectionBoxColor=A5pk0.Color
updateSelectionBoxColor() A5pk0:showGUI() table.insert(A5pk0.Connections,Selection.Changed:connect(function()A5pk0:hideHandles() if Selection.Last then A5pk0:showHandles(Selection.Last)end end)) table.insert(A5pk0.Connections,Mouse.Button2Up:connect(function()override_selection=true if Selection:find(Mouse.Target)then Selection:focus(Mouse.Target)end end)) if Selection.Last then A5pk0:showHandles(Selection.Last)end coroutine.wrap(function()updater_on=true A5pk0.Updater=function()updater_on=false end
while wait(0.1)and updater_on do if CurrentTool==A5pk0 then if A5pk0.GUI and A5pk0.GUI.Visible then A5pk0:updateGUI()end end end end)()end Tools.Resize.Listeners.Unequipped=function()local j=Tools.Resize
if j.Updater then j.Updater()j.Updater=nil end
j:hideGUI()j:hideHandles() for XE,vtfBBQgI in pairs(j.Connections)do vtfBBQgI:disconnect()j.Connections[XE]=nil end
SelectionBoxColor=j.State.PreviousSelectionBoxColor updateSelectionBoxColor()end Tools.Resize.Listeners.KeyUp=function(U1Ca2x)local AM_2j6=Tools.Resize
if U1Ca2x=='-'and AM_2j6.GUI then AM_2j6.GUI.IncrementOption.Increment.TextBox:CaptureFocus()end end Tools.Resize.showGUI=function(tqvqCh) if not tqvqCh.GUI then local wQb3=DFb100j.BTResizeToolGUI:Clone()wQb3.Parent=UI wQb3.DirectionsOption.Normal.Button.MouseButton1Down:connect(function() tqvqCh.Options.directions="normal" wQb3.DirectionsOption.Normal.SelectedIndicator.BackgroundTransparency=0 wQb3.DirectionsOption.Normal.Background.Image=Assets.DarkSlantedRectangle wQb3.DirectionsOption.Both.SelectedIndicator.BackgroundTransparency=1 wQb3.DirectionsOption.Both.Background.Image=Assets.LightSlantedRectangle end) wQb3.DirectionsOption.Both.Button.MouseButton1Down:connect(function() tqvqCh.Options.directions="both" wQb3.DirectionsOption.Normal.SelectedIndicator.BackgroundTransparency=1 wQb3.DirectionsOption.Normal.Background.Image=Assets.LightSlantedRectangle wQb3.DirectionsOption.Both.SelectedIndicator.BackgroundTransparency=0 wQb3.DirectionsOption.Both.Background.Image=Assets.DarkSlantedRectangle end) wQb3.IncrementOption.Increment.TextBox.FocusLost:connect(function(MV_ePmkQ) tqvqCh.Options.increment= tonumber(wQb3.IncrementOption.Increment.TextBox.Text)or tqvqCh.Options.increment wQb3.IncrementOption.Increment.TextBox.Text=tostring(tqvqCh.Options.increment)end) wQb3.Info.SizeInfo.X.TextButton.MouseButton1Down:connect(function() tqvqCh.State.size_x_focused=true wQb3.Info.SizeInfo.X.TextBox:CaptureFocus()end) wQb3.Info.SizeInfo.X.TextBox.FocusLost:connect(function(cX3Y) local dOb=tonumber(wQb3.Info.SizeInfo.X.TextBox.Text)if dOb then tqvqCh:changeSize('x',dOb)end tqvqCh.State.size_x_focused=false end) wQb3.Info.SizeInfo.Y.TextButton.MouseButton1Down:connect(function() tqvqCh.State.size_y_focused=true wQb3.Info.SizeInfo.Y.TextBox:CaptureFocus()end) wQb3.Info.SizeInfo.Y.TextBox.FocusLost:connect(function(JTBnP) local Nm=tonumber(wQb3.Info.SizeInfo.Y.TextBox.Text)if Nm then tqvqCh:changeSize('y',Nm)end tqvqCh.State.size_y_focused=false end) wQb3.Info.SizeInfo.Z.TextButton.MouseButton1Down:connect(function() tqvqCh.State.size_z_focused=true wQb3.Info.SizeInfo.Z.TextBox:CaptureFocus()end) wQb3.Info.SizeInfo.Z.TextBox.FocusLost:connect(function(sCwnNPE) local J=tonumber(wQb3.Info.SizeInfo.Z.TextBox.Text)if J then tqvqCh:changeSize('z',J)end tqvqCh.State.size_z_focused=false end)tqvqCh.GUI=wQb3 end
tqvqCh.GUI.Visible=true end Tools.Resize.startHistoryRecord=function(jUlV2)if jUlV2.State.HistoryRecord then jUlV2.State.HistoryRecord=nil end jUlV2.State.HistoryRecord={targets=Support.CloneTable(Selection.Items),initial_positions={},terminal_positions={},initial_sizes={},terminal_sizes={},unapply=function(jUlV2) Selection:clear() for _WlOka,tFt48gVX in pairs(jUlV2.targets)do if tFt48gVX then tFt48gVX.Size=jUlV2.initial_sizes[tFt48gVX]tFt48gVX.CFrame=jUlV2.initial_positions[tFt48gVX] tFt48gVX:MakeJoints()Selection:add(tFt48gVX)end end end,apply=function(jUlV2) Selection:clear() for VcvWqUR,g9LOIN in pairs(jUlV2.targets)do if g9LOIN then g9LOIN.Size=jUlV2.terminal_sizes[g9LOIN]g9LOIN.CFrame=jUlV2.terminal_positions[g9LOIN] g9LOIN:MakeJoints()Selection:add(g9LOIN)end end end} for Ldc7,OWMI6 in pairs(jUlV2.State.HistoryRecord.targets)do if OWMI6 then jUlV2.State.HistoryRecord.initial_sizes[OWMI6]=OWMI6.Size jUlV2.State.HistoryRecord.initial_positions[OWMI6]=OWMI6.CFrame end end end Tools.Resize.finishHistoryRecord=function(y) if not y.State.HistoryRecord then return end for PN,D4 in pairs(y.State.HistoryRecord.targets)do if D4 then y.State.HistoryRecord.terminal_sizes[D4]=D4.Size y.State.HistoryRecord.terminal_positions[D4]=D4.CFrame end end
History:add(y.State.HistoryRecord) y.State.HistoryRecord=nil end Tools.Resize.changeSize=function(bqUq2I19,vfT16V9,Idod8USP)bqUq2I19:startHistoryRecord() for n,Enpu in pairs(Selection.Items)do local F=Enpu.CFrame if (pcall(function()local ed=Enpu.FormFactor end))then Enpu.FormFactor=Enum.FormFactor.Custom end Enpu.Size=Vector3.new(vfT16V9 =='x'and Idod8USP or Enpu.Size.x, vfT16V9 =='y'and Idod8USP or Enpu.Size.y, vfT16V9 =='z'and Idod8USP or Enpu.Size.z)Enpu.CFrame=F end
bqUq2I19:finishHistoryRecord()end Tools.Resize.updateGUI=function(QamDb5OV)if not QamDb5OV.GUI then return end local Jz=QamDb5OV.GUI if#Selection.Items>0 then local by73,lQlrrh,XQtO=nil,nil,nil for JefwEh,sbbJI in pairs(Selection.Items)do if JefwEh==1 then by73,lQlrrh,XQtO=Support.Round(sbbJI.Size.x,2),Support.Round(sbbJI.Size.y,2),Support.Round(sbbJI.Size.z,2)else if by73 ~=Support.Round(sbbJI.Size.x,2)then by73=nil end if lQlrrh~=Support.Round(sbbJI.Size.y,2)then lQlrrh=nil end if XQtO~=Support.Round(sbbJI.Size.z,2)then XQtO=nil end end end if not QamDb5OV.State.size_x_focused then Jz.Info.SizeInfo.X.TextBox.Text= by73 and tostring(by73)or"*"end
if not QamDb5OV.State.size_y_focused then Jz.Info.SizeInfo.Y.TextBox.Text= lQlrrh and tostring(lQlrrh)or"*"end if not QamDb5OV.State.size_z_focused then Jz.Info.SizeInfo.Z.TextBox.Text=XQtO and tostring(XQtO)or"*"end
Jz.Info.Visible=true else Jz.Info.Visible=false end if QamDb5OV.State.length_resized then Jz.Changes.Text.Text="resized ".. tostring(QamDb5OV.State.length_resized).." studs"Jz.Changes.Position=Jz.Info.Visible and UDim2.new(0,5,0,165)or UDim2.new(0,5,0,100) Jz.Changes.Visible=true else Jz.Changes.Text.Text=""Jz.Changes.Visible=false end end Tools.Resize.hideGUI=function(QYayh) if QYayh.GUI then QYayh.GUI.Visible=false end end Tools.Resize.showHandles=function(nr6uCL,FQ1oRl_) if not nr6uCL.Handles then nr6uCL.Handles=RbxUtility.Create"Handles"{Name="BTResizeHandles",Style=Enum.HandlesStyle.Resize,Color=nr6uCL.Color,Parent=GUIContainer} nr6uCL.Handles.MouseButton1Down:connect(function()override_selection=true nr6uCL.State.resizing=true
nr6uCL.State.length_resized=0 nr6uCL:startHistoryRecord() for Q,sHA_0P in pairs(Selection.Items)do nr6uCL.State.PreResize[sHA_0P]=sHA_0P:Clone() if (pcall(function()local zskX=sHA_0P.FormFactor end))then sHA_0P.FormFactor=Enum.FormFactor.Custom end
sHA_0P.Anchored=true end nr6uCL.Connections.HandleReleaseListener=Mouse.Button1Up:connect(function() override_selection=true
nr6uCL.State.resizing=false if nr6uCL.Connections.HandleReleaseListener then nr6uCL.Connections.HandleReleaseListener:disconnect()nr6uCL.Connections.HandleReleaseListener=nil end
nr6uCL:finishHistoryRecord() for z37Qz,MUu in pairs(nr6uCL.State.PreResize)do z37Qz.Anchored=MUu.Anchored nr6uCL.State.PreResize[z37Qz]=nil
z37Qz:MakeJoints()end end)end) nr6uCL.Handles.MouseDrag:connect(function(rRNsXW,zslu25lH) local K=zslu25lH%nr6uCL.Options.increment
local dBzmP=zslu25lH-K local obk=zslu25lH-K+nr6uCL.Options.increment
local MsipHD_w=math.abs(zslu25lH-dBzmP) local uBw1Z77=math.abs(zslu25lH-obk)if MsipHD_w<=uBw1Z77 then zslu25lH=dBzmP else zslu25lH=obk end local bdJJE=zslu25lH
nr6uCL.State.previous_distance=zslu25lH
if nr6uCL.Options.directions=="both"then bdJJE=zslu25lH*2 end nr6uCL.State.length_resized=bdJJE for spYT,lEPWTkAE in pairs(Selection.Items)do local S=lEPWTkAE:Clone() lEPWTkAE:BreakJoints() if rRNsXW==Enum.NormalId.Top then local Zbxec if (pcall(function()local ViHDT=lEPWTkAE.Shape end))and (lEPWTkAE.Shape==Enum.PartType.Ball or lEPWTkAE.Shape== Enum.PartType.Cylinder)then Zbxec=Vector3.new(bdJJE,bdJJE,bdJJE)elseif not (pcall(function()local fcbl4H=lEPWTkAE.Shape end))or(lEPWTkAE.Shape and lEPWTkAE.Shape==Enum.PartType.Block)then Zbxec=Vector3.new(0,bdJJE,0)end lEPWTkAE.Size=nr6uCL.State.PreResize[lEPWTkAE].Size+Zbxec if lEPWTkAE.Size== nr6uCL.State.PreResize[lEPWTkAE].Size+Zbxec then lEPWTkAE.CFrame= ( nr6uCL.Options.directions=="normal"and nr6uCL.State.PreResize[lEPWTkAE].CFrame:toWorldSpace(CFrame.new(0, bdJJE/2,0)))or (nr6uCL.Options.directions=="both"and nr6uCL.State.PreResize[lEPWTkAE].CFrame)else lEPWTkAE.Size=S.Size
lEPWTkAE.CFrame=S.CFrame end elseif rRNsXW==Enum.NormalId.Bottom then local ora4Z if (pcall(function()local wmfjOlWH=lEPWTkAE.Shape end))and (lEPWTkAE.Shape==Enum.PartType.Ball or lEPWTkAE.Shape== Enum.PartType.Cylinder)then ora4Z=Vector3.new(bdJJE,bdJJE,bdJJE)elseif not (pcall(function()local d=lEPWTkAE.Shape end))or(lEPWTkAE.Shape and lEPWTkAE.Shape==Enum.PartType.Block)then ora4Z=Vector3.new(0,bdJJE,0)end lEPWTkAE.Size=nr6uCL.State.PreResize[lEPWTkAE].Size+ora4Z if lEPWTkAE.Size== nr6uCL.State.PreResize[lEPWTkAE].Size+ora4Z then lEPWTkAE.CFrame= ( nr6uCL.Options.directions=="normal"and nr6uCL.State.PreResize[lEPWTkAE].CFrame:toWorldSpace(CFrame.new(0, -bdJJE/2,0)))or (nr6uCL.Options.directions=="both"and nr6uCL.State.PreResize[lEPWTkAE].CFrame)else lEPWTkAE.Size=S.Size
lEPWTkAE.CFrame=S.CFrame end elseif rRNsXW==Enum.NormalId.Front then local w60sb3_ if (pcall(function()local MCm__CEC=lEPWTkAE.Shape end))and (lEPWTkAE.Shape==Enum.PartType.Ball or lEPWTkAE.Shape== Enum.PartType.Cylinder)then w60sb3_=Vector3.new(bdJJE,bdJJE,bdJJE)elseif not (pcall(function()local Jr9hz4jk=lEPWTkAE.Shape end))or(lEPWTkAE.Shape and lEPWTkAE.Shape==Enum.PartType.Block)then w60sb3_=Vector3.new(0,0,bdJJE)end lEPWTkAE.Size=nr6uCL.State.PreResize[lEPWTkAE].Size+w60sb3_ if lEPWTkAE.Size== nr6uCL.State.PreResize[lEPWTkAE].Size+w60sb3_ then lEPWTkAE.CFrame= ( nr6uCL.Options.directions=="normal"and nr6uCL.State.PreResize[lEPWTkAE].CFrame:toWorldSpace(CFrame.new(0,0, -bdJJE/2)))or (nr6uCL.Options.directions=="both"and nr6uCL.State.PreResize[lEPWTkAE].CFrame)else lEPWTkAE.Size=S.Size
lEPWTkAE.CFrame=S.CFrame end elseif rRNsXW==Enum.NormalId.Back then local Abv if (pcall(function()local aqOk=lEPWTkAE.Shape end))and (lEPWTkAE.Shape==Enum.PartType.Ball or lEPWTkAE.Shape== Enum.PartType.Cylinder)then Abv=Vector3.new(bdJJE,bdJJE,bdJJE)elseif not (pcall(function()local A4ZSOV=lEPWTkAE.Shape end))or(lEPWTkAE.Shape and lEPWTkAE.Shape==Enum.PartType.Block)then Abv=Vector3.new(0,0,bdJJE)end lEPWTkAE.Size=nr6uCL.State.PreResize[lEPWTkAE].Size+Abv if lEPWTkAE.Size== nr6uCL.State.PreResize[lEPWTkAE].Size+Abv then lEPWTkAE.CFrame= ( nr6uCL.Options.directions=="normal"and nr6uCL.State.PreResize[lEPWTkAE].CFrame:toWorldSpace(CFrame.new(0,0, bdJJE/2)))or (nr6uCL.Options.directions=="both"and nr6uCL.State.PreResize[lEPWTkAE].CFrame)else lEPWTkAE.Size=S.Size
lEPWTkAE.CFrame=S.CFrame end elseif rRNsXW==Enum.NormalId.Left then local wtbkXqKs if (pcall(function()local vX_5TSFO=lEPWTkAE.Shape end))and (lEPWTkAE.Shape==Enum.PartType.Ball or lEPWTkAE.Shape== Enum.PartType.Cylinder)then wtbkXqKs=Vector3.new(bdJJE,bdJJE,bdJJE)elseif not (pcall(function()local MFweCJ3=lEPWTkAE.Shape end))or(lEPWTkAE.Shape and lEPWTkAE.Shape==Enum.PartType.Block)then wtbkXqKs=Vector3.new(bdJJE,0,0)end lEPWTkAE.Size=nr6uCL.State.PreResize[lEPWTkAE].Size+wtbkXqKs if lEPWTkAE.Size== nr6uCL.State.PreResize[lEPWTkAE].Size+wtbkXqKs then lEPWTkAE.CFrame= ( nr6uCL.Options.directions=="normal"and nr6uCL.State.PreResize[lEPWTkAE].CFrame:toWorldSpace(CFrame.new( -bdJJE/2,0,0)))or (nr6uCL.Options.directions=="both"and nr6uCL.State.PreResize[lEPWTkAE].CFrame)else lEPWTkAE.Size=S.Size
lEPWTkAE.CFrame=S.CFrame end elseif rRNsXW==Enum.NormalId.Right then local z6 if (pcall(function()local n0q2=lEPWTkAE.Shape end))and (lEPWTkAE.Shape==Enum.PartType.Ball or lEPWTkAE.Shape== Enum.PartType.Cylinder)then z6=Vector3.new(bdJJE,bdJJE,bdJJE)elseif not (pcall(function()local X2UHF=lEPWTkAE.Shape end))or(lEPWTkAE.Shape and lEPWTkAE.Shape==Enum.PartType.Block)then z6=Vector3.new(bdJJE,0,0)end lEPWTkAE.Size=nr6uCL.State.PreResize[lEPWTkAE].Size+z6 if lEPWTkAE.Size== nr6uCL.State.PreResize[lEPWTkAE].Size+z6 then lEPWTkAE.CFrame= ( nr6uCL.Options.directions=="normal"and nr6uCL.State.PreResize[lEPWTkAE].CFrame:toWorldSpace(CFrame.new( bdJJE/2,0,0)))or (nr6uCL.Options.directions=="both"and nr6uCL.State.PreResize[lEPWTkAE].CFrame)else lEPWTkAE.Size=S.Size
lEPWTkAE.CFrame=S.CFrame end end
lEPWTkAE:MakeJoints()end end)end if nr6uCL.Connections.AdorneeExistenceListener then nr6uCL.Connections.AdorneeExistenceListener:disconnect()nr6uCL.Connections.AdorneeExistenceListener=nil end
nr6uCL.Handles.Adornee=FQ1oRl_ nr6uCL.Connections.AdorneeExistenceListener=FQ1oRl_.AncestryChanged:connect(function(uanm,BJf2)if uanm~=FQ1oRl_ then return end
if BJf2 ==nil then nr6uCL:hideHandles()else nr6uCL:showHandles(FQ1oRl_)end end)end
Tools.Resize.hideHandles=function(bV) if bV.Handles then bV.Handles.Adornee=nil end end Tools.Resize.Loaded=true end},{"Rotate",function() repeat wait()until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.Rotate={} Tools.Rotate.Connections={} Tools.Rotate.Options={["increment"]=15,["pivot"]="center"} Tools.Rotate.State={["PreRotation"]={},["rotating"]=false,["previous_distance"]=0,["degrees_rotated"]=0,["rotation_size"]=0}Tools.Rotate.Listeners={} Tools.Rotate.Color=BrickColor.new("Bright green") Tools.Rotate.Listeners.Equipped=function()local hhe=Tools.Rotate hhe.State.PreviousSelectionBoxColor=SelectionBoxColor
SelectionBoxColor=hhe.Color
updateSelectionBoxColor() hhe:showGUI()if not hhe.BoundingBox then hhe.BoundingBox=RbxUtility.Create"Part"{Name="BTBoundingBox",CanCollide=false,Transparency=1,Anchored=true}end Mouse.TargetFilter=hhe.BoundingBox
hhe:changePivot(hhe.Options.pivot) hhe.State.StaticItems={}hhe.State.StaticExtents=nil hhe.State.RecalculateStaticExtents=true
local hw={} function AddStaticItem(Xjh2) if# Support.FindTableOccurrences(hhe.State.StaticItems,Xjh2)>0 then return end
table.insert(hhe.State.StaticItems,Xjh2) hw[Xjh2]=Xjh2.Changed:connect(function(wS)if wS=='CFrame'or wS=='Size'then hhe.State.RecalculateStaticExtents=true elseif wS=='Anchored'and not Xjh2.Anchored then RemoveStaticItem(Xjh2)end end)hhe.State.RecalculateStaticExtents=true end function RemoveStaticItem(SxbR) local G=Support.FindTableOccurrences(hhe.State.StaticItems,SxbR)[1]if G then hhe.State.StaticItems[G]=nil end
if hw[SxbR]then hw[SxbR]:disconnect()hw[SxbR]=nil end hhe.State.RecalculateStaticExtents=true end
for ufs,rBbV5m in pairs(Selection.Items)do if rBbV5m.Anchored then AddStaticItem(rBbV5m)end end table.insert(hhe.Connections,Selection.ItemAdded:connect(function(v)if v.Anchored then AddStaticItem(v)end end)) table.insert(hhe.Connections,Selection.ItemRemoved:connect(function(L_4ez,ILvdT1AO)if ILvdT1AO or not hw[L_4ez]then return end
RemoveStaticItem(L_4ez)end)) table.insert(hhe.Connections,Selection.Cleared:connect(function()for X,iiB in pairs(hw)do iiB:disconnect()hw[X]=nil end
hhe.State.StaticExtents=nil hhe.State.StaticItems={}end)) coroutine.wrap(function()updater_on=true hhe.Updater=function()updater_on=false end while wait(0.1)and updater_on do if CurrentTool==hhe then if hhe.GUI and hhe.GUI.Visible then hhe:updateGUI()end
if hhe.Options.pivot=="center"then hhe:updateBoundingBox()end end end end)() SelectEdge:start(function(Ai9ugkhp)hhe:changePivot("last") hhe.Options.PivotPoint=Ai9ugkhp.CFrame hhe.Connections.EdgeSelectionRemover=Selection.Changed:connect(function() hhe.Options.PivotPoint=nil if hhe.Connections.EdgeSelectionRemover then hhe.Connections.EdgeSelectionRemover:disconnect()hhe.Connections.EdgeSelectionRemover=nil end end)hhe:showHandles(Ai9ugkhp)end)end Tools.Rotate.Listeners.Unequipped=function()local vx0=Tools.Rotate
if vx0.Updater then vx0.Updater()vx0.Updater=nil end
SelectEdge:stop()if vx0.Options.PivotPoint then vx0.Options.PivotPoint=nil end vx0:hideGUI()vx0:hideHandles()for oTT0I_tH,d in pairs(vx0.Connections)do d:disconnect()vx0.Connections[oTT0I_tH]= nil end SelectionBoxColor=vx0.State.PreviousSelectionBoxColor
updateSelectionBoxColor()end Tools.Rotate.Listeners.Button1Down=function()local HF=Tools.Rotate if not HF.State.rotating and HF.Options.PivotPoint then HF.Options.PivotPoint=nil end end Tools.Rotate.Listeners.KeyUp=function(ORg_K6y)local Y0=Tools.Rotate
if ORg_K6y=='-'and Y0.GUI then Y0.GUI.IncrementOption.Increment.TextBox:CaptureFocus()end end Tools.Rotate.showGUI=function(gwII) if not gwII.GUI then local ItMCtiyJ=DFb100j.BTRotateToolGUI:Clone()ItMCtiyJ.Parent=UI ItMCtiyJ.PivotOption.Center.Button.MouseButton1Down:connect(function() gwII:changePivot("center")end) ItMCtiyJ.PivotOption.Local.Button.MouseButton1Down:connect(function() gwII:changePivot("local")end) ItMCtiyJ.PivotOption.Last.Button.MouseButton1Down:connect(function() gwII:changePivot("last")end) ItMCtiyJ.IncrementOption.Increment.TextBox.FocusLost:connect(function(iXtk) gwII.Options.increment= tonumber(ItMCtiyJ.IncrementOption.Increment.TextBox.Text)or gwII.Options.increment ItMCtiyJ.IncrementOption.Increment.TextBox.Text=tostring(gwII.Options.increment)end) ItMCtiyJ.Info.RotationInfo.X.TextButton.MouseButton1Down:connect(function() gwII.State.rot_x_focused=true ItMCtiyJ.Info.RotationInfo.X.TextBox:CaptureFocus()end) ItMCtiyJ.Info.RotationInfo.X.TextBox.FocusLost:connect(function(snG) local V5j=tonumber(ItMCtiyJ.Info.RotationInfo.X.TextBox.Text) if V5j then gwII:changeRotation('x',math.rad(V5j))end
gwII.State.rot_x_focused=false end) ItMCtiyJ.Info.RotationInfo.Y.TextButton.MouseButton1Down:connect(function() gwII.State.rot_y_focused=true ItMCtiyJ.Info.RotationInfo.Y.TextBox:CaptureFocus()end) ItMCtiyJ.Info.RotationInfo.Y.TextBox.FocusLost:connect(function(lItF) local xq1bs=tonumber(ItMCtiyJ.Info.RotationInfo.Y.TextBox.Text) if xq1bs then gwII:changeRotation('y',math.rad(xq1bs))end
gwII.State.rot_y_focused=false end) ItMCtiyJ.Info.RotationInfo.Z.TextButton.MouseButton1Down:connect(function() gwII.State.rot_z_focused=true ItMCtiyJ.Info.RotationInfo.Z.TextBox:CaptureFocus()end) ItMCtiyJ.Info.RotationInfo.Z.TextBox.FocusLost:connect(function(F) local Oro89=tonumber(ItMCtiyJ.Info.RotationInfo.Z.TextBox.Text) if Oro89 then gwII:changeRotation('z',math.rad(Oro89))end
gwII.State.rot_z_focused=false end)gwII.GUI=ItMCtiyJ end
gwII.GUI.Visible=true end Tools.Rotate.startHistoryRecord=function(O_dX)if O_dX.State.HistoryRecord then O_dX.State.HistoryRecord=nil end O_dX.State.HistoryRecord={targets=Support.CloneTable(Selection.Items),initial_cframes={},terminal_cframes={},unapply=function(O_dX) Selection:clear() for k3U,p8 in pairs(O_dX.targets)do if p8 then p8.CFrame=O_dX.initial_cframes[p8] p8:MakeJoints()Selection:add(p8)end end end,apply=function(O_dX) Selection:clear() for BLvFfZ,_ in pairs(O_dX.targets)do if _ then _.CFrame=O_dX.terminal_cframes[_] _:MakeJoints()Selection:add(_)end end end} for dAcD,e in pairs(O_dX.State.HistoryRecord.targets)do if e then O_dX.State.HistoryRecord.initial_cframes[e]=e.CFrame end end end Tools.Rotate.finishHistoryRecord=function(RG) if not RG.State.HistoryRecord then return end for Y,htKd_R2 in pairs(RG.State.HistoryRecord.targets)do if htKd_R2 then RG.State.HistoryRecord.terminal_cframes[htKd_R2]=htKd_R2.CFrame end end
History:add(RG.State.HistoryRecord)RG.State.HistoryRecord= nil end Tools.Rotate.changeRotation=function(vr,ylrttgX,L)vr:startHistoryRecord() for I,KYV in pairs(Selection.Items)do local d,sBB,vvEDp5PM=KYV.CFrame:toEulerAnglesXYZ() KYV.CFrame= CFrame.new(KYV.Position)* CFrame.Angles(ylrttgX=='x'and L or d,ylrttgX=='y'and L or sBB, ylrttgX=='z'and L or vvEDp5PM)end
vr:finishHistoryRecord()end Tools.Rotate.updateGUI=function(EBzZ)if not EBzZ.GUI then return end
local JnR5AeB=EBzZ.GUI if# Selection.Items>0 then local vfXvA0O,OZRh,eNaZt=nil,nil,nil for eE49cc,n_Q69rHB in pairs(Selection.Items)do local h2_ty,zHG,FYzFO1=n_Q69rHB.CFrame:toEulerAnglesXYZ() if eE49cc==1 then vfXvA0O,OZRh,eNaZt=Support.Round(math.deg(h2_ty),2),Support.Round(math.deg(zHG),2),Support.Round(math.deg(FYzFO1),2)else if vfXvA0O~=Support.Round(math.deg(h2_ty),2)then vfXvA0O=nil end
if OZRh~=Support.Round(math.deg(zHG),2)then OZRh=nil end
if eNaZt~= Support.Round(math.deg(FYzFO1),2)then eNaZt=nil end end end
if not EBzZ.State.rot_x_focused then JnR5AeB.Info.RotationInfo.X.TextBox.Text= vfXvA0O and tostring(vfXvA0O)or"*"end
if not EBzZ.State.rot_y_focused then JnR5AeB.Info.RotationInfo.Y.TextBox.Text= OZRh and tostring(OZRh)or"*"end
if not EBzZ.State.rot_z_focused then JnR5AeB.Info.RotationInfo.Z.TextBox.Text= eNaZt and tostring(eNaZt)or"*"end JnR5AeB.Info.Visible=true else JnR5AeB.Info.Visible=false end if EBzZ.State.degrees_rotated then JnR5AeB.Changes.Text.Text="rotated ".. tostring(EBzZ.State.degrees_rotated).." degrees" JnR5AeB.Changes.Position= JnR5AeB.Info.Visible and UDim2.new(0,5,0,165)or UDim2.new(0,5,0,100)JnR5AeB.Changes.Visible=true else JnR5AeB.Changes.Text.Text=""JnR5AeB.Changes.Visible=false end end Tools.Rotate.hideGUI=function(gR48Oozb) if gR48Oozb.GUI then gR48Oozb.GUI.Visible=false end end Tools.Rotate.updateBoundingBox=function(bK0bhdq) if#Selection.Items>0 then if bK0bhdq.State.RecalculateStaticExtents then bK0bhdq.State.StaticExtents=calculateExtents(bK0bhdq.State.StaticItems,nil,true)bK0bhdq.State.RecalculateStaticExtents=false end local nP,eN5tc=calculateExtents(Selection.Items,bK0bhdq.State.StaticExtents)bK0bhdq.BoundingBox.Size=nP bK0bhdq.BoundingBox.CFrame=eN5tc
bK0bhdq:showHandles(bK0bhdq.BoundingBox)else bK0bhdq:hideHandles()end end Tools.Rotate.changePivot=function(KehBOft6,R) local ao5=KehBOft6.GUI and KehBOft6.GUI.PivotOption or nil if KehBOft6.Connections.HandleFocusChangeListener then KehBOft6.Connections.HandleFocusChangeListener:disconnect()KehBOft6.Connections.HandleFocusChangeListener=nil end if KehBOft6.Connections.HandleSelectionChangeListener then KehBOft6.Connections.HandleSelectionChangeListener:disconnect()KehBOft6.Connections.HandleSelectionChangeListener=nil end if KehBOft6.Options.PivotPoint then KehBOft6.Options.PivotPoint=nil end if R=="center"then KehBOft6.Options.pivot="center" KehBOft6:showHandles(KehBOft6.BoundingBox) if KehBOft6.GUI then ao5.Center.SelectedIndicator.BackgroundTransparency=0
ao5.Center.Background.Image=Assets.DarkSlantedRectangle ao5.Local.SelectedIndicator.BackgroundTransparency=1
ao5.Local.Background.Image=Assets.LightSlantedRectangle ao5.Last.SelectedIndicator.BackgroundTransparency=1
ao5.Last.Background.Image=Assets.LightSlantedRectangle end end if R=="local"then KehBOft6.Options.pivot="local" KehBOft6.Connections.HandleSelectionChangeListener=Selection.Changed:connect(function() KehBOft6:hideHandles() if Selection.Last then KehBOft6:showHandles(Selection.Last)end end) KehBOft6.Connections.HandleFocusChangeListener=Mouse.Button2Up:connect(function() override_selection=true if Selection:find(Mouse.Target)then Selection:focus(Mouse.Target)KehBOft6:showHandles(Mouse.Target)end end) if Selection.Last then KehBOft6:showHandles(Selection.Last)end if KehBOft6.GUI then ao5.Center.SelectedIndicator.BackgroundTransparency=1 ao5.Center.Background.Image=Assets.LightSlantedRectangle
ao5.Local.SelectedIndicator.BackgroundTransparency=0 ao5.Local.Background.Image=Assets.DarkSlantedRectangle
ao5.Last.SelectedIndicator.BackgroundTransparency=1 ao5.Last.Background.Image=Assets.LightSlantedRectangle end end if R=="last"then KehBOft6.Options.pivot="last" KehBOft6.Connections.HandleSelectionChangeListener=Selection.Changed:connect(function()if not KehBOft6.Options.PivotPoint then KehBOft6:hideHandles()end
if Selection.Last and not KehBOft6.Options.PivotPoint then KehBOft6:showHandles(Selection.Last)end end) KehBOft6.Connections.HandleFocusChangeListener=Mouse.Button2Up:connect(function() override_selection=true if Selection:find(Mouse.Target)then Selection:focus(Mouse.Target)KehBOft6:showHandles(Mouse.Target)end end) if Selection.Last then KehBOft6:showHandles(Selection.Last)end if KehBOft6.GUI then ao5.Center.SelectedIndicator.BackgroundTransparency=1 ao5.Center.Background.Image=Assets.LightSlantedRectangle
ao5.Local.SelectedIndicator.BackgroundTransparency=1 ao5.Local.Background.Image=Assets.LightSlantedRectangle
ao5.Last.SelectedIndicator.BackgroundTransparency=0 ao5.Last.Background.Image=Assets.DarkSlantedRectangle end end end Tools.Rotate.showHandles=function(oZy,oZ) if not oZy.Handles then oZy.Handles=RbxUtility.Create"ArcHandles"{Name="BTRotationHandles",Color=oZy.Color,Parent=GUIContainer} oZy.Handles.MouseButton1Down:connect(function()override_selection=true oZy.State.rotating=true
oZy.State.degrees_rotated=0
oZy.State.rotation_size=0 oZy:startHistoryRecord() for idRDAlB,tXR1E510 in pairs(Selection.Items)do oZy.State.PreRotation[tXR1E510]=tXR1E510:Clone()tXR1E510.Anchored=true end
local ndeNBp,o76bqPp=calculateExtents(oZy.State.PreRotation) oZy.State.PreRotationPosition=o76bqPp oZy.Connections.HandleReleaseListener=Mouse.Button1Up:connect(function()override_selection=true oZy.State.rotating=false if oZy.Connections.HandleReleaseListener then oZy.Connections.HandleReleaseListener:disconnect()oZy.Connections.HandleReleaseListener=nil end
oZy:finishHistoryRecord()for ZawK6,bK in pairs(oZy.State.PreRotation)do ZawK6.Anchored=bK.Anchored
oZy.State.PreRotation[ZawK6]=nil ZawK6:MakeJoints()end end)end) oZy.Handles.MouseDrag:connect(function(OJGVLn,UzgoE5O) local UzgoE5O=math.floor(math.deg(UzgoE5O))local RvHs=UzgoE5O%oZy.Options.increment local u=UzgoE5O-RvHs
local Anrb=UzgoE5O-RvHs+oZy.Options.increment
local C9lJAfo=math.abs( UzgoE5O-u) local NeSAkW=math.abs(UzgoE5O-Anrb)if C9lJAfo<=NeSAkW then UzgoE5O=u else UzgoE5O=Anrb end local Ccoa= oZy.Options.increment*math.floor(UzgoE5O/oZy.Options.increment)oZy.State.degrees_rotated=UzgoE5O for Y,zljPh in pairs(Selection.Items)do local C7mQfN=zljPh:Clone()zljPh:BreakJoints() if OJGVLn==Enum.Axis.Y then if oZy.Options.pivot=="center"then zljPh.CFrame=oZy.State.PreRotationPosition:toWorldSpace(CFrame.new(0,0,0)* CFrame.Angles(0,math.rad(Ccoa),0)):toWorldSpace(oZy.State.PreRotation[zljPh].CFrame:toObjectSpace(oZy.State.PreRotationPosition):inverse())elseif oZy.Options.pivot=="local"then zljPh.CFrame=oZy.State.PreRotation[zljPh].CFrame:toWorldSpace( CFrame.new(0,0,0)*CFrame.Angles(0,math.rad(Ccoa),0))elseif oZy.Options.pivot=="last"then zljPh.CFrame=(oZy.Options.PivotPoint or oZy.State.PreRotation[Selection.Last].CFrame):toWorldSpace( CFrame.new(0,0,0)*CFrame.Angles(0,math.rad(Ccoa),0)):toWorldSpace(oZy.State.PreRotation[zljPh].CFrame:toObjectSpace( oZy.Options.PivotPoint or oZy.State.PreRotation[Selection.Last].CFrame):inverse())end elseif OJGVLn==Enum.Axis.X then if oZy.Options.pivot=="center"then zljPh.CFrame=oZy.State.PreRotationPosition:toWorldSpace( CFrame.new(0,0,0)*CFrame.Angles(math.rad(Ccoa),0,0)):toWorldSpace(oZy.State.PreRotation[zljPh].CFrame:toObjectSpace(oZy.State.PreRotationPosition):inverse())elseif oZy.Options.pivot=="local"then zljPh.CFrame=oZy.State.PreRotation[zljPh].CFrame:toWorldSpace( CFrame.new(0,0,0)*CFrame.Angles(math.rad(Ccoa),0,0))elseif oZy.Options.pivot=="last"then zljPh.CFrame=(oZy.Options.PivotPoint or oZy.State.PreRotation[Selection.Last].CFrame):toWorldSpace( CFrame.new(0,0,0)*CFrame.Angles(math.rad(Ccoa),0,0)):toWorldSpace(oZy.State.PreRotation[zljPh].CFrame:toObjectSpace( oZy.Options.PivotPoint or oZy.State.PreRotation[Selection.Last].CFrame):inverse())end elseif OJGVLn==Enum.Axis.Z then if oZy.Options.pivot=="center"then zljPh.CFrame=oZy.State.PreRotationPosition:toWorldSpace( CFrame.new(0,0,0)*CFrame.Angles(0,0,math.rad(Ccoa))):toWorldSpace(oZy.State.PreRotation[zljPh].CFrame:toObjectSpace(oZy.State.PreRotationPosition):inverse())elseif oZy.Options.pivot=="local"then zljPh.CFrame=oZy.State.PreRotation[zljPh].CFrame:toWorldSpace( CFrame.new(0,0,0)*CFrame.Angles(0,0,math.rad(Ccoa)))elseif oZy.Options.pivot=="last"then zljPh.CFrame=(oZy.Options.PivotPoint or oZy.State.PreRotation[Selection.Last].CFrame):toWorldSpace( CFrame.new(0,0,0)*CFrame.Angles(0,0,math.rad(Ccoa))):toWorldSpace(oZy.State.PreRotation[zljPh].CFrame:toObjectSpace( oZy.Options.PivotPoint or oZy.State.PreRotation[Selection.Last].CFrame):inverse())end end
zljPh:MakeJoints()end end)end if oZy.Connections.AdorneeExistenceListener then oZy.Connections.AdorneeExistenceListener:disconnect()oZy.Connections.AdorneeExistenceListener=nil end
oZy.Handles.Adornee=oZ oZy.Connections.AdorneeExistenceListener=oZ.AncestryChanged:connect(function(hIkuxuG,wSnPWSA8)if hIkuxuG~=oZ then return end
if wSnPWSA8 ==nil then oZy:hideHandles()else oZy:showHandles(oZ)end end)end Tools.Rotate.hideHandles=function(Ktu1) if Ktu1.Handles then Ktu1.Handles.Adornee=nil end end
Tools.Rotate.Loaded=true end},{"Surface",function() repeat wait()until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.Surface={} Tools.Surface.Color=BrickColor.new("Bright violet")Tools.Surface.Connections={} Tools.Surface.State={["type"]=nil} Tools.Surface.Options={["side"]=Enum.NormalId.Front}Tools.Surface.Listeners={} Tools.Surface.Listeners.Equipped=function() local g=Tools.Surface
g.State.PreviousSelectionBoxColor=SelectionBoxColor SelectionBoxColor=g.Color
updateSelectionBoxColor()g:showGUI() g:changeSurface(g.Options.side) coroutine.wrap(function()updater_on=true g.Updater=function()updater_on=false end while wait(0.1)and updater_on do if CurrentTool==g then local R={} if g.Options.side=='*'then for t,jYRxYT in pairs(Selection.Items)do table.insert(R,jYRxYT.TopSurface) table.insert(R,jYRxYT.BottomSurface)table.insert(R,jYRxYT.LeftSurface) table.insert(R,jYRxYT.RightSurface)table.insert(R,jYRxYT.FrontSurface) table.insert(R,jYRxYT.BackSurface)end else local kd=g.Options.side.Name..'Surface' for kalNjedc,b2Pn in pairs(Selection.Items)do table.insert(R,b2Pn[kd])end end
local WiBcS8j=Support.IdentifyCommonItem(R) g.State.type=WiBcS8j
if g.GUI and g.GUI.Visible then g:updateGUI()end end end end)()end Tools.Surface.Listeners.Unequipped=function()local trdghrt=Tools.Surface
if trdghrt.Updater then trdghrt.Updater()trdghrt.Updater=nil end trdghrt:hideGUI()for J,y1gHSu in pairs(trdghrt.Connections)do y1gHSu:disconnect()trdghrt.Connections[J]= nil end SelectionBoxColor=trdghrt.State.PreviousSelectionBoxColor
updateSelectionBoxColor()end Tools.Surface.Listeners.Button2Down=function()local lF3FR=Tools.Surface local _HG,W,rEJdQN=Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ() lF3FR.State.PreB2DownCameraRotation=Vector3.new(_HG,W,rEJdQN)end Tools.Surface.Listeners.Button2Up=function()local HF6Ag=Tools.Surface local Y,TEM,jWvh=Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ()local YO_aE9lks=Vector3.new(Y,TEM,jWvh) if  Selection:find(Mouse.Target)and HF6Ag.State.PreB2DownCameraRotation==YO_aE9lks then HF6Ag:changeSurface(Mouse.TargetSurface)end end Tools.Surface.startHistoryRecord=function(wuF) if wuF.State.HistoryRecord then wuF.State.HistoryRecord=nil end wuF.State.HistoryRecord={targets=Support.CloneTable(Selection.Items),target_surface=wuF.Options.side,initial_surfaces={},terminal_surfaces={},unapply=function(wuF) Selection:clear() for ipXc,EgbUS in pairs(wuF.targets)do if EgbUS then for XJ,RDsGq in pairs(wuF.initial_surfaces[EgbUS])do EgbUS[XJ]=RDsGq end
EgbUS:MakeJoints() Selection:add(EgbUS)end end end,apply=function(wuF) Selection:clear() for wg6c1w,iPEJyOaN in pairs(wuF.targets)do if iPEJyOaN then for D0,a223 in pairs(wuF.terminal_surfaces[iPEJyOaN])do iPEJyOaN[D0]=a223 end iPEJyOaN:MakeJoints()Selection:add(iPEJyOaN)end end end} for px4R7I,a in pairs(wuF.State.HistoryRecord.targets)do if a then wuF.State.HistoryRecord.initial_surfaces[a]={} if wuF.State.HistoryRecord.target_surface=='*'then wuF.State.HistoryRecord.initial_surfaces[a].RightSurface=a.RightSurface wuF.State.HistoryRecord.initial_surfaces[a].LeftSurface=a.LeftSurface wuF.State.HistoryRecord.initial_surfaces[a].FrontSurface=a.FrontSurface wuF.State.HistoryRecord.initial_surfaces[a].BackSurface=a.BackSurface wuF.State.HistoryRecord.initial_surfaces[a].TopSurface=a.TopSurface wuF.State.HistoryRecord.initial_surfaces[a].BottomSurface=a.BottomSurface else wuF.State.HistoryRecord.initial_surfaces[a][ wuF.State.HistoryRecord.target_surface.Name..'Surface']=a[ wuF.State.HistoryRecord.target_surface.Name..'Surface']end end end end Tools.Surface.finishHistoryRecord=function(I29) if not I29.State.HistoryRecord then return end for a,qji75cGk in pairs(I29.State.HistoryRecord.targets)do if qji75cGk then I29.State.HistoryRecord.terminal_surfaces[qji75cGk]={} if I29.State.HistoryRecord.target_surface=='*'then I29.State.HistoryRecord.terminal_surfaces[qji75cGk].RightSurface=qji75cGk.RightSurface I29.State.HistoryRecord.terminal_surfaces[qji75cGk].LeftSurface=qji75cGk.LeftSurface I29.State.HistoryRecord.terminal_surfaces[qji75cGk].FrontSurface=qji75cGk.FrontSurface I29.State.HistoryRecord.terminal_surfaces[qji75cGk].BackSurface=qji75cGk.BackSurface I29.State.HistoryRecord.terminal_surfaces[qji75cGk].TopSurface=qji75cGk.TopSurface I29.State.HistoryRecord.terminal_surfaces[qji75cGk].BottomSurface=qji75cGk.BottomSurface else I29.State.HistoryRecord.terminal_surfaces[qji75cGk][ I29.State.HistoryRecord.target_surface.Name..'Surface']=qji75cGk[ I29.State.HistoryRecord.target_surface.Name..'Surface']end end end
History:add(I29.State.HistoryRecord)I29.State.HistoryRecord= nil end Tools.Surface.SpecialTypeNames={SmoothNoOutlines="NO OUTLINE",Inlet="INLETS"} Tools.Surface.changeType=function(BRk_bg,B97ZvZrX)BRk_bg:startHistoryRecord() for DINB,rvLAm9 in pairs(Selection.Items)do if BRk_bg.Options.side=='*'then rvLAm9.FrontSurface=B97ZvZrX rvLAm9.BackSurface=B97ZvZrX
rvLAm9.RightSurface=B97ZvZrX
rvLAm9.LeftSurface=B97ZvZrX rvLAm9.TopSurface=B97ZvZrX
rvLAm9.BottomSurface=B97ZvZrX else rvLAm9[BRk_bg.Options.side.Name.."Surface"]=B97ZvZrX end
rvLAm9:MakeJoints()end
BRk_bg:finishHistoryRecord() BRk_bg.TypeDropdown:selectOption( BRk_bg.SpecialTypeNames[B97ZvZrX.Name]or B97ZvZrX.Name:upper())if BRk_bg.TypeDropdown.open then BRk_bg.TypeDropdown:toggle()end end Tools.Surface.changeSurface=function(E,Im)E.Options.side=Im E.SideDropdown:selectOption( Im=='*'and'ALL'or Im.Name:upper()) if E.SideDropdown.open then E.SideDropdown:toggle()end end Tools.Surface.updateGUI=function(yWsj)if not yWsj.GUI then return end if #Selection.Items>0 then yWsj.TypeDropdown:selectOption(yWsj.State.type and ( yWsj.SpecialTypeNames[yWsj.State.type.Name]or yWsj.State.type.Name:upper())or"*")else yWsj.TypeDropdown:selectOption("")end end Tools.Surface.showGUI=function(MFbe) if not MFbe.GUI then local i=DFb100j.BTSurfaceToolGUI:Clone()i.Parent=UI
local ayLU=createDropdown()MFbe.SideDropdown=ayLU ayLU.Frame.Parent=i.SideOption
ayLU.Frame.Position=UDim2.new(0,30,0,0) ayLU.Frame.Size=UDim2.new(0,72,0,25) ayLU:addOption('ALL').MouseButton1Up:connect(function() MFbe:changeSurface('*')end) ayLU:addOption("TOP").MouseButton1Up:connect(function() MFbe:changeSurface(Enum.NormalId.Top)end) ayLU:addOption("BOTTOM").MouseButton1Up:connect(function() MFbe:changeSurface(Enum.NormalId.Bottom)end) ayLU:addOption("FRONT").MouseButton1Up:connect(function() MFbe:changeSurface(Enum.NormalId.Front)end) ayLU:addOption("BACK").MouseButton1Up:connect(function() MFbe:changeSurface(Enum.NormalId.Back)end) ayLU:addOption("LEFT").MouseButton1Up:connect(function() MFbe:changeSurface(Enum.NormalId.Left)end) ayLU:addOption("RIGHT").MouseButton1Up:connect(function() MFbe:changeSurface(Enum.NormalId.Right)end)local T2y=createDropdown()MFbe.TypeDropdown=T2y T2y.Frame.Parent=i.TypeOption
T2y.Frame.Position=UDim2.new(0,30,0,0) T2y.Frame.Size=UDim2.new(0,87,0,25) T2y:addOption("STUDS").MouseButton1Up:connect(function() MFbe:changeType(Enum.SurfaceType.Studs)end) T2y:addOption("INLETS").MouseButton1Up:connect(function() MFbe:changeType(Enum.SurfaceType.Inlet)end) T2y:addOption("SMOOTH").MouseButton1Up:connect(function() MFbe:changeType(Enum.SurfaceType.Smooth)end) T2y:addOption("WELD").MouseButton1Up:connect(function() MFbe:changeType(Enum.SurfaceType.Weld)end) T2y:addOption("GLUE").MouseButton1Up:connect(function() MFbe:changeType(Enum.SurfaceType.Glue)end) T2y:addOption("UNIVERSAL").MouseButton1Up:connect(function() MFbe:changeType(Enum.SurfaceType.Universal)end) T2y:addOption("HINGE").MouseButton1Up:connect(function() MFbe:changeType(Enum.SurfaceType.Hinge)end) T2y:addOption("MOTOR").MouseButton1Up:connect(function() MFbe:changeType(Enum.SurfaceType.Motor)end) T2y:addOption("NO OUTLINE").MouseButton1Up:connect(function() MFbe:changeType(Enum.SurfaceType.SmoothNoOutlines)end)MFbe.GUI=i end
MFbe.GUI.Visible=true end Tools.Surface.hideGUI=function(QgLdZF) if QgLdZF.GUI then QgLdZF.GUI.Visible=false end end
Tools.Surface.Loaded=true end},{"Texture",function() repeat wait()until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.Texture={} Tools.Texture.Color=BrickColor.new("Bright violet") Tools.Texture.Options={side=Enum.NormalId.Front,mode="decal"}Tools.Texture.State={}Tools.Texture.Connections={} Tools.Texture.Listeners={} Tools.Texture.Listeners.Equipped=function()local XGyz6oE=Tools.Texture XGyz6oE.State.PreviousSelectionBoxColor=SelectionBoxColor
SelectionBoxColor=XGyz6oE.Color
updateSelectionBoxColor() XGyz6oE:showGUI()XGyz6oE:changeSide(XGyz6oE.Options.side) XGyz6oE:changeMode(XGyz6oE.Options.mode) coroutine.wrap(function()updater_on=true XGyz6oE.Updater=function()updater_on=false end
while wait(0.1)and updater_on do if CurrentTool==XGyz6oE then if XGyz6oE.GUI and XGyz6oE.GUI.Visible then XGyz6oE:updateGUI()end end end end)()end Tools.Texture.Listeners.Unequipped=function()local i3NlQ94=Tools.Texture
if i3NlQ94.Updater then i3NlQ94.Updater()i3NlQ94.Updater=nil end i3NlQ94:hideGUI()for RnFNLp,wOOFocF in pairs(i3NlQ94.Connections)do wOOFocF:disconnect()i3NlQ94.Connections[RnFNLp]= nil end SelectionBoxColor=i3NlQ94.State.PreviousSelectionBoxColor
updateSelectionBoxColor()end Tools.Texture.Listeners.Button2Down=function()local cUoJ=Tools.Texture local m3QdLvW,xv,H=Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ() cUoJ.State.PreB2DownCameraRotation=Vector3.new(m3QdLvW,xv,H)end Tools.Texture.Listeners.Button2Up=function()local Gjvc=Tools.Texture local u3iW5,MGaxDz,ezQ=Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ()local c=Vector3.new(u3iW5,MGaxDz,ezQ) if  Selection:find(Mouse.Target)and Gjvc.State.PreB2DownCameraRotation==c then Gjvc:changeSide(Mouse.TargetSurface)end end Tools.Texture.startHistoryRecord=function(FVJlfw,MwzzZ)if FVJlfw.State.HistoryRecord then FVJlfw.State.HistoryRecord=nil end FVJlfw.State.HistoryRecord={targets=Support.CloneTable(MwzzZ),initial_texture={},terminal_texture={},initial_transparency={},terminal_transparency={},initial_repeat={},terminal_repeat={},initial_side={},terminal_side={},unapply=function(FVJlfw) Selection:clear() for EQI,zdm in pairs(FVJlfw.targets)do if zdm then Selection:add(zdm.Parent) zdm.Texture=FVJlfw.initial_texture[zdm]zdm.Transparency=FVJlfw.initial_transparency[zdm] zdm.Face=FVJlfw.initial_side[zdm] if zdm:IsA("Texture")then zdm.StudsPerTileU=FVJlfw.initial_repeat[zdm].x
zdm.StudsPerTileV=FVJlfw.initial_repeat[zdm].y end end end end,apply=function(FVJlfw) Selection:clear() for OQaP,V1AAbF in pairs(FVJlfw.targets)do if V1AAbF then Selection:add(V1AAbF.Parent) V1AAbF.Texture=FVJlfw.terminal_texture[V1AAbF] V1AAbF.Transparency=FVJlfw.terminal_transparency[V1AAbF]V1AAbF.Face=FVJlfw.terminal_side[V1AAbF]if V1AAbF:IsA("Texture")then V1AAbF.StudsPerTileU=FVJlfw.terminal_repeat[V1AAbF].x V1AAbF.StudsPerTileV=FVJlfw.terminal_repeat[V1AAbF].y end end end end} for DVp,uMHoys in pairs(FVJlfw.State.HistoryRecord.targets)do if uMHoys then FVJlfw.State.HistoryRecord.initial_texture[uMHoys]=uMHoys.Texture FVJlfw.State.HistoryRecord.initial_transparency[uMHoys]=uMHoys.Transparency FVJlfw.State.HistoryRecord.initial_side[uMHoys]=uMHoys.Face
if uMHoys:IsA("Texture")then FVJlfw.State.HistoryRecord.initial_repeat[uMHoys]=Vector2.new(uMHoys.StudsPerTileU,uMHoys.StudsPerTileV)end end end end Tools.Texture.finishHistoryRecord=function(hebAWpv) if not hebAWpv.State.HistoryRecord then return end for iO,kQfTr6 in pairs(hebAWpv.State.HistoryRecord.targets)do if kQfTr6 then hebAWpv.State.HistoryRecord.terminal_texture[kQfTr6]=kQfTr6.Texture hebAWpv.State.HistoryRecord.terminal_transparency[kQfTr6]=kQfTr6.Transparency hebAWpv.State.HistoryRecord.terminal_side[kQfTr6]=kQfTr6.Face
if kQfTr6:IsA("Texture")then hebAWpv.State.HistoryRecord.terminal_repeat[kQfTr6]=Vector2.new(kQfTr6.StudsPerTileU,kQfTr6.StudsPerTileV)end end end
History:add(hebAWpv.State.HistoryRecord)hebAWpv.State.HistoryRecord= nil end Tools.Texture.changeMode=function(VF,qby)VF.Options.mode=qby
if not VF.GUI then return end if qby== "decal"then VF.GUI.ModeOption.Decal.SelectedIndicator.Transparency=0 VF.GUI.ModeOption.Texture.SelectedIndicator.Transparency=1 VF.GUI.ModeOption.Decal.Background.Image=Assets.DarkSlantedRectangle VF.GUI.ModeOption.Texture.Background.Image=Assets.LightSlantedRectangle
VF.GUI.AddButton.Button.Text="ADD DECAL" VF.GUI.RemoveButton.Button.Text="REMOVE DECAL"elseif qby=="texture"then VF.GUI.ModeOption.Decal.SelectedIndicator.Transparency=1 VF.GUI.ModeOption.Texture.SelectedIndicator.Transparency=0 VF.GUI.ModeOption.Decal.Background.Image=Assets.LightSlantedRectangle VF.GUI.ModeOption.Texture.Background.Image=Assets.DarkSlantedRectangle
VF.GUI.AddButton.Button.Text="ADD TEXTURE" VF.GUI.RemoveButton.Button.Text="REMOVE TEXTURE"end end Tools.Texture.changeSide=function(xocXyH,guNNjlMM)xocXyH.Options.side=guNNjlMM if xocXyH.SideDropdown then xocXyH.SideDropdown:selectOption(guNNjlMM.Name:upper())if xocXyH.SideDropdown.open then xocXyH.SideDropdown:toggle()end end end Tools.Texture.changeTexture=function(wvoHfla,UIgl)local ij={} for m,TO857 in pairs(Selection.Items)do local Uo5o=Support.GetChildrenOfClass(TO857,"Texture") for m,xX9 in pairs(Uo5o)do if xX9.Face==wvoHfla.Options.side then table.insert(ij,xX9)end end end if HttpAvailable then local pOltGg='http://www.f3xteam.com/bt/getDecalImageID/%s' local aD=HttpInterface.GetAsync(pOltGg:format(UIgl))if aD and aD:len()>0 then UIgl=aD end end
wvoHfla:startHistoryRecord(ij) for KO,Z in pairs(ij)do Z.Texture= "http://www.roblox.com/asset/?id="..UIgl end
wvoHfla:finishHistoryRecord()end Tools.Texture.changeDecal=function(kv6Rc,G8PtJug)local RwGMa={} for wODtgBt,R83 in pairs(Selection.Items)do local O3=Support.GetChildrenOfClass(R83,"Decal")for wODtgBt,Y in pairs(O3)do if Y.Face==kv6Rc.Options.side then table.insert(RwGMa,Y)end end end if HttpAvailable then local Nau29CQd='http://www.f3xteam.com/bt/getDecalImageID/%s' local rPWy4BIw=HttpInterface.GetAsync(Nau29CQd:format(G8PtJug)) if rPWy4BIw and rPWy4BIw:len()>0 then G8PtJug=rPWy4BIw end end
kv6Rc:startHistoryRecord(RwGMa) for FIDceK,h in pairs(RwGMa)do h.Texture= "http://www.roblox.com/asset/?id="..G8PtJug end
kv6Rc:finishHistoryRecord()end Tools.Texture.changeTransparency=function(lSW,kl)local W={} for xtH,qujnE in pairs(Selection.Items)do if lSW.Options.mode== "texture"then local fX=Support.GetChildrenOfClass(qujnE,"Texture") for xtH,Gu9cA in pairs(fX)do if Gu9cA.Face==lSW.Options.side then table.insert(W,Gu9cA)end end elseif lSW.Options.mode=="decal"then local qie86E6k=Support.GetChildrenOfClass(qujnE,"Decal") for xtH,_7XdqeK in pairs(qie86E6k)do if _7XdqeK.Face==lSW.Options.side then table.insert(W,_7XdqeK)end end end end
lSW:startHistoryRecord(W) for FUhqkm2,OmYbhPA in pairs(W)do OmYbhPA.Transparency=kl end
lSW:finishHistoryRecord()end Tools.Texture.changeFrequency=function(o1,cKy3Dt,y)local zB6zO={} for C6,J09Np7H8 in pairs(Selection.Items)do local tf=Support.GetChildrenOfClass(J09Np7H8,"Texture") for C6,VzDXmgRS in pairs(tf)do if VzDXmgRS.Face==o1.Options.side then table.insert(zB6zO,VzDXmgRS)end end end
o1:startHistoryRecord(zB6zO) for QHdb,dtRn in pairs(zB6zO)do if cKy3Dt=="x"then dtRn.StudsPerTileU=y elseif cKy3Dt=="y"then dtRn.StudsPerTileV=y end end
o1:finishHistoryRecord()end Tools.Texture.addTexture=function(eHQcOZ4) local Sd6s={apply=function(eHQcOZ4)Selection:clear()for KVcI5x,AHVxk8 in pairs(eHQcOZ4.textures)do AHVxk8.Parent=eHQcOZ4.texture_parents[AHVxk8] Selection:add(AHVxk8.Parent)end end,unapply=function(eHQcOZ4) Selection:clear()for ykIP,XQaA in pairs(eHQcOZ4.textures)do Selection:add(XQaA.Parent)XQaA.Parent= nil end end}local G4={}local A={} for UFkKFj0,mj8vF in pairs(Selection.Items)do local N=Support.GetChildrenOfClass(mj8vF,"Texture")local XN_r=false
for UFkKFj0,ihQKt in pairs(N)do if ihQKt.Face==eHQcOZ4.Options.side then XN_r=true
break end end if not XN_r then local Nf=RbxUtility.Create"Texture"{Parent=mj8vF,Face=eHQcOZ4.Options.side}table.insert(G4,Nf)A[Nf]=mj8vF end end
Sd6s.textures=G4
Sd6s.texture_parents=A
History:add(Sd6s)end Tools.Texture.addDecal=function(v0xXBtzp) local Rh8dzZf_={apply=function(v0xXBtzp)Selection:clear() for DQKzz7t,I in pairs(v0xXBtzp.decals)do I.Parent=v0xXBtzp.decal_parents[I]Selection:add(I.Parent)end end,unapply=function(v0xXBtzp) Selection:clear()for jvpPcK,s in pairs(v0xXBtzp.decals)do Selection:add(s.Parent) s.Parent=nil end end}local k6z={}local W={} for Tx,izebj in pairs(Selection.Items)do local RioX=Support.GetChildrenOfClass(izebj,"Decal")local sgtu=false for Tx,i3XH in pairs(RioX)do if i3XH.Face==v0xXBtzp.Options.side then sgtu=true break end end if not sgtu then local USt6PLe2=RbxUtility.Create"Decal"{Parent=izebj,Face=v0xXBtzp.Options.side}table.insert(k6z,USt6PLe2)W[USt6PLe2]=izebj end end
Rh8dzZf_.decals=k6z
Rh8dzZf_.decal_parents=W History:add(Rh8dzZf_)end Tools.Texture.removeTexture=function(j) local EHi={textures={},texture_parents={},apply=function(j)Selection:clear()for Du4PWm2,jEJClb in pairs(j.textures)do Selection:add(jEJClb.Parent)jEJClb.Parent=nil end end,unapply=function(j) Selection:clear()for np8JkPc,Rfao in pairs(j.textures)do Rfao.Parent=j.texture_parents[Rfao] Selection:add(Rfao.Parent)end end} for N6IWFa,Hr3mtiCq in pairs(Selection.Items)do local mf1UO=Support.GetChildrenOfClass(Hr3mtiCq,"Texture") for N6IWFa,wykbGA84 in pairs(mf1UO)do if wykbGA84.Face==j.Options.side then table.insert(EHi.textures,wykbGA84)EHi.texture_parents[wykbGA84]=wykbGA84.Parent wykbGA84.Parent=nil end end end
History:add(EHi)end Tools.Texture.removeDecal=function(Pd) local po2ff4F={decals={},decal_parents={},apply=function(Pd)Selection:clear()for f,a in pairs(Pd.decals)do Selection:add(a.Parent)a.Parent=nil end end,unapply=function(Pd) Selection:clear()for mBRe,Cb in pairs(Pd.decals)do Cb.Parent=Pd.decal_parents[Cb] Selection:add(Cb.Parent)end end} for QP,k in pairs(Selection.Items)do local NTz6jdr=Support.GetChildrenOfClass(k,"Decal") for QP,cgIU3 in pairs(NTz6jdr)do if cgIU3.Face==Pd.Options.side then table.insert(po2ff4F.decals,cgIU3)po2ff4F.decal_parents[cgIU3]=cgIU3.Parent cgIU3.Parent=nil end end end
History:add(po2ff4F)end Tools.Texture.updateGUI=function(auV7A3JP)if not auV7A3JP.GUI then return end local FzJwZ=auV7A3JP.GUI if#Selection.Items==0 then auV7A3JP.GUI.AddButton.Visible=false
auV7A3JP.GUI.RemoveButton.Visible=false auV7A3JP.GUI.ImageIDOption.Visible=false
auV7A3JP.GUI.TransparencyOption.Visible=false auV7A3JP.GUI.RepeatOption.Visible=false
auV7A3JP.GUI.Size=UDim2.new(0,200,0,100)else if auV7A3JP.Options.mode=="texture"then local Zb5={} for Ofe,TV4H8 in pairs(Selection.Items)do local HdS=Support.GetChildrenOfClass(TV4H8,"Texture") for Ofe,bvGUlnl8 in pairs(HdS)do if bvGUlnl8.Face==auV7A3JP.Options.side then table.insert(Zb5,bvGUlnl8)break end end end if#Zb5 ==0 then auV7A3JP.GUI.AddButton.Visible=true auV7A3JP.GUI.RemoveButton.Visible=false
auV7A3JP.GUI.ImageIDOption.Visible=false auV7A3JP.GUI.TransparencyOption.Visible=false
auV7A3JP.GUI.RepeatOption.Visible=false auV7A3JP.GUI.Size=UDim2.new(0,200,0,130)elseif#Zb5 ~=#Selection.Items then auV7A3JP.GUI.AddButton.Visible=true
auV7A3JP.GUI.RemoveButton.Visible=true auV7A3JP.GUI.ImageIDOption.Visible=true
auV7A3JP.GUI.TransparencyOption.Visible=true auV7A3JP.GUI.RepeatOption.Visible=true auV7A3JP.GUI.ImageIDOption.Position=UDim2.new(0,14,0,135) auV7A3JP.GUI.TransparencyOption.Position=UDim2.new(0,14,0,170) auV7A3JP.GUI.RepeatOption.Position=UDim2.new(0,0,0,205)auV7A3JP.GUI.Size=UDim2.new(0,200,0,280)elseif#Zb5 ==# Selection.Items then auV7A3JP.GUI.AddButton.Visible=false
auV7A3JP.GUI.RemoveButton.Visible=true auV7A3JP.GUI.ImageIDOption.Visible=true
auV7A3JP.GUI.TransparencyOption.Visible=true auV7A3JP.GUI.RepeatOption.Visible=true auV7A3JP.GUI.ImageIDOption.Position=UDim2.new(0,14,0,100) auV7A3JP.GUI.TransparencyOption.Position=UDim2.new(0,14,0,135) auV7A3JP.GUI.RepeatOption.Position=UDim2.new(0,0,0,170)auV7A3JP.GUI.Size=UDim2.new(0,200,0,245)end
local U,D1Bo4qP,CaGUl8h,zL for E2J9X,y in pairs(Zb5)do if E2J9X==1 then U=y.Texture:lower() D1Bo4qP=y.Transparency
CaGUl8h=y.StudsPerTileU
zL=y.StudsPerTileV else if U~=y.Texture:lower()then U=nil end
if D1Bo4qP~=y.Transparency then D1Bo4qP=nil end
if CaGUl8h~=y.StudsPerTileU then CaGUl8h=nil end
if zL~=y.StudsPerTileV then zL=nil end end end
if not auV7A3JP.State.image_id_focused then auV7A3JP.GUI.ImageIDOption.TextBox.Text= U and(U:match("%?id=([0-9]+)")or"")or"*"end if not auV7A3JP.State.transparency_focused then auV7A3JP.GUI.TransparencyOption.TransparencyInput.TextBox.Text= D1Bo4qP and Support.Round(D1Bo4qP,2)or"*"end
if not auV7A3JP.State.rep_x_focused then auV7A3JP.GUI.RepeatOption.XInput.TextBox.Text= CaGUl8h and Support.Round(CaGUl8h,2)or"*"end
if not auV7A3JP.State.rep_y_focused then auV7A3JP.GUI.RepeatOption.YInput.TextBox.Text= zL and Support.Round(zL,2)or"*"end elseif auV7A3JP.Options.mode=="decal"then local _Sbcpg={} for WO,dcu in pairs(Selection.Items)do local HR=Support.GetChildrenOfClass(dcu,"Decal") for WO,P in pairs(HR)do if P.Face==auV7A3JP.Options.side then table.insert(_Sbcpg,P)break end end end if#_Sbcpg==0 then auV7A3JP.GUI.AddButton.Visible=true auV7A3JP.GUI.RemoveButton.Visible=false
auV7A3JP.GUI.ImageIDOption.Visible=false auV7A3JP.GUI.TransparencyOption.Visible=false
auV7A3JP.GUI.RepeatOption.Visible=false auV7A3JP.GUI.Size=UDim2.new(0,200,0,130)elseif#_Sbcpg~=#Selection.Items then auV7A3JP.GUI.AddButton.Visible=true
auV7A3JP.GUI.RemoveButton.Visible=true auV7A3JP.GUI.ImageIDOption.Visible=true
auV7A3JP.GUI.TransparencyOption.Visible=true auV7A3JP.GUI.RepeatOption.Visible=false auV7A3JP.GUI.ImageIDOption.Position=UDim2.new(0,14,0,135) auV7A3JP.GUI.TransparencyOption.Position=UDim2.new(0,14,0,170)auV7A3JP.GUI.Size=UDim2.new(0,200,0,245)elseif#_Sbcpg==# Selection.Items then auV7A3JP.GUI.AddButton.Visible=false
auV7A3JP.GUI.RemoveButton.Visible=true auV7A3JP.GUI.ImageIDOption.Visible=true
auV7A3JP.GUI.TransparencyOption.Visible=true auV7A3JP.GUI.RepeatOption.Visible=false auV7A3JP.GUI.ImageIDOption.Position=UDim2.new(0,14,0,100) auV7A3JP.GUI.TransparencyOption.Position=UDim2.new(0,14,0,135)auV7A3JP.GUI.Size=UDim2.new(0,200,0,205)end
local y99_,f7ZTY for y1jZqCcc,ARVZ in pairs(_Sbcpg)do if y1jZqCcc==1 then y99_=ARVZ.Texture:lower() f7ZTY=ARVZ.Transparency else if y99_~=ARVZ.Texture:lower()then y99_=nil end
if f7ZTY~= ARVZ.Transparency then f7ZTY=nil end end end if not auV7A3JP.State.image_id_focused then auV7A3JP.GUI.ImageIDOption.TextBox.Text=  y99_ and(y99_:match("%?id=([0-9]+)")or"")or"*"end if not auV7A3JP.State.transparency_focused then auV7A3JP.GUI.TransparencyOption.TransparencyInput.TextBox.Text= f7ZTY and Support.Round(f7ZTY,2)or"*"end end end end Tools.Texture.showGUI=function(ulU) if not ulU.GUI then local mkpyU5eh=DFb100j.BTTextureToolGUI:Clone()mkpyU5eh.Parent=UI mkpyU5eh.AddButton.Button.MouseButton1Up:connect(function()if ulU.Options.mode=="decal"then ulU:addDecal()elseif ulU.Options.mode=="texture"then ulU:addTexture()end end) mkpyU5eh.RemoveButton.Button.MouseButton1Up:connect(function() if ulU.Options.mode=="decal"then ulU:removeDecal()elseif ulU.Options.mode=="texture"then ulU:removeTexture()end end) mkpyU5eh.ModeOption.Decal.Button.MouseButton1Down:connect(function() ulU:changeMode("decal")end) mkpyU5eh.ModeOption.Texture.Button.MouseButton1Down:connect(function() ulU:changeMode("texture")end)local U9=createDropdown()ulU.SideDropdown=U9 U9.Frame.Parent=mkpyU5eh.SideOption
U9.Frame.Position=UDim2.new(0,35,0,0) U9.Frame.Size=UDim2.new(1,-50,0,25) U9:addOption("TOP").MouseButton1Up:connect(function() ulU:changeSide(Enum.NormalId.Top)end) U9:addOption("BOTTOM").MouseButton1Up:connect(function() ulU:changeSide(Enum.NormalId.Bottom)end) U9:addOption("FRONT").MouseButton1Up:connect(function() ulU:changeSide(Enum.NormalId.Front)end) U9:addOption("BACK").MouseButton1Up:connect(function() ulU:changeSide(Enum.NormalId.Back)end) U9:addOption("LEFT").MouseButton1Up:connect(function() ulU:changeSide(Enum.NormalId.Left)end) U9:addOption("RIGHT").MouseButton1Up:connect(function() ulU:changeSide(Enum.NormalId.Right)end) mkpyU5eh.RepeatOption.XInput.TextButton.MouseButton1Down:connect(function() ulU.State.rep_x_focused=true mkpyU5eh.RepeatOption.XInput.TextBox:CaptureFocus()end) mkpyU5eh.RepeatOption.XInput.TextBox.FocusLost:connect(function(pzpDOr) local yoo=tonumber(mkpyU5eh.RepeatOption.XInput.TextBox.Text)if yoo then ulU:changeFrequency('x',yoo)end ulU.State.rep_x_focused=false end) mkpyU5eh.RepeatOption.YInput.TextButton.MouseButton1Down:connect(function() ulU.State.rep_y_focused=true mkpyU5eh.RepeatOption.YInput.TextBox:CaptureFocus()end) mkpyU5eh.RepeatOption.YInput.TextBox.FocusLost:connect(function(MXzW) local Uvqu6c5=tonumber(mkpyU5eh.RepeatOption.YInput.TextBox.Text) if Uvqu6c5 then ulU:changeFrequency('y',Uvqu6c5)end
ulU.State.rep_y_focused=false end) mkpyU5eh.ImageIDOption.TextButton.MouseButton1Down:connect(function() ulU.State.image_id_focused=true mkpyU5eh.ImageIDOption.TextBox:CaptureFocus()end) mkpyU5eh.ImageIDOption.TextBox.FocusLost:connect(function(MMXv) local R=mkpyU5eh.ImageIDOption.TextBox.Text local u=tonumber(R)or R:lower():match("%?id=([0-9]+)")if u then if ulU.Options.mode=="decal"then ulU:changeDecal(u)elseif ulU.Options.mode== "texture"then ulU:changeTexture(u)end end ulU.State.image_id_focused=false end) mkpyU5eh.TransparencyOption.TransparencyInput.TextButton.MouseButton1Down:connect(function() ulU.State.transparency_focused=true mkpyU5eh.TransparencyOption.TransparencyInput.TextBox:CaptureFocus()end) mkpyU5eh.TransparencyOption.TransparencyInput.TextBox.FocusLost:connect(function(ipLsp) local cpC=tonumber(mkpyU5eh.TransparencyOption.TransparencyInput.TextBox.Text)if cpC then if cpC>1 then cpC=1 elseif cpC<0 then cpC=0 end ulU:changeTransparency(cpC)end ulU.State.transparency_focused=false end)ulU.GUI=mkpyU5eh end
ulU.GUI.Visible=true end Tools.Texture.hideGUI=function(k73bTK) if k73bTK.GUI then k73bTK.GUI.Visible=false end end
Tools.Texture.Loaded=true end},{"Weld",function() repeat wait()until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.Weld={} Tools.Weld.Color=BrickColor.new("Really black")Tools.Weld.State={}Tools.Weld.Connections={} Tools.Weld.Listeners={} Tools.Weld.Listeners.Equipped=function()local cqVt=Tools.Weld cqVt.State.PreviousSelectionBoxColor=SelectionBoxColor
SelectionBoxColor=cqVt.Color
updateSelectionBoxColor() cqVt:showGUI()if Selection.Last and SelectionBoxes[Selection.Last]then SelectionBoxes[Selection.Last].Color=BrickColor.new("Pastel Blue")end cqVt.Connections.LastPartHighlighter=Selection.Changed:connect(function() updateSelectionBoxColor()if Selection.Last and SelectionBoxes[Selection.Last]then SelectionBoxes[Selection.Last].Color=BrickColor.new("Pastel Blue")end end)end Tools.Weld.Listeners.Unequipped=function()local ywq=Tools.Weld
ywq:hideGUI() for lMF,WVA in pairs(ywq.Connections)do WVA:disconnect()ywq.Connections[lMF]=nil end
SelectionBoxColor=ywq.State.PreviousSelectionBoxColor updateSelectionBoxColor()end Tools.Weld.Listeners.Button2Down=function()local iWh=Tools.Weld local XG,Ts,K8jL8qZ=Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ() iWh.State.PreB2DownCameraRotation=Vector3.new(XG,Ts,K8jL8qZ)end Tools.Weld.Listeners.Button2Up=function()local wucZH2qz=Tools.Weld local Ox0yyMI3,hvw,ZFhe=Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ()local Kgpa=Vector3.new(Ox0yyMI3,hvw,ZFhe) if  Selection:find(Mouse.Target)and wucZH2qz.State.PreB2DownCameraRotation==Kgpa then Selection:focus(Mouse.Target)end end Tools.Weld.weld=function(TEz) local AJJ1kZS={weld_parents={},unapply=function(TEz)Selection:clear() for Bd,e in pairs(TEz.welds)do Selection:add(e.Part0)Selection:add(e.Part1)e.Parent=nil end end,apply=function(TEz) Selection:clear() for tsGRH,U in pairs(TEz.welds)do U.Parent=TEz.weld_parents[U] Selection:add(U.Part0)Selection:add(U.Part1)end end}local B={} if#Selection.Items>1 and Selection.Last then for m,U84H37 in pairs(Selection.Items)do if U84H37 ~=Selection.Last then local C=RbxUtility.Create"Weld"{Name='BTWeld',Parent=Selection.Last,Part0=Selection.Last,Part1=U84H37,Archivable=false,C1=U84H37.CFrame:toObjectSpace(Selection.Last.CFrame)}table.insert(B,C)AJJ1kZS.weld_parents[C]=C.Parent end end end
AJJ1kZS.welds=B
History:add(AJJ1kZS) TEz.GUI.Changes.Text.Text= "created "..#B.." weld".. (#B~=1 and"s"or"") local vZdI=RbxUtility.Create"Sound"{Name="BTActionCompletionSound",Pitch=1.5,SoundId=Assets.ActionCompletionSound,Volume=1,Parent=Player}vZdI:Play()vZdI:Destroy()end Tools.Weld.breakWelds=function(f4fN) local ODzAx={weld_parents={},apply=function(f4fN)Selection:clear() for SC,bWuOG in pairs(f4fN.welds)do Selection:add(bWuOG.Part0)Selection:add(bWuOG.Part1)bWuOG.Parent=nil end end,unapply=function(f4fN) Selection:clear() for jGg,x in pairs(f4fN.welds)do Selection:add(x.Part1) Selection:add(x.Part0)x.Parent=f4fN.weld_parents[x]end end}local IsAkf={} local Pwzq_Fj=Support.GetAllDescendants(Game.Workspace) for vqs1_7,vLdk in pairs(Pwzq_Fj)do if vLdk:IsA("Weld")and vLdk.Name=="BTWeld"then for vqs1_7,cU6JgXi in pairs(Selection.Items)do if vLdk.Part0 ==cU6JgXi or vLdk.Part1 ==cU6JgXi then if not ODzAx.weld_parents[vLdk]then table.insert(IsAkf,vLdk) ODzAx.weld_parents[vLdk]=vLdk.Parent
vLdk.Parent=nil end end end end end
ODzAx.welds=IsAkf
History:add(ODzAx)f4fN.GUI.Changes.Text.Text= "broke ".. #IsAkf.." weld".. (#IsAkf~=1 and"s"or"") local GKDMp=RbxUtility.Create"Sound"{Name="BTActionCompletionSound",Pitch=1.5,SoundId=Assets.ActionCompletionSound,Volume=1,Parent=Player}GKDMp:Play()GKDMp:Destroy()end Tools.Weld.showGUI=function(tEiL) if not tEiL.GUI then local nWMi=DFb100j.BTWeldToolGUI:Clone()nWMi.Parent=UI nWMi.Interface.WeldButton.MouseButton1Up:connect(function() tEiL:weld()end) nWMi.Interface.BreakWeldsButton.MouseButton1Up:connect(function() tEiL:breakWelds()end)tEiL.GUI=nWMi end
tEiL.GUI.Visible=true end Tools.Weld.hideGUI=function(gl9xJb) if gl9xJb.GUI then gl9xJb.GUI.Visible=false end end
Tools.Weld.Loaded=true end},{"Lighting",function() repeat wait()until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.Lighting={} Tools.Lighting.Color=BrickColor.new("Really black")Tools.Lighting.State={}Tools.Lighting.Connections={} Tools.Lighting.Listeners={} Tools.Lighting.Listeners.Equipped=function()local oHk5pUB=Tools.Lighting oHk5pUB.State.PreviousSelectionBoxColor=SelectionBoxColor
SelectionBoxColor=oHk5pUB.Color
updateSelectionBoxColor() oHk5pUB:showGUI() coroutine.wrap(function()updater_on=true oHk5pUB.Updater=function()updater_on=false end
while wait(0.1)and updater_on do if CurrentTool==oHk5pUB then if oHk5pUB.GUI and oHk5pUB.GUI.Visible then oHk5pUB:updateGUI()end end end end)()end Tools.Lighting.Listeners.Unequipped=function()local Ltm=Tools.Lighting
if Ltm.Updater then Ltm.Updater()Ltm.Updater=nil end
Ltm:hideGUI() for yW9GRj,QGXSL6 in pairs(Ltm.Connections)do QGXSL6:disconnect()Ltm.Connections[yW9GRj]=nil end
SelectionBoxColor=Ltm.State.PreviousSelectionBoxColor updateSelectionBoxColor()end Tools.Lighting.Listeners.Button2Down=function()local M=Tools.Lighting local _X,eir,e=Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ()M.State.PreB2DownCameraRotation=Vector3.new(_X,eir,e)end Tools.Lighting.Listeners.Button2Up=function()local XKqiVa3=Tools.Lighting local v4mltq,AIOtQ8e_,d=Workspace.CurrentCamera.CoordinateFrame:toEulerAnglesXYZ()local l7=Vector3.new(v4mltq,AIOtQ8e_,d) if  Selection:find(Mouse.Target)and XKqiVa3.State.PreB2DownCameraRotation==l7 then XKqiVa3:changeSide(Mouse.TargetSurface)end end Tools.Lighting.updateGUI=function(vtjp)if not vtjp.GUI then return end if #Selection.Items>0 then local qLEp2=vtjp:getSpotlights() local XbIEI_3k=vtjp:getPointLights()local Ysuv,v,my19G,oO,zqYNA,XMzOvb,l8zYu,x17pq6s
local Cxc,G,dZty4,d,NQQjm0G,qeyvW for fuJ,vBt in pairs(qLEp2)do if fuJ==1 then Ysuv,v,my19G=vBt.Color.r,vBt.Color.g,vBt.Color.b
oO=vBt.Brightness
zqYNA=vBt.Range
XMzOvb=vBt.Shadows
l8zYu=vBt.Angle x17pq6s=vBt.Face else if Ysuv~=vBt.Color.r then Ysuv=nil end if v~=vBt.Color.g then v=nil end
if my19G~=vBt.Color.b then my19G=nil end
if oO~=vBt.Brightness then oO=nil end
if zqYNA~=vBt.Range then zqYNA=nil end
if XMzOvb~=vBt.Shadows then XMzOvb=nil end
if l8zYu~=vBt.Angle then l8zYu=nil end
if x17pq6s~=vBt.Face then x17pq6s=nil end end end for j6f,DhLDRM in pairs(XbIEI_3k)do if j6f==1 then Cxc,G,dZty4=DhLDRM.Color.r,DhLDRM.Color.g,DhLDRM.Color.b
d=DhLDRM.Brightness
NQQjm0G=DhLDRM.Range
qeyvW=DhLDRM.Shadows else if Cxc~= DhLDRM.Color.r then Cxc=nil end if G~=DhLDRM.Color.g then G=nil end
if dZty4 ~=DhLDRM.Color.b then dZty4=nil end
if d~=DhLDRM.Brightness then d=nil end if NQQjm0G~=DhLDRM.Range then NQQjm0G=nil end
if qeyvW~=DhLDRM.Shadows then qeyvW=nil end end end
vtjp.State.sl_color= (Ysuv and v and my19G)and Color3.new(Ysuv,v,my19G)or nil
vtjp.State.pl_color= ( Cxc and G and dZty4)and Color3.new(Cxc,G,dZty4)or nil
if not vtjp.State.sl_color_r_focused then vtjp.GUI.Spotlight.Options.ColorOption.RInput.TextBox.Text= Ysuv and Support.Round(Ysuv*255,0)or'*'end
if not vtjp.State.sl_color_g_focused then vtjp.GUI.Spotlight.Options.ColorOption.GInput.TextBox.Text= v and Support.Round(v*255,0)or'*'end
if not vtjp.State.sl_color_b_focused then vtjp.GUI.Spotlight.Options.ColorOption.BInput.TextBox.Text= my19G and Support.Round(my19G*255,0)or'*'end
if not vtjp.State.sl_brightness_focused then vtjp.GUI.Spotlight.Options.BrightnessOption.Input.TextBox.Text= oO and Support.Round(oO,2)or'*'end
if not vtjp.State.sl_range_focused then vtjp.GUI.Spotlight.Options.RangeOption.Input.TextBox.Text= zqYNA and Support.Round(zqYNA,2)or'*'end if XMzOvb==nil then vtjp.GUI.Spotlight.Options.ShadowsOption.On.Background.Image=Assets.LightSlantedRectangle vtjp.GUI.Spotlight.Options.ShadowsOption.On.SelectedIndicator.BackgroundTransparency=1 vtjp.GUI.Spotlight.Options.ShadowsOption.Off.Background.Image=Assets.LightSlantedRectangle vtjp.GUI.Spotlight.Options.ShadowsOption.Off.SelectedIndicator.BackgroundTransparency=1 elseif XMzOvb==true then vtjp.GUI.Spotlight.Options.ShadowsOption.On.Background.Image=Assets.DarkSlantedRectangle vtjp.GUI.Spotlight.Options.ShadowsOption.On.SelectedIndicator.BackgroundTransparency=0 vtjp.GUI.Spotlight.Options.ShadowsOption.Off.Background.Image=Assets.LightSlantedRectangle vtjp.GUI.Spotlight.Options.ShadowsOption.Off.SelectedIndicator.BackgroundTransparency=1 elseif XMzOvb==false then vtjp.GUI.Spotlight.Options.ShadowsOption.On.Background.Image=Assets.LightSlantedRectangle vtjp.GUI.Spotlight.Options.ShadowsOption.On.SelectedIndicator.BackgroundTransparency=1 vtjp.GUI.Spotlight.Options.ShadowsOption.Off.Background.Image=Assets.DarkSlantedRectangle vtjp.GUI.Spotlight.Options.ShadowsOption.Off.SelectedIndicator.BackgroundTransparency=0 end
if not vtjp.State.sl_angle_focused then vtjp.GUI.Spotlight.Options.AngleOption.Input.TextBox.Text= l8zYu and Support.Round(l8zYu,2)or'*'end vtjp.SideDropdown:selectOption( x17pq6s and x17pq6s.Name:upper()or'*')if not vtjp.State.pl_color_r_focused then vtjp.GUI.PointLight.Options.ColorOption.RInput.TextBox.Text= Cxc and Support.Round(Cxc*255,0)or'*'end
if not vtjp.State.pl_color_g_focused then vtjp.GUI.PointLight.Options.ColorOption.GInput.TextBox.Text= G and Support.Round(G*255,0)or'*'end
if not vtjp.State.pl_color_b_focused then vtjp.GUI.PointLight.Options.ColorOption.BInput.TextBox.Text= dZty4 and Support.Round(dZty4*255,0)or'*'end
if not vtjp.State.pl_brightness_focused then vtjp.GUI.PointLight.Options.BrightnessOption.Input.TextBox.Text= d and Support.Round(d,2)or'*'end
if not vtjp.State.pl_range_focused then vtjp.GUI.PointLight.Options.RangeOption.Input.TextBox.Text= NQQjm0G and Support.Round(NQQjm0G,2)or'*'end if qeyvW== nil then vtjp.GUI.PointLight.Options.ShadowsOption.On.Background.Image=Assets.LightSlantedRectangle vtjp.GUI.PointLight.Options.ShadowsOption.On.SelectedIndicator.BackgroundTransparency=1 vtjp.GUI.PointLight.Options.ShadowsOption.Off.Background.Image=Assets.LightSlantedRectangle vtjp.GUI.PointLight.Options.ShadowsOption.Off.SelectedIndicator.BackgroundTransparency=1 elseif qeyvW==true then vtjp.GUI.PointLight.Options.ShadowsOption.On.Background.Image=Assets.DarkSlantedRectangle vtjp.GUI.PointLight.Options.ShadowsOption.On.SelectedIndicator.BackgroundTransparency=0 vtjp.GUI.PointLight.Options.ShadowsOption.Off.Background.Image=Assets.LightSlantedRectangle vtjp.GUI.PointLight.Options.ShadowsOption.Off.SelectedIndicator.BackgroundTransparency=1 elseif qeyvW==false then vtjp.GUI.PointLight.Options.ShadowsOption.On.Background.Image=Assets.LightSlantedRectangle vtjp.GUI.PointLight.Options.ShadowsOption.On.SelectedIndicator.BackgroundTransparency=1 vtjp.GUI.PointLight.Options.ShadowsOption.Off.Background.Image=Assets.DarkSlantedRectangle vtjp.GUI.PointLight.Options.ShadowsOption.Off.SelectedIndicator.BackgroundTransparency=0 end
if vtjp.GUI.SelectNote.Visible then vtjp:closePointLight() vtjp:closeSpotlight()end vtjp.GUI.Spotlight.Visible=true
vtjp.GUI.PointLight.Visible=true vtjp.GUI.SelectNote.Visible=false if not vtjp.State.spotlight_open and not vtjp.State.pointlight_open then vtjp.GUI:TweenSize(UDim2.new(0,200,0,95),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end if#qLEp2 ==0 then vtjp.GUI.Spotlight.Options.Size=UDim2.new(1,-3,0,0)vtjp.GUI.Spotlight.AddButton.Visible=true vtjp.GUI.Spotlight.RemoveButton.Visible=false if vtjp.State.spotlight_open then vtjp:closeSpotlight()end elseif#qLEp2 ~=#Selection.Items then vtjp.GUI.Spotlight.AddButton.Visible=true vtjp.GUI.Spotlight.RemoveButton.Position=UDim2.new(0,90,0,3)vtjp.GUI.Spotlight.RemoveButton.Visible=true elseif# qLEp2 ==#Selection.Items then vtjp.GUI.Spotlight.AddButton.Visible=false vtjp.GUI.Spotlight.RemoveButton.Position=UDim2.new(0,127,0,3)vtjp.GUI.Spotlight.RemoveButton.Visible=true
if vtjp.GUI.Spotlight.Size==UDim2.new(0,200,0,52)then vtjp.GUI.Spotlight.Size=UDim2.new(0,200,0,95)end end if#XbIEI_3k==0 then vtjp.GUI.PointLight.Options.Size=UDim2.new(1,-3,0,0)vtjp.GUI.PointLight.AddButton.Visible=true vtjp.GUI.PointLight.RemoveButton.Visible=false if vtjp.State.pointlight_open then vtjp:closePointLight()end elseif#XbIEI_3k~=#Selection.Items then vtjp.GUI.PointLight.AddButton.Visible=true vtjp.GUI.PointLight.RemoveButton.Position=UDim2.new(0,90,0,3) vtjp.GUI.PointLight.RemoveButton.Visible=true elseif#XbIEI_3k==#Selection.Items then vtjp.GUI.PointLight.AddButton.Visible=false vtjp.GUI.PointLight.RemoveButton.Position=UDim2.new(0,127,0,3) vtjp.GUI.PointLight.RemoveButton.Visible=true end else vtjp.GUI.Spotlight.Visible=false vtjp.GUI.PointLight.Visible=false
vtjp.GUI.SelectNote.Visible=true vtjp.GUI.Size=UDim2.new(0,200,0,52)end end Tools.Lighting.openSpotlight=function(LgVwYh6)LgVwYh6.State.spotlight_open=true LgVwYh6:closePointLight() LgVwYh6.GUI.Spotlight.Options:TweenSize(UDim2.new(1,-3,0,300),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) LgVwYh6.GUI.Spotlight:TweenPosition(UDim2.new(0,10,0,30),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) LgVwYh6.GUI:TweenSize(UDim2.new(0,200,0,275),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end Tools.Lighting.openPointLight=function(tSBo)tSBo.State.pointlight_open=true tSBo:closeSpotlight() tSBo.GUI.PointLight.Options:TweenSize(UDim2.new(1,-3,0,110),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) tSBo.GUI.PointLight:TweenPosition(UDim2.new(0,10,0,60),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) tSBo.GUI:TweenSize(UDim2.new(0,200,0,200),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end Tools.Lighting.closeSpotlight=function(FuIUnM)FuIUnM.State.spotlight_open=false FuIUnM.GUI.Spotlight.Options:TweenSize(UDim2.new(1, -3,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) FuIUnM.GUI.PointLight:TweenPosition(UDim2.new(0,10,0,60),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)if not FuIUnM.State.pointlight_open then FuIUnM.GUI:TweenSize(UDim2.new(0,200,0,95),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end end Tools.Lighting.closePointLight=function(WtoMT)WtoMT.State.pointlight_open=false WtoMT.GUI.PointLight:TweenPosition(UDim2.new(0,10,0, WtoMT.State.spotlight_open and 240 or 60),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) WtoMT.GUI.PointLight.Options:TweenSize(UDim2.new(1,-3,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)if not WtoMT.State.spotlight_open then WtoMT.GUI:TweenSize(UDim2.new(0,200,0,95),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end end Tools.Lighting.showGUI=function(gTa7jfw) if not gTa7jfw.GUI then local d6RaDSY=DFb100j.BTLightingToolGUI:Clone()d6RaDSY.Parent=UI d6RaDSY.Spotlight.ArrowButton.MouseButton1Up:connect(function() if not gTa7jfw.State.spotlight_open and #gTa7jfw:getSpotlights()>0 then gTa7jfw:openSpotlight()else gTa7jfw:closeSpotlight()end end) d6RaDSY.PointLight.ArrowButton.MouseButton1Up:connect(function() if not gTa7jfw.State.pointlight_open and #gTa7jfw:getPointLights()>0 then gTa7jfw:openPointLight()else gTa7jfw:closePointLight()end end) d6RaDSY.Spotlight.AddButton.MouseButton1Up:connect(function() gTa7jfw:addLight('SpotLight')gTa7jfw:openSpotlight()end) d6RaDSY.PointLight.AddButton.MouseButton1Up:connect(function() gTa7jfw:addLight('PointLight')gTa7jfw:openPointLight()end) d6RaDSY.Spotlight.RemoveButton.MouseButton1Up:connect(function() gTa7jfw:removeLight('spotlight')gTa7jfw:closeSpotlight()end) d6RaDSY.PointLight.RemoveButton.MouseButton1Up:connect(function() gTa7jfw:removeLight('pointlight')gTa7jfw:closePointLight()end)local hJEr=createDropdown()gTa7jfw.SideDropdown=hJEr hJEr.Frame.Parent=d6RaDSY.Spotlight.Options.SideOption
hJEr.Frame.Position=UDim2.new(0,35,0,0) hJEr.Frame.Size=UDim2.new(0,90,0,25) hJEr:addOption("TOP").MouseButton1Up:connect(function() gTa7jfw:changeSide(Enum.NormalId.Top)end) hJEr:addOption("BOTTOM").MouseButton1Up:connect(function() gTa7jfw:changeSide(Enum.NormalId.Bottom)end) hJEr:addOption("FRONT").MouseButton1Up:connect(function() gTa7jfw:changeSide(Enum.NormalId.Front)end) hJEr:addOption("BACK").MouseButton1Up:connect(function() gTa7jfw:changeSide(Enum.NormalId.Back)end) hJEr:addOption("LEFT").MouseButton1Up:connect(function() gTa7jfw:changeSide(Enum.NormalId.Left)end) hJEr:addOption("RIGHT").MouseButton1Up:connect(function() gTa7jfw:changeSide(Enum.NormalId.Right)end)local deq_fwZ=d6RaDSY.Spotlight
local d4iuG=deq_fwZ.Options.ColorOption d4iuG.RInput.TextButton.MouseButton1Down:connect(function() gTa7jfw.State.sl_color_r_focused=true
d4iuG.RInput.TextBox:CaptureFocus()end) d4iuG.RInput.TextBox.FocusLost:connect(function(Lc4UCGl) local lEoJniu=tonumber(d4iuG.RInput.TextBox.Text) if lEoJniu then if lEoJniu>255 then lEoJniu=255 elseif lEoJniu<0 then lEoJniu=0 end
gTa7jfw:changeColor('spotlight','r', lEoJniu/255)end
gTa7jfw.State.sl_color_r_focused=false end) d4iuG.GInput.TextButton.MouseButton1Down:connect(function() gTa7jfw.State.sl_color_g_focused=true
d4iuG.GInput.TextBox:CaptureFocus()end) d4iuG.GInput.TextBox.FocusLost:connect(function(sMV) local HLkyy=tonumber(d4iuG.GInput.TextBox.Text) if HLkyy then if HLkyy>255 then HLkyy=255 elseif HLkyy<0 then HLkyy=0 end
gTa7jfw:changeColor('spotlight','g', HLkyy/255)end
gTa7jfw.State.sl_color_g_focused=false end) d4iuG.BInput.TextButton.MouseButton1Down:connect(function() gTa7jfw.State.sl_color_b_focused=true
d4iuG.BInput.TextBox:CaptureFocus()end) d4iuG.BInput.TextBox.FocusLost:connect(function(ttFi_l_) local dSeSQ5=tonumber(d4iuG.BInput.TextBox.Text) if dSeSQ5 then if dSeSQ5 >255 then dSeSQ5=255 elseif dSeSQ5 <0 then dSeSQ5=0 end
gTa7jfw:changeColor('spotlight','b', dSeSQ5/255)end
gTa7jfw.State.sl_color_b_focused=false end) d4iuG.HSVPicker.MouseButton1Up:connect(function() ColorPicker:start(function(...)local CHYkRQW6={...}if# CHYkRQW6 ==3 then gTa7jfw:changeColor('spotlight',Support.HSVToRGB(...))end end,gTa7jfw.State.sl_color)end)local tn2=deq_fwZ.Options.BrightnessOption.Input tn2.TextButton.MouseButton1Down:connect(function() gTa7jfw.State.sl_brightness_focused=true
tn2.TextBox:CaptureFocus()end) tn2.TextBox.FocusLost:connect(function(cZtDtN7N) local Z7UyFJN=tonumber(tn2.TextBox.Text)if Z7UyFJN then if Z7UyFJN>5 then Z7UyFJN=5 elseif Z7UyFJN<0 then Z7UyFJN=0 end gTa7jfw:changeBrightness('spotlight',Z7UyFJN)end gTa7jfw.State.sl_brightness_focused=false end)local iFXPT_P=deq_fwZ.Options.AngleOption.Input iFXPT_P.TextButton.MouseButton1Down:connect(function() gTa7jfw.State.sl_angle_focused=true
iFXPT_P.TextBox:CaptureFocus()end) iFXPT_P.TextBox.FocusLost:connect(function(DYBqYM) local s1=tonumber(iFXPT_P.TextBox.Text)if s1 then gTa7jfw:changeAngle(s1)end gTa7jfw.State.sl_angle_focused=false end)local KY=deq_fwZ.Options.RangeOption.Input KY.TextButton.MouseButton1Down:connect(function() gTa7jfw.State.sl_range_focused=true
KY.TextBox:CaptureFocus()end) KY.TextBox.FocusLost:connect(function(v) local aFb6x0hg=tonumber(KY.TextBox.Text) if aFb6x0hg then if aFb6x0hg>60 then aFb6x0hg=60 elseif aFb6x0hg<0 then aFb6x0hg=0 end
gTa7jfw:changeRange('spotlight',aFb6x0hg)end
gTa7jfw.State.sl_range_focused=false end)local Vg7WM=deq_fwZ.Options.ShadowsOption Vg7WM.On.Button.MouseButton1Down:connect(function() gTa7jfw:changeShadows('spotlight',true)end) Vg7WM.Off.Button.MouseButton1Down:connect(function() gTa7jfw:changeShadows('spotlight',false)end)local DPOHoac=d6RaDSY.PointLight
local HLe=DPOHoac.Options.ColorOption HLe.RInput.TextButton.MouseButton1Down:connect(function() gTa7jfw.State.pl_color_r_focused=true
HLe.RInput.TextBox:CaptureFocus()end) HLe.RInput.TextBox.FocusLost:connect(function(_KKTJh) local Gikjz8_9=tonumber(HLe.RInput.TextBox.Text)if Gikjz8_9 then if Gikjz8_9 >255 then Gikjz8_9=255 elseif Gikjz8_9 <0 then Gikjz8_9=0 end gTa7jfw:changeColor('pointlight','r',Gikjz8_9/255)end gTa7jfw.State.pl_color_r_focused=false end) HLe.GInput.TextButton.MouseButton1Down:connect(function() gTa7jfw.State.pl_color_g_focused=true
HLe.GInput.TextBox:CaptureFocus()end) HLe.GInput.TextBox.FocusLost:connect(function(WN20gP) local L2VjlBE=tonumber(HLe.GInput.TextBox.Text) if L2VjlBE then if L2VjlBE>255 then L2VjlBE=255 elseif L2VjlBE<0 then L2VjlBE=0 end
gTa7jfw:changeColor('pointlight','g', L2VjlBE/255)end
gTa7jfw.State.pl_color_g_focused=false end) HLe.BInput.TextButton.MouseButton1Down:connect(function() gTa7jfw.State.pl_color_b_focused=true
HLe.BInput.TextBox:CaptureFocus()end) HLe.BInput.TextBox.FocusLost:connect(function(xH) local N=tonumber(HLe.BInput.TextBox.Text)if N then if N>255 then N=255 elseif N<0 then N=0 end gTa7jfw:changeColor('pointlight','b',N/255)end gTa7jfw.State.pl_color_b_focused=false end) HLe.HSVPicker.MouseButton1Up:connect(function() ColorPicker:start(function(...)local R={...}if#R==3 then gTa7jfw:changeColor('pointlight',Support.HSVToRGB(...))end end,gTa7jfw.State.pl_color)end)local COX=DPOHoac.Options.BrightnessOption.Input COX.TextButton.MouseButton1Down:connect(function() gTa7jfw.State.pl_brightness_focused=true
COX.TextBox:CaptureFocus()end) COX.TextBox.FocusLost:connect(function(owi4kS) local zUfjp=tonumber(COX.TextBox.Text)if zUfjp then if zUfjp>5 then zUfjp=5 elseif zUfjp<0 then zUfjp=0 end gTa7jfw:changeBrightness('pointlight',zUfjp)end gTa7jfw.State.pl_brightness_focused=false end)local BP9Y0=DPOHoac.Options.RangeOption.Input BP9Y0.TextButton.MouseButton1Down:connect(function() gTa7jfw.State.pl_range_focused=true
BP9Y0.TextBox:CaptureFocus()end) BP9Y0.TextBox.FocusLost:connect(function(fd5S4R) local Jt=tonumber(BP9Y0.TextBox.Text)if Jt then if Jt>60 then Jt=60 elseif Jt<0 then Jt=0 end gTa7jfw:changeRange('pointlight',Jt)end gTa7jfw.State.pl_range_focused=false end)local DR=DPOHoac.Options.ShadowsOption DR.On.Button.MouseButton1Down:connect(function() gTa7jfw:changeShadows('pointlight',true)end) DR.Off.Button.MouseButton1Down:connect(function() gTa7jfw:changeShadows('pointlight',false)end)gTa7jfw.GUI=d6RaDSY end
gTa7jfw.GUI.Visible=true end Tools.Lighting.changeSide=function(vJ88gTG,GVscDb)local eGuTD=vJ88gTG:getSpotlights() vJ88gTG:startHistoryRecord(eGuTD)for l,rcJbyavv in pairs(eGuTD)do rcJbyavv.Face=GVscDb end vJ88gTG:finishHistoryRecord()if vJ88gTG.SideDropdown.open then vJ88gTG.SideDropdown:toggle()end end Tools.Lighting.changeAngle=function(nPu,wKdmIyn)local Po67cFi=nPu:getSpotlights() nPu:startHistoryRecord(Po67cFi)for nlAeE,h in pairs(Po67cFi)do h.Angle=wKdmIyn end nPu:finishHistoryRecord()end Tools.Lighting.getSpotlights=function(B)local mmcA={} for Pk,es in pairs(Selection.Items)do local F0ZX=Support.GetChildOfClass(es,'SpotLight')if F0ZX then table.insert(mmcA,F0ZX)end end
return mmcA end Tools.Lighting.getPointLights=function(W_)local he3X={} for IAEOa,lq0 in pairs(Selection.Items)do local cJ=Support.GetChildOfClass(lq0,'PointLight')if cJ then table.insert(he3X,cJ)end end
return he3X end Tools.Lighting.changeColor=function(VxeY5X,oS8SgP,...)local hBilFrU4={...}local AodN1 if oS8SgP=='spotlight'then AodN1=VxeY5X:getSpotlights()elseif oS8SgP=='pointlight'then AodN1=VxeY5X:getPointLights()end
VxeY5X:startHistoryRecord(AodN1) if#hBilFrU4 ==2 then local yj4Mo=hBilFrU4[1]local BiwDB=hBilFrU4[2] for Ca,wHJE0ZY in pairs(AodN1)do wHJE0ZY.Color=Color3.new(yj4Mo=='r'and BiwDB or wHJE0ZY.Color.r,yj4Mo=='g'and BiwDB or wHJE0ZY.Color.g, yj4Mo=='b'and BiwDB or wHJE0ZY.Color.b)end elseif#hBilFrU4 ==3 then local Js7,h6W2B6z,Cx=...for oj,u1 in pairs(AodN1)do u1.Color=Color3.new(Js7,h6W2B6z,Cx)end end
VxeY5X:finishHistoryRecord()end Tools.Lighting.changeBrightness=function(TYixjzX4,vI9Mah0,Ad)local l if vI9Mah0 =='spotlight'then l=TYixjzX4:getSpotlights()elseif vI9Mah0 =='pointlight'then l=TYixjzX4:getPointLights()end
TYixjzX4:startHistoryRecord(l)for LwNRuJvR,nohO9Ia in pairs(l)do nohO9Ia.Brightness=Ad end TYixjzX4:finishHistoryRecord()end Tools.Lighting.changeRange=function(FDJ,u,v)local i0iuEsi if u=='spotlight'then i0iuEsi=FDJ:getSpotlights()elseif u=='pointlight'then i0iuEsi=FDJ:getPointLights()end
FDJ:startHistoryRecord(i0iuEsi)for qWrjc,y2zVVi in pairs(i0iuEsi)do y2zVVi.Range=v end
FDJ:finishHistoryRecord()end Tools.Lighting.changeShadows=function(mQIVEP5,QV4HoK0r,uqoP)local fXnJ2kO if QV4HoK0r=='spotlight'then fXnJ2kO=mQIVEP5:getSpotlights()elseif QV4HoK0r=='pointlight'then fXnJ2kO=mQIVEP5:getPointLights()end
mQIVEP5:startHistoryRecord(fXnJ2kO)for mHD8,L in pairs(fXnJ2kO)do L.Shadows=uqoP end
mQIVEP5:finishHistoryRecord()end Tools.Lighting.addLight=function(tlNupYZ,VY6SD) local ydb={apply=function(tlNupYZ)Selection:clear() for ElVn76,yAEULfS in pairs(tlNupYZ.lights)do yAEULfS.Parent=tlNupYZ.light_parents[yAEULfS]Selection:add(yAEULfS.Parent)end end,unapply=function(tlNupYZ) Selection:clear()for O6Ft6oPX,RWubfxqF in pairs(tlNupYZ.lights)do Selection:add(RWubfxqF.Parent)RWubfxqF.Parent=nil end end}local O={}local _={} for E,e0kpxJ in pairs(Selection.Items)do local VXZfG=Support.GetChildOfClass(e0kpxJ,VY6SD) if not VXZfG then local VXZfG=RbxUtility.Create(VY6SD){Parent=e0kpxJ}table.insert(O,VXZfG)_[VXZfG]=e0kpxJ end end
ydb.lights=O
ydb.light_parents=_
History:add(ydb)end Tools.Lighting.removeLight=function(Bd,Qf) local p2jTk={apply=function(Bd)Selection:clear()for IR7v,_SmNfMoD in pairs(Bd.lights)do Selection:add(_SmNfMoD.Parent)_SmNfMoD.Parent=nil end end,unapply=function(Bd) Selection:clear()for g5wBR,z0SIbm in pairs(Bd.lights)do z0SIbm.Parent=Bd.light_parents[z0SIbm] Selection:add(z0SIbm.Parent)end end}local _5Pf={}local vHVSWs9={}local _5Pf if Qf=='spotlight'then _5Pf=Bd:getSpotlights()elseif Qf=='pointlight'then _5Pf=Bd:getPointLights()end for zL,nWzKrVe in pairs(_5Pf)do vHVSWs9[nWzKrVe]=nWzKrVe.Parent
nWzKrVe.Parent=nil end
p2jTk.lights=_5Pf
p2jTk.light_parents=vHVSWs9 History:add(p2jTk)end Tools.Lighting.startHistoryRecord=function(zha,yBtE)if zha.State.HistoryRecord then zha.State.HistoryRecord=nil end zha.State.HistoryRecord={targets=Support.CloneTable(yBtE),initial_color={},terminal_color={},initial_brightness={},terminal_brightness={},initial_range={},terminal_range={},initial_shadows={},terminal_shadows={},initial_side={},terminal_side={},initial_angle={},terminal_angle={},unapply=function(zha) Selection:clear() for GlmZIM,bm in pairs(zha.targets)do if bm then Selection:add(bm.Parent) bm.Color=zha.initial_color[bm]bm.Brightness=zha.initial_brightness[bm] bm.Range=zha.initial_range[bm]bm.Shadows=zha.initial_shadows[bm] if bm:IsA('SpotLight')then bm.Face=zha.initial_side[bm]bm.Angle=zha.initial_angle[bm]end end end end,apply=function(zha) Selection:clear() for ken,gHpr in pairs(zha.targets)do if gHpr then Selection:add(gHpr.Parent) gHpr.Color=zha.terminal_color[gHpr]gHpr.Brightness=zha.terminal_brightness[gHpr] gHpr.Range=zha.terminal_range[gHpr]gHpr.Shadows=zha.terminal_shadows[gHpr]if gHpr:IsA('SpotLight')then gHpr.Face=zha.terminal_side[gHpr] gHpr.Angle=zha.terminal_angle[gHpr]end end end end} for wL,uXW in pairs(zha.State.HistoryRecord.targets)do if uXW then zha.State.HistoryRecord.initial_color[uXW]=uXW.Color zha.State.HistoryRecord.initial_brightness[uXW]=uXW.Brightness zha.State.HistoryRecord.initial_range[uXW]=uXW.Range zha.State.HistoryRecord.initial_shadows[uXW]=uXW.Shadows
if uXW:IsA('SpotLight')then zha.State.HistoryRecord.initial_side[uXW]=uXW.Face zha.State.HistoryRecord.initial_angle[uXW]=uXW.Angle end end end end Tools.Lighting.finishHistoryRecord=function(f1Guph) if not f1Guph.State.HistoryRecord then return end for VoIe2R,wULNB in pairs(f1Guph.State.HistoryRecord.targets)do if wULNB then f1Guph.State.HistoryRecord.terminal_color[wULNB]=wULNB.Color f1Guph.State.HistoryRecord.terminal_brightness[wULNB]=wULNB.Brightness f1Guph.State.HistoryRecord.terminal_range[wULNB]=wULNB.Range f1Guph.State.HistoryRecord.terminal_shadows[wULNB]=wULNB.Shadows if wULNB:IsA('SpotLight')then f1Guph.State.HistoryRecord.terminal_side[wULNB]=wULNB.Face f1Guph.State.HistoryRecord.terminal_angle[wULNB]=wULNB.Angle end end end
History:add(f1Guph.State.HistoryRecord)f1Guph.State.HistoryRecord= nil end Tools.Lighting.hideGUI=function(Uin1c) if Uin1c.GUI then Uin1c.GUI.Visible=false end end
Tools.Lighting.Loaded=true end},{"Decorate",function() repeat wait()until(_G.BTCoreEnv and _G.BTCoreEnv["tool"]and _G.BTCoreEnv["tool"].CoreReady)setfenv(1,_G.BTCoreEnv["tool"])Tools.Decorate={} Tools.Decorate.Color=BrickColor.new("Really black")Tools.Decorate.State={}Tools.Decorate.Connections={} Tools.Decorate.Listeners={} Tools.Decorate.Listeners.Equipped=function()local uZOynu=Tools.Decorate uZOynu.State.PreviousSelectionBoxColor=SelectionBoxColor
SelectionBoxColor=uZOynu.Color
updateSelectionBoxColor() uZOynu:showGUI() coroutine.wrap(function()updater_on=true uZOynu.Updater=function()updater_on=false end
while wait(0.1)and updater_on do if CurrentTool==uZOynu then if uZOynu.GUI and uZOynu.GUI.Visible then uZOynu:updateGUI()end end end end)()end Tools.Decorate.Listeners.Unequipped=function()local XYjab=Tools.Decorate
if XYjab.Updater then XYjab.Updater()XYjab.Updater=nil end
XYjab:hideGUI() for g226Ed,iKS in pairs(XYjab.Connections)do iKS:disconnect()XYjab.Connections[g226Ed]=nil end
SelectionBoxColor=XYjab.State.PreviousSelectionBoxColor updateSelectionBoxColor()end Tools.Decorate.updateGUI=function(vKlf)if not vKlf.GUI then return end if #Selection.Items>0 then local SlWsaU=vKlf:getSmoke()local Mj=vKlf:getFire() local c_=vKlf:getSparkles()local Kw4ta8iS,AlV6,LtS,TaJ2US,Ghp0,opR
local sif2,PGiQADW,PI,dZc,iebKJjA,d,CaFSQRf,vn3NH
local JFZ,L,j_st9 for Ubiy,mIV in pairs(SlWsaU)do if Ubiy==1 then Kw4ta8iS,AlV6,LtS=mIV.Color.r,mIV.Color.g,mIV.Color.b
TaJ2US=mIV.Opacity
Ghp0=mIV.RiseVelocity
opR=mIV.Size else if Kw4ta8iS~=mIV.Color.r then Kw4ta8iS=nil end if AlV6 ~=mIV.Color.g then AlV6=nil end
if LtS~=mIV.Color.b then LtS=nil end if TaJ2US~=mIV.Opacity then TaJ2US=nil end
if Ghp0 ~=mIV.RiseVelocity then Ghp0=nil end if opR~=mIV.Size then opR=nil end end end for hgRaw,vvwRldj in pairs(Mj)do if hgRaw==1 then sif2,PGiQADW,PI=vvwRldj.Color.r,vvwRldj.Color.g,vvwRldj.Color.b dZc,iebKJjA,d=vvwRldj.SecondaryColor.r,vvwRldj.SecondaryColor.g,vvwRldj.SecondaryColor.b
CaFSQRf=vvwRldj.Heat
vn3NH=vvwRldj.Size else if sif2 ~=vvwRldj.Color.r then sif2= nil end if PGiQADW~=vvwRldj.Color.g then PGiQADW=nil end
if PI~=vvwRldj.Color.b then PI=nil end
if dZc~= vvwRldj.SecondaryColor.r then dZc=nil end
if iebKJjA~= vvwRldj.SecondaryColor.g then iebKJjA=nil end
if d~= vvwRldj.SecondaryColor.b then d=nil end
if CaFSQRf~=vvwRldj.Heat then CaFSQRf=nil end
if vn3NH~=vvwRldj.Size then vn3NH=nil end end end for f_7I8Jo,K072gC9 in pairs(c_)do if f_7I8Jo==1 then JFZ,L,j_st9=K072gC9.SparkleColor.r,K072gC9.SparkleColor.g,K072gC9.SparkleColor.b else if JFZ~=K072gC9.SparkleColor.r then JFZ=nil end
if L~= K072gC9.SparkleColor.g then L=nil end
if j_st9 ~=K072gC9.SparkleColor.b then j_st9=nil end end end vKlf.State.smoke_color=(Kw4ta8iS and AlV6 and LtS)and Color3.new(Kw4ta8iS,AlV6,LtS)or nil vKlf.State.fire_color=(sif2 and PGiQADW and PI)and Color3.new(sif2,PGiQADW,PI)or nil vKlf.State.fire_2nd_color=(dZc and iebKJjA and d)and Color3.new(dZc,iebKJjA,d)or nil
vKlf.State.sparkles_color= (JFZ and L and j_st9)and Color3.new(JFZ,L,j_st9)or nil if not vKlf.State.smoke_color_r_focused then vKlf.GUI.Smoke.Options.ColorOption.RInput.TextBox.Text= Kw4ta8iS and Support.Round(Kw4ta8iS*255,0)or'*'end
if not vKlf.State.smoke_color_g_focused then vKlf.GUI.Smoke.Options.ColorOption.GInput.TextBox.Text= AlV6 and Support.Round(AlV6*255,0)or'*'end
if not vKlf.State.smoke_color_b_focused then vKlf.GUI.Smoke.Options.ColorOption.BInput.TextBox.Text= LtS and Support.Round(LtS*255,0)or'*'end
if not vKlf.State.smoke_opacity_focused then vKlf.GUI.Smoke.Options.OpacityOption.Input.TextBox.Text= TaJ2US and Support.Round(TaJ2US,2)or'*'end
if not vKlf.State.smoke_velocity_focused then vKlf.GUI.Smoke.Options.VelocityOption.Input.TextBox.Text= Ghp0 and Support.Round(Ghp0,2)or'*'end
if not vKlf.State.smoke_size_focused then vKlf.GUI.Smoke.Options.SizeOption.Input.TextBox.Text= opR and Support.Round(opR,2)or'*'end
if not vKlf.State.fire_color_r_focused then vKlf.GUI.Fire.Options.ColorOption.RInput.TextBox.Text= sif2 and Support.Round(sif2*255,0)or'*'end
if not vKlf.State.fire_color_g_focused then vKlf.GUI.Fire.Options.ColorOption.GInput.TextBox.Text= PGiQADW and Support.Round(PGiQADW*255,0)or'*'end
if not vKlf.State.fire_color_b_focused then vKlf.GUI.Fire.Options.ColorOption.BInput.TextBox.Text= PI and Support.Round(PI*255,0)or'*'end
if not vKlf.State.fire_2nd_color_r_focused then vKlf.GUI.Fire.Options.SecondColorOption.RInput.TextBox.Text= dZc and Support.Round(dZc*255,0)or'*'end if not vKlf.State.fire_2nd_color_g_focused then vKlf.GUI.Fire.Options.SecondColorOption.GInput.TextBox.Text= iebKJjA and Support.Round(iebKJjA*255,0)or'*'end
if not vKlf.State.fire_2nd_color_b_focused then vKlf.GUI.Fire.Options.SecondColorOption.BInput.TextBox.Text= d and Support.Round(d*255,0)or'*'end
if not vKlf.State.fire_heat_focused then vKlf.GUI.Fire.Options.HeatOption.Input.TextBox.Text= CaFSQRf and Support.Round(CaFSQRf,2)or'*'end
if not vKlf.State.fire_size_focused then vKlf.GUI.Fire.Options.SizeOption.Input.TextBox.Text= vn3NH and Support.Round(vn3NH,2)or'*'end
if not vKlf.State.sparkles_color_r_focused then vKlf.GUI.Sparkles.Options.ColorOption.RInput.TextBox.Text= JFZ and Support.Round(JFZ*255,0)or'*'end
if not vKlf.State.sparkles_color_g_focused then vKlf.GUI.Sparkles.Options.ColorOption.GInput.TextBox.Text= L and Support.Round(L*255,0)or'*'end if not vKlf.State.sparkles_color_b_focused then vKlf.GUI.Sparkles.Options.ColorOption.BInput.TextBox.Text= j_st9 and Support.Round(j_st9*255,0)or'*'end if vKlf.GUI.SelectNote.Visible then vKlf:closeSmoke() vKlf:closeFire()vKlf:closeSparkles()end
vKlf.GUI.Smoke.Visible=true vKlf.GUI.Fire.Visible=true
vKlf.GUI.Sparkles.Visible=true vKlf.GUI.SelectNote.Visible=false if  not vKlf.State.smoke_open and not vKlf.State.fire_open and not vKlf.State.sparkles_open then vKlf.GUI:TweenSize(UDim2.new(0,200,0,125),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end if#SlWsaU==0 then vKlf.GUI.Smoke.Options.Size=UDim2.new(1,-3,0,0)vKlf.GUI.Smoke.AddButton.Visible=true vKlf.GUI.Smoke.RemoveButton.Visible=false
if vKlf.State.smoke_open then vKlf:closeSmoke()end elseif #SlWsaU~=#Selection.Items then vKlf.GUI.Smoke.AddButton.Visible=true vKlf.GUI.Smoke.RemoveButton.Position=UDim2.new(0,90,0,3)vKlf.GUI.Smoke.RemoveButton.Visible=true elseif#SlWsaU==# Selection.Items then vKlf.GUI.Smoke.AddButton.Visible=false vKlf.GUI.Smoke.RemoveButton.Position=UDim2.new(0,127,0,3)vKlf.GUI.Smoke.RemoveButton.Visible=true
if vKlf.GUI.Smoke.Size==UDim2.new(0,200,0,52)then vKlf.GUI.Smoke.Size=UDim2.new(0,200,0,125)end end if#Mj==0 then vKlf.GUI.Fire.Options.Size=UDim2.new(1,-3,0,0)vKlf.GUI.Fire.AddButton.Visible=true vKlf.GUI.Fire.RemoveButton.Visible=false
if vKlf.State.fire_open then vKlf:closeFire()end elseif#Mj~=# Selection.Items then vKlf.GUI.Fire.AddButton.Visible=true vKlf.GUI.Fire.RemoveButton.Position=UDim2.new(0,90,0,3)vKlf.GUI.Fire.RemoveButton.Visible=true elseif#Mj==# Selection.Items then vKlf.GUI.Fire.AddButton.Visible=false vKlf.GUI.Fire.RemoveButton.Position=UDim2.new(0,127,0,3)vKlf.GUI.Fire.RemoveButton.Visible=true end if#c_==0 then vKlf.GUI.Sparkles.Options.Size=UDim2.new(1,-3,0,0)vKlf.GUI.Sparkles.AddButton.Visible=true vKlf.GUI.Sparkles.RemoveButton.Visible=false if vKlf.State.sparkles_open then vKlf:closeSparkles()end elseif#c_~=#Selection.Items then vKlf.GUI.Sparkles.AddButton.Visible=true vKlf.GUI.Sparkles.RemoveButton.Position=UDim2.new(0,90,0,3)vKlf.GUI.Sparkles.RemoveButton.Visible=true elseif#c_==# Selection.Items then vKlf.GUI.Sparkles.AddButton.Visible=false vKlf.GUI.Sparkles.RemoveButton.Position=UDim2.new(0,127,0,3)vKlf.GUI.Sparkles.RemoveButton.Visible=true end else vKlf.GUI.Smoke.Visible=false vKlf.GUI.Fire.Visible=false
vKlf.GUI.Sparkles.Visible=false vKlf.GUI.SelectNote.Visible=true
vKlf.GUI.Size=UDim2.new(0,200,0,52)end end Tools.Decorate.openSmoke=function(SbuPM)SbuPM.State.smoke_open=true SbuPM:closeFire()SbuPM:closeSparkles() SbuPM.GUI.Smoke.Options:TweenSize(UDim2.new(1, -3,0,110),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) SbuPM.GUI.Smoke:TweenPosition(UDim2.new(0,10,0,30),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) SbuPM.GUI:TweenSize(UDim2.new(0,200,0,235),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end Tools.Decorate.openFire=function(cobaoFK)cobaoFK.State.fire_open=true cobaoFK:closeSmoke()cobaoFK:closeSparkles() cobaoFK.GUI.Fire.Options:TweenSize(UDim2.new(1, -3,0,110),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) cobaoFK.GUI.Fire:TweenPosition(UDim2.new(0,10,0,60),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) cobaoFK.GUI:TweenSize(UDim2.new(0,200,0,235),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end Tools.Decorate.openSparkles=function(JbhOvI)JbhOvI.State.sparkles_open=true JbhOvI:closeSmoke()JbhOvI:closeFire() JbhOvI.GUI.Sparkles.Options:TweenSize(UDim2.new(1, -3,0,40),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) JbhOvI.GUI.Sparkles:TweenPosition(UDim2.new(0,10,0,90),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) JbhOvI.GUI:TweenSize(UDim2.new(0,200,0,160),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end Tools.Decorate.closeSmoke=function(yA)yA.State.smoke_open=false yA.GUI.Smoke.Options:TweenSize(UDim2.new(1, -3,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) yA.GUI.Fire:TweenPosition(UDim2.new(0,10,0,60),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)if not yA.State.fire_open then yA.GUI.Sparkles:TweenPosition(UDim2.new(0,10,0,90),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end if not yA.State.fire_open and not yA.State.sparkles_open then yA.GUI:TweenSize(UDim2.new(0,200,0,125),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end end Tools.Decorate.closeFire=function(NUsjSgB)NUsjSgB.State.fire_open=false if NUsjSgB.State.smoke_open then NUsjSgB.GUI.Fire:TweenPosition(UDim2.new(0,10,0,170),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)else NUsjSgB.GUI.Fire:TweenPosition(UDim2.new(0,10,0,60),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end NUsjSgB.GUI.Fire.Options:TweenSize(UDim2.new(1,-3,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) if not NUsjSgB.State.smoke_open then NUsjSgB.GUI.Sparkles:TweenPosition(UDim2.new(0,10,0,90),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end if not NUsjSgB.State.smoke_open and not NUsjSgB.State.sparkles_open then NUsjSgB.GUI:TweenSize(UDim2.new(0,200,0,125),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end end Tools.Decorate.closeSparkles=function(Xuvxfbm)Xuvxfbm.State.sparkles_open=false if Xuvxfbm.State.smoke_open or Xuvxfbm.State.fire_open then Xuvxfbm.GUI.Sparkles:TweenPosition(UDim2.new(0,10,0,200),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)else Xuvxfbm.GUI.Sparkles:TweenPosition(UDim2.new(0,10,0,90),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end Xuvxfbm.GUI.Sparkles.Options:TweenSize(UDim2.new(1,-3,0,0),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true) if not Xuvxfbm.State.smoke_open and not Xuvxfbm.State.fire_open then Xuvxfbm.GUI:TweenSize(UDim2.new(0,200,0,125),Enum.EasingDirection.Out,Enum.EasingStyle.Quad,0.5,true)end end Tools.Decorate.showGUI=function(tY) if not tY.GUI then local l1YAdT2c=DFb100j.BTDecorateToolGUI:Clone()l1YAdT2c.Parent=UI l1YAdT2c.Smoke.ArrowButton.MouseButton1Up:connect(function() if  not tY.State.smoke_open and#tY:getSmoke()>0 then tY:openSmoke()else tY:closeSmoke()end end) l1YAdT2c.Fire.ArrowButton.MouseButton1Up:connect(function()if not tY.State.fire_open and#tY:getFire()>0 then tY:openFire()else tY:closeFire()end end) l1YAdT2c.Sparkles.ArrowButton.MouseButton1Up:connect(function() if not tY.State.sparkles_open and#tY:getSparkles()>0 then tY:openSparkles()else tY:closeSparkles()end end) l1YAdT2c.Smoke.AddButton.MouseButton1Up:connect(function() tY:addSmoke()tY:openSmoke()end) l1YAdT2c.Fire.AddButton.MouseButton1Up:connect(function() tY:addFire()tY:openFire()end) l1YAdT2c.Sparkles.AddButton.MouseButton1Up:connect(function() tY:addSparkles()tY:openSparkles()end) l1YAdT2c.Smoke.RemoveButton.MouseButton1Up:connect(function() tY:removeSmoke()tY:closeSmoke()end) l1YAdT2c.Fire.RemoveButton.MouseButton1Up:connect(function() tY:removeFire()tY:closeFire()end) l1YAdT2c.Sparkles.RemoveButton.MouseButton1Up:connect(function() tY:removeSparkles()tY:closeSparkles()end)local A1A=l1YAdT2c.Smoke
local PMB1UGv=A1A.Options.ColorOption PMB1UGv.RInput.TextButton.MouseButton1Down:connect(function() tY.State.smoke_color_r_focused=true PMB1UGv.RInput.TextBox:CaptureFocus()end) PMB1UGv.RInput.TextBox.FocusLost:connect(function(_MI) local TITR=tonumber(PMB1UGv.RInput.TextBox.Text)if TITR then if TITR>255 then TITR=255 elseif TITR<0 then TITR=0 end tY:changeSmokeColor('r',TITR/255)end tY.State.smoke_color_r_focused=false end) PMB1UGv.GInput.TextButton.MouseButton1Down:connect(function() tY.State.smoke_color_g_focused=true PMB1UGv.GInput.TextBox:CaptureFocus()end) PMB1UGv.GInput.TextBox.FocusLost:connect(function(i_aIFe) local YFJRo6=tonumber(PMB1UGv.GInput.TextBox.Text) if YFJRo6 then if YFJRo6 >255 then YFJRo6=255 elseif YFJRo6 <0 then YFJRo6=0 end
tY:changeSmokeColor('g', YFJRo6/255)end
tY.State.smoke_color_g_focused=false end) PMB1UGv.BInput.TextButton.MouseButton1Down:connect(function() tY.State.smoke_color_b_focused=true PMB1UGv.BInput.TextBox:CaptureFocus()end) PMB1UGv.BInput.TextBox.FocusLost:connect(function(V3EcTFrW) local zJbXZu2D=tonumber(PMB1UGv.BInput.TextBox.Text) if zJbXZu2D then if zJbXZu2D>255 then zJbXZu2D=255 elseif zJbXZu2D<0 then zJbXZu2D=0 end
tY:changeSmokeColor('b',zJbXZu2D/255)end
tY.State.smoke_color_b_focused=false end) PMB1UGv.HSVPicker.MouseButton1Up:connect(function() ColorPicker:start(function(...)local drq={...}if #drq==3 then tY:changeSmokeColor(Support.HSVToRGB(...))end end,tY.State.smoke_color)end)local TicLenZ=A1A.Options.OpacityOption.Input TicLenZ.TextButton.MouseButton1Down:connect(function() tY.State.smoke_opacity_focused=true
TicLenZ.TextBox:CaptureFocus()end) TicLenZ.TextBox.FocusLost:connect(function(ezkF) local dlHohKjZ=tonumber(TicLenZ.TextBox.Text) if dlHohKjZ then if dlHohKjZ>1 then dlHohKjZ=1 elseif dlHohKjZ<0 then dlHohKjZ=0 end
tY:changeSmokeOpacity(dlHohKjZ)end
tY.State.smoke_opacity_focused=false end)local Xc=A1A.Options.VelocityOption.Input Xc.TextButton.MouseButton1Down:connect(function() tY.State.smoke_velocity_focused=true
Xc.TextBox:CaptureFocus()end) Xc.TextBox.FocusLost:connect(function(QI) local fI=tonumber(Xc.TextBox.Text)if fI then if fI>25 then fI=25 elseif fI<-25 then fI=-25 end tY:changeSmokeVelocity(fI)end tY.State.smoke_velocity_focused=false end)local onx=A1A.Options.SizeOption.Input onx.TextButton.MouseButton1Down:connect(function() tY.State.smoke_size_focused=true
onx.TextBox:CaptureFocus()end) onx.TextBox.FocusLost:connect(function(In) local u=tonumber(onx.TextBox.Text) if u then if u>100 then u=100 elseif u<0.1 then u=0.1 end
tY:changeSmokeSize(u)end
tY.State.smoke_size_focused=false end)local z=l1YAdT2c.Fire
local hHo=z.Options.ColorOption hHo.RInput.TextButton.MouseButton1Down:connect(function() tY.State.fire_color_r_focused=true
hHo.RInput.TextBox:CaptureFocus()end) hHo.RInput.TextBox.FocusLost:connect(function(ygfhj) local fN=tonumber(hHo.RInput.TextBox.Text)if fN then if fN>255 then fN=255 elseif fN<0 then fN=0 end tY:changeFireColor('r',fN/255)end tY.State.fire_color_r_focused=false end) hHo.GInput.TextButton.MouseButton1Down:connect(function() tY.State.fire_color_g_focused=true
hHo.GInput.TextBox:CaptureFocus()end) hHo.GInput.TextBox.FocusLost:connect(function(ws8) local yDc8=tonumber(hHo.GInput.TextBox.Text)if yDc8 then if yDc8 >255 then yDc8=255 elseif yDc8 <0 then yDc8=0 end tY:changeFireColor('g',yDc8/255)end tY.State.fire_color_g_focused=false end) hHo.BInput.TextButton.MouseButton1Down:connect(function() tY.State.fire_color_b_focused=true
hHo.BInput.TextBox:CaptureFocus()end) hHo.BInput.TextBox.FocusLost:connect(function(d3g) local vZH=tonumber(hHo.BInput.TextBox.Text)if vZH then if vZH>255 then vZH=255 elseif vZH<0 then vZH=0 end tY:changeFireColor('b',vZH/255)end tY.State.fire_color_b_focused=false end) hHo.HSVPicker.MouseButton1Up:connect(function() ColorPicker:start(function(...)local RWqs={...}if#RWqs==3 then tY:changeFireColor(Support.HSVToRGB(...))end end,tY.State.fire_color)end)local fgqM6D=z.Options.SecondColorOption fgqM6D.RInput.TextButton.MouseButton1Down:connect(function() tY.State.fire_2nd_color_r_focused=true
fgqM6D.RInput.TextBox:CaptureFocus()end) fgqM6D.RInput.TextBox.FocusLost:connect(function(tn) local FKyVcS=tonumber(fgqM6D.RInput.TextBox.Text) if FKyVcS then if FKyVcS>255 then FKyVcS=255 elseif FKyVcS<0 then FKyVcS=0 end
tY:changeFireColor2('r', FKyVcS/255)end
tY.State.fire_2nd_color_r_focused=false end) fgqM6D.GInput.TextButton.MouseButton1Down:connect(function() tY.State.fire_2nd_color_g_focused=true
fgqM6D.GInput.TextBox:CaptureFocus()end) fgqM6D.GInput.TextBox.FocusLost:connect(function(zNfSeV) local HtbHbcu=tonumber(fgqM6D.GInput.TextBox.Text) if HtbHbcu then if HtbHbcu>255 then HtbHbcu=255 elseif HtbHbcu<0 then HtbHbcu=0 end
tY:changeFireColor2('g', HtbHbcu/255)end
tY.State.fire_2nd_color_g_focused=false end) fgqM6D.BInput.TextButton.MouseButton1Down:connect(function() tY.State.fire_2nd_color_b_focused=true
fgqM6D.BInput.TextBox:CaptureFocus()end) fgqM6D.BInput.TextBox.FocusLost:connect(function(MDLzj7) local RNIZJ=tonumber(fgqM6D.BInput.TextBox.Text) if RNIZJ then if RNIZJ>255 then RNIZJ=255 elseif RNIZJ<0 then RNIZJ=0 end
tY:changeFireColor2('b', RNIZJ/255)end
tY.State.fire_2nd_color_b_focused=false end) fgqM6D.HSVPicker.MouseButton1Up:connect(function() ColorPicker:start(function(...)local ma={...}if #ma==3 then tY:changeFireColor2(Support.HSVToRGB(...))end end,tY.State.fire_2nd_color)end)local KXz5=z.Options.HeatOption.Input KXz5.TextButton.MouseButton1Down:connect(function() tY.State.fire_heat_focused=true
KXz5.TextBox:CaptureFocus()end) KXz5.TextBox.FocusLost:connect(function(X_) local E_fkS=tonumber(KXz5.TextBox.Text)if E_fkS then if E_fkS>25 then E_fkS=25 elseif E_fkS<-25 then E_fkS=-25 end tY:changeFireHeat(E_fkS)end tY.State.fire_heat_focused=false end)local IxVqKpu=z.Options.SizeOption.Input IxVqKpu.TextButton.MouseButton1Down:connect(function() tY.State.fire_size_focused=true
IxVqKpu.TextBox:CaptureFocus()end) IxVqKpu.TextBox.FocusLost:connect(function(iv18CGzs) local TpEB=tonumber(IxVqKpu.TextBox.Text)if TpEB then if TpEB>30 then TpEB=30 elseif TpEB<2 then TpEB=2 end tY:changeFireSize(TpEB)end tY.State.fire_size_focused=false end)local B0cg08r_=l1YAdT2c.Sparkles
local GRkE=B0cg08r_.Options.ColorOption GRkE.RInput.TextButton.MouseButton1Down:connect(function() tY.State.sparkles_color_r_focused=true
GRkE.RInput.TextBox:CaptureFocus()end) GRkE.RInput.TextBox.FocusLost:connect(function(x) local yF1U=tonumber(GRkE.RInput.TextBox.Text)if yF1U then if yF1U>255 then yF1U=255 elseif yF1U<0 then yF1U=0 end tY:changeSparklesColor('r',yF1U/255)end tY.State.sparkles_color_r_focused=false end) GRkE.GInput.TextButton.MouseButton1Down:connect(function() tY.State.sparkles_color_g_focused=true
GRkE.GInput.TextBox:CaptureFocus()end) GRkE.GInput.TextBox.FocusLost:connect(function(JE6a4s) local sloRQ=tonumber(GRkE.GInput.TextBox.Text) if sloRQ then if sloRQ>255 then sloRQ=255 elseif sloRQ<0 then sloRQ=0 end
tY:changeSparklesColor('g', sloRQ/255)end
tY.State.sparkles_color_g_focused=false end) GRkE.BInput.TextButton.MouseButton1Down:connect(function() tY.State.sparkles_color_b_focused=true
GRkE.BInput.TextBox:CaptureFocus()end) GRkE.BInput.TextBox.FocusLost:connect(function(mJ2) local P=tonumber(GRkE.BInput.TextBox.Text)if P then if P>255 then P=255 elseif P<0 then P=0 end tY:changeSparklesColor('b',P/255)end tY.State.sparkles_color_b_focused=false end) GRkE.HSVPicker.MouseButton1Up:connect(function() ColorPicker:start(function(...)local Ge={...}if#Ge==3 then tY:changeSparklesColor(Support.HSVToRGB(...))end end,tY.State.sparkles_color)end)tY.GUI=l1YAdT2c end
tY.GUI.Visible=true end Tools.Decorate.changeSmokeOpacity=function(tYF,jzn73)local vQTwJ6V1=tYF:getSmoke() tYF:startHistoryRecord(vQTwJ6V1)for Knf7U,I0 in pairs(vQTwJ6V1)do I0.Opacity=jzn73 end tYF:finishHistoryRecord()end Tools.Decorate.changeSmokeVelocity=function(jFyAt,LyJxC)local E=jFyAt:getSmoke() jFyAt:startHistoryRecord(E)for vnC8kIGX,dnKfz in pairs(E)do dnKfz.RiseVelocity=LyJxC end jFyAt:finishHistoryRecord()end Tools.Decorate.changeSmokeSize=function(kDt,QLp)local IXNl=kDt:getSmoke() kDt:startHistoryRecord(IXNl)for oqPG,Pa in pairs(IXNl)do Pa.Size=QLp end kDt:finishHistoryRecord()end Tools.Decorate.changeFireHeat=function(j37n1ZA,aLxQ)local GW=j37n1ZA:getFire() j37n1ZA:startHistoryRecord(GW)for AzhdvccS,J in pairs(GW)do J.Heat=aLxQ end j37n1ZA:finishHistoryRecord()end Tools.Decorate.changeFireSize=function(PYFFxAp,i)local AP1UcfB=PYFFxAp:getFire() PYFFxAp:startHistoryRecord(AP1UcfB)for e,H4 in pairs(AP1UcfB)do H4.Size=i end PYFFxAp:finishHistoryRecord()end Tools.Decorate.getSmoke=function(CMIGYkL8)local n9FOtM={} for K,EeAZn in pairs(Selection.Items)do local aCKog=Support.GetChildOfClass(EeAZn,'Smoke')if aCKog then table.insert(n9FOtM,aCKog)end end
return n9FOtM end Tools.Decorate.getFire=function(c)local OWrvY={} for lp2,k in pairs(Selection.Items)do local sEjUvkV=Support.GetChildOfClass(k,'Fire')if sEjUvkV then table.insert(OWrvY,sEjUvkV)end end
return OWrvY end Tools.Decorate.getSparkles=function(pnOWD9)local iRm2={} for J61iBvjC,_ in pairs(Selection.Items)do local X79LkbfD=Support.GetChildOfClass(_,'Sparkles')if X79LkbfD then table.insert(iRm2,X79LkbfD)end end
return iRm2 end Tools.Decorate.changeSmokeColor=function(JNRj6X,...)local ldz480={...}local rE=JNRj6X:getSmoke() JNRj6X:startHistoryRecord(rE) if#ldz480 ==2 then local f7eR2T=ldz480[1]local l=ldz480[2] for XZ3A,Czs0f in pairs(rE)do Czs0f.Color=Color3.new(f7eR2T== 'r'and l or Czs0f.Color.r,f7eR2T=='g'and l or Czs0f.Color.g,f7eR2T=='b'and l or Czs0f.Color.b)end elseif#ldz480 ==3 then local aMvb,_QG,CWG=...for z1q,YkD6SuyP in pairs(rE)do YkD6SuyP.Color=Color3.new(aMvb,_QG,CWG)end end
JNRj6X:finishHistoryRecord()end Tools.Decorate.changeFireColor=function(GW3xWh,...)local eA_ohY={...}local b5p2AMKP=GW3xWh:getFire() GW3xWh:startHistoryRecord(b5p2AMKP) if#eA_ohY==2 then local m=eA_ohY[1]local Xve=eA_ohY[2]for Hk0hzj,Mfs in pairs(b5p2AMKP)do Mfs.Color=Color3.new(m== 'r'and Xve or Mfs.Color.r,m=='g'and Xve or Mfs.Color.g, m=='b'and Xve or Mfs.Color.b)end elseif# eA_ohY==3 then local JqnndWc,l5T8J5g1,RhLeG=...for tOSI20,n in pairs(b5p2AMKP)do n.Color=Color3.new(JqnndWc,l5T8J5g1,RhLeG)end end
GW3xWh:finishHistoryRecord()end Tools.Decorate.changeFireColor2=function(mZcPQEV,...)local O_oVTYL={...}local PGzKhtPH=mZcPQEV:getFire() mZcPQEV:startHistoryRecord(PGzKhtPH) if#O_oVTYL==2 then local wI3DS0Kh=O_oVTYL[1]local CwTDNbR=O_oVTYL[2] for A,JfSij6_ in pairs(PGzKhtPH)do JfSij6_.SecondaryColor=Color3.new( wI3DS0Kh=='r'and CwTDNbR or JfSij6_.Color.r, wI3DS0Kh=='g'and CwTDNbR or JfSij6_.Color.g, wI3DS0Kh=='b'and CwTDNbR or JfSij6_.Color.b)end elseif#O_oVTYL==3 then local Lr,NXu695,lzWnF=...for sNe6_x,fBLoB6JH in pairs(PGzKhtPH)do fBLoB6JH.SecondaryColor=Color3.new(Lr,NXu695,lzWnF)end end
mZcPQEV:finishHistoryRecord()end Tools.Decorate.changeSparklesColor=function(z6gv,...)local ZZ93rHc0={...}local j_V=z6gv:getSparkles() z6gv:startHistoryRecord(j_V) if#ZZ93rHc0 ==2 then local I_=ZZ93rHc0[1]local yPn=ZZ93rHc0[2] for LsT,E in pairs(j_V)do E.SparkleColor=Color3.new( I_=='r'and yPn or E.SparkleColor.r,I_=='g'and yPn or E.SparkleColor.g,I_=='b'and yPn or E.SparkleColor.b)end elseif#ZZ93rHc0 ==3 then local dOD2G,jhOfPSgm,eri=...for uaTR,JDs76MG in pairs(j_V)do JDs76MG.SparkleColor=Color3.new(dOD2G,jhOfPSgm,eri)end end
z6gv:finishHistoryRecord()end Tools.Decorate.addSmoke=function(aDZVav) local sRoTvf={apply=function(aDZVav)Selection:clear() for cUR,p in pairs(aDZVav.smoke)do p.Parent=aDZVav.smoke_parents[p]Selection:add(p.Parent)end end,unapply=function(aDZVav) Selection:clear() for kKdY4XaA,d in pairs(aDZVav.smoke)do Selection:add(d.Parent)d.Parent=nil end end}local R1TLssk={}local H={} for sPM6lF,Qp_1 in pairs(Selection.Items)do local q1YAR=Support.GetChildOfClass(Qp_1,'Smoke') if not q1YAR then local q1YAR=RbxUtility.Create('Smoke'){Parent=Qp_1}table.insert(R1TLssk,q1YAR)H[q1YAR]=Qp_1 end end
sRoTvf.smoke=R1TLssk
sRoTvf.smoke_parents=H History:add(sRoTvf)end Tools.Decorate.removeSmoke=function(kg) local bijI={apply=function(kg)Selection:clear()for NhucT,SZMbpM in pairs(kg.smoke)do Selection:add(SZMbpM.Parent)SZMbpM.Parent=nil end end,unapply=function(kg) Selection:clear()for aTkVS,eBp38EEt in pairs(kg.smoke)do eBp38EEt.Parent=kg.smoke_parents[eBp38EEt] Selection:add(eBp38EEt.Parent)end end}local K=kg:getSmoke()local lCr41We={}for U8NHKEk,yf0 in pairs(K)do lCr41We[yf0]=yf0.Parent yf0.Parent=nil end
bijI.smoke=K bijI.smoke_parents=lCr41We
History:add(bijI)end Tools.Decorate.addFire=function(skphQH) local ioxmHxH={apply=function(skphQH)Selection:clear() for e09Nk,ifI_m2 in pairs(skphQH.fire)do ifI_m2.Parent=skphQH.fire_parents[ifI_m2]Selection:add(ifI_m2.Parent)end end,unapply=function(skphQH) Selection:clear()for QSX2,L1dTNDQb in pairs(skphQH.fire)do Selection:add(L1dTNDQb.Parent)L1dTNDQb.Parent= nil end end}local YGhYv64={}local i={} for eMzb,J0KiSt in pairs(Selection.Items)do local pXdVoc=Support.GetChildOfClass(J0KiSt,'Fire') if not pXdVoc then local pXdVoc=RbxUtility.Create('Fire'){Parent=J0KiSt}table.insert(YGhYv64,pXdVoc)i[pXdVoc]=J0KiSt end end
ioxmHxH.fire=YGhYv64
ioxmHxH.fire_parents=i History:add(ioxmHxH)end Tools.Decorate.removeFire=function(xme) local kAbF={apply=function(xme)Selection:clear()for sqZtSeO,K4W6 in pairs(xme.fire)do Selection:add(K4W6.Parent)K4W6.Parent=nil end end,unapply=function(xme) Selection:clear()for R4qp7,_F71WhJ in pairs(xme.fire)do _F71WhJ.Parent=xme.fire_parents[_F71WhJ] Selection:add(_F71WhJ.Parent)end end}local h=xme:getFire()local GtezA0={}for YciJj,CZ2Wt in pairs(h)do GtezA0[CZ2Wt]=CZ2Wt.Parent
CZ2Wt.Parent= nil end
kAbF.fire=h kAbF.fire_parents=GtezA0
History:add(kAbF)end Tools.Decorate.addSparkles=function(rp3QaP) local Anqa={apply=function(rp3QaP)Selection:clear()for C,wM4R in pairs(rp3QaP.sparkles)do wM4R.Parent=rp3QaP.sparkles_parents[wM4R] Selection:add(wM4R.Parent)end end,unapply=function(rp3QaP) Selection:clear()for sHOVr,v4D in pairs(rp3QaP.sparkles)do Selection:add(v4D.Parent) v4D.Parent=nil end end}local sDak1ecL={}local r={} for KBI_GdWx,XcV in pairs(Selection.Items)do local yq_h4JT=Support.GetChildOfClass(XcV,'Sparkles') if not yq_h4JT then local yq_h4JT=RbxUtility.Create('Sparkles'){Parent=XcV,SparkleColor=Color3.new(1,0,0)}table.insert(sDak1ecL,yq_h4JT)r[yq_h4JT]=XcV end end
Anqa.sparkles=sDak1ecL
Anqa.sparkles_parents=r History:add(Anqa)end Tools.Decorate.removeSparkles=function(Dde) local RIc={apply=function(Dde)Selection:clear()for _neQ47D,scY in pairs(Dde.sparkles)do Selection:add(scY.Parent)scY.Parent=nil end end,unapply=function(Dde) Selection:clear()for H42,JLx in pairs(Dde.sparkles)do JLx.Parent=Dde.sparkles_parents[JLx] Selection:add(JLx.Parent)end end}local WL7T8_G=Dde:getSparkles()local DN={}for vDPis1Y,pEV in pairs(WL7T8_G)do DN[pEV]=pEV.Parent
pEV.Parent= nil end
RIc.sparkles=WL7T8_G RIc.sparkles_parents=DN
History:add(RIc)end Tools.Decorate.startHistoryRecord=function(v1pCX6,NK)if v1pCX6.State.HistoryRecord then v1pCX6.State.HistoryRecord=nil end v1pCX6.State.HistoryRecord={targets=Support.CloneTable(NK),initial_color={},terminal_color={},initial_2nd_color={},terminal_2nd_color={},initial_opacity={},terminal_opacity={},initial_velocity={},terminal_velocity={},initial_size={},terminal_size={},initial_heat={},terminal_heat={},unapply=function(v1pCX6) Selection:clear() for KNYh,STO_Hubw in pairs(v1pCX6.targets)do if STO_Hubw then Selection:add(STO_Hubw.Parent) if STO_Hubw:IsA('Sparkles')then STO_Hubw.SparkleColor=v1pCX6.initial_color[STO_Hubw]else STO_Hubw.Color=v1pCX6.initial_color[STO_Hubw] STO_Hubw.Size=v1pCX6.initial_size[STO_Hubw]end
if STO_Hubw:IsA('Smoke')then STO_Hubw.Opacity=v1pCX6.initial_opacity[STO_Hubw] STO_Hubw.RiseVelocity=v1pCX6.initial_velocity[STO_Hubw]end if STO_Hubw:IsA('Fire')then STO_Hubw.SecondaryColor=v1pCX6.initial_2nd_color[STO_Hubw]STO_Hubw.Heat=v1pCX6.initial_heat[STO_Hubw]end end end end,apply=function(v1pCX6) Selection:clear() for S4jSoR,w in pairs(v1pCX6.targets)do if w then Selection:add(w.Parent) if w:IsA('Sparkles')then w.SparkleColor=v1pCX6.terminal_color[w]else w.Color=v1pCX6.terminal_color[w]w.Size=v1pCX6.terminal_size[w]end
if w:IsA('Smoke')then w.Opacity=v1pCX6.terminal_opacity[w] w.RiseVelocity=v1pCX6.terminal_velocity[w]end if w:IsA('Fire')then w.SecondaryColor=v1pCX6.terminal_2nd_color[w]w.Heat=v1pCX6.terminal_heat[w]end end end end} for yX3j,bOwWOjQH in pairs(v1pCX6.State.HistoryRecord.targets)do if bOwWOjQH then if bOwWOjQH:IsA('Sparkles')then v1pCX6.State.HistoryRecord.initial_color[bOwWOjQH]=bOwWOjQH.SparkleColor else v1pCX6.State.HistoryRecord.initial_color[bOwWOjQH]=bOwWOjQH.Color v1pCX6.State.HistoryRecord.initial_size[bOwWOjQH]=bOwWOjQH.Size end if bOwWOjQH:IsA('Smoke')then v1pCX6.State.HistoryRecord.initial_opacity[bOwWOjQH]=bOwWOjQH.Opacity v1pCX6.State.HistoryRecord.initial_velocity[bOwWOjQH]=bOwWOjQH.RiseVelocity end if bOwWOjQH:IsA('Fire')then v1pCX6.State.HistoryRecord.initial_2nd_color[bOwWOjQH]=bOwWOjQH.SecondaryColor v1pCX6.State.HistoryRecord.initial_heat[bOwWOjQH]=bOwWOjQH.Heat end end end end Tools.Decorate.finishHistoryRecord=function(d) if not d.State.HistoryRecord then return end for pM6sO5R0,TF4nyv in pairs(d.State.HistoryRecord.targets)do if TF4nyv then if TF4nyv:IsA('Sparkles')then d.State.HistoryRecord.terminal_color[TF4nyv]=TF4nyv.SparkleColor else d.State.HistoryRecord.terminal_color[TF4nyv]=TF4nyv.Color d.State.HistoryRecord.terminal_size[TF4nyv]=TF4nyv.Size end if TF4nyv:IsA('Smoke')then d.State.HistoryRecord.terminal_opacity[TF4nyv]=TF4nyv.Opacity d.State.HistoryRecord.terminal_velocity[TF4nyv]=TF4nyv.RiseVelocity end if TF4nyv:IsA('Fire')then d.State.HistoryRecord.terminal_2nd_color[TF4nyv]=TF4nyv.SecondaryColor d.State.HistoryRecord.terminal_heat[TF4nyv]=TF4nyv.Heat end end end
History:add(d.State.HistoryRecord) d.State.HistoryRecord=nil end Tools.Decorate.hideGUI=function(lilD_Ll) if lilD_Ll.GUI then lilD_Ll.GUI.Visible=false end end
Tools.Decorate.Loaded=true end}}if not _G.BTCoreEnv then _G.BTCoreEnv={}end _G.BTCoreEnv["tool"]=getfenv(0)CoreReady=true
for Q2jN,Y1v09ha in pairs(q)do Y1v09ha[2]()end for XWU,t in pairs(q)do if not Tools[t[1]]then repeat wait()print("is tool not hooking?")until Tools[t[1]]end repeat wait()until Tools[t[1]].Loaded end if ToolType=='plugin'then local i=false ToolbarButton.Click:connect(function()if i then i=false unequipBT()else i=true
plugin:Activate(true) equipBT(plugin:GetMouse())end end)plugin.Deactivation:connect(unequipBT)elseif ToolType== 'tool'then Tool.Equipped:connect(equipBT) Tool.Unequipped:connect(unequipBT)end
