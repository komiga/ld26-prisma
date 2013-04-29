
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

function Teleporter:__init(world, trd)
	Util.tcheck(trd.props, "table")
	Util.tcheck(trd.props[1], "number")
	Util.tcheck(trd.props[2], "number")

	self.data=trd
	self.props=self.data.props
	self.props.x=self.props[1]
	self.props.y=self.props[2]

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

function Teleporter:activate(world)
	if Trigger.__trg_callback(world, self) then
		Util.debug_sub(State.trg_debug, "Trigger.Teleporter:activate")
		AudioManager.spawn(Asset.sound.trigger_teleporter_activate)
		World.current():position_player(
			self.props.x, self.props.y,
			true
		)
	end
	return self:is_active()
end

function Teleporter:entered(world)
	self:activate(world)
	return self:is_active()
end

function Teleporter:update(_, dt, px,py)
	return self:is_active()
end

function Teleporter:render(_, px, py)
	local rx,ry=Data.tile_rpos(self.data.tx, self.data.ty)
	ry=ry+Data.HH
	Util.set_color_table(Data.ColorTable.Black)
	Gfx.line(
		rx,ry, rx+Data.TW, ry
	)
end

function new_teleporter(world, trd)
	return Util.new_object(Teleporter, world, trd)
end
