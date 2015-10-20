function love.conf(t)
    t.window.height = 600
    t.window.width = 1200
    t.window.vsync = false -- XXX
    t.title = "veggie fighter 5000"

    -- disable unused modules
    t.modules.joystick = false
    t.modules.audio = false
    --t.modules.mouse = false
    t.modules.sound = false
    t.modules.physics = false
end
