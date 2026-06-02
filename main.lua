function _config()
  return { name = "Astroids", game_id = "com.usagiengine.astroids" }
end

function _init()
  -- Live reload preserves globals across saved edits but resets locals.
  -- Stash mutable game state in a capitalized global like `State` so it
  -- survives reloads; F5 calls _init again to reset.
  State = {
    input_vector = {
      x = 0,
      y = 0
    },
    location = {
      x = usagi.GAME_W / 2,
      y = usagi.GAME_H / 2,
    },
    direction = 0, -- angle in radians
    health = 100,
    stopped = false,
    -- {sprite_idx, location, scale, rotation, speed, direction, spin}
    astroids = {},
    start_time = os.time(),
    time = 0,
    last_astroid = 0,
    debug = false
  }
end

-- game constants {{{
SPEED = 100
SIZE = {
  x = 10,
  y = 10,
}
HEALTH_BAR = {
  x = 100,
  y = 5,
  thickness = 1,
  padding = 10,
}
SCREEN = {
  w = 320,
  h = 180,
}
GAME_OVER_OFFSET = 16
GAME_OVER_MULT = 2
SPRITES = {
  player = 1,
  astroid1 = 2,
  astroid2 = 3,
  astroid3 = 4,
}
ASTROID_INTERVAL = 1
HITSTOP_INTERVAL = .2
DAMAGE = 5
-- }}}

-- helper functions {{{
local function bool_to_int(bool)
  return bool and 1 or 0
end

local function vec_magnitude(vec)
  return math.sqrt(vec.x ^ 2 + vec.y ^ 2)
end

local function spr_scaled(idx, x, y, flip_x, flip_y, rotation, tint, alpha, scale)
  gfx.sspr_ex(
    0, (idx - 1) * usagi.SPRITE_SIZE, -- adjust for 0 vs 1 based index
    usagi.SPRITE_SIZE, usagi.SPRITE_SIZE,
    x, y,
    usagi.SPRITE_SIZE * scale, usagi.SPRITE_SIZE * scale,
    flip_x, flip_y,
    rotation,
    tint,
    alpha
  )
end

local function get_timer()
  return os.time() - State.start_time
end

-- }}}

-- constructors {{{
--- Spawns an astroid in a random location on one edge of the screen
local function spawn_astroid()
  -- randomly place one coordinate on the edge of the screen
  local location = {
    x = math.random(usagi.GAME_W),
    y = math.random(usagi.GAME_H),
  }

  if math.random(2) % 2 == 0 then
    location.x = location.x > (usagi.GAME_W / 2) and usagi.GAME_W or 0
  else
    location.y = location.y > (usagi.GAME_H / 2) and usagi.GAME_H or 0
  end

  -- create a vector from the location toward the center of the screen
  local direction = util.vec_normalize({
    x = (usagi.GAME_W / 2) - location.x,
    y = (usagi.GAME_H / 2) - location.y
  })

  local sprite_idx = math.random(SPRITES.astroid1, SPRITES.astroid3)
  local scale = math.random(2)
  local rotation = math.random() * 2 * math.pi
  local speed = math.random(30, 70)
  local spin = math.random(2) % 2 == 0 and 1 or -1

  table.insert(State.astroids, {
    sprite_idx = sprite_idx,
    location = location,
    scale = scale,
    rotation = rotation,
    speed = speed,
    direction = direction,
    spin = spin,
  })
end
-- }}}

function _update(dt)
  -- input and player movement {{{
  if not State.stopped then
    State.input_vector = {
      x = bool_to_int(input.held(input.RIGHT)) -
          bool_to_int(input.held(input.LEFT)),
      y = bool_to_int(input.held(input.DOWN)) -
          bool_to_int(input.held(input.UP))
    }

    State.input_vector = util.vec_normalize(State.input_vector)
    State.location.x = (State.location.x + State.input_vector.x * SPEED * dt) % usagi.GAME_W
    State.location.y = (State.location.y + State.input_vector.y * SPEED * dt) % usagi.GAME_H

    -- TODO: lerp vector for smooth rotation (maybe)
    if vec_magnitude(State.input_vector) ~= 0 then
      State.direction = math.atan(State.input_vector.y, State.input_vector.x)
    end
  end
  -- }}}

  -- game logic {{{
  if State.health <= 0 and not State.stopped then
    State.stopped = true
    effect.screen_shake(2, 2)
  end

  if not State.stopped then
    State.time = get_timer()
    if State.time - State.last_astroid > ASTROID_INTERVAL then
      spawn_astroid()
      State.last_astroid = State.time
    end
  end

  local destroy_list = {}

  for idx, value in ipairs(State.astroids) do
    value.location = {
      x = value.location.x + (value.direction.x * value.speed * dt),
      y = value.location.y + (value.direction.y * value.speed * dt)
    }

    value.rotation += dt * math.random(5) * value.spin

    -- player collisions
    if util.rect_overlap(
          {
            x = State.location.x,
            y = State.location.y,
            w = usagi.SPRITE_SIZE,
            h = usagi.SPRITE_SIZE,
          },
          {
            x = value.location.x,
            y = value.location.y,
            w = usagi.SPRITE_SIZE * value.scale,
            h = usagi.SPRITE_SIZE * value.scale,
          })
    then
      effect.hitstop(HITSTOP_INTERVAL)
      effect.flash(HITSTOP_INTERVAL, gfx.COLOR_RED)
      State.health -= DAMAGE * value.scale
      table.insert(destroy_list, idx)
    end

    -- astroid collisions
    for jdx, other in ipairs(State.astroids) do
      if idx == jdx then goto continue end -- don't compare value to value
      if util.rect_overlap(
            {
              x = value.location.x,
              y = value.location.y,
              w = usagi.SPRITE_SIZE * value.scale,
              h = usagi.SPRITE_SIZE * value.scale,
            },
            {
              x = other.location.x,
              y = other.location.y,
              w = usagi.SPRITE_SIZE * other.scale,
              h = usagi.SPRITE_SIZE * other.scale,
            })
      then
        local r1 = util.vec_normalize({
          x = other.direction.x - value.direction.x,
          y = other.direction.y - value.direction.y
        })
        local r2 = util.vec_normalize({
          x = value.direction.x - other.direction.x,
          y = value.direction.y - other.direction.y
        })
        value.direction = r1
        other.direction = r2
      end
      ::continue::
    end

    -- astroid off screen
    if
        value.location.x < 0 or value.location.x > usagi.GAME_W or
        value.location.y < 0 or value.location.y > usagi.GAME_H
    then
      table.insert(destroy_list, idx)
    end
  end

  for _, value in ipairs(destroy_list) do
    table.remove(State.astroids, value)
  end
  -- }}}

  -- debug controls {{{
  if usagi.IS_DEV then
    if input.key_held(input.KEY_F) then
      State.health -= 1
    end
    if input.key_pressed(input.KEY_R) then
      spawn_astroid()
    end
    if input.key_pressed(input.KEY_BACKTICK) then
      State.debug = not State.debug
    end
  end
  -- }}}
end

function _draw(dt)
  gfx.clear(gfx.COLOR_BLACK)

  -- player {{{
  gfx.spr_ex(
    SPRITES.player,
    State.location.x, State.location.y,
    false, false,
    State.direction,
    gfx.COLOR_WHITE, 1
  )
  --}}}

  -- astroids {{{
  for _, value in ipairs(State.astroids) do
    spr_scaled(
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

  -- timer {{{
  local time = State.time .. ""
  gfx.text(time, (usagi.GAME_W / 2) - (usagi.measure_text(time) / 2), 0, gfx.COLOR_WHITE)
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

  -- debug stuff {{{
  if usagi.IS_DEV and State.debug then
    gfx.text_ex(
      State.input_vector.x .. ", " .. State.input_vector.y, 0, 10, 1, 0, gfx.COLOR_GREEN, .7)
    gfx.text_ex("Astroids: " .. #State.astroids, 0, 20, 1, 0, gfx.COLOR_GREEN, .7)
  end
  -- }}}
end
