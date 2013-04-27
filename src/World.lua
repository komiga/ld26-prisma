
module("World", package.seeall)

require("src/Util")

require("src/State")
require("src/Data")
require("src/Trigger")
require("src/Sentient")
require("src/Player")

Dir={
	Up=1,
	Down=2,
	Left=3,
	Right=4
}

-- class World

local Unit={}
Unit.__index=Unit

function Unit:__init(wd)
	Util.tcheck(wd, "table")

	self.data=wd
	self.sentients=Sentient.new_bucket()
	self.triggers={}

	for _, trd in pairs(self.data.triggers) do
		table.insert(self.triggers, Trigger.new(trd))
	end

	assert(self:in_bounds(Data.G_SP(self.data)))
	assert(Data.AC(
		Data.GC(self.data, Data.G_SP(self.data)),
		self.data.spawn_color
	))

	self:reset()
end

function Unit:reset()
	-- TODO: state
	-- TODO: reload clean data
	for _, trg in pairs(self.triggers) do
		trg:reset()
	end

	self.sentients:clear()
	Player.reset(self.data.spawn_color)
	self:position_player(Data.G_SP(self.data))
end

function Unit:in_bounds(tx, ty)
	return
		(self.data.size[1]>=tx and 1<=tx) and
		(self.data.size[2]>=ty and 1<=ty)
end

function Unit:update(dt)
	-- TODO. Extra state for animatory things like sinks? Animated at all?
	-- Sinks need their own state anyhow. And blocks will be modified..
	-- Just reload when restarting level? Maybe override table for modified
	-- blocks, and just clear when restarting
	local px, py=Player.get_x(), Player.get_y()
	for _, trg in pairs(self.triggers) do
		trg:update(dt, px, py)
	end
	self.sentients:update(dt)
	Player.update(dt)
end

function Unit:render()
	-- TODO: Camera-based culling. chunks? mm, virtual chunks, okay
	local rx, ry=0, 0
	for y=1, self.data.size[2] do
		rx=0
		for x=1, self.data.size[1] do
			local t=self.data[y][x]
			if Data.Type.Generic==t[1] then
				Data.render_tile_abs(
					t[2], rx,ry, false
				)
			elseif Data.Type.Sink==t[1] then
				-- TODO? Should this be different from Generic?
			end
			if State.debug_mode then
				Gfx.setColor(255,0,255, 255)
				Gfx.rectangle("line", rx,ry, Data.TW,Data.TH)
			end
			rx=rx+Data.TW
		end
		ry=ry+Data.TH
	end
	self.sentients:render()
	Player.render(Data.G(self.data, Player.get_x(), Player.get_y()))
end

function Unit:position_player(nx, ny)
	if
		self:in_bounds(nx, ny) and
		Data.AC(
			Data.GC(self.data, nx, ny),
			Player.get_color()
		)
	then
		Player.set_position(nx, ny)
		return true
	end
	return false
end

function Unit:move_player(dir)
	local nx
		=Player.get_x()+
		((World.Dir.Left==dir)  and -1 or
		((World.Dir.Right==dir) and  1 or 0))
	local ny
		=Player.get_y()+
		((World.Dir.Up==dir)   and -1 or
		((World.Dir.Down==dir) and  1 or 0))
	return self:position_player(nx, ny)
end

-- World interface

local data={
	__initialized=false,
	worlds=nil,
	current=nil
}

function init(world_table, default_wd)
	Util.tcheck(world_table, "table")
	assert(not data.__initialized)

	data.worlds={}
	-- TODO: [hot-loading marker]
	for _, wd in pairs(world_table) do
		data.worlds[wd]=Util.new_object(Unit, wd)
	end
	data.current=get_world(default_wd)

	data.__initialized=true
end

function current()
	return data.current
end

function current_data()
	return data.current.data
end

function get_world(wd)
	local world=data.worlds[wd]
	assert(nil~=world)
	return world
end

function update(dt)
	data.current:update(dt)
end

function render()
	data.current:render()
end

function move_player(dir)
	data.current:move_player(dir)
end
