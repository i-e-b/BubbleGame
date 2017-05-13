-- takes a bunch of level blocks and returns an image for it

local drawLevel, stencilLevel

local bList, bCount, w, h

stencilLevel = function ()
  local i
  for i=1,bCount do
    local block = bList[i] -- relies on the format returned by levelLoader.lua
    love.graphics.rectangle("fill", block.x, block.y, 64, 64)
  end
end

drawLevel = function(blockList, blockCount, width, height)
  -- copy params for the stencil function
  bList = blockList
  bCount = blockCount

  -- new blank transparent image
  local canv = love.graphics.newCanvas( width, height )
  love.graphics.setCanvas(canv)
  love.graphics.clear( )

  -- stencil to allow only where the blocks are
  love.graphics.stencil(stencilLevel, "replace", 1)
  love.graphics.setStencilTest("greater", 0)

  love.graphics.setColor(0, 64, 128, 255)
  love.graphics.rectangle("fill", 0, 0, width, height)

  -- draw in the blocks
  love.graphics.setColor(64, 128, 128, 70)
  for i=0,width do
    local x1 = i + math.random(0, 64) - 32
    local x2 = i + math.random(0, 64) - 32
    love.graphics.line(x1, 0, x2, height)
  end

  -- turn off stencil and restore drawing to screen
  love.graphics.setStencilTest()
  love.graphics.setCanvas()
  return canv
end

return {
  drawLevel = drawLevel
}
