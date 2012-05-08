function love.conf(t)
    t.screen.height = 600
    t.screen.width = 1200
    t.screen.vsync = false -- XXX
    t.title = "veggie fighter 5000"

    -- disable unused modules
    t.modules.joystick = false
    t.modules.audio = false
    --t.modules.mouse = false
    t.modules.sound = false
    t.modules.physics = false
end
