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

function initEnemies(count)
    local enemies = {}
    for i = 1, count do
        -- randomize start frame
		enemy = Object:new(
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

	local c = Object:new(
		{
			-- Object
			x = x,
			y = y,
			sprite = sprites.rbc,
			-- Collectible
			speed = -100 * math.random(75, 125) / 100,
			score = 100,
		})
	table.insert(collectibles, c)
end

function fire()
    local b = Object:new(
		{
			x = player.x,
			y = player.y,
			sprite = sprites.bullet,
	--        speed = 400,
	--        angle = 0,  -- radians
			speed = 500 * math.random(75, 125) / 100,
			angle = math.rad((math.random() * 2 - 1) * 5),

		})
	table.insert(bullets, b)
end

function loadImage(name)
    image = love.graphics.newImage(name)
    image:setFilter("linear", "linear")
    return image
end

function setTint(enable, amount)
    if (enable) then
        tintEffect:send("tint", amount)
        love.graphics.setPixelEffect(tintEffect)
    else
        love.graphics.setPixelEffect()
    end
end

function love.load()
    time = 0
	score = 0
	
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
        down = "down"
    }

    images = {
        star = loadImage("star.png"),
    }

    sprites = {
        bg = Sprite:new("bg.png"),
        bullet = Sprite:new("bullet.png", {
            center = { x = 6, y = 2 },
			hitbox = { x = 0, y = 0, w = 12, h = 5 },
        }),
        carrot = Sprite:newAnim("carrot.png", 5, {
            center = { x = 14, y = 6 },
			hitbox = { x = 0, y = 0, w = 28, h = 13 },
        }),
		candy = Sprite:newAnim("candy.png", 6, {
            center = { x = 8, y = 8 },
			--hitbox = { x = 0, y = 0, w = 16, h = 16 },
			hitbox = { x = 6, y = 2, w = 4, h = 11 },
        }),
		rbc = Sprite:newAnim("rbc.png", 6, {
			center = { x = 5, y = 5 },
			hitbox = { x = 0, y = 0, w = 11, h = 11 }
		}),
    }

	bg = Object:new(
		{
			x = 0,
			y = 0,
			sprite = sprites.bg,
		})
		
    stars = initStars(screenWidth, screenHeight)
    starSpeed = screenWidth * 1.5
    starWidth = images.star:getWidth()
	
	player = Object:new(
		{
			x = 20,
			y = 100,
			sprite = sprites.carrot,
		})

    enableBulletAnim = true
    bullets = {}
	collectibles = {}
	
    -- init enemies
    enemies = initEnemies(15)
    scatterEnemies()

    -- time the last bullet was fired
    lastFired = 0
    fireRate = 100  -- bullets per sec
--    fireRate = 15

    -- set font
    font = love.graphics.newFont("easta_seven_condensed.ttf", 8)
    love.graphics.setFont(font)

    -- init pixel effects (shaders)
    tintEffect = love.graphics.newPixelEffect(love.filesystem.read("tint.sl"))
    blurEffect = love.graphics.newPixelEffect(love.filesystem.read("blur.sl"))
    warpEffect = love.graphics.newPixelEffect(love.filesystem.read("warp.sl"))

    -- XXX hack
    blur = false
    blurEffect:send("radius", 25)
    blurEffect:send("angle", 0)
    warp = false

    -- misc setup
    love.graphics.setBackgroundColor(0, 0, 0)
	
	-- player input
	love.mouse.setVisible(false)
	love.mouse.setGrab(true)
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

    -- draw bullets
    for _, b in pairs(bullets) do
        b:draw()
    end

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
        love.graphics.setPixelEffect(blurEffect)
    end

    if (warp) then
        warpEffect:send("time", time)
        love.graphics.setPixelEffect(warpEffect)
    end

    love.graphics.draw(fb, 0, 0, 0, scale, scale)
    love.graphics.setPixelEffect()

    -- draw meaningless gibberish
--    local bulletCount = 0
--    for b in pairs(bullets) do bulletCount = bulletCount + 1 end
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
    local df = 1/fireRate  -- time between bullets
    if slow then
        dt = dt / 4
        df = df * 4
    end

    time = time + dt

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
	local deltaX, deltaY = getMouseDeltas()
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
    else
        player.currentFrame = 3
    end

    -- update stars
    for i, s in pairs(stars) do
        s.x = s.x - s.z * starSpeed * dt
        if s.x < -starWidth then
            s.x = screenWidth + starWidth
            s.y = math.random(screenHeight)
        end
    end

    -- update bullets
    for b_i, b in pairs(bullets) do
        local dv = b.speed * dt
        local dx = math.cos(b.angle) * dv
        local dy = math.sin(b.angle) * dv
        if enableBulletAnim then
            b.x = b.x + dx
            b.y = b.y - dy
        end

        -- XXX: need to account for bullet size!
        if b.x < 0 or b.x > screenWidth or b.y < 0 or b.y > screenHeight then
            table.remove(bullets, b_i)
        end
    end

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
		
		if (player:hitObject(c)) then
			score = score + c.score
			table.remove(collectibles, c_i)
		end
    end
	
    -- update candy
    for s_i, s in pairs(enemies) do
        s:update(dt)

        -- hit check
        for b_i, b in ipairs(bullets) do
            if (b:hitObject(s)) then
                table.remove(bullets, b_i)
                if (s.hit <= 0) then
                    s.hit = 20
                end
				spawnCollectible(b.x, b.y)
            end
        end
    end
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
        warpEffect = love.graphics.newPixelEffect(love.filesystem.read("warp.sl"))
    end
end

function handleInput()
    for key, state in pairs(controls) do
        input[state] = love.keyboard.isDown(key)
    end
end

function love.mousepressed(x, y)
	love.mouse.setGrab(false)
	love.mouse.setVisible(true)
end