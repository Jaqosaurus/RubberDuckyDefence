--[[
    Basic Tower Defence game, featuring rubber ducks

    By Jaqosaurus, for my CS50 Final Project, 2020

    fonts from dafont.com
    aAhaWow - https://www.dafont.com/a-aha-wow.font
    Dimbo - https://www.dafont.com/dimbo.font 

    sounds from https://freesound.org/
    rubber duck squeeks cut from here - https://freesound.org/people/ermfilm/sounds/130013/
    shooting sound - https://freesound.org/people/tripjazz/sounds/509070/ 
    pop sound - https://freesound.org/people/unfa/sounds/245645/
]]

Class = require 'class'
push = require 'push'

require 'Animation'
require 'Map'
require 'Creep'
require 'Wave'

VIRTUAL_WIDTH = 2560
VIRTUAL_HEIGHT = 1440

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

currentLevel = 1
maxLives = 20
lives = maxLives
bankStart = 100
bank = bankStart
towerX = 1
towerY = 1
towerType = red
clicked = false

creepsKilled = 0
creepsSurvived = 0

math.randomseed(os.time())

function love.load()

        push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizeable = true,
    })

    love.window.setTitle("Rubber Ducky Defence")    

    titleFont = love.graphics.newFont('fonts/aAhaWow.ttf', 100)
    subTitle = love.graphics.newFont('fonts/aAhaWow.ttf', 50)
    genFont = love.graphics.newFont('fonts/Dimbo Regular.ttf', 40)

    gameState = 'start'
    startTime = 0
end 

-- called whenever window is resized
function love.resize(w, h)
    push:resize(w, h)
end

-- start or restart the game
function love.reset(arg)
    gameState = 'ready'
    lives = maxLives
    bank = bankStart
    currentLevel = arg
    map = Map(currentLevel)
end

function love.nextLevel(arg)
    currentLevel = arg
    gameState = 'ready'
    lives = maxLives
    bank = bankStart
    map = Map(currentLevel)
end

-- called whenever a key is pressed
function love.keypressed(key)
    if (gameState == 'start' or gameState == 'gameOver') and key == 'escape' then
        love.event.quit()
    elseif (gameState == 'run' or gameState == 'pause') and key == 'escape' then
        love.reset(currentLevel)
    elseif gameState == 'start' and key == 'space' then
        love.reset(1)
        creepsKilled = 0
    elseif gameState == 'ready' and key == 'space' then
        gameState = 'run'
        startTime = love.timer.getTime()
    elseif gameState == 'run' and key == 'space' then
        gameState = 'pause'
    elseif gameState == 'pause' and key == 'space' then
        gameState = 'run'
    elseif gameState == 'gameOver' and key == 'space' then
        love.reset(1)
        creepsKilled = 0
    elseif gameState == 'levelComplete' and key == 'space' then
        love.nextLevel(currentLevel)
    elseif gameState == 'gameComplete' and key == 'space' then
        love.reset(1)
        creepsKilled = 0
    end
    if (gameState == 'start' or gameState == 'gameOver') and key == '2' then
        love.nextLevel(2)
        gameState = 'run'
    elseif (gameState == 'start' or gameState == 'gameOver') and key == '3' then
        love.nextLevel(3)
        gameState = 'run'
    end
    
end

-- called when the mouse is clicked
function love.mousepressed(x, y, button)
    if button == 1 and (gameState == 'run' or gameState == 'pause') then
        towerX = x
        towerY = y
        clicked = true
        towerType = 'red'
    elseif button == 2 and (gameState == 'run' or gameState == 'pause') then
        towerX = x
        towerY = y
        clicked = true
        towerType = 'blue'
    end
end

-- Game Over conditions
function love.gameOver()
    if lives <= 0 then
        gameState = 'gameOver'
    end
end

-- Completed the level conditions
function love.completedLevel()
    if lives >= 0 and map.completedLevel == true then
        if currentLevel == 3 then
            gameState = 'gameComplete'
        else
            currentLevel = currentLevel + 1
            gameState = 'levelComplete'
        end
    end
end

-- called every frame, with dt passed in as delta in time since last frame
function love.update(dt)

    if gameState == 'ready' or gameState == 'run' or gameState == 'pause' then
        map:update(dt)

        -- check if the game is lost yet, or it's time to go onto the next level
        love.gameOver()
        love.completedLevel()
    end

end
    
function love.draw()
    push:apply('start')

    -- background like a bath for splash screens
    love.graphics.clear(3/255, 165/255, 252/255, 1)

    -- start screen
    if gameState == 'start' then
        love.graphics.setFont(titleFont)
        love.graphics.printf("Rubber Ducky Defence", 0, VIRTUAL_HEIGHT / 3, VIRTUAL_WIDTH, "center")
        love.graphics.setFont(subTitle)
        love.graphics.printf("Press space to begin", 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, "center")
        love.graphics.setFont(genFont)
        love.graphics.printf("Defeat the duckies before they reach the bottom of the screen, or they'll eat your bath soap or brains or something. Who knows what motivates a rampaging rubber duck." , VIRTUAL_WIDTH / 4, VIRTUAL_HEIGHT / 4 + 550, VIRTUAL_WIDTH / 2, "center")
        love.graphics.printf("PS - if you want to jump straight to level 2 or 3 then just hit 2 or 3 on your keyboard now." , VIRTUAL_WIDTH / 4, VIRTUAL_HEIGHT / 4 + 900, VIRTUAL_WIDTH / 2, "center")
    
    -- render the map in the ready, running and paused states
    elseif gameState == 'ready' or gameState == 'run' or gameState == 'pause' then
        map:render()
        love.graphics.setFont(genFont)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf('Lives: ' .. tostring(lives), 0, 64, VIRTUAL_WIDTH, "center")
        love.graphics.print('Bank: ' .. tostring(bank), VIRTUAL_WIDTH / 4, 64)
        love.graphics.print('Level: ' .. tostring(currentLevel), 3 * VIRTUAL_WIDTH / 4, 64)
        love.graphics.print('Next Wave: ' .. tostring(math.ceil(map.nextWave)), VIRTUAL_WIDTH / 4, VIRTUAL_HEIGHT - 100)
        love.graphics.print('Wave Count: ' .. tostring(map.waveCount) .. ' / ' .. tostring(map.maxWaves), VIRTUAL_WIDTH / 2, VIRTUAL_HEIGHT - 100)
        
        --[[ for debugging
        love.graphics.print('creeps in existance: ' .. tostring(table.getn(map.waves.creeps)), 100, VIRTUAL_HEIGHT - 100)
        --]]

    -- game over screen
    elseif gameState == 'gameOver' then
        love.graphics.setFont(titleFont)
        love.graphics.printf("Game Over", 0, VIRTUAL_HEIGHT / 3, VIRTUAL_WIDTH, "center")
        love.graphics.setFont(subTitle)
        love.graphics.printf("Press space to play again", 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, "center")
        love.graphics.printf("Sadly you appear to have been eaten by rubber ducks." , VIRTUAL_WIDTH / 4, VIRTUAL_HEIGHT / 4 + 550, VIRTUAL_WIDTH / 2, "center")
        love.graphics.setFont(genFont)
        love.graphics.printf("PS - if you want to jump straight to level 2 or 3 then just hit 2 or 3 on your keyboard now." , VIRTUAL_WIDTH / 4, VIRTUAL_HEIGHT / 4 + 900, VIRTUAL_WIDTH / 2, "center")
    
    -- level complete screen
    elseif gameState == 'levelComplete' then
        love.graphics.setFont(titleFont)
        love.graphics.printf("Level " .. tostring(currentLevel - 1) .." Complete!", 0, VIRTUAL_HEIGHT / 3, VIRTUAL_WIDTH, "center")
        love.graphics.setFont(subTitle)
        love.graphics.printf("Total Duckies Killed: " .. tostring(creepsKilled), 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, "center")
        love.graphics.printf("Press space to advance to the next level", 0, VIRTUAL_HEIGHT / 1.5, VIRTUAL_WIDTH, "center")
    
    -- game is won
    elseif gameState == 'gameComplete' then
        love.graphics.setFont(titleFont)
        love.graphics.printf("Hurray! All levels complete!", 0, VIRTUAL_HEIGHT / 3, VIRTUAL_WIDTH, "center")
        love.graphics.setFont(subTitle)
        love.graphics.printf("Total Duckies Killed: " .. tostring(creepsKilled), 0, VIRTUAL_HEIGHT / 2, VIRTUAL_WIDTH, "center")
        love.graphics.printf("Total Duckies nibbling on your squishy bits: " .. tostring(creepsSurvived), 0, VIRTUAL_HEIGHT / 2 + 100, VIRTUAL_WIDTH, "center")
        love.graphics.printf("Press space to play again", 0, VIRTUAL_HEIGHT / 1.5, VIRTUAL_WIDTH, "center")
    end

    -- instructions screen overlaid on the ready and pause states
    if gameState == 'ready' or gameState == 'pause' then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle("fill", VIRTUAL_WIDTH / 4, VIRTUAL_HEIGHT / 4, VIRTUAL_WIDTH / 2, VIRTUAL_HEIGHT / 2)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf('How to play', VIRTUAL_WIDTH / 4, VIRTUAL_HEIGHT / 4 + 50, VIRTUAL_WIDTH / 2, "center")
        love.graphics.printf('Left click to build a red tower - cost 50, shoots for 20 - 30 damage', VIRTUAL_WIDTH / 4, VIRTUAL_HEIGHT / 4 + 150, VIRTUAL_WIDTH / 2, "center")
        love.graphics.printf("Right click to build a blue tower - cost 60, shoots for 5 - 10 damage and at a closer range than red towers (build close to the edge!) but shoots faster and slows duckies down", VIRTUAL_WIDTH / 4, VIRTUAL_HEIGHT / 4 + 250, VIRTUAL_WIDTH / 2, "center")
        love.graphics.printf('Space bar to pause and restart', VIRTUAL_WIDTH / 4, VIRTUAL_HEIGHT / 4 + 400, VIRTUAL_WIDTH / 2, "center")
        love.graphics.printf('Press ESC to start the level again', VIRTUAL_WIDTH / 4, VIRTUAL_HEIGHT / 4 + 500, VIRTUAL_WIDTH / 2, "center")
        love.graphics.printf("Press space bar when you're ready to play... and good luck!", VIRTUAL_WIDTH / 4, VIRTUAL_HEIGHT / 4 + 650, VIRTUAL_WIDTH / 2, "center")
    end

    push:apply('end')

end