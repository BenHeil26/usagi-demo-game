--- @class Shockwave
--- @field location Usagi.Vec2 the location of the shockwave in screen coords
--- @field scale integer the size of the shockwave in multiples of usagi.SPRITE_SIZE
--- @field frames integer the current number of frames elapsed in the animation
local Shockwave = {}

--- Spawns a shockwave at the center of the specified location
--- @param location Usagi.Vec2
--- @param scale integer
--- @return Shockwave
function Shockwave.spawn(location, scale)
  return Shockwave:new({
    x = location.x + usagi.SPRITE_SIZE / 2 * scale,
    y = location.y + usagi.SPRITE_SIZE / 2 * scale
  }, scale)
end

--- Creates a new shockwave
--- @param location Usagi.Vec2
--- @param scale integer
--- @return Shockwave
function Shockwave:new(location, scale)
  local instance = setmetatable({}, self)
  self.__index = self
  instance.location = location
  instance.scale = scale
  instance.frames = 0
  return instance
end

function Shockwave:draw(dt)
  gfx.circ_fill(self.location.x, self.location.y,
    self.frames * self.scale, gfx.COLOR_WHITE)
end

return Shockwave
