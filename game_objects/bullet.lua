--- @class Bullet
--- @field location Usagi.Vec2 the current location of the bullet in screen coords
--- @field speed integer the speed the bullet travels in pixels
--- @field direction Usagi.Vec2 the direction the bullet is traveling
local Bullet = {}

--- Spawns a bullet at the tip of the player ship
--- @param location Usagi.Vec2
--- @param direction Usagi.Vec2
--- @return Bullet
function Bullet.spawn(location, direction)
  -- get the starting location
  local start = {
    x = location.x + (usagi.SPRITE_SIZE / 2)
        + (direction.x * (usagi.SPRITE_SIZE / 2)),
    y = location.y + (usagi.SPRITE_SIZE / 2)
        + (direction.y * (usagi.SPRITE_SIZE / 2)),
  }

  -- make a deep copy
  local dir_copy = {
    x = direction.x,
    y = direction.y,
  }

  return Bullet:new(start, BULLET_SPEED, dir_copy)
end

--- Creates a new bullet
--- @param location Usagi.Vec2
--- @param speed integer
--- @param direction Usagi.Vec2
--- @return Bullet
function Bullet:new(location, speed, direction)
  local instance = setmetatable({}, self)
  self.__index = self
  instance.location = location
  instance.speed = speed
  instance.direction = direction
  return instance
end

--- Updates this bullet
--- @param dt number the seconds between this frame and the last one
function Bullet:update(dt)
  self.location = {
    x = self.location.x + self.direction.x * self.speed * dt,
    y = self.location.y + self.direction.y * self.speed * dt,
  }
end

function Bullet:draw(dt)
  gfx.rect_ex(self.location.x, self.location.y, 1, 1, 1, gfx.COLOR_WHITE)
end

--- Returns true when this bullet collides with the other collider
--- @param other Usagi.Rect
--- @return boolean
function Bullet:colliding_with(other)
  return util.point_in_rect(self.location, other)
end

--- Returns true when this bullet is off screen
--- @return boolean
function Bullet:is_oob()
  return self.location.x < 0 or self.location.x > usagi.GAME_W or
      self.location.y < 0 or self.location.y > usagi.GAME_H
end

return Bullet
