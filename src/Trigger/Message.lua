
module("Trigger", package.seeall)

require("src/Util")
require("src/Asset")
require("src/AudioManager")

require("src/Data")
require("src/Presenter")
--require("src/World")

local TriggerState={
	Viewed=1,
	Unviewed=2
}

-- class Message

local Message={}
Message.__index=Message

function Message:__init(trd)
	Util.tcheck(trd.props, "table")
	Util.tcheck(trd.props[1], "string")

	self.data=trd
	self.state=TriggerState.Unviewed
	self:reset()
end

function Message:reset()
	--self.state=TriggerState.Unviewed
end

function Message:is_active()
	return true
end

function Message:start_presenter(from_enter)
	Util.debug_sub(State.trg_debug,
		"Trigger.Message:start_presenter: "..self.data.props[1]
	)
	Presenter.start(self.data.props[1], not from_enter)
end

function Message:activate()
	Util.debug_sub(State.trg_debug,
		"Trigger.Message:activate: "..self.data.props[1]
	)
	self:start_presenter(false)
	return self:is_active()
end

function Message:entered()
	Util.debug_sub(State.trg_debug,
		"Trigger.Message:entered: "..self.data.props[1]
	)
	if TriggerState.Unviewed==self.state then
		if self.data.props.starter then
			self:start_presenter(true)
			self.state=TriggerState.Viewed
		end
	end
	return self:is_active()
end

function Message:update(dt, px,py)
	return self:is_active()
end

function Message:render(px, py)
	Data.render_tile_inner(
		Data.Color.System,
		self.data.tx, self.data.ty,
		true
	)
end

function new_message(trd)
	return Util.new_object(Message, trd)
end
