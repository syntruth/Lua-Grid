--[[

Grid Class for Games or whatever else you can think of.
By Randy Carnahan, released to the Public Domain.

Version 1.0b - 7/13/2006
Version 1.0  - 7/19/2006

This library exports it's classes into a global 'grid'
table.

Usage:

require "grid"
G = grid.Grid(8, 8, "-")
G:set_cell(4, 4, "X")

neighbors = G:get_neighbors(4, 4)
for _, obj in neighbors do
  local s = string.format("Object is %s", tostring(obj))
  print(s)
end

Exposed Methods

  is_valid(x, y)             Checks to see if a given cell is within the grid.
  get_cell(x, y)             Gets the cell's data.
  get_cells(cells)           Gets a set of data for x,y pairs in table 'cells'.
  set_cell(x, y, obj)        Sets the cell's data to the given object.
  reset_cell(x, y)           Resets the cell to the default data.
  reset_all()                Resets the entire grid to the default data.
  populate(data)             Given a data-filled table, will set multiple cells.
  get_contents(no_default)   Returns a flat table of data suitable for populate()
  get_vector(vector)         Translates a GRID_* vector into a x,y vector pair.
  get_neighbor(x, y, vector) Gets a x,y's neighbor in vector direction.
  get_neighbors(x, y)        Returns a table of the given's cell's 8 neighbors.
  resize(newx, newy)         Resizes the grid. Can lose data if new grid is smaller.
  get_row(x)                 Gets the row for the given x value.
  get_column(y)              Gets the column for the given y value
  traverse(x, y, vector)     Returns all cells start at x,y in vector direction.

Caveats:

  The Grid object is data agnostic.  It doesn't care what 
  kind of data you store in a cell. This is meant to be, 
  for abstraction's sake. You could even store functions.

  Never put a nil value in a cell, even as a default value,
  since that can break loops that parse through cell data.
  Remember, the first nil value returned to a 'while' or 
  'for' loop breaks the loop, which might not be what you 
  are looking for. If you can't think of what to put in 
  'empty' cells, use GRID_NIL_VALUE.

  The class defines -no- display methods. Either sub-class
  the Grid class to add your own, or define functions that
  call the get_cell() method.

  Grid coordinates are always x,y number pairs. X is the 
  vertical, starting at the top left, and Y is the 
  horizontal, also starting at the top left. Hence, the 
  top-left cell is always 1,1. One cell to the right is
  1,2. One cell down is 2,1.

  Some Grid constants (OUTSIDE, NOT_VALID, NIL_VALUE) are 
  not numbers, but strings, just in case number data is to 
  be stored in a cell.

]]

--[[ Our global table. ]]
grid = {}

--[[ 
-- Some 'constant' values.
-- These are also exposed to the global scope.
--]]
GRID_OUTSIDE   = "GRID_OUTSIDE"
GRID_NOT_VALID = "GRID_NOT_VALID"
GRID_NIL_VALUE = "GRID_NIL_VALUE"

--[[ Traversal Vector Constants ]]
GRID_TOP_LEFT     = 1
GRID_TOP          = 2
GRID_TOP_RIGHT    = 3
GRID_LEFT         = 4
GRID_CENTER       = 5
GRID_RIGHT        = 6
GRID_BOTTOM_LEFT  = 7
GRID_BOTTOM       = 8
GRID_BOTTOM_RIGHT = 9


--[[ Grid Class Definition ]]
function grid.Grid(sizex, sizey, def_value)
  local g = {}

  --[[ Default Grid size is 4x4. ]]
  if type(sizex) ~= "number" or sizex == nil then
    sizex = 4
  end

  if type(sizey) ~= "number" or sizey == nil then
    sizey = 4
  end

  g.size_x = sizex
  g.size_y = sizey

  if def_value == nil then
    g.def_value = GRID_NIL_VALUE
  else
    g.def_value = def_value
  end

  --[[ Internal grid table. ]]
  g._grid = {}

  --[[ Build the grid and insert the def values. ]]
  for x=1, sizex do
    g._grid[x] = {}
    for y=1, sizey do
      table.insert(g._grid[x], def_value)
    end
  end

  --[[ METHOD DEFINITIONS ]]

  --[[
  -- This checks to see if a given x,y pair are within
  -- the boundries of the grid.
  --]]
  function g:is_valid(x, y)

    if (x == nil or type(x) ~= "number") or 
      (y == nil or type(y) ~= "number") then
      return false
    end

    if (x > 0 and x <= self.size_x) and (y > 0 and y <= self.size_y) then
      return true
    else
      return false
    end
  end

  --[[ Gets the data in a given x,y cell. ]]
  function g:get_cell(x, y)
    if self:is_valid(x, y) then return self._grid[x][y] end
  end

  --[[
  -- This method will return a set of cell data in a table.
  -- The 'cells' argument should be a table of x,y pairs of
  -- the cells being requested.
  --]]
  function g:get_cells(cells)
    data = {}

    local x, y, obj

    if type(cells) ~= "table" then
      return data
    end

    for _, v in cells do
      x, y = unpack(v)

      if self:is_valid(x, y) then
        table.insert(data, self._grid[x][y])
      end
    end

    return data
  end

  --[[ Sets a given x,y cell to the data object. ]]
  function g:set_cell(x, y, obj)
    if self:is_valid(x, y) then
      self._grid[x][y] = obj
    end
  end

  --[[ Resets a given x,y cell to the grid default value. ]]
  function g:reset_cell(x, y)
    if self:is_valid(x, y) then
      self._grid[x][y] = self.def_value
      return true
    else
      return false
    end
  end

  --[[ Resets the entire grid to the default value. ]]
  function g:reset_all()
    for x=1, self.size_x do
      for y=1, self.size_y do
        self._grid[x][y] = self.def_value
      end
    end
  end

  --[[
  -- This method is used to populate multiple cells at once.
  -- The 'data' argument must be a table, with each element
  -- consisting of three values: x, y, and the data to set
  -- the cell too. IE:
  --   d = {{4, 4, "X"}, {4, 5, "O"}, {5, 4, "O"}, {5, 5, "X"}}
  --   G:populate(d)
  -- If the object to be populated is nil, it is replaced with
  -- the default value.
  --]]
  function g:populate(data)
    if type(data) ~= "table" then return false end

    for i, v in data do
      x, y, obj = unpack(v)

      if self:is_valid(x, y) then
        if obj == nil then 
          obj = self.def_value
        end

				self._grid[x][y] = obj
      end
    end

    return true
  end

  --[[
  -- This method returns the entire grid's contents in a
  -- flat table suitable for feeding to populate() above.
  -- Useful for recreating a grid layout.
  -- If the 'no_default' argument is non-nil, then the
  -- returned data table only contains elements who's 
  -- cells are not the default value.
  --]]
  function g:get_contents(no_default)
    local x, y
    local data     = {}
    local cell_obj = nil

    for x=1, self.size_x do
      for y=1, self.size_y do
        cell_obj = self._grid[x][y]

        if no_default == true and cell_obj == self.def_value then
          -- Do nothing, ignore default values.
        else
          table.insert(data, {x, y, cell_obj})
        end
      end
    end

    return data
  end

  --[[ 
  -- Convience method to return an x,y vector pair from the
  -- GRID_* vector constants. Or nil if there is no such
  -- constant.
  --]]
  function g:get_vector(vector)
    if vector == GRID_TOP_LEFT then
      return -1, -1
    elseif vector == GRID_TOP then
      return -1, 0
    elseif vector == GRID_TOP_RIGHT then
      return -1, 1
    elseif vector == GRID_LEFT then
      return 0, -1
    elseif vector == GRID_CENTER then
      return 0, 0
    elseif vector == GRID_RIGHT then
      return 0, 1
    elseif vector == GRID_BOTTOM_LEFT then
      return 1, -1
    elseif vector == GRID_BOTTOM then
      return 1, 0
    elseif vector == GRID_BOTTOM_RIGHT then
      return 1, 1
    else
      --[[ Oops. ]]
      return nil
    end
  end

  --[[ Gets a cell's neighbor in a given vector. ]]
  function g:get_neighbor(x, y, vector)
    local obj    = nil
    local vx, vy = self:get_vector(vector)

    if vx ~= nil then
      x = x + vx
      y = y + vy

      if self:is_valid(x, y) then
        obj = self:get_cell(x, y)
      end
    end

    return obj
  end

  --[[
  -- Will return a table of 8 elements, with each element
  -- representing one of the 8 neighbors for the given
  -- x,y cell. Each element of the returned table will consist
  -- of the x,y cell pair, plus the data stored there, suitable
  -- for use of the populate() method. If the neighbor cell is 
  -- outside the grid, then {nil, nil, GRID_OUTSIDE} is used for 
  -- that value.
  -- If the given x,y values are not sane, an empty table
  -- is returned instead.
  --]]
  function g:get_neighbors(x, y)
    local data = {}
    local gx, gy, vx, vy

    if not self:is_valid(x, y) then return data end

    --[[
    -- The vectors used are x,y pairs between -1 and +1
    -- for the given x,y cell. 
    -- IE: 
    --     (-1, -1) (0, -1) (1, -1)
    --     (-1,  0) (0,  0) (1,  0)
    --     (-1,  1) (0,  1) (1,  1)
    -- Value of 0,0 is ignored, since that is the cell
    -- we are working with! :D
    --]]
    for gx = -1, 1 do
      for gy = -1, 1 do
        vx = x + gx
        vy = y + gy

        if (gx == 0 and gy == 0) then
          -- Do nothing
      	elseif self:is_valid(vx, vy) then
          table.insert(data, {vx, vy, self._grid[vx][vy]})
        else
          table.insert(data, {nil, nil, GRID_OUTSIDE})
        end
      end
    end

    return data
  end

  --[[
  -- This method will change the grid size. If the new size is
  -- smaller than the old size, data in the cells now 'outside'
  -- the grid is lost. If the grid is now larger, new cells are
  -- filled with the default value given when the grid was first
  -- created.
  --]]
  function g:resize(newx, newy)
    if (type(newx) ~= "number" or newx == nil) or
       (type(newy) ~= "number" or newy == nil) then
      return false
    end

    local c, x, y

    -- Save old data.
    c = self:get_contents()

    -- Destroy/reset the internal grid.
    self._grid = {}

    for x=1, newx do
      self._grid[x] = {}

      for y=1, newy do
        table.insert(self._grid[x], self.def_value)
      end
    end

    -- Set the new sizes.
    self.size_x = newx
    self.size_y = newy

    -- Restore the contents.
    self:populate(c)

    return true
  end

  --[[
  -- This method returns a table of all values in a given 
  -- row 'x' value.
  --]]
  function g:get_row(x)
    local row = {}

    if type(x) == "number" and (x > 0 and x <= self.size_x) then
      row = self._grid[x]
    end

    return row
  end

  --[[
  -- This method returns a table of all values in a given
  -- column 'y' value.
  --]]
  function g:get_column(y)
    local col = {}

    if type(y) == "number" and (y > 0 and y <= self.size_y) then
      for x=1, self.size_x do
        table.insert(col, self._grid[x][y])
      end
    end

    return col
  end

  --[[
  -- This method traverses a line of cells, from a given x,y 
  -- going in 'vector' direction. The vector arg is one of the
  -- GRID_* traversal constants. This will return a table of 
  -- data of the cells along the traversal path or nil if 
  -- the original x,y is not valid or if the vector is not one
  -- of the constant values.
  -- In the returned table, each element will be in the format 
  -- of {x, y, obj}, suitable for populate().
  --]]
  function g:traverse(x, y, vector)
    local data = {}
    local gx, gy, vx, vy

    if self:is_valid(x, y) then
      vx, vy = self:get_vector(vector)

      if vx == nil then
        -- table is still empty.
        return data
      end

      gx = x + vx
      gy = y + vy

      while self:is_valid(gx, gy) do
        local obj = self:get_cell(gx, gy)

        table.insert(data, {gx, gy, obj})
        
        gx = gx + vx
        gy = gy + vy
      end

      return data
    end

    return nil
  end

  --[[ END OF METHODS ]]

  --[[ Our object is formed, return to momma... ]]
  return g
end


