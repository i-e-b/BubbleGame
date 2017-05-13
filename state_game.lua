-- The main game logic and rendering

local anim8 = require "anim8" -- character animations
local flux = require "flux"   -- movement tweening. Modified from standard
local bump = require "bump"   -- collision detection
local levelLoader = require "levelLoader"
local levelRenderer = require "levelBlockRenderer"

local assets -- local copy of game-wide assets
local levelWorld, blockImage -- level collision and graphics
local screenWidth, screenHeight
local readyForInput

local bub = {isPlayer=true, anims={}, canJump=false} -- green dino
local bob = {isPlayer=true, anims={}, canJump=false} -- blue dino
local zen = {isCreep=true, anims={}} -- wind up robot
local protoFood = {}

local temp = 0

local Initialise,Draw,Update, playerFilter

Initialise = function(coreAssets)
  readyForInput = false
  assets = coreAssets
  screenWidth, screenHeight = love.graphics.getDimensions()

  levelWorld = levelLoader.loadLevel(1) -- level 1 until I have more!
  local items, len = levelWorld:getItems()
  blockImage = levelRenderer.drawLevel(items,len, screenWidth, screenHeight)

  bub.x = 64;      bub.y = 0; bub.dx = 0; bub.dy = 0;
  bob.x = 64 * 18; bob.y = 0; bob.dx = 0; bob.dy = 0;
  levelWorld:add(bub, bub.x,bub.y,42,50)
  levelWorld:add(bob, bob.x,bob.y,42,50)

  local sw = assets.creepSheet:getWidth()
  local sh = assets.creepSheet:getHeight()
  local grid = anim8.newGrid(64, 64, sw, sh, 0, 0)

  bub.anims['right'] = anim8.newAnimation(grid('5-10',1), 0.07)
  bub.anims['left'] = anim8.newAnimation(grid('3-8',2), 0.07)
  bub.anims['rightBurp'] = anim8.newAnimation(grid('3-4',1), 0.7)
  bub.anims['leftBurp'] = anim8.newAnimation(grid('10-9',2), 0.7)
  bub.anims['rightJump'] = anim8.newAnimation(grid('11-17',1), 0.1)--, 'pauseAtEnd')
  bub.anims['leftJump'] = anim8.newAnimation(grid('17-11',2), 0.1)--, 'pauseAtEnd')

  bob.anims['right'] = anim8.newAnimation(grid('5-10',3), 0.07)
  bob.anims['left'] = anim8.newAnimation(grid('3-8',4), 0.07)
  bob.anims['rightBurp'] = anim8.newAnimation(grid('3-4',3), 0.7)
  bob.anims['leftBurp'] = anim8.newAnimation(grid('10-9',4), 0.7)
  bob.anims['rightJump'] = anim8.newAnimation(grid('11-17',3), 0.1)--, 'pauseAtEnd')
  bob.anims['leftJump'] = anim8.newAnimation(grid('17-11',4), 0.1)--, 'pauseAtEnd')

  zen.anims['right'] = anim8.newAnimation(grid('1-6',5), 0.07)
  zen.anims['left'] = anim8.newAnimation(grid('1-6',6), 0.07)
  zen.anims['rightFall'] = anim8.newAnimation(grid('1-4',7), 0.09)
  zen.anims['leftFall'] = anim8.newAnimation(grid('1-4',8), 0.09)

  protoFood.anim = anim8.newAnimation(grid('8-11',6), 1)
end

playerFilter = function(item, other)
  if     other.isPlayer then return 'cross'
  elseif other.isWall   then return 'slide'
  elseif other.isFruit   then return 'cross'
  elseif other.isBubble then return 'bounce'
  --elseif other.isExit   then return 'touch'
  end
  -- else return nil
end

Update = function(dt, keyDownCount, connectedPad)
  if (dt > 1) then return end
  temp = temp + (dt * 70)
  if (temp > 100) then temp = 0 end

  if love.keyboard.isDown("up") then
    if (bub.canJump) then
      bub.dy = -200
      bub.canJump = false
    end
  end
  if love.keyboard.isDown("down") then bub.dy = 0 end

  if love.keyboard.isDown("left") then bub.dx = math.max(-200, bub.dx - 10)
  elseif love.keyboard.isDown("right") then bub.dx = math.min(200, bub.dx + 10)
  else
    bub.dx = bub.dx / 2
    if bub.dx > -1 and bub.dx < 1 then bub.dx = 0 end
  end

  bub.canJump = false -- assume we're falling unless stopped
  bub.dy = math.min(bub.dy + 10, 400) -- gravity
  local goalX = bub.x + (bub.dx * dt)
  local goalY = bub.y + (bub.dy * dt)
  local actualX, actualY, cols, len = levelWorld:move(bub, goalX, goalY, playerFilter)
  if (actualY == bub.y) and (bub.dy > 0) then
    bub.dy = 0
    bub.canJump = true
  end -- reset if blocked
  bub.x = actualX
  bub.y = actualY

  bub.anims['right']:update(dt)
  bub.anims['left']:update(dt)
  bub.anims['rightBurp']:update(dt)
  bub.anims['leftBurp']:update(dt)
  bub.anims['rightJump']:update(dt)
  bub.anims['leftJump']:update(dt)

  bob.anims['right']:update(dt)
  bob.anims['left']:update(dt)
  bob.anims['rightBurp']:update(dt)
  bob.anims['leftBurp']:update(dt)
  bob.anims['rightJump']:update(dt)
  bob.anims['leftJump']:update(dt)

  zen.anims['right']:update(dt)
  zen.anims['left']:update(dt)
  zen.anims['rightFall']:update(dt)
  zen.anims['leftFall']:update(dt)

  protoFood.anim:update(dt)
end

Draw = function()
  love.graphics.setBackgroundColor(0, 0, 0, 255)
  love.graphics.draw(assets.levelBg1, 0, 0, 0, 1, 1)
  love.graphics.draw(blockImage, 0, 0, 0, 1, 1)

  --sprite test
  love.graphics.setColor(255, 255, 255, 255)

  if not bub.canJump then
    if (bub.dx < 0) then
        bub.anims['leftJump']:draw(assets.creepSheet,bub.x - 9, bub.y - 14, 0, zoom)
    else
        bub.anims['rightJump']:draw(assets.creepSheet,bub.x - 9, bub.y - 14, 0, zoom)
    end
  else
    if (bub.dx < 0) then
        bub.anims['left']:draw(assets.creepSheet,bub.x - 9, bub.y - 14, 0, zoom)
    elseif (bub.dx > 0) then
        bub.anims['right']:draw(assets.creepSheet,bub.x - 9, bub.y - 14, 0, zoom)
    else
      bub.anims['leftBurp']:draw(assets.creepSheet,bub.x - 9, bub.y - 14, 0, zoom)
    end
  end

--[[
  love.graphics.setFont(assets.smallfont)
  centreSmallString("sprite test", screenWidth/2, screenHeight/2, 2)
  centreSmallString("esc to quit", screenWidth/2, 70+screenHeight/2, 2)

  local x = 300
  local y = 100
  local zoom = 1

  bub.anims['right']:draw(assets.creepSheet,x+ temp, y,0, zoom)
  bub.anims['left']:draw(assets.creepSheet,x - temp, y,0, zoom)
  bub.anims['rightBurp']:draw(assets.creepSheet,x, y+100,0, zoom)
  bub.anims['leftBurp']:draw(assets.creepSheet,x-70, y+100,0, zoom)
  bub.anims['rightJump']:draw(assets.creepSheet,x, y+180,0, zoom)
  bub.anims['leftJump']:draw(assets.creepSheet,x-70, y+180,0, zoom)

  x = 700
  bob.anims['right']:draw(assets.creepSheet,x + temp, y,0, zoom)
  bob.anims['left']:draw(assets.creepSheet,x - temp, y,0, zoom)
  bob.anims['rightBurp']:draw(assets.creepSheet,x, y+100,0, zoom)
  bob.anims['leftBurp']:draw(assets.creepSheet,x-70, y+100,0, zoom)
  bob.anims['rightJump']:draw(assets.creepSheet,x, y+180,0, zoom)
  bob.anims['leftJump']:draw(assets.creepSheet,x-70, y+180,0, zoom)

  x = 200
  y = 400
  zen.anims['right']:draw(assets.creepSheet,x + temp, y,0, zoom)
  zen.anims['left']:draw(assets.creepSheet,x - 70 - temp, y,0, zoom)
  zen.anims['rightFall']:draw(assets.creepSheet,x, y+100,0, zoom)
  zen.anims['leftFall']:draw(assets.creepSheet,x-70, y+100,0, zoom)

  protoFood.anim:draw(assets.creepSheet,70, 70,0, zoom / 2)]]
end

return {
  Initialise = Initialise,
  Draw = Draw,
  Update = Update
}
