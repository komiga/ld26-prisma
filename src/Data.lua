
module("Data", package.seeall)

require("src/Util")

-- Tile sizes

-- Generic tile
TW, TH=32, 32
HW, HH=16, 16

-- Inner tile
TIW, TIH=8, 8
HIW, HIH=4, 4
CIW, CIH=12, 12

Axis={
	X=false,
	Y=true
}

TriggerType={
	Message=1,
	ChangeWorld=2,
	Switch=3,
	Timer=4,
	Sink=5
}

ColorCount=9
TileColorCount=8

Color={
-- Non-player colors
	Black=1,
	White=2,

-- Player colors
	Red=3,
	Green=4,
	Blue=5,

-- Combined player colors
	Aqua=6,
	Yellow=7,
	Magenta=8,

-- Special colors
	System=9
}

ColorTable={
	{0,0,0}, -- Black
	{255,255,255}, -- White

	{255,0,0}, -- Red
	{0,255,0}, -- Green
	{0,0,255}, -- Blue

	{0,255,255}, -- Aqua
	{255,255,0}, -- Yellow
	{255,0,255}, -- Magenta

	{96,0,255}	 -- System; blue-purrrrrpel
	-- {255,127,0}	 -- System; orange
}

-- Named aliases
ColorTable.Black=ColorTable[Data.Color.Black]
ColorTable.White=ColorTable[Data.Color.White]

ColorTable.Red=ColorTable[Data.Color.Red]
ColorTable.Green=ColorTable[Data.Color.Green]
ColorTable.Blue=ColorTable[Data.Color.Blue]

ColorTable.Aqua=ColorTable[Data.Color.Aqua]
ColorTable.Yellow=ColorTable[Data.Color.Yellow]
ColorTable.Magenta=ColorTable[Data.Color.Magenta]

ColorTable.System=ColorTable[Data.Color.System]

-- TODO: ColorAccept inverse

ColorAccept={
	[Color.Black]={},
	[Color.White]={
		false, true, true, true, true, true, true, true
	},

	[Color.Red]={[Color.Red]=true},
	[Color.Green]={[Color.Green]=true},
	[Color.Blue]={[Color.Blue]=true},

	[Color.Aqua]={[Color.Aqua]=true},
	[Color.Yellow]={[Color.Yellow]=true},
	[Color.Magenta]={[Color.Magenta]=true},

	[Color.System]={}
}

function assert_is_color(t)
	if "number"==type(t) then
		assert(1<=t and Data.ColorCount>=t)
	else
		for _, c in pairs(t) do
			assert(1<=c and Data.ColorCount>=c)
		end
	end
end

__iw=nil

function load_data(shell_data)
	if nil==shell_data.__image_data then
		shell_data.__image_data=love.image.newImageData(
			shell_data.__path..".png"
		)
		shell_data.__data=init_data(shell_data)
	end
	if not shell_data.loaded_dynamic then
		Data.__iw=shell_data.__data
		dofile(shell_data.__path..".wrl")
		Data.__iw=nil
		shell_data.loaded_dynamic=true
	end
end

local function rgb_match(r,g,b)
	for c, t in ipairs(Data.ColorTable) do
		if
			r==t[1] and
			g==t[2] and
			b==t[3]
		then
			return c
		end
	end
	Util.debug("Data.rgb_match: unexpected: "..r..','..g..','..b)
	assert(false)
end

function init_data(shell_data)
	local wd={
		w=shell_data.__image_data:getWidth(),
		h=shell_data.__image_data:getHeight(),
		sp_x=1, sp_y=1,
		spawn_color=spawn_color,
		loaded_dynamic=false,
		triggers={},
		tiles={}
	}
	local r,g,b
	for y=1, wd.h do
		wd.tiles[y]={}
		for x=1, wd.w do
			r,g,b=shell_data.__image_data:getPixel(x-1, y-1)
			wd.tiles[y][x]=rgb_match(r,g,b)
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
	return wd.tiles[y][x]
end

-- Get tile color
function GC(wd, x, y)
	return wd.tiles[y][x]
end

-- Get spawn position
function G_SP(wd)
	return wd.spawn_x, wd.spawn_y
end

function G_SPX(wd)
	return wd.spawn_x
end
function G_SPY(wd)
	return wd.spawn_y
end

function S_SP(wd, x,y, color)
	Data.assert_is_color(color)
	wd.spawn_x=x
	wd.spawn_y=y
	wd.spawn_color=color
end

-- Set tile
function ST(wd, tx,ty, color)
	Data.assert_is_color(color)
	assert(wd.w>=tx)
	assert(wd.h>=ty)
	wd.tiles[ty][tx]=color
end

-- Set tile range (b, d)
function SR(wd, b,d, o, axis, color)
	Data.assert_is_color(color)
	local x, y=o, o
	if Data.Axis.X==axis then
		assert(wd.h>=y)
		for x=b, d do
			assert(wd.w>=x)
			wd.tiles[y][x]=color
		end
	elseif Data.Axis.Y==axis then
		assert(wd.w>=x)
		for y=b, d do
			assert(wd.h>=y)
			wd.tiles[y][x]=color
		end
	else
		assert(false)
	end
end

-- Set tile zone
function SZ(wd, x1,y1, x2,y2, color)
	Data.assert_is_color(color)
	for y=y1, y2 do
		assert(wd.h>=y)
		for x=x1, x2 do
			assert(wd.w>=x)
			wd.tiles[y][x]=color
		end
	end
end

---- Triggers

-- Make trigger
function M_TR(wd, tx,ty, tt, td, tcolor)
	table.insert(wd.triggers, {
		type=tt,
		tx=tx, ty=ty,
		props=td
	})
	if nil~=tcolor then
		Data.ST(wd, tx,ty, tcolor)
	end
end

---- Rendering

-- Get render position for tile coords
function tile_rpos(tx, ty)
	return (tx-1)*Data.TW, (ty-1)*Data.TH
end

-- Render tile to position
function render_tile_abs(color, rx,ry, lined)
	if Color.Black~=color then
		Util.set_color_table(Data.ColorTable[color])
		Gfx.rectangle("fill", rx,ry, Data.TW,Data.TH)
		if lined then
			Util.set_color_table(Data.ColorTable.White, 255)
			Gfx.rectangle("line", rx,ry, Data.TW,Data.TH)
		end
	end
end

-- Render tile to tile coords
function render_tile(color, tx,ty, lined)
	Data.render_tile_abs(color, (tx-1)*Data.TW, (ty-1)*Data.TH, lined)
end

function render_tile_inner_abs(color, rx,ry, lined)
	Util.set_color_table(Data.ColorTable[color])
	Gfx.rectangle("fill",
		Data.CIW+rx, Data.CIH+ry,
		Data.TIW   , Data.TIH
	)
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
		Gfx.rectangle("line",
			Data.CIW+rx, Data.CIH+ry,
			Data.TIW    , Data.TIH
		)
	end
end

function render_tile_inner(color, tx,ty, lined)
	Data.render_tile_inner_abs(
		color,
		(tx-1)*Data.TW, (ty-1)*Data.TH,
		lined
	)
end
