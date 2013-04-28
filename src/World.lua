
module("World", package.seeall)

require("src/Util")
require("src/Asset")
require("src/AudioManager")

require("src/State")
require("src/Data")
require("src/Trigger")
require("src/Player")
require("src/Camera")

-- class World

local Unit={}
Unit.__index=Unit

function Unit:__init(shell_data)
	Util.tcheck(shell_data, "table")

	self.shell_data=shell_data
	Data.load_data(self.shell_data)

	self.data=self.shell_data.__data
	self.state={}
	self.triggers={}
	for _, trd in pairs(self.data.triggers) do
		table.insert(self.triggers, Trigger.new(trd))
	end

	assert(self:in_bounds(Data.G_SP(self.data)))
	assert(Data.AC(
		Data.GC(self.data, Data.G_SP(self.data)),
		self.data.spawn_color
	))

	self.__initializing=true
	self:reset()
end

function Unit:reset()
	for y=1, self.data.h do
		self.state[y]={}
	end

	if not self.__initializing then
		for _, trg in pairs(self.triggers) do
			trg:reset()
		end
		--Presenter.stop()
	end

	local sx,sy=Data.G_SP(self.data)
	Player.reset(self.data.spawn_color, sx, sy)
	self:position_player(sx, sy, false)
	AudioManager.spawn(Asset.sound.player_spawn)
	self.__initializing=false
end

function Unit:in_bounds(tx,ty)
	return
		(self.data.w>=tx and 1<=tx) and
		(self.data.h>=ty and 1<=ty)
end

function Unit:tile(tx,ty)
	local t=self.state[ty][tx]
	return (nil~=t) and t or self.data.tiles[ty][tx]
end

function Unit:update(dt)
	Player.update(dt)
	--Util.debug("World.Unit:update: queued?:", Player.has_activation_queued())
	local px, py=Player.get_x(), Player.get_y()
	for _, trg in pairs(self.triggers) do
		local active=trg:update(dt, px, py)
		if active and px==trg.data.tx and py==trg.data.ty then
			if Player.has_activation_queued() then
				trg:activate()
			end
		end
	end
	Player.remove_activation_queue()
end

function Unit:render()
	-- TODO: Camera-based culling. chunks? mm, virtual chunks, okay
	local rx, ry=0, 0
	for y=1, self.data.h do
		rx=0
		for x=1, self.data.w do
			local c=self:tile(x, y)
			Data.render_tile_abs(
				c, rx,ry, false
			)
			if State.gfx_debug then
				Util.set_color_table(
					Util.ternary(
						Data.Color.Magenta==c,
						Data.ColorTable.Aqua, Data.ColorTable.Magenta
					),
					255
				)
				Gfx.rectangle("line", rx,ry, Data.TW,Data.TH)
			end
			rx=rx+Data.TW
		end
		ry=ry+Data.TH
	end

	Player.render()
	local px, py=Player.get_x(), Player.get_y()
	for _, trg in pairs(self.triggers) do
		trg:render(dt, px, py)
	end
end

function Unit:color_tile(tx,ty, color)
	local px, py=Player.get_x(), Player.get_y()
	if px==tx and py==ty then
		assert(Data.AC(
			self:tile(px,py),
			color
		))
	end
	self.state[ty][tx]=color
end

function Unit:color_player(color, colorize_tile)
	local px, py=Player.get_x(), Player.get_y()
	if not colorize_tile then
		assert(Data.AC(
			self:tile(px,py),
			color
		))
	else
		self.state[py][px]=color
	end
	Player.set_color(color)
end

function Unit:position_player(nx,ny, camera_immediate)
	if
		self:in_bounds(nx,ny) and
		Data.AC(
			self:tile(nx,ny),
			Player.get_color()
		)
	then
		Player.set_position(nx,ny)
		if camera_immediate then
			local rx,ry=Data.tile_rpos(nx,ny)
			Camera.set_position(rx+Data.HW,ry+Data.HH)
		end
		for _, trg in pairs(self.triggers) do
			if nx==trg.data.tx and ny==trg.data.ty then
				trg:entered(nx,ny)
			end
		end
		return true
	end
	return false
end

function Unit:move_player(dir)
	local nx
		=Player.get_x()+
		((Player.Dir.Left==dir)  and -1 or
		((Player.Dir.Right==dir) and  1 or 0))
	local ny
		=Player.get_y()+
		((Player.Dir.Up==dir)   and -1 or
		((Player.Dir.Down==dir) and  1 or 0))
	if self:position_player(nx,ny, false) then
		AudioManager.spawn(Asset.sound.player_move)
		return true
	else
		return false
	end
end

-- World interface

local data={
	__initialized=false,
	cache=nil,
	current=nil
}

function init(world_table, default_sd)
	Util.tcheck(world_table, "table")
	assert(not data.__initialized)

	data.cache={}
	set_world(default_sd)

	data.__initialized=true
end

function current()
	return data.current
end

function current_data()
	return data.current.data
end

function get_world(shell_data)
	return data.cache[shell_data]
end

function reset()
	data.current:reset()
end

function tile(tx,ty)
	return data.current:tile(tx,ty)
end

function color_tile(tx,ty, color)
	data.current:color_tile(tx,ty, color)
end

function color_player(color, colorize_tile)
	data.current:color_player(color, colorize_tile)
end

function move_player(dir)
	data.current:move_player(dir)
end

function set_world(shell_data)
	if nil~=data.current and shell_data==data.current.shell_data then
		Util.debug("World.set_world: already current")
		return data.current
	else
		local wrl=get_world(shell_data)
		if nil==wrl then
			wrl=Util.new_object(Unit, shell_data)
			data.cache[shell_data]=wrl
		else
			wrl:reset()
		end
		data.current=wrl
		return wrl
	end
end
