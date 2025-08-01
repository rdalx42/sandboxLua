local grid_module = require "grid"
local UI = require "rdui"

local ROWS = 100
local COLLUMNS = 100

local winH = 1000
local winW = 1000

local cw = winW / COLLUMNS
local ch = winH / COLLUMNS

local grid = grid_module.Grid.new(ROWS, COLLUMNS)
local color_dictionary = grid_module.color_dictionary

local timer = 1
local speed = 0.01

local selected_part = 1

local function table_len(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function love.load()
    love.window.setMode(winW, winH)
    grid.grid[20][20] = 1

    local controls = UI.newFrame("Controls", 10, 10, 180, 50)

    local slowMoButton = controls:addButton("Toggle Slow Motion", 10, 10, 160, 30, function()
        if speed == 0.01 then
            speed = 0.2
        else
            speed = 0.01
        end
    end)    
end

function love.update(dt)
    UI.update(dt)

    timer = timer - dt
    while timer < 0 do
        timer = timer + speed
        grid:upd()
        grid:update_dt(dt)
    end

    if love.mouse.isDown(1) then
        local x, y = love.mouse.getPosition()
        if not UI.isMouseOverUI(x, y) then   
            local row = math.ceil(y / ch)
            local col = math.ceil(x / cw)
            if row >= 1 and row <= ROWS and col >= 1 and col <= COLLUMNS then
                grid.grid[row][col] = selected_part
            end
        end
    end
end

function love.draw()
    love.graphics.push()
    love.graphics.scale(cw, ch)
    grid:draw()
    love.graphics.pop()
    UI.draw()
end

function love.mousepressed(x, y, button)
    UI.mousepressed(x, y, button)
end

function love.keypressed(key)
    if key == "1" or key == "2" or key == "3" or key == "4" then
        selected_part = tonumber(key)
    elseif key == "r" then 
        grid:reset()
    end
end
