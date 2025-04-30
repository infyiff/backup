--[[
	DataToCode - Make DataTypes actually readable

	Created by: https://github.com/78n
	License: https://github.com/78n/Roblox/blob/main/LICENSE | Covered by MIT

	A little background about the coding style:
		I sometimes use next to avoid invoking __call/__iter in tables that I dont know the orgin of
		This has been rewritten like 3 seperate times
		The reason I don't use string interpolation is because it is very slow
		I dont use a giant if then elseif in my Serializer function as it is not as maintainable/scaleable as a dictionary of methods
]]
--!optimize 2
--!native

local assert, type, typeof, rawset, getmetatable, tostring = assert, type, typeof, rawset, getmetatable, tostring
local print, warn, pack, unpack, next = print, warn, table.pack, unpack, next

local IsSharedFrozen, SharedSize = SharedTable.isFrozen, SharedTable.size
local bufftostring, fromstring, readu8 = buffer.tostring, buffer.fromstring, buffer.readu8
local isfrozen, concat = table.isfrozen, table.concat

local FindService = game.FindService
local info = debug.info

local IsClient = game:GetService("RunService"):IsClient()
local Players = game:GetService("Players")
local inf, neginf = math.huge, -math.huge

local DefaultMethods = {}
local Methods = setmetatable({}, {__index = DefaultMethods})
local Class = {
	__tostringUnsupported = false, -- whether or not to tostring unsupported types
	__Serializeinf = false
}

local Services = {
	Workspace = "workspace",
	Lighting = "game.lighting",
	GlobalSettings = "settings()",
	Stats = "stats()",
	UserSettings = "UserSettings()",
	PluginManagerInterface = "PluginManager()",
	DebuggerManager = "DebuggerManager()"
}

local Signals = { -- You theoretically could serialize the api to retrieve most of the Signals but I don't believe that its really worth it
	GraphicsQualityChangeRequest = "game.GraphicsQualityChangeRequest",
	AllowedGearTypeChanged = "game.AllowedGearTypeChanged",
	ScreenshotSavedToAlbum = "game.ScreenshotSavedToAlbum",
	UniverseMetadataLoaded = "game.UniverseMetadataLoaded",
	ScreenshotReady = "game.ScreenshotReady",
	ServiceRemoving = "game.ServiceRemoving",
	ServiceAdded = "game.ServiceAdded",
	ItemChanged = "game.ItemChanged",
	CloseLate = "game.CloseLate",
	Loaded = "game.Loaded",
	Close = "game.Close",

	RobloxGuiFocusedChanged = "game:GetService(\"RunService\").RobloxGuiFocusedChanged",
	PostSimulation = "game:GetService(\"RunService\").PostSimulation",
	RenderStepped = "game:GetService(\"RunService\").RenderStepped",
	PreSimulation = "game:GetService(\"RunService\").PreSimulation",
	PreAnimation = "game:GetService(\"RunService\").PreAnimation",
	PreRender = "game:GetService(\"RunService\").PreRender",
	Heartbeat = "game:GetService(\"RunService\").Heartbeat",
	Stepped = "game:GetService(\"RunService\").Stepped"
}

local Keywords = {
	["local"] = "\"local\"",
	["function"] = "\"function\"",
	--	["type"] = "\"type\"",
	--	["typeof"] = "\"typeof\"",
	--	["export"] = "\"export\"",
	--	["continue"] = "\"continue\"",
	["and"] = "\"and\"",
	["break"] = "\"break\"",
	["not"] = "\"not\"",
	["or"] = "\"or\"",
	["else"] = "\"else\"",
	["elseif"] = "\"elseif\"",
	["if"] = "\"if\"",
	["then"] = "\"then\"",
	["until"] = "\"until\"",
	["repeat"] = "\"repeat\"",
	["while"] = "\"while\"",
	["do"] = "\"do\"",
	["for"] = "\"for\"",
	["in"] = "\"in\"",
	["end"] = "\"end\"",
	["return"] = "\"return\"",
	["true"] = "\"true\"",
	["false"] = "\"false\"",
	["nil"] = "\"nil\""
}

local ByteList do
	ByteList = {
		[7] = "\\a",
		[8] = "\\b",
		[9] = "\\t",
		[10] = "\\n",
		[11] = "\\v",
		[12] = "\\f",
		[13] = "\\r",
		[34] = "\\\"",
		[92] = "\\\\"
	}

	for i = 0, 255 do
		local Character = string.char(i)

		if not ByteList[Character] and (i < 32 or i > 126) then
			ByteList[Character] = ("\\%03d"):format(i)
		end
	end
end

local Enums = {} do
	for i,v in Enum:GetEnums() do
		Enums[v] = "Enum."..tostring(v)
	end
end

local GlobalFunctions = {} do
	local getrenv = getrenv or (function() -- support for studio executors
		local env = { -- I could be missing a couple libraries
			bit32 = bit32,
			buffer = buffer,
			coroutine = coroutine,
			debug = debug,
			math = math,
			os = os,
			string = string,
			table = table,
			utf8 = utf8,
			Content = Content,
			Axes = Axes,
			AdReward = AdReward, --Empty
			BrickColor = BrickColor,
			CatalogSearchParams = CatalogSearchParams,
			CFrame = CFrame,
			Color3 = Color3,
			ColorSequence = ColorSequence,
			ColorSequenceKeypoint = ColorSequenceKeypoint,
			DateTime = DateTime,
			DockWidgetPluginGuiInfo = DockWidgetPluginGuiInfo,
			Faces = Faces,
			FloatCurveKey = FloatCurveKey,
			Font = Font,
			Instance = Instance,
			NumberRange = NumberRange,
			NumberSequence = NumberSequence,
			NumberSequenceKeypoint = NumberSequenceKeypoint,
			OverlapParams = OverlapParams,
			PathWaypoint = PathWaypoint,
			PhysicalProperties = PhysicalProperties,
			Random = Random,
			Ray = Ray,
			RaycastParams = RaycastParams,
			Rect = Rect,
			Region3 = Region3,
			Region3int16 = Region3int16,
			RotationCurveKey = RotationCurveKey,
			SharedTable = SharedTable,
			task = task,
			TweenInfo = TweenInfo,
			UDim = UDim,
			UDim2 = UDim2,
			Vector2 = Vector2,
			Vector2int16 = Vector2int16,
			Vector3 = Vector3,
			vector = vector,
			Vector3int16 = Vector3int16,
			CellId = CellId, -- Undocumented
			PluginDrag = PluginDrag,
			SecurityCapabilities = SecurityCapabilities,

			assert = assert,
			error = error,
			getfenv = getfenv,
			getmetatable = getmetatable,
			ipairs = ipairs,
			loadstring = loadstring,
			newproxy = newproxy,
			next = next,
			pairs = pairs,
			pcall = pcall,
			print = print,
			rawequal = rawequal,
			rawget = rawget,
			rawlen = rawlen,
			rawset = rawset,
			select = select,
			setfenv = setfenv,
			setmetatable = setmetatable,
			tonumber = tonumber,
			tostring = tostring,
			unpack = unpack,
			xpcall = xpcall,
			collectgarbage = collectgarbage,
			delay = delay,
			gcinfo = gcinfo,
			PluginManager = PluginManager,
			DebuggerManager = DebuggerManager,
			require = require,
			settings = settings,
			spawn = spawn,
			tick = tick,
			time = time,
			UserSettings = UserSettings,
			wait = wait,
			warn = warn,
			Delay = Delay,
			ElapsedTime = ElapsedTime,
			elapsedTime = elapsedTime,
			printidentity = printidentity,
			Spawn = Spawn,
			Stats = Stats,
			stats = stats,
			Version = Version,
			version = version,
			Wait = Wait
		}

		return function()
			return env
		end
	end)()

	local Visited = setmetatable({}, {__mode = "k"}) -- support for people who actually modify the roblox env

	for i,v in getrenv() do
		local ElementType = type(i) == "string" and type(v)

		if ElementType then
			if ElementType == "table" then
				local function LoadLibrary(Path : string, tbl : {[string] : any})
					if not Visited[tbl] then
						Visited[tbl] = true

						for i,v in next, tbl do
							local Type = type(i) == "string" and not Keywords[i] and i:match("[A-z_][A-z_0-9]") and type(v)
							local NewPath = Type and (Type == "function" or Type == "table") and Path.."."..i

							if NewPath then
								if Type == "function" then
									GlobalFunctions[v] = NewPath
								else
									LoadLibrary(NewPath, v)
								end
							end
						end
					end
				end

				LoadLibrary(i, v)
				table.clear(Visited)
			elseif ElementType == "function" then
				GlobalFunctions[v] = i
			end
		end
	end
end

local DefaultVectors, DefaultCFrames = {}, {} do
	local function ExtractTypes<Type>(From : {[any] : any}, Path : string, DataType : string, Storage : {}?) : {[Type] : string}
		local Storage = Storage or setmetatable({}, {__mode = "k"}) -- I dont technically dont need it but as I don't know what people are going to do with this code better safe than sorry

		for i,v in next, From do
			if typeof(v) == DataType and not Storage[v] and type(i) == "string" and not Keywords[i] and not i:match("[a-Z_][a-Z_0-9]") then
				Storage[v] = Path.."."..i
			end
		end

		return Storage
	end

	ExtractTypes(vector, "vector", "Vector3", DefaultVectors)
	ExtractTypes(Vector3, "Vector3", "Vector3", DefaultVectors)
	ExtractTypes(CFrame, "CFrame", "CFrame", DefaultCFrames)
end

local function Serialize<Type>(DataStructure : Type, format : boolean?, indents : string, CyclicList : typeof(setmetatable({}, {__mode = "k"}))?, InComment : boolean?)
	local DataHandler = Methods[typeof(DataStructure)]

	return DataHandler and DataHandler(DataStructure, format, indents, CyclicList, InComment) or "nil --["..(not InComment and "" or "=").."[ Unsupported Data Type | "..typeof(DataStructure)..(not Class.__tostringUnsupported and "" or " | "..tostring(DataStructure)).." ]"..(not InComment and "" or "=").."]"
end

local function islclosure(Function : (...any?) -> (...any?))
	return info(Function, "l") ~= -1
end

local function nanToString(int : number)
	return int == int and int or "0/0"
end

local function ValidateSharedTableIndex(Index : string)
	local IsKeyword = type(Index) == "number" and Index or Keywords[Index]

	if not IsKeyword then
		if #Index ~= 0 then
			local IndexBuffer = fromstring(Index)
			local FirstByte = readu8(IndexBuffer, 0)

			if FirstByte >= 97 and FirstByte <= 122 or FirstByte >= 65 and FirstByte <= 90 or FirstByte == 95 then
				for i = 1, #Index-1 do
					local Byte = readu8(IndexBuffer, i)

					if not ((Byte >= 97 and Byte <= 122) or (Byte >= 65 and Byte <= 90) or Byte == 95 or (Byte >= 48 and Byte <= 57)) then
						return "["..Methods.string(Index).."] = "
					end
				end

				return Index.." = "
			end

			return "["..Methods.string(Index).."] = "
		end

		return "[\"\"] = "
	end

	return "["..IsKeyword.."] = "
end

local function ValidateIndex(Index : any)
	local IndexType = type(Index)
	local IsNumber = IndexType == "number"

	if IsNumber or IndexType == "string" then
		local IsKeyword = (IsNumber and Index or Keywords[Index])

		if not IsKeyword then
			if #Index ~= 0 then
				local IndexBuffer = fromstring(Index)
				local FirstByte = readu8(IndexBuffer, 0)

				if FirstByte >= 97 and FirstByte <= 122 or FirstByte >= 65 and FirstByte <= 90 or FirstByte == 95 then
					local IndexLength = #Index

					for i = 1, IndexLength-1 do
						local Byte = readu8(IndexBuffer, i)

						if not ((Byte >= 97 and Byte <= 122) or (Byte >= 65 and Byte <= 90) or Byte == 95 or (Byte >= 48 and Byte <= 57)) then
							return "["..Methods.string(Index).."] = "
						end
					end

					return Index.." = "
				end

				return "["..Methods.string(Index).."] = "
			end

			return "[\"\"] = "
		end

		return "["..IsKeyword.."] = "
	end

	return "["..(IndexType ~= "table" and Serialize(Index, false, "") or "\"<Table> (table: "..(getmetatable(Index) == nil and tostring(Index):sub(8) or "@metatable")..")\"").."] = "
end

function DefaultMethods.Axes(Axes : Axes)
	return "Axes.new("..concat({
		Axes.X and "Enum.Axis.X" or nil,
		Axes.Y and "Enum.Axis.Y" or nil,
		Axes.Z and "Enum.Axis.Z" or nil
	},", ")..")"
end

function DefaultMethods.BrickColor(Color : BrickColor)
	return "BrickColor.new("..Color.Number..")"
end

function DefaultMethods.CFrame(CFrame : CFrame)
	local Generation = DefaultCFrames[CFrame]

	if not Generation then
		local SerializeNumber = Methods.number
		local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = CFrame:GetComponents()

		return "CFrame.new("..SerializeNumber(x)..", "..SerializeNumber(y)..", "..SerializeNumber(z)..", "..SerializeNumber(R00)..", "..SerializeNumber(R01)..", "..SerializeNumber(R02)..", "..SerializeNumber(R10)..", "..SerializeNumber(R11)..", "..SerializeNumber(R12)..", "..SerializeNumber(R20)..", "..SerializeNumber(R21)..", "..SerializeNumber(R22)..")"
	end

	return Generation
end

local DefaultCatalogSearchParams = CatalogSearchParams.new()
function DefaultMethods.CatalogSearchParams(Params : CatalogSearchParams, format : boolean?, indents : string)
	if DefaultCatalogSearchParams ~= Params then
		local formatspace = format and "\n"..indents or " "
		local SerializeString = Methods.string
		local SearchKeyword = Params.SearchKeyword
		local MinPrice = Params.MinPrice
		local MaxPrice = Params.MaxPrice
		local SortType = Params.SortType
		local SortAggregation = Params.SortAggregation
		local CategoryFilter = Params.CategoryFilter
		local SalesTypeFilter = Params.SalesTypeFilter
		local BundleTypes = Params.BundleTypes
		local AssetTypes = Params.AssetTypes
		local CreatorName = Params.CreatorName
		local CreatorType = Params.CreatorType
		local CreatorId = Params.CreatorId
		local Limit = Params.Limit

		return "(function(Param : CatalogSearchParams)"..formatspace..(SearchKeyword ~= "" and "\tParam.SearchKeyword = "..SerializeString(SearchKeyword)..formatspace or "")..(MinPrice ~= 0 and "\tParam.MinPrice = "..MinPrice..formatspace or "")..(MaxPrice ~= 2147483647 and "\tParam.MaxPrice = "..MaxPrice..formatspace or "")..(SortType ~= Enum.CatalogSortType.Relevance and "\tParam.SortType = Enum.CatalogSortType."..SortType.Name..formatspace or "")..(SortAggregation ~= Enum.CatalogSortAggregation.AllTime and "\tParam.SortAggregation = Enum.CatalogSortAggregation."..SortAggregation.Name..formatspace or "")..(CategoryFilter ~= Enum.CatalogCategoryFilter.None and "\tParam.CategoryFilter = Enum.CatalogCategoryFilter."..CategoryFilter.Name..formatspace or "")..(SalesTypeFilter ~= Enum.SalesTypeFilter.All and "\tParam.SalesTypeFilter = Enum.SalesTypeFilter."..SalesTypeFilter.Name..formatspace or "")..(#BundleTypes > 0 and "\tParam.BundleTypes = "..Methods.table(BundleTypes, false, "")..formatspace or "")..(#AssetTypes > 0 and "\tParam.AssetTypes = "..Methods.table(AssetTypes, false, "")..formatspace or "")..(Params.IncludeOffSale and "\tParams.IncludeOffSale = true"..formatspace or "")..(CreatorName ~= "" and "\tParams.CreatorName = "..SerializeString(CreatorName)..formatspace or "")..(CreatorType ~= Enum.CreatorTypeFilter.All and "\tParam.CreatorType = Enum.CreatorTypeFilter."..CreatorType.Name..formatspace or "")..(CreatorId ~= 0 and "\tParams.CreatorId = "..CreatorId..formatspace or "")..(Limit ~= 30 and "\tParams.Limit = "..Limit..formatspace or "").."\treturn Params"..formatspace.."end)(CatalogSearchParams.new())"
	end

	return "CatalogSearchParams.new()"
end

function DefaultMethods.Color3(Color : Color3)
	local SerializeNumber = Methods.number

	return "Color3.new("..SerializeNumber(Color.R)..", "..SerializeNumber(Color.G)..", "..SerializeNumber(Color.B)..")"
end

function DefaultMethods.ColorSequence(Sequence : ColorSequence)
	local SerializeColorSequenceKeypoint = Methods.ColorSequenceKeypoint
	local Keypoints = Sequence.Keypoints
	local Size = #Keypoints
	local Serialized = ""

	for i = 1, Size-1 do
		Serialized ..= SerializeColorSequenceKeypoint(Keypoints[i])..", "
	end

	return "ColorSequence.new({"..Serialized..SerializeColorSequenceKeypoint(Keypoints[Size]).."})"
end

function DefaultMethods.ColorSequenceKeypoint(KeyPoint : ColorSequenceKeypoint)
	return "ColorSequenceKeypoint.new("..Methods.number(KeyPoint.Time)..", "..Methods.Color3(KeyPoint.Value)..")"
end

function DefaultMethods.Content(content : Content)
	local Uri = content.Uri

	return Uri and "Content.fromUri("..Uri..")" or "Content.none"
end

function DefaultMethods.DateTime(Date : DateTime)
	return "DateTime.fromUnixTimestampMillis("..Date.UnixTimestampMillis..")"
end

function DefaultMethods.DockWidgetPluginGuiInfo(Dock : DockWidgetPluginGuiInfo)
	local ArgumentFunction = tostring(Dock):gmatch(":([%w%-]+)")

	return "DockWidgetPluginGuiInfo.new(Enum.InitialDockState."..ArgumentFunction()..", "..(ArgumentFunction() == "1" and "true" or "false")..", "..(ArgumentFunction() == "1" and "true" or "false")..", "..ArgumentFunction()..", "..ArgumentFunction()..", "..ArgumentFunction()..", "..ArgumentFunction()..")"
end

function DefaultMethods.Enum(Enum : Enum)
	return "Enums."..tostring(Enum)
end

function DefaultMethods.EnumItem(Item : EnumItem)
	return Enums[Item.EnumType].."."..Item.Name
end

function DefaultMethods.Enums()
	return "Enums"
end

function DefaultMethods.Faces(Faces : Faces)
	return "Faces.new("..concat({
		Faces.Top and "Enum.NormalId.Top" or nil,
		Faces.Bottom and "Enum.NormalId.Bottom" or nil,
		Faces.Left and "Enum.NormalId.Left" or nil,
		Faces.Right and "Enum.NormalId.Right" or nil,
		Faces.Back and "Enum.NormalId.Back" or nil,
		Faces.Front and "Enum.NormalId.Front" or nil,
	}, ", ")..")"
end

function DefaultMethods.FloatCurveKey(CurveKey : FloatCurveKey)
	local SerializeNumber = Methods.number

	return "FloatCurveKey.new("..SerializeNumber(CurveKey.Time)..", "..SerializeNumber(CurveKey.Value)..", Enum.KeyInterpolationMode."..CurveKey.Interpolation.Name..")"
end

function DefaultMethods.Font(Font : Font)
	return "Font.new("..Methods.string(Font.Family)..", Enum.FontWeight."..Font.Weight.Name..", Enum.FontStyle."..Font.Style.Name..")"
end

if IsClient then
	local LocalPlayer = Players.LocalPlayer
	if not LocalPlayer then
		Players:GetPropertyChangedSignal("LocalPlayer"):Once(function()
			LocalPlayer = Players.LocalPlayer
		end)
	end

	-- Not garenteed to return the correct generation
	function DefaultMethods.Instance(obj : Instance) -- Client
		local ObjectParent = obj.Parent
		local ObjectClassName = obj.ClassName

		if ObjectParent then
			local ObjectName = Methods.string(obj.Name)

			if ObjectClassName ~= "Model" and ObjectClassName ~= "Player" then
				local IsService, Output = pcall(FindService, game, ObjectClassName) -- Generation can and will break when presented with noncreatable Instances such as Path (which is created by PathService:CreateAsync())

				return (not IsService or not Output) and Methods.Instance(ObjectParent)..":WaitForChild("..ObjectName..")" or Services[ObjectClassName] or "game:GetService(\""..ObjectClassName.."\")"
			elseif ObjectClassName == "Model" then
				local Player = Players:GetPlayerFromCharacter(obj)

				return not Player and Methods.Instance(ObjectParent)..":WaitForChild("..ObjectName..")" or "game:GetService(\"Players\")".. (Player == LocalPlayer and ".LocalPlayer.Character" or ":WaitForChild("..ObjectName..").Character")
			end

			return "game:GetService(\"Players\")".. (obj == LocalPlayer and ".LocalPlayer" or ":WaitForChild("..ObjectName..")") 
		end

		return ObjectClassName == "DataModel" and "game" or "Instance.new(\""..ObjectClassName.."\", nil)"
	end
else
	function DefaultMethods.Instance(obj : Instance) -- Server
		local ObjectParent = obj.Parent
		local ObjectClassName = obj.ClassName

		if ObjectParent then
			local ObjectName = Methods.string(obj.Name)

			if ObjectClassName ~= "Model" and ObjectClassName ~= "Player" then
				local IsService, Output = pcall(FindService, game, ObjectClassName) -- Generation can and will break when presented with noncreatable Instances such as Path (which is created by PathService:CreateAsync())

				return (not IsService or not Output) and Methods.Instance(ObjectParent)..":WaitForChild("..ObjectName..")" or Services[ObjectClassName] or "game:GetService(\""..ObjectClassName.."\")"
			elseif ObjectClassName == "Model" then
				local Player = Players:GetPlayerFromCharacter(obj)

				return not Player and Methods.Instance(ObjectParent)..":WaitForChild("..ObjectName..")" or "game:GetService(\"Players\"):WaitForChild("..ObjectName..").Character"
			end

			return "game:GetService(\"Players\"):WaitForChild("..ObjectName..")"
		end

		return ObjectClassName == "DataModel" and "game" or "Instance.new(\""..ObjectClassName.."\", nil)"
	end
end

function DefaultMethods.NumberRange(Range : NumberRange)
	local SerializeNumber = Methods.number

	return "NumberRange.new("..SerializeNumber(Range.Min)..", "..SerializeNumber(Range.Max)..")"
end

function DefaultMethods.NumberSequence(Sequence : NumberSequence)
	local SerializeNumberSequenceKeypoint = Methods.NumberSequenceKeypoint
	local Keypoints = Sequence.Keypoints
	local Size = #Keypoints
	local Serialized = ""

	for i = 1, Size-1 do
		Serialized ..= SerializeNumberSequenceKeypoint(Keypoints[i])..", "
	end

	return "NumberSequence.new({"..Serialized..SerializeNumberSequenceKeypoint(Keypoints[Size]).."})"
end

local DefaultOverlapParams = OverlapParams.new()
function DefaultMethods.OverlapParams(Params : OverlapParams, format : boolean?, indents : string)
	if DefaultOverlapParams ~= Params then
		local formatspace = format and "\n"..indents or " "
		local FilterDescendantsInstances = Params.FilterDescendantsInstances
		local FilterType = Params.FilterType
		local CollisionGroup = Params.CollisionGroup

		return "(function(Param : OverlapParams)"..formatspace..(#FilterDescendantsInstances > 0 and "\tParam.FilterDescendantsInstances = "..Methods.table(FilterDescendantsInstances, false, "")..formatspace or "")..(FilterType ~= Enum.RaycastFilterType.Exclude and "\tParam.FilterType = Enum.RaycastFilterType."..FilterType.Name..formatspace or "")..(CollisionGroup ~= "Default" and "\tParam.CollisionGroup = "..Methods.string(CollisionGroup)..formatspace or "")..(Params.RespectCanCollide and "\tParam.RespectCanCollide = true"..formatspace or "")..(Params.BruteForceAllSlow and "\tParam.BruteForceAllSlow = true"..formatspace or "").."\treturn Params"..formatspace.."end)(OverlapParams.new())"
	end

	return "OverlapParams.new()"
end

function DefaultMethods.NumberSequenceKeypoint(Keypoint : NumberSequenceKeypoint)
	local SerializeNumber = Methods.number

	return "NumberSequenceKeypoint.new("..SerializeNumber(Keypoint.Time)..", "..SerializeNumber(Keypoint.Value)..", "..SerializeNumber(Keypoint.Envelope)..")"
end

function DefaultMethods.PathWaypoint(Waypoint : PathWaypoint)
	return "PathWaypoint.new("..Methods.Vector3(Waypoint.Position)..", Enum.PathWaypointAction."..Waypoint.Action.Name..", "..Methods.string(Waypoint.Label)..")"
end

function DefaultMethods.PhysicalProperties(Properties : PhysicalProperties)
	return "PhysicalProperties.new("..(nanToString(Properties.Density))..", "..nanToString(Properties.Friction)..", "..nanToString(Properties.Elasticity)..", "..nanToString(Properties.FrictionWeight)..", "..nanToString(Properties.ElasticityWeight)..")"
end

function DefaultMethods.RBXScriptConnection(Connection : RBXScriptConnection, _, _, _, InComment : boolean?)
	local CommentSeperator = not InComment and "" or "="

	return "(nil --["..CommentSeperator.."[ RBXScriptConnection | IsConnected: "..(Connection.Connected and "true" or "false").." ]"..CommentSeperator.."])" -- Can't support this
end

function DefaultMethods.RBXScriptSignal(Signal : RBXScriptSignal, _, _, _, InComment : boolean?)
	local CommentSeperator = not InComment and "" or "="
	local SignalName = tostring(Signal):match("Signal (%a+)")

	return Signals[SignalName] or "(nil --["..CommentSeperator.."[ RBXScriptSignal | "..SignalName.." is not supported ]"..CommentSeperator.."])"
end

function DefaultMethods.Random(_, _, _, _, InComment : boolean?) -- Random cant be supported because I cant get the seed
	local CommentSeperator = not InComment and "" or "="

	return "Random.new(--["..CommentSeperator.."[ <Seed> ]"..CommentSeperator.."])"
end

function DefaultMethods.Ray(Ray : Ray)
	local SerializeVector3 = Methods.Vector3

	return "Ray.new("..SerializeVector3(Ray.Origin)..", "..SerializeVector3(Ray.Direction)..")"
end

local DefaultRaycastParams = RaycastParams.new()
function DefaultMethods.RaycastParams(Params : RaycastParams, format : boolean?, indents : string)
	if DefaultRaycastParams ~= Params then
		local formatspace = format and "\n"..indents or " "
		local FilterDescendantsInstances = Params.FilterDescendantsInstances
		local FilterType = Params.FilterType
		local CollisionGroup = Params.CollisionGroup

		return "(function(Param : RaycastParams)"..formatspace..(#FilterDescendantsInstances > 0 and "\tParam.FilterDescendantsInstances = "..Methods.table(FilterDescendantsInstances, false, "")..formatspace or "")..(FilterType ~= Enum.RaycastFilterType.Exclude and "\tParam.FilterType = Enum.RaycastFilterType."..FilterType.Name..formatspace or "")..(Params.IgnoreWater and "\tParam.IgnoreWater = true"..formatspace or "")..(CollisionGroup ~= "Default" and "\tParam.CollisionGroup = "..Methods.string(CollisionGroup)..formatspace or "")..(Params.RespectCanCollide and "\tParam.RespectCanCollide = true"..formatspace or "")..(Params.BruteForceAllSlow and "\tParam.BruteForceAllSlow = true"..formatspace or "").."\treturn Params"..formatspace.."end)(RaycastParams.new())"
	end

	return "RaycastParams.new()"
end

function DefaultMethods.Rect(Rect : Rect)
	local SerializeVector2 = Methods.Vector2

	return "Rect.new("..SerializeVector2(Rect.Min)..", "..SerializeVector2(Rect.Max)..")"
end

function DefaultMethods.Region3(Region : Region3)
	local SerializeVector3 = Methods.Vector3
	local Center = Region.CFrame.Position
	local Size = Region.Size/2

	return "Region3.new("..SerializeVector3(Center - Size)..", "..SerializeVector3(Center + Size)..")"
end

function DefaultMethods.Region3int16(Region : Region3int16)
	local SerializeVector3int16 = Methods.Vector3int16

	return "Region3int16.new("..SerializeVector3int16(Region.Min)..", "..SerializeVector3int16(Region.Max)..")"
end

function DefaultMethods.RotationCurveKey(Curve : RotationCurveKey)
	return "RotationCurveKey.new("..Methods.number(Curve.Time)..", "..Methods.CFrame(Curve.Value)..", Enum.KeyInterpolationMode."..Curve.Interpolation.Name..")"
end

function DefaultMethods.SharedTable(Shared : SharedTable, format : boolean?, indents : string, _, InComment : boolean?)
	local isreadonly = IsSharedFrozen(Shared)

	if SharedSize(Shared) ~= 0 then
		local stackindent = indents..(format and "\t" or "")
		local CurrentIndex = 1
		local Serialized = {}

		for i,v in Shared do
			Serialized[CurrentIndex] = (CurrentIndex ~= i and ValidateSharedTableIndex(i) or "")..Serialize(v, format, stackindent, nil, InComment)
			CurrentIndex += 1	
		end

		local formatspace = format and "\n" or ""
		local Contents = formatspace..stackindent..concat(Serialized, (format and ",\n" or ", ")..stackindent)..formatspace..indents

		return not isreadonly and "SharedTable.new({"..Contents.."})" or "SharedTable.cloneAndFreeze(SharedTable.new({"..Contents.."}))"
	end

	return not isreadonly and "SharedTable.new()" or "SharedTable.cloneAndFreeze(SharedTable.new())"
end

function DefaultMethods.TweenInfo(Info : TweenInfo)
	return "TweenInfo.new("..Methods.number(Info.Time)..", Enum.EasingStyle."..Info.EasingStyle.Name..", Enum.EasingDirection."..Info.EasingDirection.Name..", "..Info.RepeatCount..", "..(Info.Reverses and "true" or "false")..", "..Methods.number(Info.DelayTime)..")"
end

function DefaultMethods.UDim(UDim : UDim)
	return "UDim.new("..Methods.number(UDim.Scale)..", "..UDim.Offset..")"
end

function DefaultMethods.UDim2(UDim2 : UDim2)
	local SerializeNumber = Methods.number
	local Width = UDim2.X
	local Height = UDim2.Y

	return "UDim2.new("..SerializeNumber(Width.Scale)..", "..Width.Offset..", "..SerializeNumber(Height.Scale)..", "..Height.Offset..")"
end

function DefaultMethods.Vector2(Vector : Vector2)
	local SerializeNumber = Methods.number

	return "Vector2.new("..SerializeNumber(Vector.X)..", "..SerializeNumber(Vector.Y)..")"
end

function DefaultMethods.Vector2int16(Vector : Vector2int16)
	return "Vector2int16.new("..Vector.X..", "..Vector.Y..")"
end

function DefaultMethods.Vector3(Vector : Vector3)
	local SerializeNumber = Methods.number

	return DefaultVectors[Vector] or "vector.create("..SerializeNumber(Vector.X)..", "..SerializeNumber(Vector.Y)..", "..SerializeNumber(Vector.Z)..")" -- vector library is more efficent/accurate
end

function DefaultMethods.Vector3int16(Vector : Vector3int16)
	return "Vector3int16.new("..Vector.X..", "..Vector.Y..", "..Vector.Z..")"
end

function DefaultMethods.boolean(bool : boolean)
	return bool and "true" or "false"
end

function DefaultMethods.buffer(buff : buffer)
	return "buffer.fromstring("..Methods.string(bufftostring(buff))..")"
end

DefaultMethods["function"] = function(Function : (...any?) -> ...any?, format : boolean?, indents : string, _, InComment : boolean?)
	local IsGlobal = GlobalFunctions[Function]

	if not IsGlobal then
		if format then
			local SerializeString = Methods.string

			local CommentSeperator = not InComment and "" or "="
			local tempindents = indents.."\t\t\t"
			local newlineindent = ",\n"..tempindents
			local source, line, name, numparams, vargs = info(Function, "slna")

			return "function()"..(line ~= -1 and "" or " --["..CommentSeperator.."[ CClosure "..(info(Function, "n")).." ]"..CommentSeperator.."]").."\n\t"..indents.."--["..CommentSeperator.."[\n\t\t"..indents.."info = {\n"..tempindents.."source = "..SerializeString(source)..newlineindent.."line = "..line..newlineindent.."what = "..(line ~= -1 and "\"Lua\"" or "\"C\"")..newlineindent.."name = "..SerializeString(name)..newlineindent.."numparams = "..numparams..newlineindent.."vargs = "..(vargs and "true" or "false")..newlineindent.."function = "..tostring(Function).."\n\t\t"..indents.."}\n\t"..indents.."]"..CommentSeperator.."]\n"..indents.."end"
		end

		return islclosure(Function) and "function() end" or "function() --["..(not InComment and "" or "=").."[ CClosure "..(info(Function, "n")).." ]"..(not InComment and "" or "=").."] end" -- shouldn't really ever be possible unless lego hax newcclosure
	end

	return IsGlobal
end

function DefaultMethods.table(tbl : {[any] : any}, format : boolean?, indents : string, CyclicList : typeof(setmetatable({}, {__mode = "k"}))?, InComment : boolean?)
	local CyclicList = CyclicList or setmetatable({}, {__mode = "k"})

	if not CyclicList[tbl] then
		CyclicList[tbl] = true 
		local isreadonly = isfrozen(tbl)
		local Index, Value = next(tbl)

		if Index ~= nil then
			local Indents = indents..(format and "\t" or "")
			local Ending = (format and ",\n" or ", ")
			local formatspace = format and "\n" or ""
			local Generation = "{"..formatspace

			local CurrentIndex = 1

			repeat
				Generation ..= Indents..(CurrentIndex ~= Index and ValidateIndex(Index) or "")..Serialize(Value, format, Indents, CyclicList, InComment)
				Index, Value = next(tbl, Index)
				Generation ..= Index ~= nil and Ending or formatspace..indents.."}"
				CurrentIndex += 1
			until Index == nil

			return not isreadonly and Generation or "table.freeze("..Generation..")"
		end

		return not isreadonly and "{}" or "table.freeze({})"
	else
		return "*** cycle table reference detected ***" -- I am NOT supporting cyclic tables as its a huge pain
	end
end

DefaultMethods["nil"] = function() -- why not
	return "nil"
end

function DefaultMethods.number(num : number)
	return num ~= inf and num ~= neginf and num == num and tostring(num) or num == inf and (Class.__Serializeinf and "math.huge" or "1/0") or num == neginf and (Class.__Serializeinf and "-math.huge" or "-1/0") or "0/0"
end

function DefaultMethods.string(RawString : string)
	return "\""..RawString:gsub("[\0-\31\34\92\127-\255]", ByteList).."\""
	--[[
	--Old way of doing it (I wasnt aware you could do \0xx / \00x for bytes)
	local RawStringBuffer = fromstring(RawString)
	local SerializedString = ""
	local Lastunicode = false

	for i = 0, #RawString-1 do
		local Byte = readu8(RawStringBuffer, i)

		if (Byte >= 32 and Byte <= 126) then
			local IsNumber = (Byte >= 48 and Byte <= 57)

			SerializedString ..= Lastunicode and IsNumber and "\"..\""..(Byte-48) or not IsNumber and ReadableCharacters[Byte] or Byte-48
			Lastunicode = false
		else
			local IsUnicode = Byte < 7 or Byte > 13

			SerializedString ..= IsUnicode and "\\"..Byte or SpecialCases[Byte]
			Lastunicode = IsUnicode
		end
	end

	return "\""..SerializedString.."\""
	]]
end

function DefaultMethods.thread(thread : thread)
	return "coroutine.create(function() end)"
end

function DefaultMethods.userdata(userdata : any)
	return getmetatable(userdata) ~= nil and "newproxy(true)" or "newproxy(false)"
end

local SecurityCapabilityEnums = Enum.SecurityCapability:GetEnumItems()
function DefaultMethods.SecurityCapabilities(Capabilities : SecurityCapabilities, format : boolean?, _, _, InComment : boolean?)
	local Contains = {}
	local CurrentIndex = 1

	for i,v in SecurityCapabilityEnums do
		if Capabilities:Contains(v) then
			Contains[CurrentIndex] = "Enum.SecurityCapability."..v.Name
			CurrentIndex += 1
		end
	end

	return "SecurityCapabilities.new("..concat(Contains, ", ")..")"
end

function DefaultMethods.PluginDrag(Drag : PluginDrag)
	local SerializeString = Methods.string

	return "PluginDrag.new("..SerializeString(Drag.Sender)..", "..SerializeString(Drag.MimeType)..", "..SerializeString(Drag.Data)..", "..SerializeString(Drag.MouseIcon)..", "..SerializeString(Drag.DragIcon)..", "..Methods.Vector2(Drag.HotSpot)..")"
end

function DefaultMethods.CellId()
	return "CellId.new()" -- Undocumented so I have no idea what the properties are
end

local function Serializevargs(... : any)
	local tbl = pack(...) -- Thank you https://github.com/sown0000 for pointing out that nils arent printed
	local GenerationSize = 0

	for i = 1, #tbl do
		local Generation = Serialize(tbl[i], true, "")
		tbl[i] = Generation
		GenerationSize += #Generation

		if GenerationSize > 100000 then -- output functions will trim the generation
			break
		end
	end

	return unpack(tbl, 1, tbl.n)
end

Class.Methods = setmetatable(Methods, {
	__index = getmetatable(Methods).__index,
	__newindex = function(self, index : string, newindex : ((...any?) -> (...any?))?)
		assert(type(index) == "string" and (not newindex or type(newindex) == "function"), "Methods.index<string> = newindex<function?> expected, got: Methods.index<"..typeof(index).."> = newindex<"..typeof(newindex)..">")
		rawset(self, index, newindex)
	end
})

Class.Signals = setmetatable(Signals, {
	__newindex = function(self, index : string, newindex : string?)
		assert(type(index) == "string" and (not newindex or type(newindex) == "string"), "Signals.index<string> = newindex<string?> expected, got: Signals.index<"..typeof(index).."> = newindex<"..typeof(newindex)..">")
		rawset(self, index, newindex)
	end
})

Class.Services = setmetatable(Services, {
	__newindex = function(self, index : string, newindex : string?)
		assert(type(index) == "string" and (not newindex or type(newindex) == "string"), "Services.index<string> = newindex<string?> expected, got: Services.index<"..typeof(index).."> = newindex<"..typeof(newindex)..">")
		rawset(self, index, newindex)
	end
})

Class.GlobalFunctions = setmetatable(GlobalFunctions, {
	__newindex = function(self, index : string, newindex : (...any?) -> ()?)
		assert(type(index) == "string" and (not newindex or type(newindex) == "function"), "GlobalFunctions.index<string> = newindex<function> expected, got: GlobalFunctions.index<"..typeof(index).."> = newindex<"..typeof(newindex)..">")
		rawset(self, index, newindex)
	end
})

Class.DefaultTypes = {
	Vector3 = setmetatable(DefaultVectors, {
		__newindex = function(self, index : Vector3, newindex : string?)
			assert(type(index) == "vector" and (not newindex or type(newindex) == "string"), "DefaultTypes.Vector3.index<Vector3> = newindex<string?> expected, got: DefaultTypes.Vector3.index<"..typeof(index).."> = newindex<"..typeof(newindex)..">")
			rawset(self, index, newindex)
		end
	}),
	CFrame = setmetatable(DefaultCFrames, {
		__newindex = function(self, index : CFrame, newindex : string?)
			assert(typeof(index) == "CFrame" and (not newindex or type(newindex) == "string"), "DefaultTypes.CFrame.index<CFrame> = newindex<string?> expected, got: DefaultTypes.CFrame.index<"..typeof(index).."> = newindex<"..typeof(newindex)..">")
			rawset(self, index, newindex)
		end
	})
}

-- Safe parallel
function Class.Convert<Type>(DataStructure : Type, format : boolean?)
	return Serialize(DataStructure, format, "")
end

-- Safe parallel
function Class.ConvertKnown<Type>(DataType : string, DataStructure : Type, format : boolean?)
	return Methods[DataType](DataStructure, format, "")
end

-- Safe parallel
function Class.print(... : any?)
	print(Serializevargs(...))
end

-- Safe Parallel
function Class.warn(... : any?)
	warn(Serializevargs(...))
end

return setmetatable(Class, {
	__tostring = "DataToCode"
})
