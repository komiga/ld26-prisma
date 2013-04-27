
module("Trigger", package.seeall)

require("src/Util")

require("src/Data")
require("src/Presenter")

local GenericState={
	Active=1,
	Inactive=2
}

-- class Message

local Message={}
Message.__index=Message

function Message:__init(trd)
	Util.tcheck(trd.props, "table")
	Util.tcheck(trd.props[1], "string")

	self.data=trd
	self:reset()
end

function Message:reset()
	self.state=GenericState.Active
end

function Message:update(dt, px,py)
if self:is_active() then
	if self.data.tx==px and self.data.ty==py then
		Util.debug(
			"Trigger.Message:update: activated: "..self.data.props[1]
		)
		Presenter.start(self.data.props[1])
		self.state=GenericState.Inactive
	end
end
	return self:is_active()
end

function Message:is_active()
	return GenericState.Active==self.state
end

-- class ChangeWorld

local ChangeWorld={}
ChangeWorld.__index=ChangeWorld

function ChangeWorld:__init(trd)
	Util.tcheck(trd.props, "table")
	Util.tcheck(trd.props[1], "string")

	self.data=trd
	self:reset()
end

function ChangeWorld:reset()
	self.state=GenericState.Active
end

function ChangeWorld:update(dt, px,py)
if self:is_active() then
	if self.data.tx==px and self.data.ty==py then
		Util.debug(
			"Trigger.ChangeWorld:update: activated "..self.data.props[1]
		)
		-- TODO
		self.state=GenericState.Inactive
	end
end
	return self:is_active()
end

function ChangeWorld:is_active()
	return GenericState.Active==self.state
end

-- Trigger interface

local data={
	__initialized=false
}

local TriggerInstantiator={
	[Data.TriggerType.Message]=
	function(trd)
		return Util.new_object(Message, trd)
	end,

	[Data.TriggerType.ChangeWorld]=
	function(trd)
		return Util.new_object(ChangeWorld, trd)
	end
}

function new(trd)
	Util.tcheck(trd, "table")
	Util.tcheck(trd.type, "number")
	Util.tcheck(trd.tx, "number")
	Util.tcheck(trd.ty, "number")

	return TriggerInstantiator[trd.type](trd)
end

function init()
	assert(not data.__initialized)
	data.__initialized=true
end
