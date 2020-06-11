--[[
    Build towers and sort the projectiles. Pew pew.
]]

Towers = Class{}

require 'Util'


function Towers:init(map, wave)
    self.map = map
    self.wave = wave

    self.towers = {}
    self.projectiles = {}

    self.redCost = 50
    self.blueCost = 60

    self.projectileTimerMax = 0.9
    self.projectileTimer = self.projectileTimerMax

    self.fastFireTimerMax = 0.6
    self.fastFireTimer = self.fastFireTimerMax

    self.canFire = false
    self.fastFire = false

    self.sounds = {
        ['pew'] = love.audio.newSource('sounds/pew.wav', 'static'),
        ['pew1'] = love.audio.newSource('sounds/pew1.wav', 'static')
    }

end

function Towers:update(dt)
    if clicked == true then

            i = math.floor(towerX / (self.map.tileWidth / (VIRTUAL_WIDTH / WINDOW_WIDTH)))
            j = math.floor(towerY / (self.map.tileHeight / (VIRTUAL_HEIGHT / WINDOW_HEIGHT)))
        
            if self.map:canBuild(self.map:tileUnder(i, j)) then
                if (towerType == 'red' and bank - self.redCost > -1) or (towerType == 'blue' and bank - self.blueCost > -1) then
                    self:buildTower(i, j, towerType)
                end
            end
        clicked = false
            
    end
    self:updateTowers(dt)
    if gameState == 'run' then     
        self:updateProjectiles(dt)
    end

    if self.projectileTimer > 0 then
        self.projectileTimer = self.projectileTimer - dt
    else
        self.canFire = true
    end

    if self.fastFireTimer > 0 then
        self.fastFireTimer = self.fastFireTimer - dt
    else
        self.fastFire = true
    end
end

function Towers:render()
    for index, projectile in ipairs(self.projectiles) do
        love.graphics.setColor(0, 0, 0, 1)
        if projectile.slow == 0 then
            love.graphics.circle("fill", projectile.x, projectile.y, 5)
        elseif projectile.slow > 0 then
            love.graphics.setColor(0, 0.1, 0.5, 1)
            love.graphics.circle("fill", projectile.x, projectile.y, 10)
        end
    end
end

-- Build our towers

Tower = {y = 0, x = 0, type = type}

function Tower:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Towers:buildTower(x, y, type)
    tower = Tower:new{y = y, x = x, type = type}
    table.insert(self.towers, tower)
    if type == 'red' then
        self.map:changeTile(i, j, RED_TOWER)
        bank = bank - self.redCost
    elseif type == 'blue' then
        self.map:changeTile(i, j, BLUE_TOWER)
        bank = bank - self.blueCost
    end
end

-- spawn projectiles

function Towers:spawnProjectile()

    -- Red towers shoot slower
    if self.canFire then
        for i = table.getn(self.towers), 1, -1 do
                tower = self.towers[i]

                if tower.type == 'red' then

                    if self:creepInRange(i) > 0  then

                        local dir = math.atan2((tower.y * 64 + 32) - (creep.y + creep.yOffset), (tower.x * 64 + 32) - (creep.x + creep.xOffset))
                        local ax = math.cos(dir)
                        local ay = math.sin(dir)

                        projectile = {x = tower.x * 64 + 32, y = tower.y * 64 + 32, speed = 850, ax = -ax, ay = -ay, slow = 0, damage = math.random(20, 30)}

                        table.insert(self.projectiles, projectile)
                        
                        --self.sounds['pew1']:play()
                    end
                end
        end

        self.canFire = false
        self.projectileTimer = self.projectileTimerMax
    end

    -- Blue towers shoot faster
    if self.fastFire then
        for i = table.getn(self.towers), 1, -1 do
            tower = self.towers [i]

            if tower.type == 'blue' then
                if self:creepInBlueRange(i) > 0 then
                
                    local dir = math.atan2((tower.y * 64 + 32) - (creep.y + creep.yOffset), (tower.x * 64 + 32) - (creep.x + creep.xOffset))
                    local ax = math.cos(dir)
                    local ay = math.sin(dir)

                    projectile = {x = tower.x * 64 + 32, y = tower.y * 64 + 32, speed = 1100, ax = -ax, ay = -ay, slow = 2.1, damage = math.random(5, 10)}
                    table.insert(self.projectiles, projectile)

                    --self.sounds['pew']:play()
                end
            end
        end
        self.fastFire = false
        self.fastFireTimer = self.fastFireTimerMax
    end
end

function Towers:updateProjectiles(dt)
    for index, projectile in ipairs(self.projectiles) do
        
        -- update projectile position
        projectile.x = projectile.x + projectile.ax * (dt * projectile.speed) 
        projectile.y = projectile.y + projectile.ay * (dt * projectile.speed) 

        -- remove the projectile from the table if it leaves the screen
        if projectile.x > VIRTUAL_WIDTH or projectile.y > VIRTUAL_HEIGHT or projectile.x < 0 or projectile.y < 0 then
            table.remove(self.projectiles, index)
        end
    end
end

function Towers:updateTowers(dt)
    self:spawnProjectile()
end

-- is there a creep within range of the tower?
function Towers:creepInRange(i)
    tower = self.towers[i]
    for j = 1, table.getn(self.wave.creeps) do
        creep = self.wave.creeps[j]
        if math.abs((tower.x * 64 + 32) - (creep.x + creep.xOffset)) < 250 and math.abs((tower.y * 64 + 32) - (creep.y + creep.yOffset)) < 300 then
            return j
        end
        
    end
    return -1
end

-- is there a creep within a smaller range for a blue tower
function Towers:creepInBlueRange(i)
    tower = self.towers[i]
    for j = 1, table.getn(self.wave.creeps) do
        creep = self.wave.creeps[j]
        if math.abs((tower.x * 64 + 32) - (creep.x + creep.xOffset)) < 150 and math.abs((tower.y * 64 + 32) - (creep.y + creep.yOffset)) < 200 then
            return j
        end
        
    end
    return -1
end