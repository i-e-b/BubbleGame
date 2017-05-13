-- functions to generate images

drawBgToImg = function (width, height, r,g,b)
  local canv = love.graphics.newCanvas( width, height )

  love.graphics.setCanvas(canv)

  love.graphics.clear( )
  love.graphics.setColor(r, g, b, 10)
  local my = 7000
  for i=1,my do
    local x = math.random(0, width)
    local y = math.random(i / 2, height - (i/2))
    love.graphics.circle('fill', x, y, 30, 40)
  end

  love.graphics.setCanvas()
  return canv
end

return {
  drawBgToImg = drawBgToImg
}
