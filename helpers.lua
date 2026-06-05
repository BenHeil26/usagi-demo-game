local helpers = {}

--- Converts a boolean value to integer
---   returns 1 if true and 0 otherwise
--- @param bool boolean
--- @return integer
function helpers.bool_to_int(bool)
  return bool and 1 or 0
end

--- Returns the scalar magnitude of a vector2
---   the magnitude of a vector2 is the cartisian product
---   of each component
---   m = sqrt(x^2 + y^2)
--- @param vec Usagi.Vec2
--- @return number
function helpers.vec_magnitude(vec)
  return math.sqrt(vec.x ^ 2 + vec.y ^ 2)
end

--- Draws a sprite to the screen scaled by `scale`
---   scale should be an integer value
---@param idx integer
---@param x integer
---@param y integer
---@param flip_x boolean
---@param flip_y boolean
---@param rotation number
---@param tint integer
---@param alpha number
---@param scale integer
function helpers.spr_scaled(idx, x, y, flip_x, flip_y, rotation, tint, alpha, scale)
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

return helpers
