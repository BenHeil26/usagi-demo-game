-- imports {{{
local helpers = require("helpers")
local Astroid = require("game_objects.astroids")
-- }}}

function _config()
  return { name = "Astroids", game_id = "com.usagiengine.astroids" }
end

function _init()
  -- Live reload preserves globals across saved edits but resets locals.
  -- Stash mutable game state in a capitalized global like `State` so it
  -- survives reloads; F5 calls _init again to reset.
  --- @class State
  --- @field input Usagi.Vec2
  --- @field location Usagi.Vec2
  --- @field direction Usagi.Vec2
  --- @field sprite_direction number
  --- @field healh integer
  --- @field stopped boolean
  --- @field astroids Astroid[]
  ---
  State = {
    input = {
      x = 0,
      y = 0
    },
    location = {
      x = usagi.GAME_W / 2,
      y = usagi.GAME_H / 2,
    },
    direction = {
      x = 1,
      y = 0,
    },
    -- angle in radians
    sprite_direction = 0,
    health = 100,
    stopped = false,
    astroids = {},
    -- {location, scale, frames}
    shockwaves = {},
    -- {location, speed, direction}
    bullets = {},
    ammo = 5,
    last_bullet = 0,
    time = 0,
    score = 0,
    last_astroid = 0,
    debug = false,
    shader_on = true,
  }

  gfx.shader_set('crt')
end

-- constructors {{{
--- spawns a bullet at the front of the ship that fires in the direction
--- the ship is facing until it reaches an edge of the screen
local function spawn_bullet()
  -- get the starting location
  local start = {
    x = State.location.x + (usagi.SPRITE_SIZE / 2)
        + (State.direction.x * (usagi.SPRITE_SIZE / 2)),
    y = State.location.y + (usagi.SPRITE_SIZE / 2)
        + (State.direction.y * (usagi.SPRITE_SIZE / 2))
  }

  table.insert(State.bullets, {
    location = start,
    speed = BULLET_SPEED,
    direction = State.direction,
  })
end

--- spawns a shockwave at the specified location
local function spawn_shockwave(location, scale)
  table.insert(State.shockwaves, {
    location = location,
    scale = scale,
    frames = 0,
  })
end
-- }}}

function _update(dt)
  -- input and player movement {{{
  if not State.stopped then
    State.input = {
      x = helpers:bool_to_int(input.held(input.RIGHT)) -
          helpers:bool_to_int(input.held(input.LEFT)),
      y = helpers:bool_to_int(input.held(input.DOWN)) -
          helpers:bool_to_int(input.held(input.UP))
    }

    -- TODO: lerp vector for smooth rotation (maybe)
    if helpers:vec_magnitude(State.input) ~= 0 then
      State.direction = State.input
      State.sprite_direction = math.atan(State.input.y, State.input.x)
    end

    State.input = util.vec_normalize(State.input)
    State.location.x = (State.location.x + State.input.x * SPEED * dt) % usagi.GAME_W
    State.location.y = (State.location.y + State.input.y * SPEED * dt) % usagi.GAME_H


    if input.pressed(input.BTN1) and State.ammo > 0 then
      spawn_bullet()
      State.ammo -= 1
    end
  end
  -- }}}

  -- game logic {{{
  if State.health <= 0 and not State.stopped then
    State.stopped = true
    effect.screen_shake(2, 2)
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
    if util.rect_overlap(
          {
            x = State.location.x,
            y = State.location.y,
            w = usagi.SPRITE_SIZE,
            h = usagi.SPRITE_SIZE,
          },
          {
            x = astroid.location.x,
            y = astroid.location.y,
            w = usagi.SPRITE_SIZE * astroid.scale,
            h = usagi.SPRITE_SIZE * astroid.scale,
          })
    then
      effect.hitstop(HITSTOP_INTERVAL)
      effect.flash(HITSTOP_INTERVAL, gfx.COLOR_RED)
      State.health -= DAMAGE * astroid.scale
      table.insert(destroy_astroids, idx)
    end

    -- astroid collisions
    for jdx, other in ipairs(State.astroids) do
      if idx == jdx then goto continue end -- don't compare value to value
      if util.rect_overlap(
            {
              x = astroid.location.x,
              y = astroid.location.y,
              w = usagi.SPRITE_SIZE * astroid.scale,
              h = usagi.SPRITE_SIZE * astroid.scale,
            },
            {
              x = other.location.x,
              y = other.location.y,
              w = usagi.SPRITE_SIZE * other.scale,
              h = usagi.SPRITE_SIZE * other.scale,
            })
      then
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
    if
        astroid.location.x < 0 or astroid.location.x > usagi.GAME_W or
        astroid.location.y < 0 or astroid.location.y > usagi.GAME_H
    then
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

  for _, value in ipairs(State.bullets) do
    value.location = {
      x = value.location.x + value.direction.x * value.speed * dt,
      y = value.location.y + value.direction.y * value.speed * dt,
    }
  end

  for idx, value in ipairs(State.bullets) do
    -- astroid collision
    for jdx, other in ipairs(State.astroids) do
      if util.point_in_rect(
            value.location,
            {
              x = other.location.x,
              y = other.location.y,
              w = usagi.SPRITE_SIZE * other.scale,
              h = usagi.SPRITE_SIZE * other.scale,
            }
          )
      then
        State.score += ASTROID_SCORE * other.scale
        table.insert(destroy_astroids, jdx)
        table.insert(destroy_bullets, idx)
        -- spawn at center of sprite
        spawn_shockwave(value.location, other.scale)
      end
    end

    -- bullet off screen
    if
        value.location.x < 0 or value.location.x > usagi.GAME_W or
        value.location.y < 0 or value.location.y > usagi.GAME_H
    then
      table.insert(destroy_bullets, idx)
    end
  end

  -- }}}

  -- shockwaves {{{
  local destroy_shockwaves = {}

  for idx, value in ipairs(State.shockwaves) do
    value.frames += 1
    if value.frames > SHOCKWAVE_FRAMES then
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

  -- player {{{
  gfx.spr_ex(
    SPRITES.player,
    State.location.x, State.location.y,
    false, false,
    State.sprite_direction,
    gfx.COLOR_WHITE, 1
  )
  --}}}

  -- astroids {{{
  for _, value in ipairs(State.astroids) do
    helpers:spr_scaled(
      value.sprite_idx,
      value.location.x, value.location.y,
      false, false,
      value.rotation,
      gfx.COLOR_WHITE,
      1,
      value.scale
    )
  end
  -- }}}

  -- bullets {{{
  for _, value in ipairs(State.bullets) do
    gfx.rect_ex(value.location.x, value.location.y, 1, 1, 1, gfx.COLOR_WHITE)
  end
  -- }}}

  -- shockwaves {{{
  for _, value in ipairs(State.shockwaves) do
    gfx.circ_fill(value.location.x, value.location.y,
      value.frames * value.scale, gfx.COLOR_WHITE)
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
  gfx.text(time, usagi.GAME_W - TIMER_OFFSET, 0, gfx.COLOR_WHITE)
  gfx.text(score, usagi.GAME_W - SCORE_OFFSET, 0, gfx.COLOR_WHITE)
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
      "D:" .. State.direction.x .. ", " .. State.direction.y, 0, 20, 1, 0, gfx.COLOR_GREEN, .5)
    gfx.text_ex(
      "Da:" .. State.sprite_direction, 0, 30, 1, 0, gfx.COLOR_GREEN, .5)
    -- astroid count
    gfx.text_ex("Astroids: " .. #State.astroids, 0, 40, 1, 0, gfx.COLOR_GREEN, .5)
    -- bullet count
    gfx.text_ex("Bullets: " .. #State.bullets, 0, 50, 1, 0, gfx.COLOR_GREEN, .5)
    gfx.text_ex("Ammo: " .. State.ammo, 0, 60, 1, 0, gfx.COLOR_GREEN, .5)

    -- astroid colliders
    for _, value in ipairs(State.astroids) do
      gfx.rect_ex(
        value.location.x, value.location.y,
        usagi.SPRITE_SIZE * value.scale,
        usagi.SPRITE_SIZE * value.scale,
        1, gfx.COLOR_RED
      )
    end
    -- player collider
    gfx.rect_ex(
      State.location.x, State.location.y,
      usagi.SPRITE_SIZE,
      usagi.SPRITE_SIZE,
      1, gfx.COLOR_GREEN
    )
  end
  -- }}}
end
