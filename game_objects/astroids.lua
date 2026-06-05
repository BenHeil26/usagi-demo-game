--- @class Astroid
--- @field sprite_idx integer the index of the sprite on the sprite sheet
--- @field location Usagi.Vec2 the location in screen coords
--- @field scale integer the scale of the sprite and collider
--- @field rotation number the rotation in radians
--- @field speed integer the linear speed of the
--- @field direction Usagi.Vec2 the direction as a vector in screen coords
--- @field spin number the spin direction of the sprite
local Astroid = {}

--- Creates a new astroid on the edge of the screen
--- @return Astroid
function Astroid.spawn()
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

  return Astroid:new(sprite_idx, location, scale, rotation, speed, direction, spin)
end

function Astroid:new(sprite_idx, location, scale, rotation, speed, direction, spin)
  local instance = setmetatable({}, self)
  self.__index = self
  instance.sprite_idx = sprite_idx
  instance.location = location
  instance.scale = scale
  instance.rotation = rotation
  instance.speed = speed
  instance.direction = direction
  instance.spin = spin
  return instance
end

--- updates self
--- @param dt number the time elapsed between this frame and the last one
function Astroid:update(dt)
  self.location = {
    x = self.location.x + (self.direction.x * self.speed * dt),
    y = self.location.y + (self.direction.y * self.speed * dt)
  }

  self.rotation += dt * math.random(5) * self.spin
end

--- Draws self to the screen
function Astroid:draw()

end

return Astroid
