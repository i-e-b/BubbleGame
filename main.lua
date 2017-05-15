require "miniSound"           -- audio manager
local anim8 = require "anim8" -- character animations
local flux = require "flux"   -- movement tweening. Modified from standard
local backgroundGen = require "backgroundGen"

local state_titleScreen = require "state_titleScreen"
local state_game = require "state_game"

local screenWidth, screenHeight

local assets = {} -- fonts, images etc used by states
local currentJoystick = nil

local CurrentGlobalState = nil
local GameState = nil -- the current game. "New Game" resets, "Load" sets up

local keyDownCount = 0 -- helper for skip scenes

-- function defs
local runSetup,startGame,exitGame,pauseGame

-- Load non dynamic values
function love.load()
  love.window.fullscreen = (love.system.getOS() == "Android")
  screenWidth, screenHeight = love.graphics.getDimensions()

  assets.enableGamepad = true
  assets.gamepadMap = {up="a2p", down="a2n", left="a1p", right="a1n", action="b3"}

  assets.creepSheet = love.graphics.newImage("assets/creepSheet.png")
  assets.bigfont = love.graphics.newImageFont("assets/bigfont.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-.,?!")
  assets.smallfont = love.graphics.newImageFont("assets/smallfont.png", " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`'*#=[]>")
  assets.titlebg = love.graphics.newImage("assets/titlebg.png")
  assets.levelBg1 = backgroundGen.drawBgToImg(screenWidth, screenHeight, 244, 140, 170)


  assets.creepSheet:setFilter("linear", "nearest")
  assets.bigfont:setFilter("linear", "linear")
  assets.smallfont:setFilter("linear", "nearest")

  --[[ static only for small short and repeated sounds
  assets.munchSnd = love.audio.newSource("assets/munch.wav")
  assets.pickupSnd = love.audio.newSource("assets/pickup.wav")
  assets.shoveSnd = love.audio.newSource("assets/shove.wav")
  assets.saveSnd = love.audio.newSource("assets/save.wav")
  assets.walkSnd = love.audio.newSource("assets/walk.wav")
  assets.coinSnd = love.audio.newSource("assets/coin.wav")]]

  math.randomseed(os.time())
  state_titleScreen.Initialise(assets)
  state_game.Initialise(assets)

  love.handlers['runSetup'] = runSetup
  love.handlers['startGame'] = startGame
  love.handlers['exitGame'] = exitGame
  love.handlers['pauseGame'] = pauseGame

  love.audio.mute()
  CurrentGlobalState = state_titleScreen
end

-- A few useful global funcitons
function centreBigString (str, x, y, scale)
  scale = scale or 1
  local w = scale * assets.bigfont:getWidth(str) / 2
  love.graphics.print(str, math.floor(x - w), math.floor(y - (scale * 13.5)), 0, scale)
end
function centreSmallString(str, x, y, scale)
  scale = scale or 1
  local w = scale * assets.smallfont:getWidth(str) / 2
  love.graphics.print(str, math.floor(x - w), math.floor(y), 0, scale)
end

function indexInTable(tab, obj)
  local i
  for i=1,#tab do
    if tab[i] == obj then return i end
  end
  return nil
end

runSetup = function()
  --[[state_configure.Reset()
  CurrentGlobalState = state_configure]]
end

runSetupGamepad = function()
  --[[state_configureGamepad.Reset()
  CurrentGlobalState = state_configureGamepad]]
end

startGame = function()
  --[[if (GameState == nil) then return end]]
  CurrentGlobalState = state_game
end
pauseGame = function()
  --[[if (CurrentGlobalState ~= state_game) then return end
  state_pause.Reset()
  CurrentGlobalState = state_pause]]
end
exitGame = function()
  state_titleScreen.Reset()
  CurrentGlobalState = state_titleScreen
end

-- connect joysticks and gamepads
function love.joystickadded(joystick)
  currentJoystick = joystick
end

function love.joystickremoved(joystick)
  if (currentJoystick == joystick) then
    currentJoystick = nil
  end
end

-- Update, with frame time in fractional seconds
function love.update(dt)
  love.audio.update(dt)

  --[[if (GameState and GameState.LevelComplete) then
    if (GameState.LevelShouldAdvance) then
      state_game.AdvanceLevel(GameState)
      if (levelNames[GameState.Level]) then
        state_game.LoadState(levelNames[GameState.Level], GameState)
        CurrentGlobalState = state_game
      else
        state_finalScreen.LoadState(GameState)
        CurrentGlobalState = state_finalScreen
      end
    else
      state_levelEnd.LoadState(GameState)
      CurrentGlobalState = state_levelEnd
    end
  end]]

  local activeStick = currentJoystick
  if (not assets.enableGamepad) then activeStick = nil end
  CurrentGlobalState.Update(dt, keyDownCount, activeStick)
end

-- Draw a frame
function love.draw()
  CurrentGlobalState.Draw()
end

function love.keypressed(key)
  keyDownCount = keyDownCount + 1
  if key == 'escape' then
    love.event.quit()
  end
end
function love.joystickpressed(joystick,button)
  keyDownCount = keyDownCount + 1
  if button == 10 then pauseGame() end
end
function love.mousepressed( x, y, button, istouch )
  keyDownCount = keyDownCount + 1
end

function love.keyreleased(key)
  keyDownCount = keyDownCount - 1
end
function love.mousereleased( x, y, button, istouch )
  keyDownCount = keyDownCount - 1
end
function love.joystickreleased(joystick,button)
  keyDownCount = keyDownCount - 1
end
