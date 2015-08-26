
module("Trigger", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Asset")
require("src/AudioManager")

require("src/Data")
--require("src/World")

local TriggerState = Trigger.GenericState

-- class Switch

local Switch = {}
Switch.__index = Switch

function Switch:__init(world, trd)
	Util.tcheck(trd.props, "table")
	Util.tcheck(trd.props[1], "number") -- start color
	Data.assert_is_color(trd.props[1])

	self.data = trd
	self.props = self.data.props
	self.props.start_color = self.props[1]

	self:reset()
end

function Switch:reset()
	-- NB: World state should be reset if this is called, so we don't
	-- have to reset the tile
	self.state = TriggerState.Active
	self.sound = '1'
	self.color = self.props.start_color
end

function Switch:set_active(enable)
	self.state = Util.ternary(
		enable,
		TriggerState.Active,
		TriggerState.Inactive
	)
end

function Switch:is_active()
	return TriggerState.Inactive ~= self.state
end

function Switch:activate(world)
	Util.debug_sub(State.trg_debug,
		"Switch:activate: ", self.data.name
	)
	AudioManager.spawn(Asset.sound["trigger_switch_activate_"..self.sound])
	self.sound = Util.ternary('1' == self.sound, '2', '1')
	local tc = self.color
	self.color = World.tile(self.data.tx, self.data.ty)
	World.color_player(tc, true)
	Trigger.__trg_callback(world, self)
	return self:is_active()
end

function Switch:entered(_)
	return self:is_active()
end

function Switch:update(_, dt, px,py)
	return self:is_active()
end

function Switch:render(_, px, py)
	local c = Util.ternary(
		self:is_active(),
		self.color, Data.Color.Black
	)
	-- TODO: render lined diamond
	Data.render_tile_inner(
		c,
		self.data.tx, self.data.ty,
		true
	)
end

function new_switch(world, trd)
	return Util.new_object(Switch, world, trd)
end
