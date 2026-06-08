local GameScene = require "scenes.game_scene"
local MenuScene = require "scenes.menu_scene"
--- @class SceneManager
--- @field scenes Scene[] An array of possible scenes, scenes are registered in code
--- @field current Scene The currently loaded scene (defaults to scenes[1])
local SceneManager = {}

--- Returns a new instance of SceneManager
---@return SceneManager
function SceneManager:new()
  local instance = setmetatable({}, self)
  self.__index = self
  instance.scenes = {
    MenuScene:new(instance),
    GameScene:new(instance),
  }
  instance.current = instance.scenes[1]
  instance.current:load()
  return instance
end

--- Loads the scene specified by the index
--- @param index integer
function SceneManager:load(index)
  self.current = self.scenes[index]
  self.current:load()
end

--- Runs the update loop of the currently loaded scene
--- @param dt number the time elapsed since the last update in seconds
function SceneManager:update(dt)
  self.current:update(dt)
end

--- Runs the draw loop of the currently loaded scene
--- @param dt number time elapsed since the last draw in seconds
function SceneManager:draw(dt)
  self.current:draw(dt)
end

return SceneManager
