
module("Core", package.seeall)

require("src/State")
require("src/Util")
require("src/Bind")
require("src/Camera")
require("src/AudioManager")
require("src/FieldAnimator")
require("src/Hooker")
require("src/Animator")
require("src/AssetLoader")
require("src/Asset")

require("src/Data")
require("src/Presenter")
require("src/World")
require("src/Sentient")
require("src/Player")

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
	["f4"]={
		on_release=true,
		handler=function(_, _, _, _)
			State.debug_mode=not State.debug_mode
			if State.debug_mode then
				print("debug mode enabled")
			else
				print("debug mode disabled")
			end
		end
	},
	[{"up",'w', "down",'s', "left",'a', "right",'d'}]={
		time=0.0,
		on_press=true,
		on_active=true,
		handler=function(ident, dt, kind, bind)
			-- FIXME: Hacky hackerton
			if Bind.Kind.Active==kind then
				bind.time=bind.time+dt
				if 0.2<=bind.time then
					bind.time=bind.time-0.2
				else
					return
				end
			elseif Bind.Kind.Press==kind then
				bind.time=-0.2
			end
			local dir=0
			if "up"==ident or "w"==ident then
				dir=World.Dir.Up
			elseif "down"==ident or "s"==ident then
				dir=World.Dir.Down
			elseif "left"==ident or "a"==ident then
				dir=World.Dir.Left
			elseif "right"==ident or "d"==ident then
				dir=World.Dir.Right
			end
			if 0~=dir then
				World.move_player(dir)
			end
		end
	}
}

function bind_trigger_gate(_, ident, _, kind)
	--[[Util.debug(
		"bind_trigger_gate: ident: "..ident,
		"Presenter: ", Presenter.is_active(), Presenter.is_ending()
	)--]]
	if State.paused then
		return false
	elseif
		"pause"~=ident and
		Presenter.is_active() and
		not Presenter.is_ending()
	then
		Presenter.stop()
		return false
	end
	return true
end

function init(_)
	-- Ensure debug_mode is enabled for initialization
	local debug_mode_temp=false
	if not State.debug_mode then
		State.debug_mode=true
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
	Hooker.init(Asset.hooklet, Asset.font.main)

	Animator.init(Asset.anim)
	AudioManager.init(Asset.sound)

	Camera.init(0,0, 0,0)

	Presenter.init(Asset.font.presenter)

	Sentient.init()
	Player.init(1, 1, Data.Color.Red)
	World.init(Asset.world, Asset.world.world_1)

	-- default rendering state
	Gfx.setFont(Asset.font.main)
	Gfx.setColor(255,255,255, 255)
	Gfx.setBackgroundColor(0,0,0, 255)

	Gfx.setPointSize(4.0)
	Gfx.setLineWidth(2.0)
	--Gfx.setLineStyle("smooth")

	-- Ensure debug_mode is disabled after initialization
	if debug_mode_temp then
		State.debug_mode=false
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
		Hooker.update(dt)
		AudioManager.update(dt)
		Presenter.update(dt)
		World.update(dt)
		Camera.update(dt)
	end
end

function render()
	Camera.lock()
		World.render()
		Hooker.render()

		Gfx.setColor(0,0,0, 255)
		Gfx.point(
			Camera.rel_x(0),
			Camera.rel_y(0)
		)
	Camera.unlock()

	Presenter.render()

	if State.debug_mode then
		Gfx.setColor(255,255,255, 255)
		Gfx.rectangle("line",
			0.0,0.0, Core.display_width, Core.display_height
		)
	end
end
