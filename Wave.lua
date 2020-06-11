--[[
    Makes the waves appear on the map
]]

Wave = Class{}

require 'Creep'
require 'Util'

function Wave:init(map)
    self.map = map

    self.type = 'yellow'

    self.creeps = {}

    self.spawnTimer = 0

    -- How quickly the creeps spawn, in seconds
    self.spawnTimerMax = 1

    self.creepSpeed = 200

    self.creepCount = 0
    self.creepMax = 20

    self.wallZone = 192

    self.waveCount = 1

    self.baseCreepHealth = 50

    self.sounds = {
        ['pop'] = love.audio.newSource('sounds/pop.flac', 'static'),
        ['squeak1'] = love.audio.newSource('sounds/quack1.wav', 'static'),
        ['squeak2'] = love.audio.newSource('sounds/quack2.wav', 'static'),
        ['squeak3'] = love.audio.newSource('sounds/quack3.wav', 'static')
    }
end

function Wave:update(dt)
    if love.timer.getTime() > startTime and gameState == 'run' then
        self:updateCreeps(dt)
        if map.waveCount < map.maxWaves then
            map.nextWave = map.nextWave - dt
        else
            map.nextWave = 0
        end
    end
end

function Wave:render()
    for index, creep in ipairs(self.creeps) do
        --
        local rotation

        --rotate the sprite depending on which direction he's facing
        if creep.direction == 'up' then
            rotation = 0
        elseif creep.direction == 'right' then
            rotation = math.rad(90)
        elseif creep.direction == 'down' then
            rotation = math.rad(180)
        elseif creep.direction == 'left' then
            rotation = math.rad(270)
        end
        --
    
        -- draw the creep, with relevant rotation, assuming it's alive
        if creep.alive == true then
            love.graphics.draw(creep.texture, creep.currentFrame, math.floor(creep.x + creep.xOffset), 
            math.floor(creep.y + creep.yOffset), rotation, creep.scaleX, creep.scaleY, creep.xOffset, creep.yOffset)

            love.graphics.setColor(0, 1, 0, 1)
            love.graphics.rectangle("fill", creep.x, creep.y + creep.yOffset*2 + 10, 98 * (creep.health / creep.maxHealth), 10)
            love.graphics.setColor(1, 1, 1, 1)
        end
        --]]
    end
end

function Wave:updateCreeps(dt)
    if self.creepCount < self.creepMax then
        if self.spawnTimer > 0 then
            self.spawnTimer = self.spawnTimer - dt
        else
            self:spawnCreep()
            self.creepCount = self.creepCount + 1
            self.spawnTimer = self.spawnTimerMax
        end
    end

    for i = table.getn(self.creeps), 1, -1 do
        creep = self.creeps[i]

        -- Adjust speed based on if they've recently been hit by a slowing projectile
        if creep.slowTimer > 0 then
            creep.currentSpeed = creep.speed / 2
            creep.slowTimer = creep.slowTimer - dt
        else
            creep.currentSpeed = creep.speed
        end

        -- Make their way around the maze, colliding with walls and changing direction
        if creep.direction == 'right' then
            creep.dx = creep.currentSpeed
        
            if self:collides(self:tileAt(creep.x + 136 + math.random(-20, 20), creep.y)) then
                creep.dx = 0
                if self:collides(self:tileAt(creep.x, creep.y - self.wallZone)) then
                    creep.direction = 'down'
                    creep.dy = creep.currentSpeed
                elseif self:collides(self:tileAt(creep.x, creep.y + self.wallZone)) then
                    creep.direction = 'up'
                    creep.dy = -creep.currentSpeed
                end
            end
        elseif creep.direction == 'left' then
            creep.dx = -creep.currentSpeed
            if self:collides(self:tileAt(creep.x - math.random(20, 60), creep.y)) then
                creep.dx = 0
                if self:collides(self:tileAt(creep.x, creep.y - self.wallZone)) then
                    creep.direction = 'down'
                    creep.dy = creep.currentSpeed
                elseif self:collides(self:tileAt(creep.x, creep.y + self.wallZone)) then
                    creep.direction = 'up'
                    creep.dy = -creep.currentSpeed
                end
            end
        elseif creep.direction == 'down' then
            creep.dy = creep.currentSpeed
            if self:collides(self:tileAt(creep.x, creep.y + 136 + math.random(-20, 40))) then
                creep.dy = 0
                if self:collides(self:tileAt(creep.x + self.wallZone, creep.y)) then
                    creep.direction = 'left'
                    creep.dx = -creep.currentSpeed
                elseif self:collides(self:tileAt(creep.x - self.wallZone, creep.y)) then
                    creep.direction = 'right'
                    creep.dx = creep.currentSpeed
                end
            end
        elseif creep.direction == 'up' then
            creep.dy = -creep.currentSpeed
            if self:collides(self:tileAt(creep.x, creep.y - math.random(20, 60))) then
                creep.dy = 0
                if self:collides(self:tileAt(creep.x + self.wallZone, creep.y)) then
                    creep.dx = -creep.currentSpeed
                    creep.direction = 'left'
                elseif self:collides(self:tileAt(creep.x - self.wallZone, creep.y)) then
                    creep.dx = creep.currentSpeed
                    creep.direction = 'right'
                end
            end
        end

        -- update animations and the location of our ducky
        creep.currentFrame = creep.animation:getCurrentFrame()
        creep.x = creep.x + creep.dx * dt
        creep.y = creep.y + creep.dy * dt

        -- remove them when they run off the bottom or right, and lose a life
        if creep.x > VIRTUAL_WIDTH or creep.y > VIRTUAL_HEIGHT then
            lives = lives - 1
            creepsSurvived = creepsSurvived + 1
            table.remove(self.creeps, i)
            local squeak = math.random(3)
            if squeak == 1 then
                self.sounds['squeak1']:play()
            elseif squeak == 2 then
                self.sounds['squeak2']:play()
            else
                self.sounds['squeak3']:play()
            end
        end
    end

    creep.animation:update(dt)
    
    self:removeDeadCreeps()

    -- call the next wave if it's time
    if map.nextWave <= 0 and map.waveCount < map.maxWaves then
        self:nextWave()
    -- if we've called all waves and destroyed all creeps then complete the level
    elseif map.waveCount == map.maxWaves and table.getn(self.creeps) == 0 then
        map.completedLevel = true
    end

end

-- Stuff to make creeps appear
Creep = Creep{}

function Creep:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o 
end

function Wave:spawnCreep()

    -- Waves with fast (pink) creeps
    if map.waveCount == 5 or map.waveCount == 10 or map.waveCount == 15 or map.waveCount == 18 or map.waveCount == 20 then
        t = 'pink'
        s = self.creepSpeed * 2
        h = self.baseCreepHealth * (map.waveCount / 3)
        self.spawnTimerMax = 0.8
        scale = 1
        -- wave 20 (final wave) has 50 rather than 20 creeps, plus they spawn at a faster rate. A boss wave.
        if map.waveCount == 20 then
            self.creepMax = 50
        else
            self.creepMax = 20
        end
    -- 19 has giant yellow boss ducks 
    elseif map.waveCount == 19 then
        t = 'yellow'
        s = self.creepSpeed * 0.75
        h = self.baseCreepHealth * map.waveCount * 3
        scale = 1.5
        self.spawnTimerMax = 3
        self.creepMax = 10
    -- rest of the waves are standard yellow ducks
    else
        t = 'yellow'
        s = self.creepSpeed
        h = self.baseCreepHealth * map.waveCount
        scale = 1
        self.spawnTimerMax = 1
        self.creepMax = 20
    end 
    -- spawn new creep by adding it to the table with the properties defined above
    creep = Creep:new{y = 210 + math.random(20), dx = speed, speed = s, health = h, maxHealth = h, type = t, scaleX = scale, scaleY = scale}
    table.insert(self.creeps, creep)

    -- initialise animations and current frame
    creep.animation = creep.animations[creep.type]
    creep.currentFrame = creep.animation:getCurrentFrame()

end

-- things our creeps can collide with - to allow expansion for different types of side
function Wave:collides(tile)
    -- define our collidable tiles
    local collidables = {
        SIDE, RED_TOWER, BLUE_TOWER
    }

    -- iterate and return true if our tile type matches
    for _, v in ipairs(collidables) do
        if tile.id == v then
            return true
        end
    end

    return false
end

-- gets the tile type at a given pixel coordinate
function Wave:tileAt(x, y)
    return {
        x = math.floor(x / map.tileWidth) + 1,
        y = math.floor(y / map.tileHeight) + 1,
        id = self:getTile(math.floor(x / map.tileWidth) + 1, math.floor(y / map.tileHeight) + 1)
    }
end

-- returns an integer value for the tile at a given x-y coordinate
function Wave:getTile(x, y)
    return map.tiles[(y - 1) * map.mapWidth + x]
end

-- Removes the dead creeps
function Wave:removeDeadCreeps()
    for i = table.getn(self.creeps), 1, -1 do
        creep = self.creeps[i]
        if creep.health <= 0 then
            self.sounds['pop']:play()
            bank = bank + 5
            table.remove(self.creeps, i)
            -- keep track of how many we've killed
            creepsKilled = creepsKilled + 1
        end
    end
end

-- Calls the next wave and iterates the count
function Wave:nextWave()
    self.creepCount = 0
    map.nextWave = 30
    map.waveCount = map.waveCount + 1
end