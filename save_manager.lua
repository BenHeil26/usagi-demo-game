local Player = require('game_objects.player')

--- @class SaveFile
--- @field high_score integer

local save_manager = {}

--- Converts a state to a save file and persists
--- @param state State
function save_manager.save(state)
  --- @type SaveFile
  local save_file = {
    high_score = state.score > state.high_score
        and state.score or state.high_score
  }

  usagi.save(save_file)
end

--- Loads a save file and returns a valid state
--- @return State
function save_manager.load()
  --- @type SaveFile
  local save_file = usagi.load()
      or {
        high_score = 0
      }

  --- @type State
  return {
    player = Player:new(
      {
        x = usagi.GAME_W / 2,
        y = usagi.GAME_H / 2,
      },
      {
        x = 1,
        y = 0,
      },
      0
    ),
    input = {
      x = 0,
      y = 0
    },
    health = 100,
    astroids = {},
    shockwaves = {},
    bullets = {},
    stopped = false,
    ammo = 5,
    last_bullet = 0,
    time = 0,
    score = 0,
    high_score = save_file.high_score,
    last_astroid = 0,
    debug = false,
    shader_on = true,
  }
end

return save_manager
