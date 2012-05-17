Sprite = {
    scale = { x = 1, y = 1 },
    center = { x = 0, y = 0 },
    opacity = 1,
    anim = nil,
    hitbox = { x = 0, y = 0, w = 0, h = 0 },
}

function Sprite:new(imageName, data)
    s = {}
    setmetatable(s, self)
    self.__index = self

    -- load image. always use nearest interpolation for full retro flavor
    s.image = love.graphics.newImage(imageName)
    s.image:setFilter("nearest", "nearest")

    if data then
        for k, v in pairs(data) do
            s[k] = v
        end
    end

    return s
end

function Sprite:newAnim(imageName, numFrames, data)
    s = Sprite:new(imageName, data)

    -- populate sprite sheet table
    s.anim = {
        count = numFrames,
        quads = {},
    }

    local width = s.image:getWidth()
    local height = s.image:getHeight()
    local frameWidth = width / numFrames
    local x = 0
    for i = 1, numFrames do
        table.insert(s.anim.quads,
        love.graphics.newQuad(x, 0, frameWidth, height, width, height))
        x = x + frameWidth
    end

    return s
end
