
module("Data", package.seeall)

require("src/Util")

-- Tile sizes

-- Generic tile
TW, TH=32, 32
HW, HH=16, 16

-- Inner tile
TIW, TIH= 8, 8
HIW, HIH= 4, 4
CIW, CIH=12,12
LIW, LIH=12,12

Axis={
	X=false,
	Y=true
}

TriggerType={
	Message=1,
	ChangeWorld=2,
	Switch=3,
	Teleporter=4,
	Timer=5,
	Sink=6
}

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
	Magenta=7,
	Yellow=8,

-- Special colors
	System=9,

	WhiteInvisible=10
}

ColorCount=Data.Color.Yellow
FullColorCount=Data.WhiteInvisible

ColorTable={
	{0,0,0}, -- Black
	{255,255,255}, -- White

	{255,0,0}, -- Red
	{0,255,0}, -- Green
	{0,0,255}, -- Blue

	{0,255,255}, -- Aqua
	{255,0,255}, -- Magenta
	{255,128,0}, -- Yellow
	--{255,255,0}, -- Yellow

	{96,0,255},	 -- System; purpley
	{128,128,128} -- WhiteInvisible; ...invisible
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
ColorTable.WhiteInvisible=ColorTable[Data.Color.WhiteInvisible]

-- TODO: ColorAccept inverse

ColorAccept={
	{},
	{false,true, true,true,true, true,true,true},

	{[Color.Red]=true},
	{[Color.Green]=true},
	{[Color.Blue]=true},

	{[Color.Aqua]=true},
	{[Color.Magenta]=true},
	{[Color.Yellow]=true},

	{},
	{false,true, true,true,true, true,true,true, false,true}
}

ColorOpposite={
	[Color.Black]=Color.White,
	[Color.White]=Color.Black,

	[Color.Red]=Color.Aqua,
	[Color.Green]=Color.Magenta,
	[Color.Blue]=Color.Yellow,

	[Color.Aqua]=Color.Red,
	[Color.Magenta]=Color.Green,
	[Color.Yellow]=Color.Blue,

	[Color.System]=Color.System,
	[Color.WhiteInvisible]=Color.WhiteInvisible
}

ColorAdd={
	{true,true, true,true,true, true,true,true},
	{},

	{true,true, false,true ,true , false,false,false},
	{true,true, true ,false,true , false,false,false},
	{true,true, true ,true ,false, false,false,false},

	{true,true, true ,false,false, false,false,false},
	{true,true, false,true ,false, false,false,false},
	{true,true, false,false,true , false,false,false},

	{},
	{}
}

ColorAddResult={
	[Color.Black]={1,2, 3,4,5, 6,7,8},
	[Color.White]={},

	[Color.Red]  ={3,2, nil,8,7, nil,nil,nil},
	[Color.Green]={4,2, 8,nil,6, nil,nil,nil},
	[Color.Blue] ={5,2, 7,6,nil, nil,nil,nil},

	[Color.Aqua]   ={6,2, 2,nil,nil, nil,nil,nil},
	[Color.Magenta]={7,2, nil,2,nil, nil,nil,nil},
	[Color.Yellow] ={8,2, nil,nil,2, nil,nil,nil},

	[Color.System]={},
	[Color.WhiteInvisible]={}
}

function assert_is_color(t)
	if "number"==type(t) then
		assert(1<=t and Data.Color.WhiteInvisible>=t)
	else
		for _, c in pairs(t) do
			assert(1<=c and Data.Color.WhiteInvisible>=c)
		end
	end
end

function world_name(id)
	return "world_"..id
end

__iw=nil

function load_data(shell_data)
	if not shell_data.loaded_base then
		local image_data=love.image.newImageData(
			shell_data.__path..".png"
		)
		shell_data.__data=init_data(shell_data, image_data)
		image_data=nil
		shell_data.loaded_base=true
	end
	if not shell_data.loaded_dynamic then
		Data.__iw=shell_data.__data
		local wd_path=shell_data.__path..".wrl"
		local wd_str=love.filesystem.read(wd_path)
		local wd_chunk, err=loadstring(wd_str)
		if nil~=wd_chunk then
			wd_chunk()
		else
			print("error while loading world: "..wd_path)
		end
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

local function __world_default_reset_callback(_)
	return
end

function init_data(shell_data, image_data)
	local wd={
		w=image_data:getWidth(),
		h=image_data:getHeight(),
		sp_x=1, sp_y=1,
		spawn_color=spawn_color,
		loaded_dynamic=false,
		triggers={},
		--triggers_by_name={},
		reset_callback=__world_default_reset_callback,
		tiles={}
	}
	local r,g,b, c
	for y=1, wd.h do
		wd.tiles[y]={}
		for x=1, wd.w do
			r,g,b=image_data:getPixel(x-1, y-1)
			c=rgb_match(r,g,b)
			if Color.Black~=c then
				wd.tiles[y][x]=c
			end
		end
	end
	return wd
end

function set_reset_callback(wd, callback)
	wd.reset_callback=callback or __world_default_reset_callback
end

---- Tiles & data

-- Check if a color can accept another color (e.g., a sentient of
-- color b can be placed on a tile of color a)
function AC(a, b)
	return Data.ColorAccept[a][b] or false
end

-- Get tile
function G(wd, tx,ty)
	return wd.tiles[ty][tx]
end

-- Get tile color
function GC(wd, tx,ty)
	return wd.tiles[ty][tx] or Data.Color.Black
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

function S_SP(wd, tx,ty, color)
	Data.assert_is_color(color)
	wd.spawn_x=tx
	wd.spawn_y=ty
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
	local x,y=o, o
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

local function __trg_default_callback(_, _)
	-- Util.debug("__trg_default_callback")
	return false
end

-- Make trigger
function M_TR(wd, tx,ty, tt, name, td, tcolor, callback)
	local td={
		type=tt,
		name=name,
		tx=tx, ty=ty,
		props=td,
		callback=callback or __trg_default_callback
	}
	table.insert(wd.triggers, td)
	--[[if nil~=name then
		wd.triggers_by_name[name]=td
	end--]]
	if nil~=tcolor then
		Data.ST(wd, tx,ty, tcolor)
	end
	return td
end

---- Rendering

-- Get render position for tile coords
function tile_rpos(tx, ty)
	return
		(tx-1)*Data.TW,
		(ty-1)*Data.TH
end

-- Render tile to position
function render_tile_abs(color, rx,ry, line, line_color)
	if Color.Black~=color and Color.WhiteInvisible~=color then
		Util.set_color_table(Data.ColorTable[color])
		Gfx.rectangle("fill", rx,ry, Data.TW,Data.TH)
		if line then
			Util.set_color_table(
				Data.ColorTable[line_color or Data.Color.White],
				255
			)
			Gfx.rectangle("line", rx,ry, Data.TW,Data.TH)
		end
	end
end

-- Render tile to tile coords
function render_tile(color, tx,ty, line, line_color)
	Data.render_tile_abs(
		color, (tx-1)*Data.TW, (ty-1)*Data.TH,
		line, line_color
	)
end

function render_tile_inner_abs(color, rx,ry, line, line_color)
	Util.set_color_table(Data.ColorTable[color])
	Gfx.rectangle("fill",
		Data.CIW+rx, Data.CIH+ry,
		Data.TIW   , Data.TIH
	)
	if line then
		Util.set_color_table(
			Data.ColorTable[line_color or Data.Color.Black],
			255
		)
		Gfx.rectangle("line",
			Data.CIW+rx, Data.CIH+ry,
			Data.TIW   , Data.TIH
		)
	end
end

function render_tile_inner(color, tx,ty, line, line_color)
	Data.render_tile_inner_abs(
		color,
		(tx-1)*Data.TW, (ty-1)*Data.TH,
		line, line_color
	)
end

function render_tile_inner_circle_abs(color, rx,ry, line, line_color)
	--Util.set_color_table(Data.ColorTable[color])
	--Gfx.circle("fill", Data.HW+rx, Data.HH+ry, 6, 15)
	if line then
		Util.set_color_table(
			Data.ColorTable[line_color or Data.Color.Black],
			255
		)
		Gfx.circle("line", Data.HW+rx, Data.HH+ry, 6, 15)
	end
end

function render_tile_inner_circle(color, tx,ty, line, line_color)
	Data.render_tile_inner_circle_abs(
		color,
		(tx-1)*Data.TW, (ty-1)*Data.TH,
		line, line_color
	)
end

function render_tile_inner_triangle_abs(color, rx,ry, line, line_color)
	rx=rx+Data.HW
	ry=ry+Data.HH
	-- FIXME: no worky with translate; Camera is a douchebag
	--Gfx.push()
	local __inner_triangle={
		rx+0,ry-Data.HIH,
		rx-Data.HIW, ry+Data.HIH,
		rx+Data.HIW, ry+Data.HIH
	}
	--Gfx.translate(rx, ry)
	--Util.set_color_table(Data.ColorTable[color])
	--Gfx.polygon("fill", __inner_triangle)
	if line then
		Util.set_color_table(
			Data.ColorTable[line_color or Data.Color.Black],
			255
		)
		Gfx.polygon("line", __inner_triangle)
	end
	--Gfx.pop()
end

function render_tile_inner_triangle(color, tx,ty, line, line_color)
	Data.render_tile_inner_triangle_abs(
		color,
		(tx-1)*Data.TW, (ty-1)*Data.TH,
		line, line_color
	)
end
