Cannon = {
    fireRate = 1,   -- bullets per sec
    lastFired = -1, -- time since last fired
    bullets = {},
    sprite = Sprite:new("images/bullet.png", {
        center = { x = 6, y = 2 },
        hitbox = { x = 0, y = 0, w = 12, h = 5 },
    }),

    -- XXX class inheritance would be really handy for this ...
    bulletFunc = nil,
}

function Cannon:new(data)
    s = {}
    setmetatable(s, self)
    self.__index = self

    if data then
        for k, v in pairs(data) do
            s[k] = v
        end
    end

    return s
end

function Cannon:update(dt, fire, x, y)
    local fireInterval = 1/self.fireRate  -- time between bullets

    -- update existing bullets
    for b_i, b in pairs(self.bullets) do
        local dv = b.speed * dt
        local dx = math.cos(b.angle) * dv
        local dy = math.sin(b.angle) * dv
        if enableBulletAnim then
            b.x = b.x + dx
            b.y = b.y - dy
        end

        -- XXX: need to account for bullet size!
        if b.x < 0 or b.x > screenWidth or b.y < 0 or b.y > screenHeight then
            table.remove(self.bullets, b_i)
        end
    end

    -- fire new bullets
    if fire then
        if (self.lastFired == -1) then
            -- start firing immediately
            self.lastFired = fireInterval
        end

        if (self.lastFired >= fireInterval) then
            local n = 0
            for i = 1, (self.lastFired / fireInterval) do
                self:fire(x, y)
                n = n + 1
            end
            self.lastFired = 0
        else
            self.lastFired = self.lastFired + dt
        end
    else
        -- not firing; reset
        self.lastFired = -1
    end
end

function Cannon:hitGobs(gobs)
    for s_i, s in pairs(enemies) do
        for b_i, b in ipairs(self.bullets) do
            if (b:hitGob(s)) then
                table.remove(self.bullets, b_i)
                if (s.hit <= 0) then
                    s.hit = 20
                end
--                spawnCollectible(b.x, b.y)
            end
        end
    end
end

function Cannon:draw()
    for _, b in pairs(self.bullets) do
        b:draw()
    end
end

function Cannon:fire(x, y)
    firedBullets = self.bulletFunc(self, x, y)
    for _, b in ipairs(firedBullets) do
        b.sprite = self.sprite
        table.insert(self.bullets, b)
    end
end

--
-- the armory
--

function twin(cannon, x, y)
    local dist = 4
    return {
        Gob:new({
            x = x,
            y = y - dist,
            speed = 500,
            angle = 0
        }),
        Gob:new({
            x = x,
            y = y + dist,
            speed = 500,
            angle = 0
        }),
    }
end

function hose(cannon, x, y)
    local b = Gob:new(
    {
        x = x,
        y = y,
        speed = 500 * math.random(75, 125) / 100,
        angle = math.rad((math.random() * 2 - 1) * 5),
    })
    return {b}
end

function spread(cannon, x, y)
    local bullets = {}
    local count = 5
    for i = 1, count do
        local angle = 20 - (math.floor(40 * (i - 1) / (count - 1)))
        local b = Gob:new(
        {
            x = x,
            y = y,
            speed = 400,
            angle = math.rad(angle),
        })
        table.insert(bullets, b)
    end
    return bullets
end

function wtf(cannon, x, y)
    local bullets = {}
    local count = 50
    for i = 1, count do
        local b = Gob:new(
        {
            x = x,
            y = y,
            speed = 300,
            angle = math.rad(i / count * 360),
        })
        table.insert(bullets, b)
    end
    return bullets
end

local weapons = {
    Cannon:new({
        fireRate = 10,
        bulletFunc = twin,
    }),
    Cannon:new({
        fireRate = 7,
        bulletFunc = spread,
    }),
    Cannon:new({
        fireRate = 100,
        bulletFunc = hose,
    }),
    Cannon:new({
        fireRate = 10,
        bulletFunc = wtf,
    }),
}

local currentWeapon = 1
function switchWeapon()
    currentWeapon = (currentWeapon + 1)

    -- fucking 1-based arrays, man
    if (currentWeapon > #weapons) then
        currentWeapon = 1
    end
end

function getWeapon()
    return weapons[currentWeapon]
end
