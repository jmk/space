require "sprite"

function initStars(width, height)
    local stars = {}
    for i = 1, 100 do
        table.insert(stars, {
            x = math.random(width),
            y = math.random(height),
            z = (math.random() ^ 4) * 0.9 + 0.1,
        })
    end
    return stars
end

function fire()
    local b = {
        x = sprites.carrot.x,
        y = sprites.carrot.y,
        speed = 400,
        angle = 0,  -- radians
    }
    bullets[b] = true
end

function loadImage(name)
    image = love.graphics.newImage(name)
    image:setFilter("nearest", "nearest")
    return image
end

function newAnim(img, numFrames)
    anim = {
        image = img,
        quads = {},
    }

    local width = img:getWidth()
    local height = img:getHeight()
    local frameWidth = width / numFrames
    local x = 0
    for i = 1, numFrames do
        table.insert(anim.quads,
            love.graphics.newQuad(x, 0, frameWidth, height, width, height)) 
        x = x + frameWidth
    end

    return anim
end

function love.load()
    -- establish scale factor
    scale = 2
    screenWidth = love.graphics.getWidth() / scale
    screenHeight = love.graphics.getHeight() / scale

    -- input state table
    input = {}
    controls = {
        [" "] = "fire",
        up = "up",
        down = "down"
    }

    images = {
        star = loadImage("star.png"),
    }

    sprites = {
        bg = Sprite:new("bg.png"),
        bullet = Sprite:new("bullet.png", {
            center = { x = 6, y = 2 },
        }),
        carrot = Sprite:newAnim("carrot.png", 5, {
            x = 20,
            y = 100,
            center = { x = 14, y = 6 },
        }),
    }

    stars = initStars(screenWidth, screenHeight)
    starSpeed = screenWidth * 1.5
    starWidth = images.star:getWidth()

    bullets = {}

    -- time the last bullet was fired
    lastFired = 0
    fireRate = 15  -- bullets per sec

    -- set font
    font = love.graphics.newFont("easta_seven_condensed.ttf", 8)
    love.graphics.setFont(font)

    -- misc setup
    love.graphics.setBackgroundColor(0, 0, 0)
end

function love.draw()
    love.graphics.scale(scale, scale)

    -- draw background
--    love.graphics.setColor(255, 255, 255, 255)
--    love.graphics.draw(images.bg, 0, 0)
    sprites.bg:draw()

    -- draw stars
    for i, s in ipairs(stars) do
        local starScale = math.max(1/starWidth, s.z)
        local x = math.floor(s.x + 0.5)
        local alpha = math.max(0.2, s.z) * 0.75

        if slow then
            starScale = starScale / 2
        end

        love.graphics.setColor(255, 255, 255, 255 * alpha)
        love.graphics.draw(images.star, s.x, s.y, 0, starScale, 1.0)
    end

    -- restore color
    love.graphics.setColor(255, 255, 255, 255)

    -- draw bullets
    for b in pairs(bullets) do
        sprites.bullet.x = b.x
        sprites.bullet.y = b.y
        sprites.bullet:draw()
    end

    -- draw ship
    sprites.carrot:draw()

    -- draw meaningless gibberish
    local bulletCount = 0
    for b in pairs(bullets) do bulletCount = bulletCount + 1 end
    love.graphics.print("bullets: " .. bulletCount, 10, 20)
    love.graphics.print("Seiji Ozawa quit, vexing rabid symphonic folk!", 10, 35)
end

function love.update(dt)
    -- if paused, bail
    if paused then
        return
    end

    handleInput()

    -- compute time scale
    local t = love.timer.getTime()
    local df = 1/fireRate  -- time between bullets
    if slow then
        dt = dt / 4
        df = df * 4
    end

    if input.fire then
        if (t - lastFired > df) then
            local n = 0
            for i = 1, (t - lastFired) / df do
                fire()
                n = n + 1
            end
            lastFired = lastFired + n * df
        end
    else
        -- XXX gross hack
        lastFired = t
    end

    -- update player
    if input.up then
        sprites.carrot.anim.currentFrame = 1
        sprites.carrot.y = sprites.carrot.y - 150 * dt
    elseif input.down then
        sprites.carrot.anim.currentFrame = 5
        sprites.carrot.y = sprites.carrot.y + 150 * dt
    else
        sprites.carrot.anim.currentFrame = 3
    end

    -- update stars
    for i, s in ipairs(stars) do
        s.x = s.x - s.z * starSpeed * dt
        if s.x < -starWidth then
            s.x = screenWidth + starWidth
            s.y = math.random(screenHeight)
        end
    end

    -- update bullets
    for b in pairs(bullets) do
        local dv = b.speed * dt
        local dx = math.cos(b.angle) * dv
        local dy = math.sin(b.angle) * dv
        b.x = b.x + dx
        b.y = b.y - dy

        -- XXX: need to account for bullet size!
        if b.x > screenWidth or b.y > screenHeight then
            bullets[b] = nil
        end
    end
end

function love.keypressed(key, unicode)
    if key == "escape" then
        paused = not paused
    elseif key == "s" then
        slow = not slow
    end
end

function handleInput()
    for key, state in pairs(controls) do
        input[state] = love.keyboard.isDown(key)
    end
end
