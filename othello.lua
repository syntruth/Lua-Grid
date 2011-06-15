#!/usr/bin/env lua

--[[
  Console Based Othello/Reversi Game using the Grid class.

  Logic inspired by:
    http://www.java2s.com/Code/C/String/REVERSIAnOthellotypegame.htm
--]]

require "grid"

local DEBUG = true

function OthelloBoard(single_player, difficulty)
  local OB = grid.Grid(8, 8, " ")

  OB._top_line = "     A   B   C   D   E   F   G   H  "
  OB._row_line = "   +---+---+---+---+---+---+---+---+"
  OB._row_data = " %s | %s | %s | %s | %s | %s | %s | %s | %s |"
  OB._score    = "   Score -- %s:  %s -- %s:  %s"

  OB._allowed = {"#", "O"}

  -- Are we a single-player game?
  -- If we are, additional methods and data will be
  -- defined after the core methods.
  -- Also, if we are single-player, we need to check
  -- to see how difficult the computer player will be.
  if single_player then
    OB.single_player = true
    
    if difficulty then
      OB.difficult = true
    else
      OB.difficult = false
    end
  else
    OB.single_player = false
  end

  --[[ The vectors in a table so we can loop through them. ]]
  OB._vectors = {
    GRID_TOP_LEFT,
    GRID_TOP,
    GRID_TOP_RIGHT,
    GRID_LEFT,
    GRID_RIGHT,
    GRID_BOTTOM_LEFT,
    GRID_BOTTOM,
    GRID_BOTTOM_RIGHT
  }

  --[[ Our Columns Table for translation ]]
  OB._columns = {
    A = 1, B = 2, C = 3, D = 4,
    E = 5, F = 6, G = 7, H = 8
  }

  --[[ Place our initial pieces. ]]
  local start_places = {
    {4, 4, "#"},
    {4, 5, "O"},
    {5, 4, "O"},
    {5, 5, "#"}
  }

  OB:populate(start_places)

  --[[ Methods Definitions ]]

  function OB:display()
    local x, s, row
    
    print(self._top_line)
    print(OB._row_line)

    for x=1, self.size_x do
      row = self:get_row(x)
      s   = string.format(self._row_data, x, unpack(row))

      print(s)
      print(OB._row_line)
    end

    s = string.format(OB._score, "#", self:get_score("#"), "O", self:get_score("O"))
    
    print(s)
    
    return
  end

  function OB:get_column_number(col_letter)
    if type(col_letter) == "string" then

      col_letter = string.upper(col_letter)

      for k, v in self._columns do
        if k == col_letter then
          return v
        end
      end
    end

    return nil
  end

  function OB:get_column_letter(col_number)
    if type(col_number) == "number" and 
      (col_number > 0 and col_number <= self.size_y) then

      for k, v in self._columns do
        if v == col_number then
          return string.upper(k)
        end
      end
    end

    return nil
  end

  function OB:is_valid_piece(player)
    if type(player) == "string" then
      for _, p in self._allowed do
        if player == p then
          return true
        end
      end
    end

    return false
  end

  function OB:get_opponent(player)
    if OB:is_valid_piece(player) then
      if player == "#" then
        return "O"
      else
        return "#"
      end
    end

    return nil
  end

  function OB:get_valid_moves(player)
    local x, y, vx, vy, piece

    local moves = {}
    local cells = {}
    local opp   = self:get_opponent(player)

    if opp == nil then
      return moves
    end

    -- Check every cell of the board...
    for x=1, self.size_x do
      for y=1, self.size_y do

        -- ...and if the cell is empty...
        if self:get_cell(x, y) == " " then

          -- ...then check each of it's neighbors...
          for _, vector in self._vectors do
            piece = self:get_neighbor(x, y, vector)

            -- ...and if the neighbor contains the 
            -- opponents piece...
            if piece == opp then

              -- ...traverse that vector looking for our
              -- player's piece. If we find our player, 
              -- then we note the original blank x,y cell
              -- in our moves table.
              cells = self:traverse(x, y, vector)

              for _, c in cells do
                vx, vy, obj = unpack(c)

                if obj == player then
                  table.insert(moves, {x, y})
                  break
                end
              end
            end
          end
        end
      end
    end

    -- ...but wait, there's more!
    -- Sometimes, a certain cell is a valid move for
    -- for more than one direction, those get listed
    -- multiple times. We want to remove the dupes.
    local uniq_moves = {}
    local tmp        = {}
    local key        = ""

    for _, c in moves do
      local found

      x, y = unpack(c)

      -- We make a xy string. Each cell is then unique.
      key = string.format("%s%s", x, y)

      -- if our tmp table size is not 0...
      if table.getn(tmp) ~= 0 then
        found = false

        -- ...loop through our tmp table and if we find our
        -- key, we set found to true...
        for _, v in tmp do
          if key == v then
            found = true
          end
        end

        -- ...and if we have -not- found this key before,
        -- we add it to the tmp table and our unique moves
        -- table.
        if found == false then
          table.insert(tmp, key)
          table.insert(uniq_moves, {x, y})
        end
      else
        -- ...else this is our first item, so of -course- we
        -- haven't found it yet.
        table.insert(tmp, key)
        table.insert(uniq_moves, {x, y})
      end
    end

    return uniq_moves
  end

  function OB:is_valid_move(x, y, player)
    local moves = self:get_valid_moves(player)
    local gx, gy

    for _, v in moves do
      gx, gy = unpack(v)

      if x == gx and y == gy then
        return true
      end
    end

    return false
  end

  function OB:has_valid_moves(player)
    local moves = self:get_valid_moves(player)

    if table.getn(moves) > 0 then
      return true
    else
      return false
    end
  end

  function OB:get_score(player)
    local opp   = self:get_opponent(player)
    local score = 0

    if not self:is_valid_piece(player) then
      return score
    end

    for x=1, self.size_x do
      for y=1, self.size_y do
        if self:get_cell(x, y) == player then
          score = score + 1
        end
      end
    end

    return score
  end

  function OB:place(x, y, player)
    local nbr, vx, vy, obj

    local cells = {}
    local opp   = self:get_opponent(player)

    self:set_cell(x, y, player)

    for _, vector in self._vectors do

      -- Check each neighbor cell...
      nbr = self:get_neighbor(x, y, vector)

      -- ...if we find an opponent...
      if nbr == opp then
        local changed      = {}
        local player_found = false

        -- ...traverse that vector...
        cells = self:traverse(x, y, vector)

        for _, c in cells do
          vx, vy, obj = unpack(c)

          -- ...if we find a blank, we can't change any, 
          -- so move on.
          -- ...if we find the player's piece, we mark it
          -- as found, then break to change the cells.
          -- ...otherwise, we note the x,y pair in a table
          -- to track cells to change.
          if obj == " " then
            break
          elseif obj == player then
            player_found = true
            break
          elseif obj == opp then
            table.insert(changed, {vx, vy})
          end
        end

        -- if we have found a players piece and have cells 
        -- to change, then change all of those cell's to 
        -- the player's piece.
        if player_found and table.getn(changed) > 0 then
          for _, c in changed do
            vx, vy = unpack(c)
            self:set_cell(vx, vy, player)
          end
        end
      end
    end
  end

  --[[ End of Core Methods ]]

  --[[
      The following methods are used for single-player use
      only.
  --]]
  if OB.single_player then

    -- Checks to see if a piece is along the edge or a
    -- corner piece. Returns 0 if not, 2 if it is an edge 
    -- piece, and 4 if it is a corner piece. This will be 
    -- used on the Hard difficulty in helping the computer
    -- to chose a move to make.
    function OB:is_corner_edge(x, y)
      if OB:is_valid(x, y) then

        -- Check for corners
        if (x == 1 and y == 1) or (x == 1 and y == self.size_y) or
          (x == self.size_x and y == 1) or 
          (x == self.size_x and y == self.size_y) then
          return 4
        end

        -- Check for edges
        if (x == 1 or x == self.size_y) and (y == 1 or y == self.size_x) then
          return 2
        end

      end

      return 0
    end

    function OB:computer_move(player)
      local moves = self:get_valid_moves(player)

      local movex, movey -- the move we will make.

      -- If this is a hard game, we find the absolute
      -- best move from our valid moves and then place
      -- it.  If we're on an easy game, we randomly 
      -- pick one of the moves from the valid moves and
      -- hope for the best...
      -- We return the x,y move that the computer made.

      if self.difficult then
        local x, y
        local opp        = self:get_opponent(player)
        local curr_score = self:get_score(player)
        local score      = 0
        local diff       = 0

        -- temp board copy
        local tmpob = OthelloBoard()

        -- contents of our live board.
        local contents = self:get_contents()

        -- This works by looping through our moves table
        -- making the move on a temp board, and compiling
        -- a score matrix, that gets as many new cells as
        -- as possible. Edge and Corner moves are weighted
        -- more favorably, with Edge moves getting a +2 to
        -- the score, and corners getting +4 to the score.
        for _, m in moves do
          x, y = unpack(m)

          local new_score = 0
          local edge      = 0

          tmpob:reset_all()
          tmpob:populate(contents)
          tmpob:place(x, y, player)

          new_score = tmpob:get_score(player)
          edge      = OB:is_corner_edge(x, y)

          new_score = (new_score - curr_score) + edge

          if new_score > score then
            score = new_score
            movex = x
            movey = y
          end
        end

        -- We didn't find a best move, then random the move.
        if movex == nil or movey == nil then
          movex, movey = random_move(moves)
        end

      else
        movex, movey = random_move(moves)
      end

      if movex and movey then
        self:place(movex, movey, player)
      end

      return movex, movey
    end

    -- Randomly picks a move from a given moves table.
    function random_move(moves)
      math.randomseed(os.time())

      local i = math.random(1, table.getn(moves))

      return unpack(moves[i])
    end

  --[[ End of single-player methods ]]
  end
  
  -- Return our OthelloBoard object
  return OB

end

--[[ Misc Functions ]]

-- Rolling our own input again...
function input(str)
  local in_data = nil

  -- flush our stdin
  io.stdin:flush()

  if type(str) ~= "string" then
    str = "> "
  end

  io.stdout:write(str)

  in_data = io.stdin:read("*l")

  return in_data
end

-- Convience wrapper...
function output(str, ...)
  if table.getn(arg) >= 1 then
    str = string.format(str, unpack(arg))
  end

  print(str)
end

function parse_xy(str)
  if type(str) ~= "string" then
    return nil
  end

  local x, y, tmp

  for n, m in string.gfind(str, "(%w) (%w)") do
    tmp = tonumber(n)

    -- if n was not the number, then swap them
    -- around, else store them as we got them.
    if tmp == nil then
      x = tonumber(m)
      y = n
    else
      x = tmp
      y = m
    end
  end

  -- is x -still- not a number?
  -- If so, we have an problem, return nil
  if type(x) ~= "number" then
    return nil
  end

  return x, y
end

-- To clear the screen between each update.
-- Yes, it sucks, but I don't feel like 
-- complicating this using [n]curses lib. 
-- ...which not everyone would have anyways. ^.^
function clear()
  return os.execute("clear") or os.execute("cls")
end

-- Function to pause the game.
function pause()
  input("-- Press Enter To Continue --")
end

function debug(msg, do_pause, do_exit)
  if DEBUG then
    if type(msg) ~= "string" then
      msg = "Default Debug Message: This is not helpful. :P"
    end

    print(msg)

    if do_pause then pause()   end
    if do_exit  then os.exit() end
  end
end

function main()
  local sp       -- Single player?
  local spdiff   -- Single player difficulty
  local instr    -- Multi-use input variable.
  local current  -- The current player
  local opp      -- holds the opponent
  local x, y     -- Placement grid vars.
  local ly       -- 'Letter' y from the input.

  --[[ ...the flow, y'know?

      1.) Find out if we are single player or not.
      
      2.) if we are single player, get difficulty and 
          then set up the board appropriately.

      3.) alternate between each player (or computer)
          placing pieces.

          a.) Check if player has valid moves...
              i.  ) ...if so, prompt for a move...
              ii. ) ...if that move is within the valid moves...
              iii.) ...place the player's piece.
              iv. ) Update score.

          b.) If the player has no valid moves...
            i.  ) Check if opponent has any valid moves...
            ii. ) ...and if not, display scores and quit.
            iii.) ...else switch turns and repeat.
  --]]

  clear()

  output("Welcome to Conthello! (The Console Othello! >.>)")

  while true do
    instr = input("Is this a single player game? [Y]es or [N]o: ")
    instr = string.upper(instr)
    instr = string.sub(instr, 1, 1)

    if instr == "Y" then
      sp = true
      break
    elseif instr == "N" then
      sp = false
      break
    end
  end

  if sp then
    instr = nil

    while true do
      instr = input("Difficulty? [E]asy or [H]ard: ")
      instr = string.upper(instr)
      instr = string.sub(instr, 1, 1)

      if instr == "E" then
        spdiff = false
        break
      elseif instr == "H" then
        spdiff = true
        break
      end
    end
  end

  current = "#"

  local ob      = OthelloBoard(sp, spdiff)
  local do_play = true

  while do_play do
    clear()
    ob:display()

    opp = ob:get_opponent(current)

    if ob:has_valid_moves(current) then
      output("The current player is %s", current)

      -- reset our x, y coords.
      x = nil
      y = nil

      while x == nil do
        output("Please enter a row and column, with a space in between...")
        
        instr = input("or 'q' to quit: ")

        if string.lower(string.sub(instr, 1, 1)) == "q" then
          output("Quitting Conthello.")
          do_play = false
          break
        end

        x, ly = parse_xy(instr)
        y     = ob:get_column_number(ly)

        if x ~= nil then
          if ob:is_valid_move(x, y, current) then
            ob:place(x, y, current)

            if ob:has_valid_moves(opp) then
              if ob.single_player then
                local cx, cy = ob:computer_move(opp)

                clear()
                ob:display()

                output("Computer moved at %s,%s.", cx, ob:get_column_letter(cy))
                pause()
              else
                current = opp
              end
            end
          else
            output("%s %s is not a valid move.", x, ly)
            pause()
          end
        end
      end
    elseif ob:has_valid_moves(opp) then
      output("You have no valid moves available.")
      pause()

      if ob.single_player then
        local cx, cy = ob:computer_move(opp)

        clear()
        ob:display()

        output("Computer moved at %s,%s.", cx, ob:get_column_letter(cy))
        pause()
      else
        current = opp
      end
    else
      do_play = false 
    end
  end

  clear()
  ob:display()

  local c_score = ob:get_score(current)
  local o_score = ob:get_score(opp)

  if c_score == o_score then
    output("The game was a tie!")
  else
    if c_score > o_score then
      winner = current
    else
      winner = opp
    end

    output("%s is the winner!", winner)
  end
end

-- Start this shindig!
main()


