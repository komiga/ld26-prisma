
module("AssetLoader", package.seeall)

require("src/Util")
require("src/AudioManager")
require("src/Animator")

require("src/Data")

local Kind = {}

local function get_asset_path(root_path, path, name, ext)
	Util.tcheck(path, "string", true)
	local p_ext = (nil ~= ext) and ('.' .. ext) or ""
	if nil == path then
		return root_path .. name .. p_ext
	else
		return root_path .. string.gsub(path, '@', name) .. p_ext
	end
end

--[[

NOTE: '@' in descriptor paths will be replaced with the name of the asset.

All descriptors can take a 'path' value, but default to 'name.ext'
where 'ext' is the default extension for the asset kind. 'ext' can be
used to override the default extension.

All assets except for fonts (that is, all tables) will have a unique
integer value '__id' and '__name' set to the asset's name.

]]

--[[

With path (using name and .ttf):

	name = {
		18
	}

Or default font with size:

	name = {
		18,
		default = true
	}

]]
Kind.font = {
	slug = "font/",
	loader = function(root_path, name, desc)
		local size = desc[1]
		local default = desc.default
		Util.tcheck(size, "number")
		Util.tcheck(default, "boolean", true)

		if default then
			return Gfx.newFont(size)
		else
			return Gfx.newFont(
				get_asset_path(root_path, desc.path, name, desc.ext or "ttf"),
				size
			)
		end
	end
}

--[[

With positions and sizes:

	name = {
		tex = {
			{"t0",  0,0, 32,32},
			{"t1", 32,0, 32,32},
			{"t2", 64,0, 32,32}
		}
	}

With constant size:

	name = {
		size = {32,32},
		tex = {
			{"t0",  0,0},
			{"t1", 32,0},
			{"t2", 64,0}
		}
	}

With constant size and indexed positions:

	name = {
		indexed = true,
		size = {32,32},
		tex = {
			{"t0", 0,0},
			{"t1", 1,0},
			{"t2", 2,0}
		}
	}

All of the descriptors above describe the same atlas.

In the last two forms, full quads are still permitted
(in which form the position for the texture does not use indexing).

]]
Kind.atlas = {
	slug = "atlas/",
	loader = function(root_path, name, desc)
		local indexed = desc.indexed
		local size = desc.size
		local tex = desc.tex
		Util.tcheck(indexed, "boolean", true)
		Util.tcheck(size, "table", true)
		Util.tcheck(tex, "table")

		local atlas = {
			__tex = Gfx.newImage(
				get_asset_path(root_path, desc.path, name, desc.ext or "png")
			)
		}

		local aw = atlas.__tex:getWidth()
		local ah = atlas.__tex:getHeight()
		local x0,y0, sw,sh
		local idx, t

		for idx, t in pairs(tex) do
			if 3 ~= #t and 5 ~= #t then
				error(
					"atlas subtexture descriptor " .. 
					idx .. " is malformed"
				)
			end
			if 5 ~= #t and not size then
				error(
					"atlas subtextures must be full " .. 
					"quads if 'size' is absent."
				)
			end
			x0 = t[2]
			y0 = t[3]
			if 5 == #t then
				sw = t[4]
				sh = t[5]
			else
				if indexed then
					x0 = size[1] * x0
					y0 = size[2] * y0
				end
				sw = size[1]
				sh = size[2]
			end
			atlas[t[1]] = Gfx.newQuad(x0,y0, sw,sh, aw,ah)
		end
		return atlas
	end
}

--[[

Animation data.

	name = {
		duration = 0.2,
		size = {32,32},
		set = {
			{10},
			{10},
			{10}
		}
	}

'duration' is the duration of a frame (in seconds).

'size' is the size of each frame.

'set' defines sequence sets. Each set contains only a frame count.

A set will automatically move to the next row if the end of a row is
reached before all of its frames are loaded.

If a set is completed and the frame isn't the last frame in the row,
the next row will be used for the next set. This can be disabled with
tight_packing = true.

Once loaded, a frame quad is accessed by index:

	anim_data.set[set][frame]

Each frame is a Quad.

See Animator/AnimInstance.

]]
Kind.anim = {
	slug = "anim/",
	loader = function(root_path, name, desc)
		local duration = desc.duration
		local size = desc.size
		local set = desc.set
		local tight_packing = desc.tight_packing
		Util.tcheck(duration, "number")
		Util.tcheck(size, "table")
		Util.tcheck(set, "table")
		Util.tcheck(tight_packing, "boolean", true)

		local ad = {
			duration = duration,
			frame_width = size[1],
			frame_height = size[2],
			set = {},
			tex = Gfx.newImage(
				get_asset_path(root_path, desc.path, name, desc.ext or "png")
			)
		}
		ad.tex_width = ad.tex:getWidth()
		ad.tex_height = ad.tex:getHeight()

		local dw = ad.frame_width
		local dh = ad.frame_height
		local x0, y0 = 0, 0

		assert(dw <= ad.tex_width)
		assert(dh <= ad.tex_height)

		local y0_overflow = function(sidx)
			error("animation set " .. sidx .. " overflows texture")
		end

		for sidx, s in pairs(set) do
			ad.set[sidx] = {}
			x0 = 0
			for frame = 1, s[1] do
				if ad.tex_width < x0 + dw then
					x0 = 0
					y0 = y0 + dh
					if ad.tex_height < y0 then
						y0_overflow(sidx)
					end
				end
				ad.set[sidx][frame] = Gfx.newQuad(
					x0,y0, dw,dh, ad.tex_width,ad.tex_height
				)
				x0 = x0 + dw
			end
			if not tight_packing then
				y0 = y0 + dh
				if ad.tex_height < y0 then
					y0_overflow(sidx)
				end
			end
		end
		return ad
	end
}

--[[

With path, instance policy, and instance limit:

	name = {
		InstancePolicy.Constant,
		limit = 10
	}

'limit' is 0 by default.

The second parameter is the instance policy. This is defaulted to
Constant if limit > 0, or Immediate if limit <= 0.

See AudioManager/SoundInstance.

--]]
Kind.sound = {
	slug = "sound/",
	loader = function(root_path, name, desc)
		local policy = desc[1]
		local limit = desc.limit
		Util.tcheck(policy, "number", true)
		Util.tcheck(limit, "number", true)

		limit = Util.optional(limit, 0)
		policy = Util.optional(
			policy,
			Util.ternary(
				0 < limit,
				AudioManager.InstancePolicy.Constant,
				AudioManager.InstancePolicy.Immediate
			)
		)
		if AudioManager.InstancePolicy.Constant == policy and 0 == limit then
			error("policy cannot be Constant when limit=0")
		end

		local sd = {
			data = love.sound.newSoundData(
				get_asset_path(root_path, desc.path, name, desc.ext or "ogg")
			),
			policy = policy,
			limit = limit
		}
		return sd
	end
}

--[[

These descriptors are empty tables. World/Data handle hot-loading.

--]]
Kind.world = {
	slug = "world/",
	preload = function(root_path, _, asset_kind_table)
		local dir = love.filesystem.getDirectoryItems(root_path)
		for _, e in pairs(dir) do
			local is_file = love.filesystem.isFile(root_path .. e)
			local name, ext = string.match(e, "([%w_%-]+)(.wrl)")
			--[[Util.debug(
				"Kind.world.preload:", is_file, name, ext
			)--]]
			if is_file and nil ~= ext then
				asset_kind_table[name] = {
					__data = nil,
					__w_id = name,
					__path = get_asset_path(
						root_path, nil, name, nil
					)
				}
			end
		end
	end
}

local LoadOrder = {
	"font",
	"atlas",
	"anim",
	"sound",
	"world"
}

local function load_kind(id, root_path, kind_name, desc_table, asset_table)
	local kind = Kind[kind_name]
	root_path = root_path .. kind.slug
	local asset_kind_table = asset_table[kind_name]
	if kind.preload then
		kind.preload(root_path, desc_table, asset_kind_table)
	end
	if kind.loader then
		for name, desc in pairs(desc_table) do
			Util.tcheck(desc, "table")
			local asset = kind.loader(root_path, name, desc)
			if "table" == type(asset) then
				asset.__id = id
				asset.__name = name
				id = id + 1
			end
			assert(nil == asset_kind_table[name])
			asset_kind_table[name] = asset
		end
	end
	return id
end

function load(root_path, desc_root, asset_table)
	Util.tcheck(root_path, "string")
	Util.tcheck(desc_root, "table")
	Util.tcheck(asset_table, "table")

	local id = 1
	for _, kind_name in pairs(LoadOrder) do
		local desc_table = desc_root[kind_name]
		if nil ~= desc_table then
			if nil == asset_table[kind_name] then
				asset_table[kind_name] = {}
			end
			id = load_kind(id, root_path, kind_name, desc_table, asset_table)
		end
	end
end
