-- imports {{{
require('constants')
local save_manager = require("save_manager")
local helpers      = require("helpers")
local Astroid      = require("game_objects.astroid")
local Bullet       = require("game_objects.bullet")
local Shockwave    = require("game_objects.shockwave")
-- }}}

function _config()
  return { name = "Astroids", game_id = "com.usagiengine.astroids" }
end

function _init()
  -- Live reload preserves globals across saved edits but resets locals.
  -- Stash mutable game state in a capitalized global like `State` so it
  -- survives reloads; F5 calls _init again to reset.
  --- @class State
  --- @field player Player
  --- @field input Usagi.Vec2
  --- @field health integer
  --- @field astroids Astroid[]
  --- @field shockwaves Shockwave[]
  --- @field bullets Bullet[]
  --- @field stopped boolean
  --- @field ammo integer
  --- @field last_bullet number
  --- @field time number
  --- @field score integer
  --- @field high_score integer
  --- @field last_astroid number
  --- @field debug boolean
  --- @field shader_on boolean
  State = save_manager.load()

  gfx.shader_set('crt')
end

function _update(dt)
  -- input and player movement {{{
  if not State.stopped then
    State.input = {
      x = helpers.bool_to_int(input.held(input.RIGHT)) -
          helpers.bool_to_int(input.held(input.LEFT)),
      y = helpers.bool_to_int(input.held(input.DOWN)) -
          helpers.bool_to_int(input.held(input.UP))
    }

    State.player:update(dt, State.input)

    if input.pressed(input.BTN1) and State.ammo > 0 then
      table.insert(State.bullets, Bullet.spawn(State.player.location, State.player.direction))
      State.ammo -= 1
    end
  end
  -- }}}

  -- game logic {{{
  if State.health <= 0 and not State.stopped then
    State.stopped = true
    effect.screen_shake(2, 2)
    save_manager.save(State)
  end

  if not State.stopped then
    State.time += dt
    if State.time - State.last_astroid > ASTROID_INTERVAL then
      table.insert(State.astroids, Astroid.spawn())
      State.last_astroid = State.time
    end
  end

  -- astroids {{{
  local destroy_astroids = {}

  for idx, astroid in ipairs(State.astroids) do
    astroid:update(dt)

    -- player collisions
    if astroid:colliding_with(State.player:get_collider())
        and not State.stopped
    then
      effect.hitstop(HITSTOP_INTERVAL)
      effect.flash(HITSTOP_INTERVAL, gfx.COLOR_RED)
      State.health -= DAMAGE * astroid.scale
      table.insert(destroy_astroids, idx)
    end

    -- astroid collisions
    for jdx, other in ipairs(State.astroids) do
      if idx == jdx then goto continue end -- don't compare self to self
      if astroid:colliding_with(other:get_collider()) then
        -- get 'bounce' vectors
        local r1 = util.vec_normalize({
          x = other.direction.x - astroid.direction.x,
          y = other.direction.y - astroid.direction.y
        })
        local r2 = util.vec_normalize({
          x = astroid.direction.x - other.direction.x,
          y = astroid.direction.y - other.direction.y
        })
        astroid.direction = r1
        other.direction = r2
      end
      ::continue::
    end

    -- astroid off screen
    if astroid:is_oob() then
      table.insert(destroy_astroids, idx)
    end
  end


  -- }}}

  -- bullets {{{

  if State.ammo < MAX_AMMO and State.time - State.last_bullet > RELOAD_SPEED then
    State.ammo += 1
    State.last_bullet = State.time
  end

  local destroy_bullets = {}

  for idx, bullet in ipairs(State.bullets) do
    bullet:update(dt)

    -- astroid collision
    for jdx, other in ipairs(State.astroids) do
      if util.point_in_rect(bullet.location, other:get_collider()) then
        State.score += ASTROID_SCORE * other.scale
        table.insert(destroy_astroids, jdx)
        table.insert(destroy_bullets, idx)
        -- spawn at center of sprite
        table.insert(State.shockwaves, Shockwave.spawn(other.location, other.scale))
      end
    end

    -- bullet off screen
    if bullet:is_oob() then
      table.insert(destroy_bullets, idx)
    end
  end
  -- }}}

  -- shockwaves {{{
  local destroy_shockwaves = {}

  for idx, shockwave in ipairs(State.shockwaves) do
    shockwave.frames += 1
    if shockwave.frames > SHOCKWAVE_FRAMES then
      table.insert(destroy_shockwaves, idx)
    end
  end

  -- }}}

  for _, value in ipairs(destroy_astroids) do
    table.remove(State.astroids, value)
  end

  for _, value in ipairs(destroy_bullets) do
    table.remove(State.bullets, value)
  end

  for _, value in ipairs(destroy_shockwaves) do
    table.remove(State.shockwaves, value)
  end

  -- }}}

  -- debug controls {{{
  if usagi.IS_DEV then
    if input.key_pressed(input.KEY_BACKTICK) then
      State.debug = not State.debug
    end
    if State.debug then
      if input.key_held(input.KEY_F) then
        State.health -= 1
      end
      if input.key_pressed(input.KEY_R) then
        Astroid.spawn()
      end
      if input.key_pressed(input.KEY_1) then
        State.shader_on = not State.shader_on
        if State.shader_on then
          gfx.shader_set('crt')
        else
          gfx.shader_set(nil)
        end
      end
    end
  end
  -- }}}
end

function _draw(dt)
  gfx.clear(gfx.COLOR_DARK_GRAY)

  -- game_objects {{{
  State.player:draw(dt)

  for _, astroid in ipairs(State.astroids) do
    astroid:draw(dt)
  end

  for _, bullet in ipairs(State.bullets) do
    bullet:draw(dt)
  end

  for _, shockwave in ipairs(State.shockwaves) do
    shockwave:draw(dt)
  end
  -- }}}

  -- UI {{{

  -- health bar {{{
  gfx.rect_ex(
    usagi.GAME_W - HEALTH_BAR.x - HEALTH_BAR.padding - HEALTH_BAR.thickness,
    usagi.GAME_H - HEALTH_BAR.y - HEALTH_BAR.padding - HEALTH_BAR.thickness,
    HEALTH_BAR.x + (2 * HEALTH_BAR.thickness),
    HEALTH_BAR.y + (2 * HEALTH_BAR.thickness),
    HEALTH_BAR.thickness,
    gfx.COLOR_WHITE)

  gfx.rect_fill(
    usagi.GAME_W - HEALTH_BAR.x - HEALTH_BAR.padding,
    usagi.GAME_H - HEALTH_BAR.y - HEALTH_BAR.padding,
    State.health,
    HEALTH_BAR.y,
    gfx.COLOR_WHITE)
  -- }}}

  -- ammo {{{
  for i = 1, MAX_AMMO do
    gfx.circ_ex(
      usagi.GAME_W - AMMO_BAR.x + (i * AMMO_BAR.padding),
      usagi.GAME_H - AMMO_BAR.y,
      AMMO_BAR.r,
      AMMO_BAR.thickness,
      gfx.COLOR_WHITE
    )
    if State.ammo >= i then
      gfx.circ_fill(
        usagi.GAME_W - AMMO_BAR.x + (i * AMMO_BAR.padding),
        usagi.GAME_H - AMMO_BAR.y,
        AMMO_BAR.r,
        gfx.COLOR_WHITE
      )
    end
  end

  -- }}}

  -- timer and score {{{
  local time = math.ceil(State.time) .. ""
  local score = State.score .. ""
  local high_score = "HI " .. State.high_score
  gfx.text(time, usagi.GAME_W - TIMER_OFFSET, 0, gfx.COLOR_WHITE)
  gfx.text(score, usagi.GAME_W - SCORE_OFFSET, 0, gfx.COLOR_WHITE)
  gfx.text(high_score, usagi.GAME_W - HIGH_SCORE_OFFSET, 0, gfx.COLOR_WHITE)
  -- }}}

  -- game over {{{
  if State.health <= 0 then
    local text = 'GAME OVER'
    gfx.text_ex(
      text,
      (usagi.GAME_W / 2) - (usagi.measure_text(text)),
      (usagi.GAME_H / 2) - GAME_OVER_OFFSET,
      GAME_OVER_MULT,
      0,
      gfx.COLOR_RED,
      1
    )
    if State.score > State.high_score then
      local new_text = "NEW HIGH SCORE!"
      gfx.text(
        new_text,
        (usagi.GAME_W / 2) - (usagi.measure_text(new_text) / 2),
        (usagi.GAME_H / 2) - HIGH_SCORE_OFFSET,
        gfx.COLOR_RED
      )
    end
  end
  -- }}}

  -- }}}

  -- shader uniforms {{{
  -- the period between each scan line cycle
  gfx.shader_uniform("u_time", usagi.elapsed / 2)
  gfx.shader_uniform("u_resolution", { usagi.GAME_W, usagi.GAME_H })
  -- varies the intensity of the scanline to emulate CRT scan artifacts
  gfx.shader_uniform("u_scanline", .1 + math.sin(usagi.elapsed) / 2)
  -- }}}

  -- debug stuff {{{
  if usagi.IS_DEV and State.debug then
    -- input and direction vector
    gfx.text_ex(
      "I:" .. State.input.x .. ", " .. State.input.y, 0, 10, 1, 0, gfx.COLOR_GREEN, .5)
    gfx.text_ex(
      "D:" .. State.player.direction.x .. ", " .. State.player.direction.y, 0, 20, 1, 0, gfx.COLOR_GREEN, .5)
    gfx.text_ex(
      "Da:" .. State.player.sprite_direction, 0, 30, 1, 0, gfx.COLOR_GREEN, .5)
    -- astroid count
    gfx.text_ex("Astroids: " .. #State.astroids, 0, 40, 1, 0, gfx.COLOR_GREEN, .5)
    -- bullet count
    gfx.text_ex("Bullets: " .. #State.bullets, 0, 50, 1, 0, gfx.COLOR_GREEN, .5)
    gfx.text_ex("Ammo: " .. State.ammo, 0, 60, 1, 0, gfx.COLOR_GREEN, .5)

    -- astroid colliders
    for _, astroid in ipairs(State.astroids) do
      astroid:draw_debug(dt)
    end
    -- player collider
    State.player:draw_debug(dt)
  end
  -- }}}
end
