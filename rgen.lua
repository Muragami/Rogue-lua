--[[
MIT License

  rgen.lua contains generators for Rogue-lua:
    levels,
    rooms,
    etc.

Copyright (c) 2021 JasonP

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

-- create a list of numbers
function genList(cnt)
  local ret
  for i=1,cnt,1 do
    table.insert(ret,i)
  end
  return ret
end

-- shuffle a list (array table), shuffle in place
function genShuffle(rng,list)
  local len = #list
  local ret = {}
  for i=1,len,1 do
    local spot = rng.roll(len)
    ret[i] = list[spot]
    table.remove(list,spot)
    len = len - 1
  end
  rng = ret
end

function randPos(rng,room)
  return room.x + rng.roll(room.mx - 2) + 1, room.y + rng.roll(room.my - 2) + 1
end

function drawRoom(rng,cfg,lvl,rnum,room)

end

function genMonster(rng,cfg,lvl,room,mx,my)
  -- get the type
  local d
  repeat
	   d = cfg.Level + rng.roll(10) - 5
	   if d < 1 then d = rng.roll(5)
     elseif d > 26 then d = rng.roll(5) + 21
     end
  until cfg.levelTable[d] ~= ' '
  local mchar = cfg.levelTable[d]
  local mons = { mchar, 'monster', Monster[mchar], x = wx, y = wy, insideRoom = room,
        pos = wy*cfg.maxCols+wx, qty = numGP, flags = { [_ID.isMany] = true, [_ID.isItem] = true } }
  -- is there something where the monster is? if so, hold it
  local obj = lvl.map_data[mx+my*cfg.maxCols]
  if obj and obj.flags[_ID.isItem] then mons.holding = obj end
  -- find our stats
  local mstat = Monster[Monster[mchar]][3] -- gotta love that indirection!
  local hits = rng.rollDice(cfg.Level,8)
  mons.stats = {
    level = mstat[3],
    maxHP = hits,
    HP = hits,
    armor = mstat[4],
    dmg = mstat[5],
    exp = mstat[2],
    str = mstat[1],
    carry = Monster[Monster[mchar]][1],
    flags = Monster[Monster[mchar]][2],
  }
  if mchar == 'M' then mons.idTile = 23 + rng.roll(4)
  else mons.idTile = Monster[Monster[mchar]][4] end
  -- done, fire handlers
  CallHandlers('gen monster',rng,cfg,lvl,mons)
end

function genRoom(rng,cfg,lvl,i)
  local TopX = math.fmod(i,lvl.block) * lvl.blockWidth
  local TopY = math.floor(i / lvl.block) * lvl.blockHeight
    -- top of the block we are inside
  local room = lvl.room[i]
  if room[_ID.isGone] then
    -- place a gone room
    repeat
		    room.x = TopX + rng.roll(lvl.blockWidth-2) + 1
        room.y = TopY + rng.roll(lvl.blockHeight-2) + 1
		    room.mx = 0 - cfg.maxCols
		    room.my = 0 - cfg.maxLines
	  until room.y > 0 and room.y < cfg.maxLines-1
  else
    -- place a real room
    -- are we dark?
    if rng.roll(10) < (cfg.Level - 1) then lvl.room[i][_ID.isDark] = true end
    -- place us in the block randomly
    repeat
        room.mx = TopX + rng.roll(lvl.blockWidth-4) + 4
        room.my = TopY + rng.roll(lvl.blockHeight-4) + 4
        room.x = TopX + rng.roll(lvl.blockWidth - room.mx)
        room.y = TopY + rng.roll(lvl.blockHeight - room.my)
    until room.y ~= 0
    -- gold?
    if rng.roll(2) == 1 and cfg.Level < max_level then
      local numGP = rng.roll(36 + 10 * cfg.Level) + 4 -- how much?
      -- where?
      local wx,wy = randPos(rng,room)
      -- create the item data and add it to the world
      local item = { '*', 'gold', '', x = wx, y = wy, insideRoom = room,
            pos = wy*cfg.maxCols+wx, qty = numGP, flags = { [_ID.isMany] = true, [_ID.isItem] = true } }
      lvl.map_data[item.pos] = item
      -- this room's GOT GOLD BABY!
      room.flags[_ID.hasGold] = true
      CallHandlers('gen gold',rng,cfg,lvl,rnum,item)
    end
    -- draw the room onto the map, put stub data
    drawRoom(rng,cfg,lvl,rnum,room)
    -- add a monster?
    local monsterChance = 25
    if room.flags[_ID.hasGold] then monsterChance = 80 end
    if rng.roll(100) <= monsterChance then
      local mx, my = randPos(rng,room)
      genMonster(rng,cfg,lvl,room,mx,my)
    end
    -- all done, call gen room handlers
    CallHandlers('gen room',rng,cfg,lvl,rnum,room)
  end
end

-- takes an rng generator and level number, fills global Level with information
-- or puts it into lvl if you pass that
-- cfg is config data for the level, you can pass _CFG if you want
function genLevel(rng,cfg,lvl)
  if not lvl then lvl = Level end -- adjust the global if we don't pass a specific
  lvl.map = {}
  -- store the block limit for this map based on maxRooms
  lvl.block = math.floor(math.sqrt(cfg.MaxRooms))
  if (lvl.block * lvl.block) ~= cfg.MaxRooms then error("genLevel() cfg.MaxRooms must be a square! ?" .. cfg.MaxRooms) end
  -- block dims!
  lvl.blockWidth = cfg.maxCols / lvl.block
  lvl.blockHeight = cfg.maxLines / lvl.block
  lvl.maxGoneRooms = math.floor(cfg.goneRatio * cfg.MaxRooms) -- about 45%
  -- clear the map entirely
  for i=1,_CFG.maxCols*_CFG.maxLines,1 do
    lvl.map[i] = ' '              -- empty space!
    lvl.map_data[i] = _ID.nothing -- data for the thing at this location
  end
  -- create rooms
  lvl.room = {}
  for i=1, _CFG.maxRooms,1 do
    lvl.room[i] = { valGold = 0, numExits = 0, flags = {} } -- empty
  end
  local goneRooms = rng:roll(lvl.maxGoneRooms) -- how many are gone?
  local goneList = genShuffle(rng,genList(lvl.maxGoneRooms)) -- create a shuffled list
  for i=1, goneRooms,1 do lvl.room[goneList[i]].flags[_ID.isGone] = true end
  for i=1, _CFG.maxRooms,1 do
    genRoom(rng,cfg,lvl,i) -- make the room
  end

end
