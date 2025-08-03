--[=[
	@class Structure@1.0.3
	Provides utilities to bind table data to `Configuration` instances (binder),
	and to observe and read structured data (reader).

	DeepLevel mean how deep the structure can be nested, over than this level will not be binded or observed.
]=]
local RunService = game:GetService("RunService")

local IsServer = RunService:IsServer()

export type CallbackFnc = (key: string | number, value: any) -> ()
export type ValueCallbackFnc = (value: any) -> ()
export type AddOrDesCallback = (key: any) -> ()

export type BaseStructure = {
	_tb: {},
	_config: Configuration?,
	_deepLevel: number,
	_keys: { [any]: ValueBase },
	_key: any, -- key of value in table Structure
}

export type StructureBinder = {
	_bind: { [any]: StructureBinder },
	Set: (self: StructureBinder, tb: {}) -> (),
} & { [any]: StructureBinder }

export type StructureReader = {
	_parent: StructureReader?,
	_connections: { RBXScriptConnection },
	_callback: { CallbackFnc },
	_newCallback: { AddOrDesCallback },
	_desCallback: { AddOrDesCallback },
	OnChange: (self: StructureReader, callback: CallbackFnc) -> (),
	Observe: (self: StructureReader, onNew: AddOrDesCallback?, onDes: AddOrDesCallback?) -> (),
	ObserveKey: (self: StructureReader, key: string, callback: ValueCallbackFnc) -> (),
	OnPairs: (self: StructureReader, callback: CallbackFnc) -> (),
	Raw: (self: StructureReader) -> {},
	Wait: (self: StructureReader, k: string) -> any,
} & { [any]: StructureReader }

export type Structure = BaseStructure & StructureBinder & StructureReader & {
	[any]: any | Structure,
}

--[=[
	@within Structure
	@param v any Value to cast
	@return string ClassName of matching ValueBase
]=]
local function CastValueType(v: any): string
	if type(v) == "string" then
		return "StringValue"
	elseif type(v) == "number" then
		if v == math.round(v) then
			return "IntValue"
		else
			return "NumberValue"
		end
	elseif type(v) == "boolean" then
		return "BoolValue"
	elseif typeof(v) == "Instance" then
		return "ObjectValue"
	elseif typeof(v) == "CFrame" then
		return "CFrameValue"
	elseif typeof(v) == "Vector3" then
		return "Vector3Value"
	elseif typeof(v) == "Color3" then
		return "Color3Value"
	end
	error(
		"Unsupported value type: "
			.. tostring(v)
			.. " ("
			.. typeof(v)
			.. "). Supported types are: string, number, boolean, Instance, CFrame, Vector3, Color3."
	)
end

--#region @Structure

local Structure = {}
Structure.__index = Structure
Structure._tb = {}
Structure._bind = {}
Structure._deepLevel = 100
Structure._config = nil :: Configuration
Structure._parent = nil :: StructureReader
Structure.__tostring = function(self: Structure)
	return "Structure: " .. tostring(self._config:GetFullName()) .. " with deep level: " .. tostring(self._deepLevel)
end

local Enums = {}
Structure.Enums = Enums

local StructureBinder = setmetatable({}, Structure)
local StructureReader = setmetatable({}, Structure)
local ValueStructureBinder = setmetatable({}, Structure)
local ValueStructureReader = setmetatable({}, Structure)

Enums.Binder = StructureBinder
Enums.Reader = StructureReader
Enums.ValueBinder = ValueStructureBinder
Enums.ValueReader = ValueStructureReader

function Structure:Destroy()
	for _, v in self do
		local tpTable = type(v) == "table"
		if (tpTable and v.Destroy) or typeof(v) == "Instance" then
			v:Destroy()
		elseif (tpTable and v.Disconnect) or typeof(v) == "RBXScriptConnection" then
			v:Disconnect()
		end
	end
end

-------------------------------- @Binder --------------------------------
--[=[
	@within StructureBinder
	@param tb table The new table to replace existing data

	Replaces the current table data with a new table, clearing existing bindings.
]=]
function Structure:Set(tb: {})
	for k, _ in table.clone(self._tb) do
		self[k] = nil
	end
	for k, v in tb do
		self[k] = v
	end
end

------------------------------- @Reader --------------------------------
-- fire changed raw data
function Structure:_fireChanged(k: any, v: any)
	for _, callback in self._callback do
		task.spawn(callback, k, v)
	end
	if v == nil then
		for _, callback in self._desCallback do
			task.spawn(callback, k)
		end
	else
		for _, callback in self._newCallback do
			task.spawn(callback, k)
		end
	end

	-- fire change revert along parent
	local _parent = rawget(self, "_parent")
	if _parent then
		local _key = rawget(self, "_key")
		_parent:_fireChanged(_key or self._config.Name, self._tb)
	end
end

--[=[
	@within StructureReader
	@param callback CallbackFnc

	Register a callback function to be called when the structure changes.
]=]
function Structure:OnChange(callback: CallbackFnc)
	table.insert(self._callback, callback)
end

--[=[
	@within StructureReader
	@param onNew CallbackFnc?
	@param onDes CallbackFnc?

	Register callbacks for new and destroyed keys in the structure.
]=]
function Structure:Observe(onNew: AddOrDesCallback?, onDes: AddOrDesCallback?)
	if onNew then
		table.insert(self._newCallback, onNew)
	end
	if onDes then
		table.insert(self._desCallback, onDes)
	end
end

--[=[
	@within StructureReader
	@param key string
	@param callback ValueCallbackFnc

	Observe a specific key in the structure and call the callback with its value when it changes.
]=]
function Structure:ObserveKey(key: string, callback: ValueCallbackFnc)
	self:OnChange(function(k, value)
		if k == key then
			callback(value)
		end
	end)
	task.defer(function()
		if type(self[key]) == "table" then
			callback(self[key]:Raw())
		else
			callback(self[key])
		end
	end)
end

--[=[
	@within StructureReader
	@param callback CallbackFnc

	Register a callback function to be called for each key-value pair in the structure.
]=]
function Structure:OnPairs(callback: CallbackFnc)
	table.insert(self._callback, callback)
	for k, v in self._tb do
		task.spawn(callback, k, v)
	end
end

--[=[
	@within StructureReader
	@return table

	get raw table
]=]
function Structure:Raw(): {}
	return self._tb
end

--[=[
	@within StructureReader
	@param k string
	@return any

	wait for key
]=]
function Structure:Wait(k: string): any | Structure
	local s = tick()
	while not self[k] do
		task.wait(0.1)
		if tick() - s > 30 then
			error("StructureReader wait error with key: ", k)
		end
	end
	return self[k]
end

--#endregion

--#region @StructureBinder

--[=[
	@class StructureBinder@1.0.0

	@within Structure @server

	Provides a way to bind a table to a `Configuration` instance, allowing for deep binding of nested tables.
]=]
StructureBinder.__index = StructureBinder

StructureBinder.__index = function(self, k: any)
	return StructureBinder[k] or self._bind[k] or self._tb[k]
end

StructureBinder.__newindex = function(self, k: any, v: any)
	local old = self._config:FindFirstChild(tostring(k))

	if old and v == nil then
		old:Destroy()
		self._tb[k] = nil
		return
	end

	-- deep bind table
	if type(v) == "table" then
		local deepLevel = self._deepLevel - 1
		if deepLevel <= 0 then
			return
		end

		local bind = self._bind[k]
		-- create of not have old
		if not old then
			old = Instance.new("Configuration")
			old.Name = k
			old.Parent = self._config
			bind = Structure.binder(v, old, deepLevel, getmetatable(self))
			self._bind[k] = bind
		elseif bind then
			-- remove dont have in new value
			for k2, _ in table.clone(bind._tb) do
				if not v[k2] then
					bind[k2] = nil
				end
			end

			for k2, v2 in v do
				bind[k2] = v2
			end
		end
	else
		if old or not pcall(self._config.SetAttribute, self._config, k, v) then
			-- use InstanceValue instead
			if not old then
				old = Instance.new(CastValueType(v))
				old.Name = k
				old.Value = v
				old.Parent = self._config
			end
			old.Value = v
		end
	end
	self._tb[k] = v
end

--#endregion

--#region @ValueStructureBinder

--[=[
	@class ValueStructureBinder@1.0.0

	@within StructureBinder @server

	Provides a way to bind Table data to a `Configuration` and `Value` instance as key-value pairs.
	Value as Key contain a ValueInstance as Value
	Or Configuration as Name Values for table data deep binding.
]=]
ValueStructureBinder.__index = ValueStructureBinder

ValueStructureBinder.__index = function(self, k: any)
	return ValueStructureBinder[k] or self._bind[k] or self._tb[k]
end
ValueStructureBinder.__newindex = function(self, k: any, v: any)
	local keyIns = self._keys[k]

	if v == nil then
		-- remove if nil
		if keyIns then
			keyIns:Destroy()
		end
	else
		-- create key Instance if not exist
		if not keyIns then
			keyIns = Instance.new(CastValueType(k))
			keyIns.Name = tostring(k)
			keyIns.Value = k
			self._keys[k] = keyIns
			keyIns.Parent = self._config
		end

		-- deep bind value
		if type(v) == "table" then
			local deepLevel = self._deepLevel - 1
			if deepLevel <= 0 then
				return
			end

			local bind = self._bind[k]

			-- create new Configuration for table deep binding
			if not bind then
				local config = Instance.new("Configuration")
				config.Name = "Values"
				config.Parent = keyIns
				bind = Structure.binder(v, config, deepLevel, getmetatable(self))
				self._bind[k] = bind
			else
				-- remove nil value and update existing values
				for k2, _ in table.clone(bind._tb) do
					if not v[k2] then
						bind[k2] = nil
					end
				end
				for k2, v2 in v do
					bind[k2] = v2
				end
			end

			-- overwrite value
			for k2, v2 in table.clone(bind._tb) do
				if not v[k2] then
					bind[k2] = nil
				end
			end
		else
			local valueIns = keyIns:FindFirstChild("Value")
			local valueType = CastValueType(v)
			if valueIns and valueIns.ClassName ~= valueType then
				-- remove old value if type not match
				valueIns:Destroy()
				valueIns = nil
			end
			-- try set value as attribute, else use InstanceValue
			if not pcall(self._config.SetAttribute, keyIns, "Value", v) then
				-- use InstanceValue instead
				if not valueIns then
					valueIns = Instance.new(valueType)
					valueIns.Name = "Value"
					valueIns.Parent = keyIns
				end
				valueIns.Value = v
			end
		end
	end
	self._tb[k] = v
end

--#endregion

--#region @StructureReader

--[=[
	@class StructureReader@1.0.0

	@within StructureBinder @client

	Provides a way to read structured data from a `Configuration` instance, allowing for observation of changes.
]=]
StructureReader.__index = StructureReader

StructureReader.__index = function(self, k)
	return StructureReader[k] or self._tb[k]
end

--[=[
	@within StructureReader @private

	Observe changes inside `Configuration` instance and fire change data and create nested StructureReaders deeply.
]=]
function StructureBinder:_observe()
	local deepLevel = self._deepLevel - 1
	local config = self._config

	config.Destroying:Once(function()
		for _, cn in self._connections do
			cn:Disconnect()
		end
	end)

	-- first read all existing attributes, no fire change data
	for k, v in config:GetAttributes() do
		k = tonumber(k) or k
		self._tb[k] = v
	end

	-- first read all existing key-value pairs, no fire change data
	-- observe deep if deepLevel > 0
	for _, child in config:GetChildren() do
		local k = tonumber(child.Name) or child.Name
		if child:IsA("Configuration") then
			local reader = Structure.reader(child, nil, getmetatable(self))
			rawset(reader, "_parent", self)
			self._tb[k] = reader
		else
			self._tb[k] = child.Value
			if deepLevel > 0 then
				table.insert(
					self._connections,
					child:GetPropertyChangedSignal("Value"):Connect(function()
						self._tb[k] = child.Value
						self:_fireChanged(k, child.Value)
					end)
				)
			end
		end
	end

	-- deep binder
	if deepLevel <= 0 then
		return
	end

	-- connect to read and fire change data
	table.insert(
		self._connections,
		config.AttributeChanged:Connect(function(attr)
			attr = tonumber(attr) or attr
			local v = config:GetAttribute(attr)
			self._tb[attr] = v
			self:_fireChanged(attr, v)
		end)
	)
	table.insert(
		self._connections,
		config.ChildAdded:Connect(function(child: Configuration)
			local k = tonumber(child.Name) or child.Name
			if child:IsA("Configuration") then
				local reader = Structure.reader(child, nil, getmetatable(self))
				rawset(reader, "_parent", self)
				self._tb[k] = reader
				self:_fireChanged(k, reader._tb)
			else
				-- InstanceValue
				self._tb[k] = child.Value
				table.insert(
					self._connections,
					child:GetPropertyChangedSignal("Value"):Connect(function()
						self._tb[k] = child.Value
						self:_fireChanged(k, child.Value)
					end)
				)
				self:_fireChanged(k, child.Value)
			end
		end)
	)
	table.insert(
		self._connections,
		config.ChildRemoved:Connect(function(child: Configuration)
			local k = tonumber(child.Name) or child.Name
			self._tb[k] = nil
			self:_fireChanged(k, nil)
		end)
	)
end

--#endregion

--#region @ValueStructureReader

--[=[
	@class ValueStructureReader@1.0.0

	@within StructureBinder @client

	Provides a way to read structured data from a `Configuration` instance, allowing for observation of changes.
	Base on key-value pairs where key is a ValueInstance and value is a Configuration.
	And Configuration as Name Values for table data deep binding.
]=]
ValueStructureReader.__index = ValueStructureReader

ValueStructureReader.__index = function(self, k)
	return ValueStructureReader[k] or self._tb[k]
end

--[=[
	@within StructureReader @private

	Observe changes inside `Configuration` instance and fire change data and create nested StructureReaders deeply.
]=]
function ValueStructureReader:_observe()
	local deepLevel = self._deepLevel - 1
	local config = self._config

	config.Destroying:Once(function()
		for _, cn in self._connections do
			cn:Disconnect()
		end
	end)

	-- first read all existing key-value pairs, no fire change data
	for _, keyVal: ValueBase in config:GetChildren() do
		local k = keyVal.Value
		local values = keyVal:FindFirstChild("Values")
		local vVal = keyVal:FindFirstChild("Value")

		-- deep table
		if values then
			-- create nested StructureReader
			local reader = Structure.reader(values, deepLevel, getmetatable(self))
			rawset(reader, "_parent", self)
			rawset(reader, "_key", k)
			self._tb[k] = reader
		else
			-- single value
			self._tb[k] = keyVal:GetAttribute("Value") or vVal.Value
		end
	end

	-- deep observe
	if deepLevel <= 0 then
		return
	end

	-- key-value pairs instance observe -- new or remove
	table.insert(
		self._connections,
		config.ChildAdded:Connect(function(keyVal: ValueBase)
			local k = keyVal.Value
			local vVal = keyVal:FindFirstChild("Value")
			local values = keyVal:FindFirstChild("Values")
			local cns = self._connections[keyVal]
			if not cns then
				cns = {
					_cns = {},
					Disconnect = function(_cns)
						for _, cn in _cns._cns do
							cn:Disconnect()
						end
					end,
				}
				self._connections[keyVal] = cns

				-- value or values observe
				table.insert(
					cns._cns,
					keyVal.ChildAdded:Connect(function(child: ValueBase | Configuration)
						if child:IsA("Configuration") then
							-- nested StructureReader
							local reader = Structure.reader(child, deepLevel, getmetatable(self))
							rawset(reader, "_parent", self)
							rawset(reader, "_key", k)
							self._tb[k] = reader
							self:_fireChanged(k, reader._tb)
						elseif child:IsA("ValueBase") then
							-- InstanceValue
							self._tb[k] = child.Value
							self:_fireChanged(k, child.Value)
							cns._cns[child] = child:GetPropertyChangedSignal("Value"):Connect(function()
								self._tb[k] = child.Value
								self:_fireChanged(k, child.Value)
							end)
						end
					end)
				)

				table.insert(
					cns._cns,
					keyVal.ChildRemoved:Connect(function(child: ValueBase | Configuration)
						if child:IsA("Configuration") then
							self._tb[k] = nil
							self:_fireChanged(k, nil)
						elseif child:IsA("ValueBase") then
							self._tb[k] = nil
							self:_fireChanged(k, nil)
							if cns._cns[child] then
								cns._cns[child]:Disconnect()
								cns._cns[child] = nil
							end
						end
					end)
				)
			end

			-- first observe
			if values then
				-- create nested StructureReader
				local reader = Structure.reader(values, deepLevel, getmetatable(self))
				rawset(reader, "_parent", self)
				rawset(reader, "_key", k)
				self._tb[k] = reader
				self:_fireChanged(k, reader._tb)
			else
				-- InstanceValue
				local v = keyVal:GetAttribute("Value") or vVal.Value
				self._tb[k] = v
				self:_fireChanged(k, v)
				if not vVal then
					return
				end
				if cns._cns[vVal] then
					cns._cns[vVal]:Disconnect()
				end
				cns._cns[vVal] = vVal:GetPropertyChangedSignal("Value"):Connect(function()
					self._tb[k] = vVal.Value
					self:_fireChanged(k, vVal.Value)
				end)
			end
		end)
	)
	table.insert(
		self._connections,
		config.ChildRemoved:Connect(function(keyVal: ValueBase)
			local k = keyVal.Value
			self._tb[k] = nil
			self:_fireChanged(k, nil)
			if self._connections[keyVal] then
				self._connections[keyVal]:Disconnect()
			end
		end)
	)
end

--#endregion

--#region @constructor

--[=[
	@within Structure
	@param dataTable table The table to bind
	@param config Configuration The configuration instance to bind to
	@param deepLevel number? Maximum depth for nested tables
	@return table StructureBinder

	Create a new StructureBinder instance that binds a table to a Configuration instance.
]=]
function Structure.binder(dataTable: {}, config: Configuration, deepLevel: number, meta: StructureBinder)
	deepLevel = deepLevel or 100
	local self = setmetatable({
		_tb = dataTable,
		_config = config,
		_deepLevel = deepLevel,
		_bind = {},
		_keys = {},
	}, meta or StructureBinder)

	for k, v in dataTable do
		self[k] = v
	end

	return self
end

--[=[
	@within StructureBinder
	@param dataTable table The table to bind
	@param config Configuration The configuration instance to bind to
	@param skeleton table The skeleton structure to follow
	@param deepLevel number? Maximum depth for nested tables
	@return table StructureBinder

	Bind a table to a skeleton structure, creating nested StructureBinders for each table in the skeleton.
]=]
function Structure.fromSkeleton(
	dataTable: {},
	config: Configuration,
	skeleton: {},
	deepLevel: number?,
	meta: StructureBinder?
)
	deepLevel = skeleton.deepLevel or 100
	local self = setmetatable({
		_tb = dataTable,
		_config = config,
		_deepLevel = deepLevel,
		_bind = {},
		_keys = {},
	}, meta or StructureBinder)

	-- set value base from skeleton
	assert(type(skeleton) == "table", "Skeleton must be a table, got: " .. typeof(skeleton))
	for k, v in skeleton do
		if type(v) == "table" then
			local vconfig = Instance.new("Configuration")
			vconfig.Name = k

			local bind = StructureBinder.fromSkeleton(dataTable[k], vconfig, v, deepLevel - 1)
			self._bind[k] = bind
			vconfig.Parent = self._config
		else
			-- basic set with other type
			self[k] = dataTable[k]
		end
	end
	return self
end

--[=[
	@within Structure
	@param config Configuration Instance
	@param deepLevel number? Depth for recursion
	@return table StructureReader

	Create a new StructureReader instance that reads data from a Configuration instance.
]=]
function Structure.reader(config: Configuration, deepLevel: number, meta: StructureReader?)
	deepLevel = deepLevel or 100
	local self = setmetatable({
		_config = config,
		_connections = {},
		_tb = {},
		_callback = {},
		_bind = {},
		_newCallback = {},
		_desCallback = {},
		_keys = {},
		_deepLevel = deepLevel,
	}, meta or StructureReader)

	self:_observe()

	return self
end

--[=[
	@within Structure @server @client
	@param dataTable table The table to bind
	@param config Configuration The configuration instance to bind to
	@param skeleton table The skeleton structure to follow
	@param deepLevel number? Maximum depth for nested tables
	@return table StructureBinder | StructureReader

	Create a bridger that either binds a table to a Configuration instance on the server or reads structured data on the client.
]=]
function Structure.bridger(dataTable: {}, config: Configuration, skeleton: {}, deepLevel: number?)
	if IsServer then
		return Structure.fromSkeleton(dataTable, config, skeleton, deepLevel)
	else
		return Structure.reader(config, deepLevel)
	end
end
--#region @constructor

return Structure
