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

local Initialise,Draw,Update, playerFilter, setAnim, updateDino

Initialise = function(coreAssets)
  readyForInput = false
  assets = coreAssets
  screenWidth, screenHeight = love.graphics.getDimensions()

  levelWorld = levelLoader.loadLevel(1) -- level 1 until I have more!
  local items, len = levelWorld:getItems()
  blockImage = levelRenderer.drawLevel(items,len, screenWidth, screenHeight)

  bub.x = 64;      bub.y = 0; bub.dx = 0; bub.dy = 0;
  bob.x = 64 * 18; bob.y = 0; bob.dx = 0; bob.dy = 0;
  levelWorld:add(bub, bub.x,bub.y,34,50) -- the hit boxes are smaller than the graphics
  levelWorld:add(bob, bob.x,bob.y,34,50)

  local sw = assets.creepSheet:getWidth()
  local sh = assets.creepSheet:getHeight()
  local grid = anim8.newGrid(64, 64, sw, sh, 0, 0)

  bub.anims['right'] = anim8.newAnimation(grid('5-10',1), 0.07)
  bub.anims['left'] = anim8.newAnimation(grid('3-8',2), 0.07)
  bub.anims['rightIdle'] = anim8.newAnimation(grid(3,1), 1)
  bub.anims['leftIdle'] = anim8.newAnimation(grid(10,2), 1)
  bub.anims['rightBurp'] = anim8.newAnimation(grid('3-4',1), 0.7)
  bub.anims['leftBurp'] = anim8.newAnimation(grid('10-9',2), 0.7)
  bub.anims['rightJump'] = anim8.newAnimation(grid('11-17',1), 0.1, 'pauseAtEnd')
  bub.anims['leftJump'] = anim8.newAnimation(grid('17-11',2), 0.1, 'pauseAtEnd')
  bub.anim = bub.anims['rightIdle']:clone()
  bub.currentAnim = 'rightIdle'
  bub.lastDir = 'right'

  bob.anims['right'] = anim8.newAnimation(grid('5-10',3), 0.07)
  bob.anims['left'] = anim8.newAnimation(grid('3-8',4), 0.07)
  bob.anims['rightIdle'] = anim8.newAnimation(grid(3,3), 1)
  bob.anims['leftIdle'] = anim8.newAnimation(grid(10,4), 1)
  bob.anims['rightBurp'] = anim8.newAnimation(grid('3-4',3), 0.7)
  bob.anims['leftBurp'] = anim8.newAnimation(grid('10-9',4), 0.7)
  bob.anims['rightJump'] = anim8.newAnimation(grid('11-17',3), 0.1, 'pauseAtEnd')
  bob.anims['leftJump'] = anim8.newAnimation(grid('17-11',4), 0.1, 'pauseAtEnd')
  bob.anim = bob.anims['leftIdle']:clone()
  bob.currentAnim = 'leftIdle'
  bob.lastDir = 'left'

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

-- set the animation for either bub or bob
setAnim = function(char)
  if not char.canJump then
    if (char.dx < 0) then
      char.lastDir = 'left'
      if (char.currentAnim ~= 'leftJump') then
        char.anim = char.anims['leftJump']:clone()
        char.currentAnim = 'leftJump'
      end
    elseif (char.dx > 0) then
      char.lastDir = 'right'
      if (char.currentAnim ~= 'rightJump') then
        char.anim = char.anims['rightJump']:clone()
        char.currentAnim = 'rightJump'
      end
    else
      local dirj = char.lastDir..'Jump'
      if (char.currentAnim ~= dirj) then
        char.anim = char.anims[dirj]:clone()
        char.currentAnim = dirj
      end
    end
  else
    if (char.dx < 0) then
      char.lastDir = 'left'
      char.currentAnim = 'left'
      char.anim = char.anims['left']
    elseif (char.dx > 0) then
      char.lastDir = 'right'
      char.currentAnim = 'right'
      char.anim = char.anims['right']
    else
      char.anim = char.anims[char.lastDir..'Idle']
      char.currentAnim = char.lastDir..'Idle'
    end
  end
end

updateDino = function (char, ctrl, dt)
    if ctrl.up then
      if (char.canJump) then
        char.dy = -200
        char.canJump = false
      end
    end
    if ctrl.down then char.dy = 0 end

    if ctrl.left then char.dx = math.max(-200, char.dx - 10)
    elseif ctrl.right then char.dx = math.min(200, char.dx + 10)
    else
      char.dx = char.dx / 2
      if char.dx > -1 and char.dx < 1 then char.dx = 0 end
    end

    char.canJump = false -- assume we're falling unless stopped
    char.dy = math.min(char.dy + 10, 400) -- gravity
    local goalX = char.x + (char.dx * dt)
    local goalY = char.y + (char.dy * dt)
    local actualX, actualY, cols, len = levelWorld:move(char, goalX, goalY, playerFilter)
    if (actualY == char.y) and (char.dy > 0) then
      char.dy = 0
      char.canJump = true
    end -- reset if blocked
    char.x = actualX
    char.y = actualY
    if (char.y > screenHeight) then -- fell off the bottom. wrap to top
      levelWorld:update(char, char.x, 0)
      char.y = 0
    end
    setAnim(char)
end

Update = function(dt, keyDownCount, connectedPad)
  if (dt > 1) then return end
  temp = temp + (dt * 70)
  if (temp > 100) then temp = 0 end

  local ctrl = {
    up = love.keyboard.isDown("up"),
    down = love.keyboard.isDown("down"),
    left = love.keyboard.isDown("left"),
    right = love.keyboard.isDown("right"),
    act = love.keyboard.isDown("space")
  }
  updateDino(bub, ctrl, dt)

  ctrl = {
    up = love.keyboard.isDown("w"),
    down = love.keyboard.isDown("s"),
    left = love.keyboard.isDown("a"),
    right = love.keyboard.isDown("d"),
    act = love.keyboard.isDown("ctrl")
  }
  updateDino(bob, ctrl, dt)


  bub.anim:update(dt)
  bob.anim:update(dt)

  protoFood.anim:update(dt)
end

Draw = function()
  love.graphics.setBackgroundColor(0, 0, 0, 255)
  love.graphics.draw(assets.levelBg1, 0, 0, 0, 1, 1)
  love.graphics.draw(blockImage, 0, 0, 0, 1, 1)

  love.graphics.setColor(255, 255, 255, 255)

  bub.anim:draw(assets.creepSheet,bub.x - 16, bub.y - 14, 0, zoom)
  bob.anim:draw(assets.creepSheet,bob.x - 16, bob.y - 14, 0, zoom)

  --[[
  love.graphics.setFont(assets.smallfont)
  centreSmallString("sprite test", screenWidth/2, screenHeight/2, 2)
  protoFood.anim:draw(assets.creepSheet,70, 70,0, zoom / 2)]]
end

return {
  Initialise = Initialise,
  Draw = Draw,
  Update = Update
}
