push = require 'push'
Class = require 'class'

require 'StateMachine'
require 'states/BaseState'
require 'states/CountdownState'
require 'states/PlayState'
require 'states/ScoreState'
require 'states/TitleScreenState'

require 'Bird'
require 'Pipe'
require 'PipePair'


WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720


VIRTUAL_WIDTH = 512
VIRTUAL_HEIGHT = 288

local background = love.graphics.newImage('background.png')
local backgroundScroll = 0

local ground = love.graphics.newImage('ground.png')
local groundScroll = 0

local pauseIcon = love.graphics.newImage('pause.png')
pause = false

local BACKGROUND_SCROLL_SPEED = 30
local GROUND_SCROLL_SPEED = 60

local BACKGROUND_LOOPING_POINT = 413

-- global variable we can use to scroll the map
scrolling = true

function love.load()
    -- initialize our nearest-neighbor filter
    love.graphics.setDefaultFilter('nearest', 'nearest')
    math.randomseed(os.time()) 
    love.window.setTitle('Fifty Bird')

    -- initialize our nice-looking retro text fonts
    smallFont = love.graphics.newFont('font.ttf', 8)
    mediumFont = love.graphics.newFont('flappy.ttf', 14)
    flappyFont = love.graphics.newFont('flappy.ttf', 28)
    hugeFont = love.graphics.newFont('flappy.ttf', 56)
    love.graphics.setFont(flappyFont)

    -- initialize our table of sounds
    sounds = {
        ['jump'] = love.audio.newSource('jump.wav', 'static'),
        ['explosion'] = love.audio.newSource('explosion.wav', 'static'),
        ['hurt'] = love.audio.newSource('hurt.wav', 'static'),
        ['score'] = love.audio.newSource('score.wav', 'static'),
        ['pause'] = love.audio.newSource('pause.wav', 'static'),

        -- https://freesound.org/people/xsgianni/sounds/388079/
        ['music'] = love.audio.newSource('marios_way.mp3', 'static')
    }

    -- kick off music
    sounds['music']:setLooping(true)
    sounds['music']:play()

    -- initialize our virtual resolution
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        vsync = true,
        fullscreen = false,
        resizable = true
    })

    -- initialize state machine with all state-returning functions
    gStateMachine = StateMachine {
        ['title'] = function() return TitleScreenState() end,
        ['countdown'] = function() return CountdownState() end,
        ['play'] = function() return PlayState() end,
        ['pause'] = function() return PauseState() end,
        ['score'] = function() return ScoreState() end
    }
    gStateMachine:change('title')

    -- initialize input table
    love.keyboard.keysPressed = {}
end

function love.resize(w, h)
    push:resize(w, h)
end

function love.keypressed(key)
    -- add to our table of keys pressed this frame
    love.keyboard.keysPressed[key] = true
    
    if key == 'escape' then
        love.event.quit()
    end
    if key == 'p' then
        pause = not pause

        if pause then
            sounds['pause']: play()
       end 
    end
end

function love.keyboard.wasPressed(key)
    if love.keyboard.keysPressed[key] then
        return true
    else
        return false
    end
end
function love.update(dt)

    if pause then
        sounds ['music']: pause()
        return
    else 
        sounds ['music']:resume()
    end 

    if scrolling then
        backgroundScroll = (backgroundScroll + BACKGROUND_SCROLL_SPEED * dt) % BACKGROUND_LOOPING_POINT
        groundScroll = (groundScroll + GROUND_SCROLL_SPEED * dt) % VIRTUAL_WIDTH
    end

    
    gStateMachine:update(dt)

    love.keyboard.keysPressed = {}
end

function love.draw()
    push:start()

    love.graphics.draw(background, -backgroundScroll, 0)
    gStateMachine:render()
    love.graphics.draw(ground, -groundScroll, VIRTUAL_HEIGHT - 30)
    if pause then
       
        love.graphics.draw(background)
        love.graphics.draw(pauseIcon, 189, 119, 0, 0.5, 0.5)
        love.graphics.setFont(flappyFont)
        love.graphics.printf('PAUSED', 0, 90, VIRTUAL_WIDTH, 'center')
    end
    push:finish()
end