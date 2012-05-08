Gob = {
    x = 0,
    y = 0,
    angle = 0,
    time = 0.0,
    fps = 10,
    sprite = nil,
    currentFrame = 1,
}

Sprite = {
    scale = { x = 1, y = 1 },
    center = { x = 0, y = 0 },
    opacity = 1,
    anim = nil,
    hitbox = { x = 0, y = 0, w = 0, h = 0 },
}

function Gob:new(data)
    o = {}
    setmetatable(o, self)
    self.__index = self

    if data then
        for k, v in pairs(data) do
            o[k] = v
        end
    end

    return o
end

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

function Gob:draw()
    local sprite = self.sprite
    love.graphics.setColor(255, 255, 255, sprite.opacity * 255)
    if (sprite.anim) then
        love.graphics.drawq(
        sprite.image,
        sprite.anim.quads[self.currentFrame],
        self.x, self.y, -self.angle,
        sprite.scale.x, sprite.scale.y, sprite.center.x, sprite.center.y)
    else
        love.graphics.draw(
        sprite.image,
        self.x, self.y, -self.angle,
        sprite.scale.x, sprite.scale.y, sprite.center.x, sprite.center.y)
    end
end

function Gob:update(dt)
    for k,v in ipairs(getmetatable(self)) do
        print(k .. ": " .. v)
    end

    self.time = self.time + dt
    self.currentFrame = (math.floor(self.time * self.fps) % self.sprite.anim.count) + 1
end

function Gob:hitGob(obj)
    return rectsIntersect(
    self:getWorldSpaceBbox(),
    obj:getWorldSpaceBbox())
end

function Gob:getWorldSpaceBbox()
    local sprite = self.sprite
    local ul_x = self.x + sprite.hitbox.x - sprite.center.x
    local ul_y = self.y + sprite.hitbox.y - sprite.center.y
    local br_x = ul_x + sprite.hitbox.w
    local br_y = ul_y + sprite.hitbox.h
    return { ul_x = ul_x, ul_y = ul_y, br_x = br_x, br_y = br_y }
end

function rectsIntersect(rect1, rect2)
    return not (rect1.ul_x > rect2.br_x or rect1.br_x < rect2.ul_x or rect1.ul_y > rect2.br_y or rect1.br_y < rect2.ul_y)
end
