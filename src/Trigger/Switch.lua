
module("Trigger", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Asset")
require("src/AudioManager")

require("src/Data")
--require("src/World")

local TriggerState=Trigger.GenericState

-- class Switch

local Switch={}
Switch.__index=Switch

function Switch:__init(trd)
	Util.tcheck(trd.props, "table")
	Util.tcheck(trd.props[1], "number")
	Data.assert_is_color(trd.props[1])

	self.data=trd
	self:reset()
end

function Switch:reset()
	-- NB: World state should be reset if this is called, so we don't
	-- have to reset the tile
	self.state=TriggerState.Active
	self.color=self.data.props[1]
end

function Switch:is_active()
	return TriggerState.Active==self.state
end

function Switch:activate()
	Util.debug_sub(State.trg_debug, "Trigger.Switch:activate")
	AudioManager.spawn(Asset.sound.trigger_switch_activate_1)
	local tc=self.color
	self.color=World.tile(self.data.tx, self.data.ty)
	World.color_player(tc, true)
	return self:is_active()
end

function Switch:entered()
	return self:is_active()
end

function Switch:update(dt, px,py)
	return self:is_active()
end

function Switch:render(px, py)
	local c=Util.ternary(
		self:is_active(),
		self.color, Data.Color.Black
	)
	-- TODO: render lined diamond
	Data.render_tile_inner(
		self.color,
		self.data.tx, self.data.ty,
		true
	)
end

function new_switch(trd)
	return Util.new_object(Switch, trd)
end
