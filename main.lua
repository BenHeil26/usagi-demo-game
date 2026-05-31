function _config()
  return { name = "Demo Game", game_id = "com.usagiengine.demo-game" }
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
    x = 10,
    y = 10,
    direction = 0, -- angle in radians
    health = 100,
    stopped = false
  }
end

-- game constants
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

-- helper functions
local function bool_to_int(bool)
  return bool and 1 or 0
end

local function vec_magnitude(vec)
  return math.sqrt(vec.x ^ 2 + vec.y ^ 2)
end

function _update(dt)
  -- input and movement
  if not State.stopped then
    State.input_vector = {
      x = bool_to_int(input.held(input.RIGHT)) -
          bool_to_int(input.held(input.LEFT)),
      y = bool_to_int(input.held(input.DOWN)) -
          bool_to_int(input.held(input.UP))
    }

    State.input_vector = util.vec_normalize(State.input_vector)
    State.x = (State.x + State.input_vector.x * SPEED * dt) % usagi.GAME_W
    State.y = (State.y + State.input_vector.y * SPEED * dt) % usagi.GAME_H

    -- TODO: lerp vector for smooth rotation (maybe)
    if vec_magnitude(State.input_vector) ~= 0 then
      State.direction = math.atan(State.input_vector.y, State.input_vector.x)
    end
  end

  -- game logic
  if State.health <= 0 and not State.stopped then
    State.stopped = true
    effect.screen_shake(2, 2)
  end

  -- debug controls
  if usagi.IS_DEV then
    if input.key_held(input.KEY_F) then
      State.health -= 1
    end
  end
end

function _draw(dt)
  gfx.clear(gfx.COLOR_BLACK)

  -- player
  gfx.spr_ex(
    1,
    State.x, State.y,
    false, false,
    State.direction,
    gfx.COLOR_WHITE, 1
  )

  -- UI

  -- health bar
  local color = gfx.COLOR_GREEN
  if State.health < 25 then
    color = gfx.COLOR_RED
  else
    if State.health < 50 then
      color = gfx.COLOR_YELLOW
    end
  end


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
    color)


  -- game over
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

  -- debug stuff
  -- if usagi.IS_DEV then
  --   gfx.text(
  --     State.input_vector.x .. ", " .. State.input_vector.y, 10, 10, gfx.COLOR_GREEN)
  -- end
end
