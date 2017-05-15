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

local bub = {isPlayer=true, anims={}, canJump=false, burp=0, score=0} -- green dino
local bob = {isPlayer=true, anims={}, canJump=false, burp=0, score=0} -- blue dino
local protoZen = {isCreep=true, anims={}} -- wind up robot
local protoFood = {}

local bubbles = {} -- see `triggerBubble` and `updateBubbles` functions
local walkingZen = {} -- list of robots
local loots = {} -- list of food waiting to be picked up
local leftStartX, rightStartX

local Initialise,Draw,Update, playerFilter, setAnim, updateDino, triggerBubble,
      drawBubbles, updateBubbles, bubbleFilter, addZen, drawZens, zenFilter,
      spawnLoot, updateLoot, drawLoot, removeLoot, fruitFilter

Initialise = function(coreAssets)
  readyForInput = false
  assets = coreAssets
  screenWidth, screenHeight = love.graphics.getDimensions()

  levelWorld = levelLoader.loadLevel(1) -- level 1 until I have more!
  local items, len = levelWorld:getItems()
  blockImage = levelRenderer.drawLevel(items,len, screenWidth, screenHeight)

  leftStartX = 64
  rightStartX = 64 * 18
  bub.x = leftStartX;  bub.y = 0; bub.dx = 0; bub.dy = 0;
  bob.x = rightStartX; bob.y = 0; bob.dx = 0; bob.dy = 0;
  levelWorld:add(bub, bub.x,bub.y,34,50) -- the hit boxes are smaller than the graphics
  levelWorld:add(bob, bob.x,bob.y,34,50)

  local sw = assets.creepSheet:getWidth()
  local sh = assets.creepSheet:getHeight()
  local grid = anim8.newGrid(64, 64, sw, sh, 1, 1)

  bub.anims['right'] = anim8.newAnimation(grid('5-10',1), 0.07)
  bub.anims['left'] = anim8.newAnimation(grid('3-8',2), 0.07)
  bub.anims['rightIdle'] = anim8.newAnimation(grid(3,1), 1)
  bub.anims['leftIdle'] = anim8.newAnimation(grid(10,2), 1)
  bub.anims['rightBurp'] = anim8.newAnimation(grid('3-4',1), 0.1, 'pauseAtEnd')
  bub.anims['leftBurp'] = anim8.newAnimation(grid('10-9',2), 0.1, 'pauseAtEnd')
  bub.anims['rightJump'] = anim8.newAnimation(grid('11-17',1), 0.1, 'pauseAtEnd')
  bub.anims['leftJump'] = anim8.newAnimation(grid('17-11',2), 0.1, 'pauseAtEnd')
  bub.anim = bub.anims['rightIdle']:clone()
  bub.currentAnim = 'rightIdle'
  bub.lastDir = 'right'

  bob.anims['right'] = anim8.newAnimation(grid('5-10',3), 0.07)
  bob.anims['left'] = anim8.newAnimation(grid('3-8',4), 0.07)
  bob.anims['rightIdle'] = anim8.newAnimation(grid(3,3), 1)
  bob.anims['leftIdle'] = anim8.newAnimation(grid(10,4), 1)
  bob.anims['rightBurp'] = anim8.newAnimation(grid('3-4',3), 0.1, 'pauseAtEnd')
  bob.anims['leftBurp'] = anim8.newAnimation(grid('10-9',4), 0.1, 'pauseAtEnd')
  bob.anims['rightJump'] = anim8.newAnimation(grid('11-17',3), 0.1, 'pauseAtEnd')
  bob.anims['leftJump'] = anim8.newAnimation(grid('17-11',4), 0.1, 'pauseAtEnd')
  bob.anim = bob.anims['leftIdle']:clone()
  bob.currentAnim = 'leftIdle'
  bob.lastDir = 'left'

  protoZen.anims['right'] = anim8.newAnimation(grid('1-6',5), 0.07)
  protoZen.anims['left'] = anim8.newAnimation(grid('1-6',6), 0.07)
  protoZen.anims['rightFall'] = anim8.newAnimation(grid('1-4',7), 0.09)
  protoZen.anims['leftFall'] = anim8.newAnimation(grid('1-4',8), 0.09)

  protoFood.anim = anim8.newAnimation(grid('8-11',6), 1)

  addZen()
  addZen()
end

addZen = function ()
  local left = math.random(0,1) > 0.5
  local zen = { isCreep=true, anims=protoZen.anims, y=0, dy = 0 }
  if left then
    zen.x = leftStartX
    zen.lastDir = "right"
    zen.anim = zen.anims['right']:clone()
    zen.dx = 100
  else
    zen.x = rightStartX
    zen.lastDir = "left"
    zen.anim = zen.anims['left']:clone()
    zen.dx = 100
  end
  levelWorld:add(zen, zen.x, zen.y, 34, 38)
  table.insert(walkingZen, zen)
end

spawnLoot = function(x, y)
  local loot = {isFruit=true, x=x, y=y, dy= -240, age=0}
  loot.anim = protoFood.anim:clone()
  loot.anim:gotoFrame(math.random(1,4))

  levelWorld:add(loot, loot.x, loot.y, 32, 18)
  table.insert(loots, loot)
end

playerFilter = function(item, other)
  if     other.isWall   then return 'slide'
  elseif other.isFruit  then return 'cross'
  elseif other.isBubble then
    if (item.dy > 0) and (item.y + 42 < other.y) then
      return 'slide'
    else
      return 'cross'
    end
  else return nil end
end

zenFilter = function(item, other)
  if other.isWall then
    return 'slide'
  elseif other.isCreep then
    return 'touch'
  end
  return nil
end

fruitFilter = function(item, other)
  if other.isWall then return 'bounce' end
  return nil
end

bubbleFilter = function(item, other)
  if other.isCreep then return 'cross' end
  return nil
end

removeLoot = function(loot)
  local idx = indexInTable(loots, loot)
  if (idx > 0) then
    table.remove(loots, idx)
    levelWorld:remove(loot)
  end
end

-- set the animation for either bub or bob
setAnim = function(char)
  if char.burp > 0 then
    local burpAnim = char.lastDir.."Burp"
    if (char.currentAnim ~= burpAnim) then
      char.anim = char.anims[burpAnim]:clone()
      char.currentAnim = burpAnim
    end
    return
  end
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

-- trigger a new bubble
triggerBubble = function(char)
  local bubble = {x=char.x + 16, y=char.y + 28, age=0, isBubble=true, w=2, h=2}
  if char.lastDir == "left" then
    bubble.dx = -80
  else
    bubble.dx = 80
  end
  levelWorld:add(bubble, bubble.x, bubble.y, bubble.w, bubble.h)
  table.insert(bubbles, bubble)
end

updateZens = function(dt)
  local i
  for i=1,#walkingZen do
    local zen = walkingZen[i]
    zen.anim:update(dt)

    zen.dy = math.min(zen.dy + 10, 400) -- gravity
    local goalX = zen.x + (zen.dx * dt)
    local goalY = zen.y + (zen.dy * dt)
    local actualX, actualY, cols, len = levelWorld:move(zen, goalX, goalY, zenFilter)

    if (actualY <= zen.y) and (zen.dy > 0) then
      zen.dy = 0
    end
    if (actualX == zen.x) then -- flip on wall bump
      zen.dx = -zen.dx
      if (zen.dx < 0) then
        zen.lastDir = "left"
        zen.anim = zen.anims['left']:clone()
      else
        zen.lastDir = "right"
        zen.anim = zen.anims['right']:clone()
      end
    end

    zen.x = actualX
    zen.y = actualY

    if (zen.y > screenHeight) then -- fell off the bottom. wrap to top
      levelWorld:update(zen, zen.x, 0)
      zen.y = 0
    end
    if (zen.x < 0) or (zen.x > screenWidth) then -- out of bounds last resort
      zen.x = 64
      zen.y = 0
      levelWorld:update(zen, zen.x, zen.y)
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
    if ctrl.down then char.dy = 100 end

    if ctrl.left then char.dx = math.max(-200, char.dx - 10)
    elseif ctrl.right then char.dx = math.min(200, char.dx + 10)
    else
      char.dx = char.dx / 2
      if char.dx > -1 and char.dx < 1 then char.dx = 0 end
    end

    if (ctrl.act) or (char.burp > 0) then
      char.dx = 0
      if (char.burp > 0) then
        char.burp = char.burp - dt
      else
        triggerBubble(char)
        char.burp = 0.5
      end
    end

    char.canJump = false -- assume we're falling unless stopped
    char.dy = math.min(char.dy + 10, 400) -- gravity

    -- physics tests
    local goalX = char.x + (char.dx * dt)
    local goalY = char.y + (char.dy * dt)
    local actualX, actualY, cols, len = levelWorld:move(char, goalX, goalY, playerFilter)
    for i=1,len do
      local other = cols[i].other
      if (other.isBubble) and (other.age > 4) and (char.y + 42 > other.y) then
        other.shouldPop = true
      elseif (other.isFruit) and (other.age > 2) then
        removeLoot(other)
        char.score = char.score + 1
        other.shouldEat = true
      end
    end

    -- test for sitting on a surface
    if (actualY <= char.y) and (char.dy > 0) then
      char.dy = 0
      char.canJump = true
    end

    -- update to the new position
    char.x = actualX
    char.y = actualY

    -- test for out-of-bounds
    if (char.y > screenHeight) then -- fell off the bottom. wrap to top
      levelWorld:update(char, char.x, 0)
      char.y = 0
    end
    if (char.x < 0) or (char.x > screenWidth) then -- out of bounds last resort
      char.x = 64
      char.y = 0
      levelWorld:update(char, char.x, char.y)
    end

    setAnim(char)
end

updateBubbles = function(dt)
  local i
  for i=1,#bubbles do
    local b = bubbles[i]
    if (not b) then return end
    b.dx = (b.dx * (1 - dt)) + (math.random(0, 1) - 0.5)
    b.age = b.age + dt
    local goalX = b.x + (b.dx * dt)
    local goalY = b.y - (b.age * dt)

    local actualX, actualY, cols, len = levelWorld:move(b, goalX, goalY, bubbleFilter)
    b.x = actualX
    b.y = actualY

    -- check to see if we hit any zens
    if not b.captured then -- only if empty
      for i=1,len do
        local hit = cols[i]
        local idx = indexInTable(walkingZen, hit.other)
        if (idx > 0) then -- found a matching zen
          local zen = walkingZen[idx]
          b.captured = zen
          b.age = 3.4 -- half a second until it can be popped
          zen.anim = zen.anims[zen.lastDir.."Fall"]:clone()
          table.remove(walkingZen, idx)
          levelWorld:remove(zen)
          break -- one zen per bubble
        end
      end
    end

    -- update captured creeps' animations
    if b.captured then
      b.captured.anim:update(dt)
    end

    -- update the size
    local scale = b.age
    if (b.captured) then scale = 27 end
    b.w = scale + 2 + (math.sin(b.age * 7) * (scale / 7))
    b.h = scale + 2 + (math.cos(b.age * 7) * (scale / 7))
    levelWorld:update(b, b.x, b.y, b.w, b.h)

    -- any bubbles off the top are removed
    if (b.y < -30) then
      table.remove(bubbles, i)
      levelWorld:remove(b)
      i = i - 1
      -- re-add a captured creep
      if (b.captured) then
        b.captured.x = b.x
        b.captured.y = b.y
        b.captured.anim = b.captured.anims[b.captured.lastDir]
        levelWorld:add(b.captured, b.x, b.y, 34, 38)
        table.insert(walkingZen, b.captured)
      end
    end

    if (b.shouldPop) then
      table.remove(bubbles, i)
      levelWorld:remove(b)
      i = i - 1
      if (b.captured) then
        addZen()
        spawnLoot(b.x, b.y)
      end
    end
  end
end

updateLoot = function(dt)
    local i
    for i=1,#loots do
      local loot = loots[i]

      loot.age = loot.age + dt

      loot.dy = math.min(loot.dy + 10, 400) -- gravity
      local goalX = loot.x
      local goalY = loot.y + (loot.dy * dt)

      local actualX, actualY, cols, len = levelWorld:move(loot, goalX, goalY, fruitFilter)
      if actualY < goalY then
        loot.dy = math.min(-100, (-loot.dy) * 0.8) -- bounce
      end
      loot.x = actualX
      loot.y = actualY
    end
end

Update = function(dt, keyDownCount, connectedPad)
  if (dt > 1) then return end

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
    act = love.keyboard.isDown("lctrl")
  }
  updateDino(bob, ctrl, dt)

  updateBubbles(dt)
  updateZens(dt)
  updateLoot(dt)

  bub.anim:update(dt)
  bob.anim:update(dt)
end

drawBubbles = function ()
  local i
  for i=1,#bubbles do
    local b = bubbles[i]
    local cx = b.x + (b.w / 2)
    local cy = b.y + (b.h / 2)
    local sha = math.min(100, b.age * 4)

    if b.w > 2 then -- shadow
      love.graphics.setColor(0, 0, 0, sha)
      love.graphics.ellipse('fill', b.x + (b.w * 0.7), b.y + (b.h * 0.7), b.w * 0.7, b.h * 0.7)
    end

    if b.captured then
      love.graphics.setColor(255, 255, 255, 255)
      b.captured.anim:draw(assets.creepSheet, b.x - 16, b.y - 16)
    end

    love.graphics.setColor(70, 70, 128, 100)
    love.graphics.ellipse('fill', cx, cy, b.w, b.h)
    love.graphics.setColor(128, 128, 255, 255)
    love.graphics.ellipse('line', cx, cy, b.w, b.h)

    if b.w > 8 then
      love.graphics.setColor(255, 255, 255, 255)
      love.graphics.ellipse('fill', b.x, b.y, b.h / 4, b.w / 4) -- reflection
    end
  end
end

drawZens = function()
  local i
  love.graphics.setColor(255, 255, 255, 255)
  for i=1,#walkingZen do
    local zen = walkingZen[i]
    zen.anim:draw(assets.creepSheet,zen.x - 14, zen.y - 25)
  end
end

drawLoot = function()
  local i
  love.graphics.setColor(255, 255, 255, 255)
  for i=1,#loots do
    local loot = loots[i]
    loot.anim:draw(assets.creepSheet, loot.x, loot.y - 14, 0, 0.5)
  end
end

Draw = function()
  love.graphics.setBackgroundColor(0, 0, 0, 255)
  love.graphics.setColor(255, 255, 255, 255)
  love.graphics.draw(assets.levelBg1, 0, 0, 0, 1, 1)
  love.graphics.draw(blockImage, 0, 0, 0, 1, 1)

  love.graphics.setColor(255, 255, 255, 255)

  bub.anim:draw(assets.creepSheet,bub.x - 16, bub.y - 13)
  bob.anim:draw(assets.creepSheet,bob.x - 16, bob.y - 13)

  drawLoot()
  drawBubbles()
  drawZens()

  love.graphics.setFont(assets.smallfont)
  love.graphics.setColor(127, 255, 127, 255)
  centreSmallString(""..bub.score, 100, screenHeight - 40, 2)
  love.graphics.setColor(127, 127, 255, 255)
  centreSmallString(""..bob.score, screenWidth - 100, screenHeight - 40, 2)
end

return {
  Initialise = Initialise,
  Draw = Draw,
  Update = Update
}
