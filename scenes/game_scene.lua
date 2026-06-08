require("constants")
local Scene        = require("scene")
local save_manager = require("save_manager")
local helpers      = require("helpers")
local Astroid      = require("game_objects.astroid")
local Bullet       = require("game_objects.bullet")
local Shockwave    = require("game_objects.shockwave")

--- @class GameScene : Scene
--- @field state State the current state of the scene
local GameScene    = setmetatable({}, { __index = Scene })

function GameScene:new(manager)
  local instance = Scene.new(self, manager)
  self.__index = self
  return instance
end

function GameScene:load()
  self.state = save_manager.load()
end

function GameScene:update(dt)
  -- input and player movement {{{
  if not self.state.stopped then
    self.state.input = {
      x = helpers.bool_to_int(input.held(input.RIGHT)) -
          helpers.bool_to_int(input.held(input.LEFT)),
      y = helpers.bool_to_int(input.held(input.DOWN)) -
          helpers.bool_to_int(input.held(input.UP))
    }

    self.state.player:update(dt, self.state.input)

    if input.pressed(input.BTN1) and self.state.ammo > 0 then
      table.insert(self.state.bullets, Bullet.spawn(self.state.player.location, self.state.player.direction))
      self.state.ammo -= 1
    end
  end
  -- }}}

  -- game logic {{{
  if self.state.health <= 0 and not self.state.stopped then
    self.state.stopped = true
    effect.screen_shake(2, 2)
    save_manager.save(self.state)
  end

  if self.state.stopped and input.pressed(input.BTN1) then
    self.state = save_manager.load()
  end

  if not self.state.stopped then
    self.state.time += dt
    if self.state.time - self.state.last_astroid > ASTROID_INTERVAL then
      table.insert(self.state.astroids, Astroid.spawn())
      self.state.last_astroid = self.state.time
    end
  end

  -- astroids {{{
  local destroy_astroids = {}

  for idx, astroid in ipairs(self.state.astroids) do
    astroid:update(dt)

    -- player collisions
    if astroid:colliding_with(self.state.player:get_collider())
        and not self.state.stopped
    then
      effect.hitstop(HITSTOP_INTERVAL)
      effect.flash(HITSTOP_INTERVAL, gfx.COLOR_RED)
      self.state.health -= DAMAGE * astroid.scale
      table.insert(destroy_astroids, idx)
    end

    -- astroid collisions
    for jdx, other in ipairs(self.state.astroids) do
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

  if self.state.ammo < MAX_AMMO and self.state.time - self.state.last_bullet > RELOAD_SPEED then
    self.state.ammo += 1
    self.state.last_bullet = self.state.time
  end

  local destroy_bullets = {}

  for idx, bullet in ipairs(self.state.bullets) do
    bullet:update(dt)

    -- astroid collision
    for jdx, other in ipairs(self.state.astroids) do
      if util.point_in_rect(bullet.location, other:get_collider()) then
        self.state.score += ASTROID_SCORE * other.scale
        table.insert(destroy_astroids, jdx)
        table.insert(destroy_bullets, idx)
        -- spawn at center of sprite
        table.insert(self.state.shockwaves, Shockwave.spawn(other.location, other.scale))
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

  for idx, shockwave in ipairs(self.state.shockwaves) do
    shockwave.frames += 1
    if shockwave.frames > SHOCKWAVE_FRAMES then
      table.insert(destroy_shockwaves, idx)
    end
  end

  -- }}}

  for _, value in ipairs(destroy_astroids) do
    table.remove(self.state.astroids, value)
  end

  for _, value in ipairs(destroy_bullets) do
    table.remove(self.state.bullets, value)
  end

  for _, value in ipairs(destroy_shockwaves) do
    table.remove(self.state.shockwaves, value)
  end

  -- }}}

  -- debug controls {{{
  if usagi.IS_DEV then
    if input.key_pressed(input.KEY_BACKTICK) then
      self.state.debug = not self.state.debug
    end
    if self.state.debug then
      if input.key_held(input.KEY_F) then
        self.state.health -= 1
      end
      if input.key_pressed(input.KEY_R) then
        Astroid.spawn()
      end
      if input.key_pressed(input.KEY_1) then
        self.state.shader_on = not self.state.shader_on
        if self.state.shader_on then
          gfx.shader_set('crt')
        else
          gfx.shader_set(nil)
        end
      end
    end
  end
  -- }}}
end

function GameScene:draw(dt)
  -- game_objects {{{
  self.state.player:draw(dt)

  for _, astroid in ipairs(self.state.astroids) do
    astroid:draw(dt)
  end

  for _, bullet in ipairs(self.state.bullets) do
    bullet:draw(dt)
  end

  for _, shockwave in ipairs(self.state.shockwaves) do
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
    self.state.health,
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
    if self.state.ammo >= i then
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
  local time = math.ceil(self.state.time) .. ""
  local score = self.state.score .. ""
  local high_score = "HI " .. self.state.high_score
  gfx.text(time, TIMER_OFFSET, usagi.GAME_H - STATUS_LINE_OFFSET, gfx.COLOR_WHITE)
  gfx.text(score, SCORE_OFFSET, usagi.GAME_H - STATUS_LINE_OFFSET, gfx.COLOR_WHITE)
  gfx.text(high_score, HIGH_SCORE_OFFSET, usagi.GAME_H - STATUS_LINE_OFFSET, gfx.COLOR_WHITE)
  -- }}}

  -- game over {{{
  if self.state.health <= 0 then
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
    local prompt_text = "Press [fire] to try again"
    gfx.text(
      prompt_text,
      (usagi.GAME_W / 2) - (usagi.measure_text(prompt_text) / 2),
      (usagi.GAME_H / 2) - GAME_OVER_OFFSET + 20,
      gfx.COLOR_RED
    )
    if self.state.score > self.state.high_score and
        usagi.elapsed % 2 < 1 -- make the text flash
    then
      local new_text = "NEW HIGH SCORE!"
      gfx.text(
        new_text,
        (usagi.GAME_W / 2) - (usagi.measure_text(new_text) / 2),
        (usagi.GAME_H / 2) - NEW_HIGH_SCORE_OFFSET,
        gfx.COLOR_RED
      )
    end
  end
  -- }}}

  -- }}}

  -- debug stuff {{{
  if usagi.IS_DEV and self.state.debug then
    -- input and direction vector
    gfx.text_ex(
      "I:" .. self.state.input.x .. ", " .. self.state.input.y, 0, 10, 1, 0, gfx.COLOR_GREEN, .5)
    gfx.text_ex(
      "D:" .. self.state.player.direction.x .. ", " .. self.state.player.direction.y, 0, 20, 1, 0, gfx.COLOR_GREEN, .5)
    gfx.text_ex(
      "Da:" .. self.state.player.sprite_direction, 0, 30, 1, 0, gfx.COLOR_GREEN, .5)
    -- astroid count
    gfx.text_ex("Astroids: " .. #self.state.astroids, 0, 40, 1, 0, gfx.COLOR_GREEN, .5)
    -- bullet count
    gfx.text_ex("Bullets: " .. #self.state.bullets, 0, 50, 1, 0, gfx.COLOR_GREEN, .5)
    gfx.text_ex("Ammo: " .. self.state.ammo, 0, 60, 1, 0, gfx.COLOR_GREEN, .5)

    -- astroid colliders
    for _, astroid in ipairs(self.state.astroids) do
      astroid:draw_debug(dt)
    end
    -- player collider
    self.state.player:draw_debug(dt)
  end
  -- }}}
end

return GameScene
