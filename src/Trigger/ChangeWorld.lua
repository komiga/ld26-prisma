
module("Trigger", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Asset")
require("src/AudioManager")

--require("src/World")

local TriggerState = Trigger.GenericState

-- class ChangeWorld

local ChangeWorld = {}
ChangeWorld.__index = ChangeWorld

function ChangeWorld:__init(world, trd)
	Util.tcheck(trd.props, "table")
	Util.tcheck(trd.props[1], "string")

	self.data = trd
	self.props = self.data.props
	self.props.world_id = self.props[1]
	self.props.world_name = Data.world_name(self.props.world_id)

	Util.debug_sub(State.trg_debug,
		"ChangeWorld:__init: name: ", self.props.world_name
	)
	assert(nil ~= Asset.world[self.props.world_id])

	self:reset()
end

function ChangeWorld:reset()
	self.state = TriggerState.Active
end

function ChangeWorld:set_active(enable)
	self.state = Util.ternary(
		enable,
		TriggerState.Active,
		TriggerState.Inactive
	)
end

function ChangeWorld:is_active()
	return TriggerState.Inactive ~= self.state
end

function ChangeWorld:activate(world)
	Util.debug_sub(State.trg_debug,
		"ChangeWorld:activate: "..self.props.world_name
	)
	World.set_world(Asset.world[self.props.world_id])
	Bind.clear_active()
	State.change_world_lock = true
	Trigger.__trg_callback(world, self)
	return self:is_active()
end

function ChangeWorld:entered(world)
	if self:is_active() then
		self:activate(world)
	end
	return self:is_active()
end

function ChangeWorld:update(_, dt, px,py)
	return self:is_active()
end

function ChangeWorld:render(_, px,py)
	Data.render_tile_inner_triangle(
		Data.Color.Black,
		self.data.tx, self.data.ty,
		true,
		Data.Color.Black
	)
end

function new_change_world(world, trd)
	return Util.new_object(ChangeWorld, world, trd)
end
