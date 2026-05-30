function _config()
  return { name = "Demo Game", game_id = "com.usagiengine.demo-game" }
end

function _init()
  -- Live reload preserves globals across saved edits but resets locals.
  -- Stash mutable game state in a capitalized global like `State` so it
  -- survives reloads; F5 calls _init again to reset.
  State = {
    x = 10,
    y = 10,
    health = 100,
  }
end

SPEED = 50
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

function _update(dt)
  -- input
  if input.held(input.UP) then
    State.y -= SPEED * dt
  end
  if input.held(input.DOWN) then
    State.y += SPEED * dt
  end
  if input.held(input.RIGHT) then
    State.x += SPEED * dt
  end
  if input.held(input.LEFT) then
    State.x -= SPEED * dt
  end

  if input.key_held(input.KEY_F) then
    State.health -= 1
  end
end

function _draw(dt)
  gfx.clear(gfx.COLOR_BLACK)
  gfx.rect_fill(State.x, State.y, SIZE.x, SIZE.y, gfx.COLOR_PINK)
  -- health bar
  gfx.rect_ex(
    SCREEN.w - HEALTH_BAR.x - HEALTH_BAR.padding - HEALTH_BAR.thickness,
    SCREEN.h - HEALTH_BAR.y - HEALTH_BAR.padding - HEALTH_BAR.thickness,
    HEALTH_BAR.x + (2 * HEALTH_BAR.thickness),
    HEALTH_BAR.y + (2 * HEALTH_BAR.thickness),
    HEALTH_BAR.thickness,
    gfx.COLOR_WHITE)

  gfx.rect_fill(
    SCREEN.w - HEALTH_BAR.x - HEALTH_BAR.padding,
    SCREEN.h - HEALTH_BAR.y - HEALTH_BAR.padding,
    State.health,
    HEALTH_BAR.y,
    gfx.COLOR_RED)
end
