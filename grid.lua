local Grid = {}
Grid.__index = Grid

color_dictionary = {
    [1] = {1, 0, 0, 1},
    [2] = {0, 0, 1, 1},
    [3] = {1, 1, 0, 1},
    [4] = {0.6, 0.3, 0.1, 1},
    [5] = {0, 1, 213 / 255, 1},
    [6] = {0.3, 0.5, 0.55, 1},
    [7] = {0.3, 0.1, 0, 1},
    [8] = {0.25, 0.8, 0.35, 1}
}

speed_dictionary = {
    [1] = 0.05,
    [2] = 0.5,
    [3] = 0.1,
    [4] = math.huge,
    [5] = 0.1,
    [6] = 0.1,
    [7] = 0.5,
    [8] = 0.5,
}

local BURN_THRESHOLD = 1.5
local BURN_SPREAD_INTERVAL = 0.2

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

local function is_air(self, r, c)
    if r < 1 or r > self.rows or c < 1 or c > self.cols then return false end
    return self.grid[r][c] == 0
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

local function get_timer_matrix(r, c)
    local m = {}
    for i = 1, r do
        m[i] = {}
        for j = 1, c do
            m[i][j] = 0
        end
    end
    return m
end

local MAX_VELOCITY = 3

local function is_inside(r, c, rows, cols)
    return r >= 1 and r <= rows and c >= 1 and c <= cols
end

local function start_burning(self, row, col)
    local function burn_recursive(r, c)
        if not is_inside(r, c, self.rows, self.cols) then return end
        if self.grid[r][c] ~= 4 then return end
        self.grid[r][c] = 0
        self.burn_spread_timer[r][c] = -1
        burn_recursive(r + 1, c)
        burn_recursive(r - 1, c)
        burn_recursive(r, c + 1)
        burn_recursive(r, c - 1)
    end
    burn_recursive(row, col)
end

local function vary_color(base_color)
    local factor = 0.7 + math.random() * 0.3
    return {
        base_color[1] * factor,
        base_color[2] * factor,
        base_color[3] * factor,
        base_color[4]
    }
end

local function splash_water(self, row, col)
    for dx = -1, 1 do
        for dy = -1, 0 do
            local r, c = row + dy, col + dx
            if is_inside(r, c, self.rows, self.cols) and self.grid[r][c] == 0 then
                self.grid[r][c] = 2
                self.velocity[r][c] = math.random()
                self.set_color[r][c] = vary_color(color_dictionary[2])
            end
        end
    end
end

local function is_touching_water(self, r, c)
    local offsets = {
        {-1, 0}, {1, 0}, {0, -1}, {0, 1}
    }
    for _, offset in ipairs(offsets) do
        local nr, nc = r + offset[1], c + offset[2]
        if is_inside(nr, nc, self.rows, self.cols) and self.grid[nr][nc] == 2 then
            return true
        end
    end
    return false
end

local function update_pixel(self, row, col)
    local g = self.grid
    local v = self.velocity
    local rows = self.rows
    local cols = self.cols
    local pixel = g[row][col]

    if pixel == 0 then return end

    if self.set_color[row][col] == 0 then
        local base_color = color_dictionary[pixel] or {1, 1, 1, 1}
        self.set_color[row][col] = vary_color(base_color)
    end

    if pixel == 8 and is_touching_water(self, row, col) then
        g[row][col] = 7
        self.burn_timer[row][col] = 0
        self.set_color[row][col] = vary_color(color_dictionary[7])
        return
    end

    if pixel == 7 then
        if is_touching_water(self, row, col) then
            self.burn_timer[row][col] = 0
        else
            self.burn_timer[row][col] = self.burn_timer[row][col] + self.dt
            if self.burn_timer[row][col] >= 3 then
                g[row][col] = 8
                self.set_color[row][col] = vary_color(color_dictionary[8])
                self.burn_timer[row][col] = 0
                return
            end
        end
    end

    if pixel == 4 then return end

    if pixel == 1 then
        if row < rows and g[row + 1][col] == 4 then
            self.burn_timer[row + 1][col] = self.burn_timer[row + 1][col] + self.dt
            if self.burn_timer[row + 1][col] >= BURN_THRESHOLD then
                start_burning(self, row + 1, col)
            end
        end
    end

    local speed = speed_dictionary[pixel] or 0.1
    v[row][col] = math.min(v[row][col] + speed, MAX_VELOCITY)
    local fall_distance = math.floor(v[row][col])
    if fall_distance == 0 then return end

    local new_row = row + fall_distance
    if new_row > rows then new_row = rows end

    local below = g[new_row][col]

    if below == 2 and pixel ~= 2 and pixel ~= 4 then
        g[new_row][col] = pixel
        g[row][col] = 2
        local v_tmp = v[new_row][col]
        v[new_row][col] = v[row][col]
        v[row][col] = v_tmp
        local color_tmp = self.set_color[new_row][col]
        self.set_color[new_row][col] = self.set_color[row][col]
        self.set_color[row][col] = color_tmp or vary_color(color_dictionary[2])
        return
    end

    if (pixel == 1 and below == 2) or (pixel == 2 and below == 1) then
        g[row][col] = 0
        g[new_row][col] = 0
        v[row][col] = 0
        v[new_row][col] = 0
        for i = 1, 5 do
            local smoke_row = row - i
            if smoke_row >= 1 and g[smoke_row][col] == 0 then
                g[smoke_row][col] = 6
                v[smoke_row][col] = -math.random() * 1.5
                self.set_color[smoke_row][col] = vary_color(color_dictionary[6])
            end
        end
        return
    end

    if below == 2 and pixel ~= 2 then
        splash_water(self, new_row, col)
    end

    if pixel == 5 and below == 2 then
        g[new_row][col] = 5
        g[row][col] = 0
        v[new_row][col] = v[row][col]
        v[row][col] = 0
        return
    end

    if below == 0 then
        g[new_row][col] = pixel
        g[row][col] = 0
        v[new_row][col] = v[row][col]
        v[row][col] = 0
        self.set_color[new_row][col] = self.set_color[row][col]
        self.set_color[row][col] = 0
        return
    elseif below == 4 then
        v[row][col] = 0
        return
    elseif below == 2 and pixel == 3 then
        g[row][col] = 2
        g[new_row][col] = 3
        local vclone = v[new_row][col]
        v[new_row][col] = v[row][col]
        v[row][col] = vclone
    end

    local moved = false

    if pixel == 2 then
        if is_air(self, row + 1, col) then
            g[row + 1][col] = 2
            g[row][col] = 0
            v[row + 1][col] = v[row][col]
            v[row][col] = 0
            self.set_color[row + 1][col] = self.set_color[row][col]
            self.set_color[row][col] = 0
            return
        end

        local dir = math.random(0, 1) == 0 and -1 or 1

        if is_air(self, row, col + dir) then
            g[row][col + dir] = 2
            g[row][col] = 0
            v[row][col + dir] = v[row][col]
            v[row][col] = 0
            self.set_color[row][col + dir] = self.set_color[row][col]
            self.set_color[row][col] = 0
            return
        elseif is_air(self, row, col - dir) then
            g[row][col - dir] = 2
            g[row][col] = 0
            v[row][col - dir] = v[row][col]
            v[row][col] = 0
            self.set_color[row][col - dir] = self.set_color[row][col]
            self.set_color[row][col] = 0
            return
        end
    end

    if pixel == 3 then
        if g[row][col + 1] == 5 or g[row][col - 1] == 5 or g[row - 1][col] == 5 or g[row + 1][col] == 5 or g[row + 1][col + 1] == 5 or g[row - 1][col - 1] == 5 then
            g[row][col] = 5
        end
    end

    if pixel == 6 then
        v[row][col] = v[row][col] - 0.05
        if v[row][col] < -MAX_VELOCITY then
            v[row][col] = -MAX_VELOCITY
        end
        local rise_distance = math.floor(-v[row][col])
        if rise_distance == 0 then return end
        local new_r = row - rise_distance
        if new_r < 1 then new_r = 1 end

        if math.random() < 0.3 then
            local dir = math.random(0, 1) == 0 and -1 or 1
            if is_air(self, row, col + dir) then
                g[row][col + dir] = 6
                g[row][col] = 0
                v[row][col + dir] = v[row][col]
                v[row][col] = 0
                self.set_color[row][col + dir] = self.set_color[row][col]
                self.set_color[row][col] = 0
            end
        else
            v[row][col] = 0
        end
        return
    end

    if col > 1 and g[new_row][col - 1] == 0 and g[row][col - 1] == 0 then
        g[new_row][col - 1] = pixel
        g[row][col] = 0
        v[new_row][col - 1] = v[row][col]
        v[row][col] = 0
        self.set_color[new_row][col - 1] = self.set_color[row][col]
        self.set_color[row][col] = 0
        moved = true
    elseif col < cols and g[new_row][col + 1] == 0 and g[row][col + 1] == 0 then
        g[new_row][col + 1] = pixel
        g[row][col] = 0
        v[new_row][col + 1] = v[row][col]
        v[row][col] = 0
        self.set_color[new_row][col + 1] = self.set_color[row][col]
        self.set_color[row][col] = 0
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
    self.burn_timer = get_timer_matrix(rows, cols)
    self.burn_spread_timer = get_timer_matrix(rows, cols)
    self.set_color = get_matrix(rows, cols)
    self.rows = rows
    self.cols = cols
    self.dt = 0
    return self
end

function Grid:reset()
    self.grid = get_matrix(self.rows, self.cols)
    self.velocity = get_velocity_matrix(self.rows, self.cols)
    self.burn_timer = get_timer_matrix(self.rows, self.cols)
    self.burn_spread_timer = get_timer_matrix(self.rows, self.cols)
    self.set_color = get_matrix(self.rows, self.cols)
end

function Grid:upd()
    for i = 1, self.rows do
        for j = 1, self.cols do
            if self.grid[i][j] ~= 4 then
                self.burn_timer[i][j] = self.burn_timer[i][j]
            end
        end
    end
    for ri = self.rows - 1, 1, -1 do
        for ci = 1, self.cols do
            update_pixel(self, ri, ci)
        end
    end
end

function Grid:update_dt(dt)
    self.dt = dt
end

function Grid:draw()
    for i = 1, self.rows do
        for j = 1, self.cols do
            local pixel = self.grid[i][j]
            if pixel ~= 0 then
                local color = self.set_color[i][j]
                if color == 0 then
                    color = color_dictionary[pixel] or {1, 1, 1, 1}
                end
                love.graphics.setColor(color[1], color[2], color[3], color[4])
                love.graphics.rectangle("fill", j - 1, i - 1, 1, 1)
            end
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

return {
    Grid = Grid,
    color_dictionary = color_dictionary
}
