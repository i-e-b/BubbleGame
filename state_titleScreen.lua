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
  if keyDownCount < 1 then readyForInput = true end
  if not readyForInput then return end
  if keyDownCount > 0 then readyForInput = false end

  local delta = 0
  -- PAD AND KEYBOARD: these have a two stage select and activate
  if love.keyboard.isDown("up") then delta = -1 end
  if love.keyboard.isDown("down") then delta = 1 end

  local doAction = love.keyboard.isDown("lctrl","return","space")

  if (gamepad) then
    -- currently hard-coded to my own game pad
    -- TODO: config screen should be able to set this
    local dy = gamepad:getAxis(2)
    if dy == 1 then delta = 1 end
    if dy == -1 then delta = -1 end
    if gamepad:isDown(1,2,3,4) then doAction = true end
  end


  -- MOUSE AND TOUCH: these activate immediately
  if love.mouse.isDown(1) then
    triggerClick(love.mouse.getPosition())
	end

  local touches = love.touch.getTouches()
  for i, id in ipairs(touches) do
    triggerClick(love.touch.getPosition(id))
  end

  selection = math.min(math.max(1, selection + delta), selectionMax)
  if doAction then
    triggerAction()
  end

  flux.update(dt)
end

triggerClick = function(x,y)
  if (math.abs(x - (screenWidth / 2)) > 300) then return end
  selection = math.floor((y - selectionYtop - 70) / 90) + 1
  if (selection < 1) then return end
  if (selection > selectionMax) then return end
  triggerAction()
end

triggerAction = function ()
  if (selection == 1) then
    love.event.push('startGame', nil)
  elseif (selection == 2) then
    love.event.push('runSetup')
  elseif (selection == 3) then
    love.event.quit()
  end
end

LoadState = function(gameState)
  -- todo: load, create new, save, etc.
  currentGame = gameState
end

Draw = function()
  love.graphics.setBackgroundColor(222, 69, 123, 255)
  love.graphics.setColor(255, 255, 255, 255)

  local sx = screenWidth / assets.titlebg:getWidth() -- background image scale
  local sy = screenHeight / assets.titlebg:getHeight()
  love.graphics.draw(assets.titlebg, 0, 0, 0, sx, sy)
  love.graphics.setFont(assets.bigfont)


  love.graphics.setFont(assets.bigfont)
  local title = "BUBBLES"
  local leftE = (screenWidth / 4)
  local offs = screenWidth / 14
  for i=1,7 do
    local r = (math.sin(anim.i + i) + 1) * 126
    local g = (math.cos(anim.i + i) + 1) * 126
    local b = (-math.sin(anim.i + i) + 1) * 126
    love.graphics.setColor(r, g, b, 255)
    local x = leftE + (offs*i) - (math.sin(anim.i + i) * offs * 0.4)
    local y = 140 + (math.cos(anim.i + i) * 7)
    love.graphics.setColor(r, g, b, 255)
    centreBigString(string.sub(title,i,i), x, y, 3)
  end

  love.graphics.setFont(assets.smallfont)
  local height = selectionYtop
  local xpos = screenWidth / 2
  love.graphics.setColor(255, 255, 255, 255)

    local strs = {" 20 Minutes ", " 10 Minutes ", " Quit "}
  strs[selection] = "[" .. strs[selection] .. "]"

  for i=1,selectionMax do
    height = height + 90
    centreSmallString(strs[i], xpos, height, 2)
  end
end


return {
  Initialise = Initialise,
  Draw = Draw,
  Update = Update,
  LoadState = LoadState,
  Reset = Reset
}
