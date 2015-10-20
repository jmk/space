require "gob"
require "sprite"
require "weapons"

local mathx = require "mathx"

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

function initEnemies(count)
    local enemies = {}
    for i = 1, count do
        -- randomize start frame
        enemy = Gob:new(
        {
            sprite = sprites.candy,
            time = math.random(100) / 100 + 100,
            hit = 0
        })
        table.insert(enemies, enemy)
    end

    return enemies
end

function scatterEnemies()
    for i, e in ipairs(enemies) do
        e.x = math.random(200) + 200
        e.y = math.random(200)
        e.fps = math.random(8, 14)
    end
end

function spawnCollectible(x, y)
    local c = Gob:new(
    {
        -- Gob
        x = x,
        y = y,
        sprite = sprites.thing,
        -- Collectible
        speed = -100 * math.random(75, 125) / 100,
        score = 100,
    })
    table.insert(collectibles, c)
end

function loadImage(name)
    image = love.graphics.newImage(name)
    image:setFilter("linear", "linear")
    return image
end

function setTint(enable, amount)
    if (enable) then
        tintEffect:send("tint", amount)
        love.graphics.setShader(tintEffect)
    else
        love.graphics.setShader()
    end
end

function love.load()
    EPSILON = 1E-3
    time = 0
    score = math.floor(math.random() * -1000000)

    -- establish scale factor
    scale = 3
    screenWidth = love.graphics.getWidth() / scale
    screenHeight = love.graphics.getHeight() / scale

    -- create offscreen render target
    fb = love.graphics.newCanvas(screenWidth, screenHeight)
    fb:setFilter("nearest", "nearest")

    -- input state table
    input = {}
    controls = {
        [" "] = "fire",
        up = "up",
        down = "down",
        left = "left",
        right = "right",
    }

    images = {
        star = loadImage("images/star.png"),
    }

    sprites = {
        bg = Sprite:new("images/bg.png"),
        carrot = Sprite:newAnim("images/carrot.png", 5, {
            center = { x = 14, y = 6 },
            hitbox = { x = 9, y = 5, w = 12, h = 3 },
        }),
        candy = Sprite:newAnim("images/candy.png", 6, {
            center = { x = 8, y = 8 },
            --hitbox = { x = 0, y = 0, w = 16, h = 16 },
            hitbox = { x = 6, y = 2, w = 4, h = 11 },
        }),
        thing = Sprite:newAnim("images/thing.png", 6, {
            center = { x = 5, y = 5 },
            hitbox = { x = 0, y = 0, w = 11, h = 11 }
        }),
    }

    bg = Gob:new(
    {
        x = 0,
        y = 0,
        sprite = sprites.bg,
    })

    stars = initStars(screenWidth, screenHeight)
    starSpeed = screenWidth * 1.5
    starWidth = images.star:getWidth()

    player = Gob:new(
    {
        x = 20,
        y = 100,
        sprite = sprites.carrot,
    })
    avgDeltaX = 0
    avgDeltaY = 0

    enableBulletAnim = true
    collectibles = {}

    -- init enemies
    enemies = initEnemies(15)
    scatterEnemies()

    -- set font
    font = love.graphics.newFont("fonts/easta_seven_condensed.ttf", 8)
    love.graphics.setFont(font)

    -- init pixel effects (shaders)
    tintEffect = love.graphics.newShader("shaders/tint.fs")
    blurEffect = love.graphics.newShader("shaders/blur.fs")
    warpEffect = love.graphics.newShader("shaders/warp.fs")

    -- XXX hack
    blur = false
    blurEffect:send("radius", 25)
    blurEffect:send("angle", 0)
    warp = false

    -- misc setup
    love.graphics.setBackgroundColor(0, 0, 0)

    -- player input
    love.mouse.setVisible(false)
    love.mouse.setGrabbed(true)
    love.mouse.setPosition(screenWidth / 2, screenHeight / 2)
    startX, startY = love.mouse.getPosition()
end

function getMouseDeltas()
    local startMouseX = screenWidth / 2 * scale
    local startMouseY = screenHeight / 2 * scale
    local currX, currY = love.mouse.getPosition()

    local deltaX = (currX - startMouseX) / scale
    local deltaY = (currY - startMouseY) / scale

    -- reset to middle of window
    love.mouse.setPosition(startMouseX, startMouseY)

    return deltaX, deltaY
end

function love.draw()
    love.graphics.push()
    love.graphics.setCanvas(fb)

    -- draw background
    --    love.graphics.setColor(255, 255, 255, 255)
    --    love.graphics.draw(images.bg, 0, 0)
    bg:draw()

    -- draw stars
    for i, s in ipairs(stars) do
        local starScale = math.max(1/starWidth, s.z)
        local x = math.floor(s.x + 0.5)
        local alpha = math.max(0.2, s.z) * 0.75

        if slow then
            starScale = starScale / 4
        end

        love.graphics.setColor(255, 255, 255, 255 * alpha)
        love.graphics.draw(images.star, s.x, s.y, 0, starScale, 1.0)
    end

    -- restore color
    love.graphics.setColor(255, 255, 255, 255)

    -- draw weapon
    drawWeapons()

    -- draw collectibles
    for _, c in pairs(collectibles) do
        c:draw()
    end

    -- draw ship
    player:draw()

    -- draw candy
    for i, e in pairs(enemies) do
        if (e.hit > 0) then
            setTint(true, 0.7)
        end

        e:draw()

        if (e.hit > 0) then
            e.hit = e.hit - 1
        end

        setTint(false, 0.0)
    end

    -- blit framebuffer to screen
    love.graphics.pop()
    love.graphics.setCanvas()

    if (blur) then
        love.graphics.setShader(blurEffect)
    end

    if (warp) then
        warpEffect:send("time", time)
        love.graphics.setShader(warpEffect)
    end

    love.graphics.draw(fb, 0, 0, 0, scale, scale)
    love.graphics.setShader()

    -- draw meaningless gibberish
    love.graphics.print("SCORE: " .. score, 10, 10, 0, scale, scale)
    --    love.graphics.print("Seiji Ozawa quit, vexing rabid symphonic folk!", 10, 25)
end

function love.update(dt)
    -- if paused, bail
    if paused then
        return
    end

    handleInput()

    -- compute time scale
    local t = time
    if slow then
        dt = dt / 4
    end

    time = time + dt

    -- update player
    local deltaX, deltaY = getMouseDeltas()

    player.currentFrame = 3

    if avgDeltaY < -EPSILON then
        player.currentFrame = 1
        -- detect case when player changing directions
    elseif mathx.sgn(avgDeltaY) ~= mathx.sgn(deltaY) then
        player.currentFrame = 3		
    elseif avgDeltaY > EPSILON then
        player.currentFrame = 5
    end

    -- keep 5 frame average of movement to figure out which way to turn the ship	
    avgDeltaY = (avgDeltaY + deltaY) / 2

    player.x = player.x + deltaX
    player.y = player.y + deltaY

    player.x = math.max(math.min(player.x, screenWidth), 0)
    player.y = math.max(math.min(player.y, screenHeight), 0)

    if input.up then
        player.currentFrame = 1
        player.y = player.y - 150 * dt
    elseif input.down then
        player.currentFrame = 5
        player.y = player.y + 150 * dt
    end

    if input.left then
        player.x = player.x - 150 * dt
    elseif input.right then
        player.x = player.x + 150 * dt	
    end

    -- update stars
    for i, s in pairs(stars) do
        s.x = s.x - s.z * starSpeed * dt
        if s.x < -starWidth then
            s.x = screenWidth + starWidth
            s.y = math.random(screenHeight)
        end
    end

    -- update collectibles
    for c_i, c in pairs(collectibles) do
        c:update(dt)

        local dv = c.speed * dt
        local dx = dv
        local dy = 0
        c.x = c.x + dx
        c.y = c.y - dy

        -- XXX: need to account for bullet size!
        if c.x < 0 or c.x > screenWidth or c.y < 0 or c.y > screenHeight then
            table.remove(collectibles, c_i)
        end

        if (player:hitGob(c)) then
            score = score + c.score
            table.remove(collectibles, c_i)
        end
    end

    -- update enemies
    for s_i, s in pairs(enemies) do
        s:update(dt)
    end

    -- update weapon
    updateWeapons(dt, input.fire, player.x, player.y)
end

function love.keypressed(key, unicode)
    if key == "p" then
        paused = not paused
    elseif key == "s" then
        slow = not slow
    elseif key == "d" then
        enableBulletAnim = not enableBulletAnim
    elseif key == "r" then
        scatterEnemies()
    elseif key == "b" then
        blur = not blur
    elseif key == "w" then
        warp = not warp
    elseif key == "escape" then	
        love.event.quit()
    elseif key == "return" then
        warpEffect = love.graphics.newShader("warp.fs")
    elseif key == "tab" then
        switchWeapon()
    end
end

function handleInput()
    for key, state in pairs(controls) do
        input[state] = love.keyboard.isDown(key)
    end
end
