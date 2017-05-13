-- reads levels into new 'bump' worlds

local bump = require "bump"
local levelData = require "levels"

-- returns a populated bump world.
-- you can use `local items, len = world:getItems()` to
-- get a list of cells (for rendering etc)
local loadLevel = function(num)
  local world = bump.newWorld(128)
  local data = levelData[num]
  local x,y
  for y=1,#data do
    local row = data[y]
    local len = string.len(row)
    for x=1,len do
      local cell = string.sub(row, x,x)
      if (cell == "#") then
        local block = {
          isWall=true, x = (x-1)*64, y = (y)*64
        }
        world:add(block, block.x,block.y,64,64)
      end
    end
  end
  return world
end

return {
  loadLevel = loadLevel
}
