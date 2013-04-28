
module("Trigger", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Asset")
require("src/AudioManager")

--require("src/World")

local TriggerState=Trigger.GenericState

-- class ChangeWorld

local ChangeWorld={}
ChangeWorld.__index=ChangeWorld

function ChangeWorld:__init(trd)
	Util.tcheck(trd.props, "table")
	Util.tcheck(trd.props[1], "string")

	self.data=trd
	assert(nil~=Asset.world[self.data.props[1]])

	self:reset()
end

function ChangeWorld:reset()
	self.state=TriggerState.Active
end

function ChangeWorld:activate()
	AudioManager.spawn(Asset.sound.trigger_change_world_activate)
	World.set_world(Asset.world[self.data.props[1]])
	Bind.clear_active()
	State.change_world_lock=true
	return self:is_active()
end

function ChangeWorld:entered()
	if TriggerState.Active==self.state then
		Util.debug_sub(State.trg_debug,
			"Trigger.ChangeWorld:update: activated "..self.data.props[1]
		)
		self:activate()
	end
	return self:is_active()
end

function ChangeWorld:update(dt, px,py)
	return self:is_active()
end

function ChangeWorld:render(px,py)
	Data.render_tile_inner_circle(
		Data.Color.Black,
		self.data.tx, self.data.ty,
		true
	)
end

function ChangeWorld:is_active()
	return TriggerState.Active==self.state
end

function new_change_world(trd)
	return Util.new_object(ChangeWorld, trd)
end
