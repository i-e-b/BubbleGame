--[[
  Load/New/Configure: the first screen on loading
]]
local flux = require "flux"   -- movement tweening. Modified from standard

local assets -- local copy of game-wide assets
local screenWidth, screenHeight
local currentGame
local readyForInput

local anim = {i=0}

local selectionYtop = 300
local selection = 1
local selectionMax = 3

local Initialise, Update, LoadState, Draw, Reset, triggerClick, triggerAction,
      drawBgToImg

Initialise = function(coreAssets)
  readyForInput = false
  assets = coreAssets
  screenWidth, screenHeight = love.graphics.getDimensions()
  Reset()
end

Reset = function()
  selection = 1
end

Update = function(dt, keyDownCount)
  anim.i = anim.i + dt
  flux.update(dt)
end


Draw = function()
  love.graphics.setBackgroundColor(222, 69, 123, 255)
  love.graphics.setColor(255, 255, 255, 255)

  local x = (screenWidth - assets.gameOverbg:getWidth()) / 2
  local y = (screenHeight - assets.gameOverbg:getHeight()) / 2
  love.graphics.draw(assets.gameOverbg, x, y - 100, 0, 1, 1)

  love.graphics.setFont(assets.bigfont)
  local title = "YOU WIN"
  local leftE = (screenWidth / 4)
  local offs = screenWidth / 14
  for i=1,7 do
    local r = (math.sin(anim.i + i) + 1) * 126
    local g = (math.cos(anim.i + i) + 1) * 126
    local b = (-math.sin(anim.i + i) + 1) * 126
    love.graphics.setColor(r, g, b, 255)
    local x = leftE + (offs*i) - (math.sin(anim.i + i) * offs * 0.4)
    local y = screenHeight - 170 + (math.cos(anim.i + i) * 7)
    love.graphics.setColor(r, g, b, 255)
    centreBigString(string.sub(title,i,i), x, y, 3)
  end

end


return {
  Initialise = Initialise,
  Draw = Draw,
  Update = Update,
  Reset = Reset
}
