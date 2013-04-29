
module("Trigger", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Asset")
require("src/AudioManager")

require("src/Data")
--require("src/World")

local TriggerState=Trigger.GenericState

-- class Timer

local Timer={}
Timer.__index=Timer

function Timer:__init(world, trd)
	Util.tcheck(trd.props, "table")
	Util.tcheck(trd.props[1], "number") -- duration
	Util.tcheck(trd.props[2], "number") -- starting index
	Util.tcheck(trd.props[3], "table") -- sequence of colors
	Util.tcheck(trd.props[4], "table") -- table of zone to colorize
	Util.tcheck(trd.props.no_sound, "boolean", true) -- whether to spawn sound

	self.data=trd
	self.props=self.data.props
	self.props.duration=self.props[1]
	self.props.start_index=self.props[2]
	self.props.sequence=self.props[3]
	self.props.zones=self.props[4]

	if nil==self.props.zones or 0==#self.props.zones then
		self.props.zones={{self.data.tx,self.data.ty, 1,1}}
	end
	assert(
		#self.props.sequence>=self.props.start_index and
		0<=self.props.start_index
	)

	--self.base_color=world:tile_base(self.data.tx, self.data.ty)
	self:reset()
end

function Timer:reset()
	-- NB: World state should be reset if this is called, so we don't
	-- have to reset the tile
	self.state=TriggerState.Active
	self.index=self.props.start_index
	self.time=0.0
end

function Timer:set_active(enable)
	self.state=Util.ternary(
		enable,
		TriggerState.Active,
		TriggerState.Inactive
	)
end

function Timer:is_active()
	return TriggerState.Inactive~=self.state
end

function Timer:activate(world)
	--Trigger.__trg_callback(world, self)
	return self:is_active()
end

function Timer:entered(world)
	self:activate(world)
	return self:is_active()
end

function Timer:set_index(index, reset_time, no_sound)
	if reset_time then
		self.time=0.0
	end
	if not no_sound then
		AudioManager.spawn(
			Asset.sound.trigger_timer_activate_1,
			Data.tile_rpos(self.data.tx, self.data.ty)
		)
	end

	self.index=Util.ternary(
		#self.props.sequence<index,
		1, index
	)

	local y1,x1, y2,x2
	local c=self.props.sequence[self.index]
	for _, z in pairs(self.props.zones) do
		if not World.color_tile_zone(
			z[1]     , z[2],
			z[3] or 1, z[4] or 1,
			c, false
		) then
			Util.debug_sub(State.trg_debug, "Timer:set_index: ", self.data.name)
			-- Zone change killed player
			return
		end
	end
end

function Timer:next(reset_time, no_sound)
	self:set_index(self.index+1, reset_time, no_sound)
end

function Timer:update(_, dt, px,py)
	if self:is_active() then
		self.time=self.time+dt
		if self.props.duration<=self.time then
			self.time=self.time-self.props.duration
			self:next(false, self.props.no_sound)
		end
	end
	return self:is_active()
end

function Timer:render(_, px, py)
end

function new_timer(world, trd)
	return Util.new_object(Timer, world, trd)
end
