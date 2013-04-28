
module("Trigger", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Asset")
require("src/AudioManager")

require("src/Data")
--require("src/World")

local TriggerState=Trigger.GenericState

-- class Teleporter

local Teleporter={}
Teleporter.__index=Teleporter

function Teleporter:__init(trd)
	Util.tcheck(trd.props, "table")
	Util.tcheck(trd.props[1], "number")
	Util.tcheck(trd.props[2], "number")

	self.data=trd
	self:reset()
end

function Teleporter:reset()
	-- NB: World state should be reset if this is called, so we don't
	-- have to reset the tile
	self.state=TriggerState.Active
end

function Teleporter:set_active(enable)
	self.state=Util.ternary(
		enable,
		TriggerState.Active,
		TriggerState.Inactive
	)
end

function Teleporter:is_active()
	return true
end

function Teleporter:activate()
	Util.debug_sub(State.trg_debug, "Trigger.Teleporter:activate")
	AudioManager.spawn(Asset.sound.trigger_teleporter_activate)
	World.current():position_player(
		self.data.props[1], self.data.props[2],
		true
	)
	return self:is_active()
end

function Teleporter:entered()
	self:activate()
	return self:is_active()
end

function Teleporter:update(dt, px,py)
	return self:is_active()
end

function Teleporter:render(px, py)
	local rx,ry=Data.tile_rpos(self.data.tx, self.data.ty)
	ry=ry+Data.HH
	Util.set_color_table(Data.ColorTable.Black)
	Gfx.line(
		rx,ry, rx+Data.TW, ry
	)
end

function new_teleporter(trd)
	return Util.new_object(Teleporter, trd)
end
