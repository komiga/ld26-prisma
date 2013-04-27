
module("Data", package.seeall)

require("src/Util")

TW, TH=32, 32
HW, HH=16, 16

Type={
	Generic=1,
	Sink=2
}

TriggerType={
	Message=1,
	ChangeWorld=2
}

Color={
	Black=1,
	White=2,

	Red=3,
	Green=4,
	Blue=5,

-- TODO: More mixes; basic mixes
	Yellow=6,
	Magenta=7
}

ColorTable={
	{0,0,0}, -- Black
	{255,255,255}, -- White

	{255,0,0}, -- Red
	{0,255,0}, -- Green
	{0,0,255}, -- Blue

-- TODO: PICK 'EM
	{255,0,255}, -- Yellow
	{255,0,255}  -- Magenta
}

ColorAccept={
	[Color.Black]={},
	[Color.White]={
		false, true, true, true, true, true, true
	},
	[Color.Red]={[Color.Red]=true},
	[Color.Green]={[Color.Green]=true},
	[Color.Blue]={[Color.Blue]=true},
	[Color.Yellow]={[Color.Yellow]=true},
	[Color.Magenta]={[Color.Magenta]=true}
}

function init_data(width, height, color, spawn_x, spawn_y, spawn_color)
	local wd={
		size={width, height},
		spawn_pos={spawn_x, spawn_y},
		spawn_color=spawn_color,
		triggers={}
	}
	for y=1, height do
		wd[y]={}
		for x=1, width do
			wd[y][x]={Data.Type.Generic, color}
		end
	end
	return wd
end

-- Check if a color can accept another color (e.g., a sentient of
-- color b can be placed on a tile of color a)
function AC(a, b)
	return Data.ColorAccept[a][b] or false
end

---- Tiles & data

-- Get tile
function G(wd, x, y)
	return wd[y][x]
end

-- Get tile type
function GT(wd, x, y)
	return wd[y][x][1]
end

-- Get tile color
function GC(wd, x, y)
	return wd[y][x][2]
end

-- Get spawn position
function G_SP(wd)
	return wd.spawn_pos[1], wd.spawn_pos[2]
end

function G_SPX(wd)
	return wd.spawn_pos[1]
end
function G_SPY(wd)
	return wd.spawn_pos[2]
end

-- Set tile
function ST(wd, tx,ty, color, type)
	local t=wd[ty][tx]
	type=Util.optional(type, Data.Type.Generic)
	if not t then
		t={type, color}
		wd[ty][tx]=t
	else
		t[1]=type
		t[2]=color
	end
end

-- Set tile range (b, d)
function SR(wd, b, d, o, horiz, color, type)
	type=Util.optional(type, Data.Type.Generic)
	local x, y=o, o
	if horiz then
		for x=b, d do
			wd[y][x][1]=type
			wd[y][x][2]=color
		end
	else
		for y=b, d do
			wd[y][x][1]=type
			wd[y][x][2]=color
		end
	end
end

-- Set tile range (b, b+a)
function SRR(wd, b, a, o, horiz, color, type)
	Data.SR(wd, b, b+a, o, horiz, color, type)
end

-- Set tile rect
function SA(wd, x1,y1, x2,y2, color, type)
	type=Util.optional(type, Data.Type.Generic)
	for y=y1, y2 do
		for x=x1, x2 do
			wd[y][x][1]=type
			wd[y][x][2]=color
		end
	end
end

---- Triggers

-- Make trigger
function M_TR(wd, tx,ty, tt, td)
	table.insert(wd.triggers, {
		type=tt,
		tx=tx, ty=ty,
		props=td
	})
end

---- Rendering

-- Get render position for tile coords
function tile_rpos(tx, ty)
	return (tx-1)*Data.TW, (ty-1)*Data.TH
end

-- Render tile to position
function render_tile_abs(color, rx,ry, lined)
	Util.set_color_table(Data.ColorTable[color])
	Gfx.rectangle("fill", rx,ry, Data.TW,Data.TH)
	if lined then
		Util.set_color_table(
			Data.ColorTable[
			Util.ternary(
				Data.Color.Black==color,
				Data.Color.White,
				Data.Color.Black
			)],
			255
		)
		Gfx.rectangle("line", rx,ry, Data.TW,Data.TH)
	end
end

-- Render tile to tile coords
function render_tile(color, tx,ty, lined)
	render_tile_abs(color, (tx-1)*Data.TW, (ty-1)*Data.TH, lined)
end
