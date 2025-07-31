
-- some helper functions

function table_len(t) 
    local c = 0
    for i, in pairs(t) do 
        c = c + 1
    end
    return c
end
