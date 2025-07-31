local grid_module = require "grid"

local ROWS = 100
local COLLUMNS = 100

local winH = 1000
local winW = 1000

local cw = winW / COLLUMNS
local ch = winH / COLLUMNS

local grid = grid_module.Grid.new(ROWS, COLLUMNS)
local color_dictionary = grid_module.color_dictionary

local timer = 1
local speed = 0.05

local function table_len(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function love.load()
    love.window.setMode(winW, winH)
    grid.grid[20][20] = 1
end

function love.update(dt)
    timer = timer - dt
    while timer < 0 do
        timer = timer + speed
        grid:upd()
    end

    if love.mouse.isDown(1) then
        local x, y = love.mouse.getPosition()
        local row = math.ceil(y / ch)
        local col = math.ceil(x / cw)
        if row >= 1 and row <= ROWS and col >= 1 and col <= COLLUMNS then
            grid.grid[row][col] = math.random(1, table_len(color_dictionary))
        end
    end
end

function love.draw()
    love.graphics.scale(cw, ch)
    grid:draw()
end
