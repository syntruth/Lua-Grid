#!/usr/bin/env lua

--[[
  Yes, Tic-Tac-Toe!  This is just a silly script to show how
  to sub-class and use the Grid class object.
]]

require "grid"

-- This function 'sub-classes' the Grid object, adding
-- new methods for display and such.
function TicTacToe()

  local g = grid.Grid(3, 3, " ")

  g.allowed = {"O", "X"}

  -- For checking diagonal wins. See check_winner().
  g.diag_tl_to_br = {{1,1}, {2, 2}, {3, 3}}
  g.diag_tr_to_bl = {{1,3}, {2, 2}, {3, 1}}

  g._row_y_line  = "    1   2   3  "
  g._row_line    =   "  +---+---+---+"
  g._row_pattern = "%s | %s | %s | %s |"

  function g:is_empty(x, y)
    return (self:get_cell(x, y) == " ")
	end

  function g:check_allowed(piece)
    if type(piece) ~= "string" then return false end

    for _, v in self.allowed do
      if piece == v then return true end
    end

    return false
  end

  -- Checks for a winner on all rows, columns, and diagonals.
  -- Returns the winning piece or the string "tie" in the case
  -- of a tie.
  function g:check_winner()
    local piece = nil
    local row, col, diag

    -- Check rows.
    for x=1, self.size_x do
      row = self:get_row(x)

      if (self:check_allowed(row[1]) and 
         row[1] == row[2] and row[2] == row[3]) then
        return row[1]
      end
    end

    -- Check Columns
    for y=1, self.size_y do
      col = self:get_column(y)

      if (self:check_allowed(col[1]) and 
         col[1] == col[2] and col[2] == col[3]) then
        return col[1]
      end
    end

    --[[ Check Diagonals. ]]

    -- Top left to bottom right.
    diag = self:get_cells(self.diag_tl_to_br)

    if diag then
      if (self:check_allowed(diag[1]) and 
         diag[1] == diag[2] and diag[2] == diag[3]) then
        return diag[1]
      end
    end

    -- Top right to bottom left.
    diag = self:get_cells(self.diag_tr_to_bl)

    if diag then
      if (self:check_allowed(diag[1]) and 
         diag[1] == diag[2] and diag[2] == diag[3]) then
        return diag[1]
      end
    end

    -- Lastly, we check for a tie.
    -- Get all the neighbors of 2,2, if they are all not empty
    -- -and- 2, 2 is not empty, and there is no winner above, 
    -- it's a tie, man, it's a tie...
    if self:get_cell(2, 2) ~= " " then
      local nbrs = self:get_neighbors(2, 2)
      local tie  = true

      local x, y, p

      for _, v in nbrs do
        x, y, p = unpack(v)

        if p == " " then tie = false end
      end

      if tie then return "tie" end
    end

    return false
  end

  function g:display()
    local row, s

    print("")
    print(self._row_y_line)
    print(self._row_line)

    for x=1, self.size_x do
      row = self:get_row(x)
      s   = string.format(self._row_pattern, x, unpack(row))

      print(s)
      print(self._row_line)
    end

    print("")
  end

  -- Return the new sub-class object	
  return g
end

-- Lua lacks a decent built-in stdin input() function.
-- Roll our own.
function get_input(str)
  local input = nil
  local num   = nil

  if type(str) ~= "string" then str = "Input: " end

  io.stdout:write(str)

  input = io.stdin:read("*l")
  input = string.sub(input, 1)
  num   = tonumber(input)

  if num ~= nil then
    return num
  else
    if input == "q" then
      return input
    end
  end

  return nil
end

function main()
  local input, row, col

  local T     = TicTacToe()
  local piece = "X"

  print("Enter 'q' at any time to quit.")

  while true do
    T:display()

    print(string.format("It is %s's turn.", piece))

    row = get_input("Enter Row: ")

    if row == "q" then break end

    col = get_input("Enter Column: ")

    if col == "q" then break end

    if row ~= nil and col ~= nil then
      if T:is_valid(row, col) and T:is_empty(row, col) then
        T:set_cell(row, col, piece)

        winner = T:check_winner()

        if winner and winner ~= "tie" then
          T:display()
          print(string.format("The winner is %s!", piece))
          break
        elseif winner == "tie" then
          T:display()
          print("The game was a tie!")
          break
        end

        if piece == "X" then
          piece = "O"
        else
          piece = "X"
        end
      else
        local s = "Row %s and Column %s is not valid, please try again!"
        print(string.format(s, row, col))
      end
    end
  end
end

-- Call main
main()



