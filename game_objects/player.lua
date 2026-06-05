--- @class Player
--- @field location Usagi.Vec2
--- @field direction Usagi.Vec2
--- @field sprite_direction number
local Player = {}

--- Creates a new player object
--- @param location Usagi.Vec2
--- @param direction Usagi.Vec2
--- @param sprite_direction number
--- @return Player
function Player:new(location, direction, sprite_direction)
  local instance = setmetatable({}, self)
  self.__index = self
  instance.location = location
  instance.direction = direction
  instance.sprite_direction = sprite_direction
  return instance
end

--- Get the bounding box for the player
--- @return Usagi.Rect
function Player:get_collider()
  return {
    x = self.location.x,
    y = self.location.y,
    w = usagi.SPRITE_SIZE,
    h = usagi.SPRITE_SIZE,
  }
end

--- Updates the player
--- @param dt number the seconds elapsed between this frame and the last one
--- @param input any
function Player:update(dt, input)
  self.location.x = (self.location.x + input.x * SPEED * dt) % usagi.GAME_W
  self.location.y = (self.location.y + input.y * SPEED * dt) % usagi.GAME_H
end

--- Draws the player on the screen
--- @param dt number the seconds elapsed between this frame and the last one
function Player:draw(dt)
  gfx.spr_ex(
    SPRITES.player,
    self.location.x, self.location.y,
    false, false,
    self.sprite_direction,
    gfx.COLOR_WHITE, 1
  )
end

--- Draws the player collider on the screen
--- @param dt number the seconds elapsed between this frame and the last one
function Player:draw_debug(dt)
  gfx.rect_ex(
    self.location.x, self.location.y,
    usagi.SPRITE_SIZE,
    usagi.SPRITE_SIZE,
    1, gfx.COLOR_GREEN
  )
end

return Player
