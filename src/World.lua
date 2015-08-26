
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

local Unit = {}
Unit.__index = Unit

function Unit:__init(shell_data)
	Util.tcheck(shell_data, "table")

	self.__initializing = true

	self.shell_data = shell_data
	Data.load_data(self.shell_data)

	self.data = self.shell_data.__data
	self.state = {}
	for y = 1, self.data.h do
		self.state[y] = {}
	end

	self.triggers = {}
	self.triggers_by_name = {}
	for _, trd in pairs(self.data.triggers) do
		local trg = Trigger.new(self, trd)
		table.insert(self.triggers, trg)
		if nil ~= trd.name then
			self.triggers_by_name[trd.name] = trg
		end
	end

	assert(self:in_bounds(Data.G_SP(self.data)))
	assert(Data.AC(
		Data.GC(self.data, Data.G_SP(self.data)),
		self.data.spawn_color
	))

	self:reset(false)
end

function Unit:reset(killed)
	Util.debug("World:reset: ", killed)
	--Util.debug(debug.traceback())
	local sx,sy = Data.G_SP(self.data)
	Player.reset(self.data.spawn_color, sx,sy)
	Player.set_position(sx,sy) -- More hack!

	if not self.__initializing then
		for y = 1, self.data.h do
			self.state[y] = {}
		end
		for _, trg in pairs(self.triggers) do
			trg:reset()
		end
		--Presenter.stop()
	end

	self:position_player(sx,sy, false)
	AudioManager.spawn(Util.ternary(
		killed,
		Asset.sound.player_killed, Asset.sound.player_spawn
	))

	self.data.reset_callback(self)
	self.__initializing = false
end

function Unit:in_bounds(tx,ty)
	return
		(self.data.w >= tx and 1 <= tx) and
		(self.data.h >= ty and 1 <= ty)
end

function Unit:tile_base(tx,ty)
	return Data.GC(self.data, tx,ty)
end

function Unit:tile(tx,ty)
	return
		self.state[ty][tx] or
		Data.GC(self.data, tx,ty)
end

function Unit:update(dt)
	Player.update(dt)
	local px, py = Player.get_x(), Player.get_y()
	for _, trg in pairs(self.triggers) do
		local active = trg:update(self, dt, px, py)
		if active and px == trg.data.tx and py == trg.data.ty then
			if Player.has_activation_queued() then
				trg:activate(self)
			end
		end
	end
	Player.remove_activation_queue()
end

function Unit:render()
	local rx,ry = 0,0
	local sc
	for y = 1, self.data.h do
		rx = 0
		for x = 1, self.data.w do
		--for x, bc in pairs(self.data.tiles[y]) do
			sc = self.state[y][x] or self.data.tiles[y][x]
			--sc = self.state[y][x] or bc
			if nil ~= sc then
				--rx = (x - 1) * Data.TW
				Data.render_tile_abs(
					sc, rx,ry, false, nil
				)
				if State.gfx_debug then
					Util.set_color_table(
						Util.ternary(
							Data.Color.Magenta == sc,
							Data.ColorTable.Cyan, Data.ColorTable.Magenta
						),
						255
					)
					Gfx.rectangle("line", rx,ry, Data.TW,Data.TH)
				end
			end
			rx = rx + Data.TW
		end
		ry = ry + Data.TH
	end

	local px, py = Player.get_x(), Player.get_y()
	Player.render(self:tile(px, py))
	for _, trg in pairs(self.triggers) do
		trg:render(self, dt, px, py)
	end
end

function Unit:color_tile(tx,ty, color, no_reset)
	local px,py = Player.get_x(), Player.get_y()
	if
		px == tx and py == ty and
		not Data.AC(color, Player.get_color())
	then
		if not no_reset then
			self:reset(true)
		end
		return false
	else
		self.state[ty][tx] = color
		return true
	end
end

function Unit:color_tile_zone(x1,y1, x2,y2, color, no_reset)
	local px,py = Player.get_x(), Player.get_y()
	local x,y
	for y = y1, y2 do
		for x = x1, x2 do
			if
				px == x and py == y and
				not Data.AC(color, Player.get_color())
			then
				if not no_reset then
					self:reset(true)
				end
				return false
			else
				self.state[y][x] = color
			end
		end
	end
	return true
end

function Unit:color_player(color, colorize_tile)
	local px, py = Player.get_x(), Player.get_y()
	if not colorize_tile then
		Util.debug("color_player: ", color, self:tile(px,py))
		assert(Data.AC(
			self:tile(px,py),
			color
		))
	else
		self.state[py][px] = color
	end
	Player.set_color(color)
end

function Unit:position_player(nx,ny, camera_immediate)
	local inb = self:in_bounds(nx,ny)
	if
		inb and
		Data.AC(
			self:tile(nx,ny),
			Player.get_color()
		)
	then
		Player.set_position(nx,ny)
		if camera_immediate then
			local rx,ry = Data.tile_rpos(nx,ny)
			Camera.set_position(rx + Data.HW,ry + Data.HH)
		end
		for _, trg in pairs(self.triggers) do
			if nx == trg.data.tx and ny == trg.data.ty then
				trg:entered(self)
			end
		end
		return true
	elseif not inb and State.hardcore_mode then
		self:reset(true)
	end
	return false
end

function Unit:move_player(dir)
	local nx
		= Player.get_x() +
		((Player.Dir.Left == dir)  and -1 or
		((Player.Dir.Right == dir) and  1 or 0))
	local ny
		= Player.get_y() +
		((Player.Dir.Up == dir)   and -1 or
		((Player.Dir.Down == dir) and  1 or 0))

	if not State.hardcore_mode and not self:in_bounds(nx,ny) then
		return false
	end
	if self:position_player(nx,ny, false) then
		AudioManager.spawn(Asset.sound.player_move)
		return true
	else
		return false
	end
end

-- World interface

local data = {
	__initialized = false,
	cache = nil,
	current = nil
}

function init(world_table, default_sd)
	Util.tcheck(world_table, "table")
	assert(not data.__initialized)

	data.cache = {}
	set_world(default_sd)

	data.__initialized = true
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

function player_tile()
	return data.current:tile(Player.get_x(), Player.get_y())
end

function tile(tx,ty)
	return data.current:tile(tx,ty)
end

function color_tile(tx,ty, color)
	return data.current:color_tile(tx,ty, color)
end

function color_tile_zone(x1,y1, x2,y2, color, no_reset)
	return data.current:color_tile_zone(x1,y1, x2,y2, color, no_reset)
end

function color_player(color, colorize_tile)
	data.current:color_player(color, colorize_tile)
end

function set_world(shell_data)
	--[[if nil ~= data.current and shell_data == data.current.shell_data then
		Util.debug("World.set_world: already current")
		return data.current
	else--]]
		local wrl = get_world(shell_data)
		if nil == wrl then
			wrl = {}
			setmetatable(wrl, Unit)
			data.current = wrl
			data.cache[shell_data] = wrl
			wrl:__init(shell_data)
		else
			wrl:reset(false)
			data.current = wrl
		end
		return wrl
	--end
end
