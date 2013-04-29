
module("Trigger", package.seeall)

require("src/Util")
require("src/Asset")
require("src/AudioManager")

require("src/Data")
require("src/Presenter")
--require("src/World")

local TriggerState=Trigger.GenericState

-- class Message

local Message={}
Message.__index=Message

function Message:__init(world, trd)
	Util.tcheck(trd.props, "table")
	Util.tcheck(trd.props[1], "string")
	Util.tcheck(trd.props.starter, "boolean", true)

	self.data=trd
	self.props=self.data.props
	self.props.message=self.props[1]

	self.viewed=not self.props.starter
	self:reset()
end

function Message:reset()
	--self.viewed=false
end

function Message:set_active(enable)
	self.state=Util.ternary(
		enable,
		TriggerState.Active,
		TriggerState.Inactive
	)
end

function Message:is_active()
	return TriggerState.Inactive~=self.state
end

function Message:activate(world)
	if self:is_active() then
		Util.debug_sub(State.trg_debug,
		"Trigger.Message:activate: "..self.props.message
	)
		if Trigger.__trg_callback(world, self, true) then
			Bind.clear_active()
			Presenter.start(self.props.message, true)
		end
	end
	return self:is_active()
end

function Message:entered(world)
	if self:is_active() and not self.viewed then
		Util.debug_sub(State.trg_debug,
			"Trigger.Message:entered: "..self.props.message
		)
		if Trigger.__trg_callback(world, self, false) then
			Presenter.start(self.props.message, false)
			self.viewed=true
		end
	end
	return self:is_active()
end

function Message:update(_, dt, px,py)
	return self:is_active()
end

function Message:render(_, px, py)
	-- TODO: completely black?
	if self:is_active() then
		Data.render_tile_inner(
			Data.Color.System,
			self.data.tx, self.data.ty,
			true
		)
	end
end

function new_message(world, trd)
	return Util.new_object(Message, world, trd)
end
