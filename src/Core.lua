
module("Core", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Camera")
require("src/AudioManager")
require("src/FieldAnimator")
--require("src/Hooker")
--require("src/Animator")
require("src/AssetLoader")
require("src/Asset")

require("src/Data")
require("src/Presenter")
require("src/Trigger")
require("src/Trigger/Message")
require("src/Trigger/ChangeWorld")
require("src/Trigger/Switch")
require("src/Trigger/Teleporter")
require("src/Player")
require("src/World")

binds={
	["escape"]={
		on_release=true,
		handler=function(_, _, _, _)
			love.event.quit()
		end
	},
	["pause"]={
		on_release=true,
		passthrough=true,
		handler=function(_, _, _, _)
			State.pause_lock=not State.pause_lock
			State.paused=State.pause_lock
			if State.paused then
				AudioManager.pause()
			else
				AudioManager.resume()
			end
		end
	},
	["f1"]={
		on_release=true,
		handler=function(_, _, _, _)
			World.reset()
		end
	},
	["f2"]={
		on_release=true,
		handler=function(_, _, _, _)
			State.trg_debug=not State.trg_debug
			if State.trg_debug then
				print("trigger debug mode enabled")
			else
				print("trigger debug mode disabled")
			end
		end
	},
	["f3"]={
		on_release=true,
		handler=function(_, _, _, _)
			State.gfx_debug=not State.gfx_debug
			State.sfx_debug=not State.sfx_debug
			print("graphics and audio debug modes toggled")
		end
	},
	["f4"]={
		on_release=true,
		handler=function(_, _, _, _)
			State.debug=not State.debug
			if State.debug then
				print("debug mode enabled")
			else
				print("debug mode disabled")
			end
		end
	},
	[" "]={
		on_release=true,
		handler=function(_, _, _, _)
			--Util.debug("queue_activation")
			Player.queue_activation()
		end
	},
	-- FIXME: disallow both wasd+arrows in a single update;
	-- remove arrow keys or wasd?
	[{"up",'w', "down",'s', "left",'a', "right",'d'}]={
		ttable={
			["up"]   =Player.Dir.Up   , ['w']=Player.Dir.Up,
			["down"] =Player.Dir.Down , ['s']=Player.Dir.Down,
			["left"] =Player.Dir.Left , ['a']=Player.Dir.Left,
			["right"]=Player.Dir.Right, ['d']=Player.Dir.Right
		},
		time={
			[Player.Dir.Up]=0.0  , [Player.Dir.Down]=0.0,
			[Player.Dir.Left]=0.0, [Player.Dir.Right]=0.0
		},
		duration=0.125,
		on_press=true,
		on_active=true,
		handler=function(ident, dt, kind, bind)
			local dir=bind.ttable[ident]
			-- FIXME: Hacky hackerton
			if Bind.Kind.Active==kind then
				bind.time[dir]=bind.time[dir]+dt
				if bind.duration<=bind.time[dir] then
					bind.time[dir]=bind.time[dir]-bind.duration
				else
					return
				end
			elseif Bind.Kind.Press==kind then
				-- Mc hacksters
				bind.time[dir]=-bind.duration
			end
			World.move_player(dir)
		end
	}
}

function bind_trigger_gate(_, ident, _, kind)
	--[[Util.debug(
		"bind_trigger_gate: ident: "..ident.." kind: "..kind,
		"Presenter: ", Presenter.is_active(), Presenter.is_ending(),
		"change_world_lock: ", State.change_world_lock
	)--]]
	if State.paused then
		return false
	elseif true==State.change_world_lock then
		if Bind.Kind.Release==kind then
			State.change_world_lock=false
		end
		return false
	elseif
		"pause"~=ident and
		Presenter.is_active() and
		not Presenter.is_ending()
	then
		if Bind.Kind.Release==kind then
			Presenter.stop()
		end
		return false
	end
	return true
end

function init(arg)
	-- Ensure debug is enabled for initialization
	local debug_mode_temp=false
	if not State.debug then
		State.debug=true
		debug_mode_temp=true
	end

	Core.display_width=Gfx.getWidth()
	Core.display_width_half=0.5*Core.display_width
	Core.display_height=Gfx.getHeight()
	Core.display_height_half=0.5*Core.display_height

	-- system initialization
	Util.init()
	Bind.init(Core.binds, Core.bind_trigger_gate)

	-- assets
	AssetLoader.load("asset/", Asset.desc_root, Asset)
	--Hooker.init(Asset.hooklet, Asset.font.main)

	--Animator.init(Asset.anim)
	AudioManager.init(Asset.sound)

	-- more systems
	Camera.init(0,0, 320,320)

	Presenter.init(Asset.font.presenter)

	Player.init(1, 1, Data.Color.Red)
	local world_name=Util.optional(arg[2], "start")
	World.init(Asset.world, Asset.world[world_name])

	-- default rendering state
	Gfx.setFont(Asset.font.main)
	Gfx.setColor(255,255,255, 255)
	Gfx.setBackgroundColor(0,0,0, 255)

	Gfx.setPointSize(4.0)
	Gfx.setLineWidth(2.0)
	--Gfx.setLineStyle("smooth")

	-- Ensure debug is disabled after initialization
	if debug_mode_temp then
		State.debug=false
	end
end

function deinit()
	-- TODO: save data?
end

function exit()
	-- Yes! I want to terminate!
	-- ... Wait, what? That's false?
	Core.deinit()
	return false
end

function focus_changed(focused)
	if not State.pause_lock then
		State.paused=not focused
	end
end

function update(dt)
	if true==State.paused then
		Bind.update(0.0)
	else
		Bind.update(dt)
		--Hooker.update(dt)
		AudioManager.update(dt)
		Presenter.update(dt)
		World.current():update(dt)
		Camera.update(dt)
	end
end

function render()
	Camera.lock()
		World.current():render()
	Camera.unlock()

	Presenter.render()

	if State.gfx_debug then
		Gfx.setColor(255,255,255, 255)
		Gfx.rectangle("line",
			0.0,0.0, Core.display_width, Core.display_height
		)
	end
end
