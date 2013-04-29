
module("Trigger", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Asset")
require("src/AudioManager")

require("src/Data")
--require("src/Player")
--require("src/World")

local TriggerState=Trigger.GenericState

-- class Sink

local Sink={}
Sink.__index=Sink

function Sink:__init(world, trd)
	Util.tcheck(trd.props, "table")
	Util.tcheck(trd.props[1], "number") -- start color
	Util.tcheck(trd.props[2], "number") -- activation color
	Util.tcheck(trd.props[3], "table") -- table of circuit lines
	Data.assert_is_color(trd.props[1])
	Data.assert_is_color(trd.props[2])

	self.data=trd
	self.props=self.data.props
	self.props.start_color=self.props[1]
	self.props.activation_color=self.props[2]
	self.props.circuit=self.props[3]

	self:reset()
end

function Sink:reset()
	self.state=TriggerState.Active
	self.color=self.props.start_color
end

function Sink:set_active(enable)
	self.state=Util.ternary(
		enable,
		TriggerState.Active,
		TriggerState.Inactive
	)
end

function Sink:is_active()
	return TriggerState.Inactive~=self.state
end

function Sink:is_complete()
	return self.props.activation_color==self.color
end

function Sink:activate(world)
	Util.debug_sub(State.trg_debug, "Sink:activate")
	--AudioManager.spawn(Asset.sound.trigger_sink_activate)
	local pc=Player.get_color()
	local ac=Data.ColorAddResult[self.color][pc]
	if nil~=ac then
		self.color=ac
	end
	Util.debug_sub(State.trg_debug, "Sink:activate: color:", self.color)
	Trigger.__trg_callback(world, self)
	return self:is_active()
end

function Sink:entered(_)
	return self:is_active()
end

function Sink:update(_, dt, px,py)
	return self:is_active()
end

function Sink:render(_, px, py)
	-- TODO: render triangle
	Data.render_tile_inner(
		self.color,
		self.data.tx, self.data.ty,
		true
	)
	-- TODO: handle branch from data.tx,data.ty
	Util.set_color_table(Data.ColorTable[self.color], 255)
	local x1,y1, x2,y2
	for _, circ in pairs(self.props.circuit) do
		x1,y1=Data.tile_rpos(circ[2],circ[3])
		if Data.Axis.X==circ[1] then
			x2=(circ[4]-1)*Data.TW
			y2=y1
		else
			x2=x1
			y2=(circ[4]-1)*Data.TH
		end
		Gfx.rectangle("fill",
			x1+Data.TIW, y1+Data.LIH,
			(x2-x1)+Data.TIW, (y2-y1)+Data.TIH
		)
	end
end

function new_sink(world, trd)
	return Util.new_object(Sink, world, trd)
end
