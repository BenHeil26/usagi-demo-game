local SceneManager = require("scene_manager")

function _config()
  return {
    name = "Asteroids",
    game_id = "com.usagiengine.asteroids",
    pause_menu = false,
    icon = 1
  }
end

function _init()
  Manager = SceneManager:new()
  -- gloabl shader
  gfx.shader_set('crt')
end

function _update(dt)
  Manager:update(dt)
end

function _draw(dt)
  -- global background
  gfx.clear(gfx.COLOR_DARK_GRAY)

  -- the period between each scan line cycle
  gfx.shader_uniform("u_time", usagi.elapsed / 2)
  gfx.shader_uniform("u_resolution", { usagi.GAME_W, usagi.GAME_H })

  -- varies the intensity of the scanline to emulate CRT scan artifacts
  gfx.shader_uniform("u_scanline", .1 + math.sin(usagi.elapsed) / 2)

  Manager:draw(dt)
end
