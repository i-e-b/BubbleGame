
function readJoy(n)
  local joysticks = love.joystick.getJoysticks()
  local joystick = joysticks[n]
  if (joystick == nil) then
    return { up = false, down = false, left = false, right = false, act = false }
  end

  local acnt = joystick:getAxisCount()
  local x = joystick:getAxis(1)
  local y = joystick:getAxis(acnt) -- on linux this is 2, on Windows it seems to be 5
  local btn = joystick:isDown(1,2,3,4,5,6,7,8,9,10,11)
  return {
    up = y < 0,
    down = y > 0,
    left = x < 0,
    right = x > 0,
    act = btn
  }
end
