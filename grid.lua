
local Grid = {}
Grid.__index = Grid

color_dictionary = {
    [1] = {1, 0, 0, 1},     
    [2] = {0, 0, 1, 1},    
    [3] = {1, 1, 0, 1},     
}

function get_matrix(r, c)
    local m = {}
    for i = 1, r do
        m[i] = {}
        for j = 1, c do
            m[i][j] = 0
        end
    end
    return m
end

local function get_velocity_matrix(r, c)
    local m = {}
    for i = 1, r do
        m[i] = {}
        for j = 1, c do
            m[i][j] = 0
        end
    end
    return m
end

local GRAVITY = 0.1
local MAX_VELOCITY = 3

local function update_pixel(self, row, col)
    local g = self.grid
    local v = self.velocity
    local rows = self.rows
    local cols = self.cols

    local pixel = g[row][col]
    if pixel == 0 then return end

    v[row][col] = math.min(v[row][col] + GRAVITY, MAX_VELOCITY)
    local fall_distance = math.floor(v[row][col])
    if fall_distance == 0 then return end

    local new_row = row + fall_distance
    if new_row > rows then new_row = rows end

    if g[new_row][col] == 0 then
        g[new_row][col] = pixel
        g[row][col] = 0

        v[new_row][col] = v[row][col]
        v[row][col] = 0
        return
    end

    local moved = false

    if col > 1 and g[new_row][col - 1] == 0 and g[row][col - 1] == 0 then
        g[new_row][col - 1] = pixel
        g[row][col] = 0

        v[new_row][col - 1] = v[row][col]
        v[row][col] = 0
        moved = true
    end

    if not moved and col < cols and g[new_row][col + 1] == 0 and g[row][col + 1] == 0 then
        g[new_row][col + 1] = pixel
        g[row][col] = 0

        v[new_row][col + 1] = v[row][col]
        v[row][col] = 0
        moved = true
    end

    if not moved then
        v[row][col] = 0
    end
end

function Grid.new(rows, cols)
    local self = setmetatable({}, Grid)
    self.grid = get_matrix(rows, cols)
    self.velocity = get_velocity_matrix(rows, cols)
    self.rows = rows
    self.cols = cols
    return self
end

function Grid:upd()
    for ri = self.rows - 1, 1, -1 do
        for ci = 1, self.cols do
            update_pixel(self, ri, ci)
        end
    end
end

function Grid:draw()
    for i = 1, self.rows do
        for j = 1, self.cols do
            local pixel = self.grid[i][j]
            if pixel ~= 0 then
                local color = color_dictionary[pixel] or {1, 1, 1, 1} 
                love.graphics.setColor(color[1], color[2], color[3], color[4])
                love.graphics.rectangle("fill", j - 1, i - 1, 1, 1)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end


return {

        Grid = Grid ,
        color_dictionary=color_dictionary
}
