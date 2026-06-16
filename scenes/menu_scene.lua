require("constants")
local Scene = require("scene")

--- @class MenuScene : Scene
--- @field cursor_pos integer
local MenuScene = setmetatable({}, { __index = Scene })

function MenuScene:new(manager)
  local instance = Scene.new(self, manager)
  self.__index = self
  return instance
end

function MenuScene:load()
  self.cursor_pos = 1
end

function MenuScene:update(dt)
  if input.pressed(input.DOWN) and self.cursor_pos <= 1 then
    self.cursor_pos += 1
  end

  if input.pressed(input.UP) and self.cursor_pos >= #CURSOR_POSITIONS then
    self.cursor_pos -= 1
  end

  if input.pressed(input.BTN1) then
    if self.cursor_pos == 1 then
      self.manager:load(2)
    elseif self.cursor_pos == 2 then
      usagi.quit()
    end
  end
end

function MenuScene:draw(dt)
  -- title
  gfx.text_ex(
    "Asteroids",
    TITLE_POSITION.x,
    TITLE_POSITION.y,
    3,
    0,
    gfx.COLOR_WHITE,
    1
  )

  -- Play
  gfx.text("Play", PLAY_POSITION.x, PLAY_POSITION.y, gfx.COLOR_WHITE)

  -- Quit
  gfx.text("Quit", QUIT_POSITION.x, QUIT_POSITION.y, gfx.COLOR_WHITE)

  -- Cursor
  gfx.spr(SPRITES.player, PLAY_POSITION.x - 45, CURSOR_POSITIONS[self.cursor_pos])
end

return MenuScene
