--[[
    Creeps! Or in this case, rubber ducks. Creepy buggers.
]]

Creep = Class{}

function Creep:init()

    self.wave = 0

    self.width = 98
    self.height = 136

    -- to find center point, supports rotation
    self.xOffset = 49
    self.yOffset = 68

    -- if I want to scale the creep later on
    self.scaleX = 1
    self.scaleY = 1

    -- hand drawn rubber ducks
    self.texture = love.graphics.newImage('images/duckies.png')

    self.frames = {}

    self.currentFrame = nil

    self.type = 'yellow'

    self.direction = 'right'

    -- Velocity
    self.dx = 0
    self.dy = 0

    -- Spawn position
    self.y = 0
    self.x = -96

    -- Properties for some stuff
    self.alive = true
    self.slowTimer = 0
    self.direction = 'right'

    -- creep animations, so they wiggle their tail feathers
    self.animations = {
        ['yellow'] = Animation({
            texture = self.texture,
            frames = {
                love.graphics.newQuad(0, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(98, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(0, 0, self.width, self.height, self.texture:getDimensions()),
            },
            interval = 0.15
        }),
        ['pink'] = Animation({
            texture = self.texture,
            frames = {
                love.graphics.newQuad(196, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(294, 0, self.width, self.height, self.texture:getDimensions()),
                love.graphics.newQuad(196, 0, self.width, self.height, self.texture:getDimensions()),
            },
            interval = 0.15
        }),
    }


end