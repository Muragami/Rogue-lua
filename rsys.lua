--[[
MIT License

  rsys.lua is the main chunk of everything, assisted by a few other files.

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

-- general configuration
_CFG = {
  numColors = 27,
  numStones = 26,
  numWoods = 33,
  numMetal = 22,
  maxDaemons = 20,
  maxRooms = 9,
  maxThings = 9,
  maxObjects = 9,
  maxInventory = 23,
  maxTraps = 10,
  amuletLevel = 26,
  maxPassages = 13,
  goneRatio = 0.45, -- make up to 45% of rooms "gone" per level
                    -- this conforms to 4 of 9 from Rogue 5.2.1
  retNormal = 0,
  retQuit = 1,
  retMinus = 2,
  VERSION = 'RL52B',
  maxCols = 80,
  maxLines = 45,
    -- this makes a virtual map 3 times larger than the minimum screen in both dimensions
    -- meaning, we see 1/9th of the total map at any time
  Level = 1,        -- default to level one if we pass this to gen()
  -- monstertables!
  levelTable = { 'K', 'J', 'B', 'S', 'H', 'E', 'A', 'O', 'Z', 'G', 'L', 'C', 'R',
    'Q', 'N', 'Y', 'T', 'W', 'F', 'I', 'X', 'U', 'M', 'V', 'P', 'D' },
  wanderingTable = { 'K', 'J', 'B', 'S', 'H', ' ', 'A', 'O', 'Z', 'G', ' ', 'C', 'R',
    'Q', ' ', 'Y', 'T', 'W', ' ', 'I', 'X', 'U', ' ', 'V', 'P', ' ' },
}

-- a master table of Rogue Identities
_ID = {
  nothing = {},      -- something that doesn't exist!
  hasAmulet = {},     -- recovered the amulet
  isScoreless = {},   -- can't score anything, cheating/broken!
  isPlaying = {},     -- we are playing
  isRunning = {},     -- we are running
  isWizard = {},      -- cheaters gonna cheat
  initStats = { 16, 0, 1, 10, 12, "1d4", 12 },
                      -- initial stats
  isReinforced = {},  -- reinforced?
  isLeather = {},     -- leather?
  areHungry = { '', 'Hungry', 'Weak', 'Faint' },
                      -- hunger states
  isDark = {},
  isGone = {},
  hasGold = {},
  isCursed = {},
  isItem = {},
  isMany = {},
  isMissle = {},
  canSee = {},
  canConfuse = {},
  isBlind = {},
  isCanceled = {},
  isFound = {},
  isGreedy = {},
  isHasted = {},
  isHeld = {},
  isConfused = {},
  isInvisible = {},
  isMean = {},
  isFlying = {},
  isImmortal = {}, -- regen
  isRunning = {},
  seeUnseen = {},
  isSlowed = {},
                      -- states
  typeRogue = {},
  typeMonster = {},
  typeWizard = {},
                      -- rogue or monster, or?
  mapPassage = {},
  mapSeen = {},
  mapDropped = {},
  mapLocked = {},
  mapReal = {},
                      -- map stuff
  itemEats = {},      -- item eats food
}

-- define a Rogue
Rogue = {
  name = '',          -- the name
  savefile = '',      -- the save file for this run
  knows = {},         -- what a rogue knows!
  state = {},         -- state of the rogue/game
  weapon = false,     -- a weapon?
  armor = false,      -- armor?
  leftRing = false,   -- ring on left hand?
  rightRing = false,  -- ring on right hand?
  inventory = { purse = {}, },
                      -- stuff we picked up, are holding
  enchant = {},       -- enchants on anything (to inventory)
  level = 0,
  deepest = 0,
  food = 0,
  hunger = 1,
  favFruit = "slime-mold"
}

-- weapons!
Weapons = {
  -- dmg wield, dmg thrown, launcher, flags
  ['mace'] =              { '2d4', '1d3', false, {} },
  ['long sword'] =        { '3d4', '1d2', false, {} },
  ['short bow'] =         { '1d1', '1d1', false, {} },
  ['arrow'] =             { '1d1', '2d3', 'short bow', { [_ID.isMissle] = true , [_ID.isMany] = true } },
  ['dagger'] =            { '1d6', '1d4', false, { [_ID.isMissle] = true } },
  ['two handed sword'] =  { '4d4', '1d2', false, {} },
  ['dart'] =              { '1d1', '1d3', false, { [_ID.isMissle] = true , [_ID.isMany] = true } },
  ['crossbow'] =          { '1d1', '1d1', false, {} },
  ['crossbow bolt'] =     { '1d2', '2d5', 'crossbow', { [_ID.isMissle] = true , [_ID.isMany] = true } },
  ['spear'] =             { '2d3', '1d6', false, { [_ID.isMissle] = true } },
  [0] = 'mace',
  [1] = 'long sword',
  [2] = 'short bow',
  [3] = 'arrow',
  [4] = 'dagger',
  [5] = 'two handed sword',
  [6] = 'dart',
  [7] = 'crossbow',
  [8] = 'crossbow bolt',
  [9] = 'spear'
}

-- armors!
Armor = {
          -- armor stats (chance, class, flags)
  ['leather armor'] =         { 20, 8, { [_ID.isLeather] = true } },
  ['ring mail'] =             { 35, 7, {} },
  ['studded leather armor'] = { 50, 7, { [_ID.isReinforced] = true, [_ID.isLeather] = true } },
  ['scale mail'] =            { 75, 5, {} },
  ['chain mail'] =            { 63, 6, {} },
  ['splint mail'] =           { 95, 4, {} },
  ['banded mail'] =           { 85, 4, { [_ID.isReinforced] = true } },
  ['plate mail'] =            { 100, 3, {} },
  [0] = 'leather armor',
  [1] = 'ring mail',
  [2] = 'studded leather armor',
  [3] = 'scale mail',
  [4] = 'chain mail',
  [5] = 'splint mail',
  [6] = 'banded mail',
  [7] = 'plate mail'
}

-- magic stuff
Magic = {
  Potion = {
    -- probability, worth
    ['confuse'] =         { 08, 5 },
    ['paralyze'] =        { 10, 5 },
    ['poison'] =          { 08, 5 },
    ['strength'] =        { 15, 150 },
    ['truesight'] =       { 02, 100 },
    ['healing'] =         { 15, 130 },
    ['detect monster'] =  { 06, 100 },
    ['detect treasure'] = { 06, 105 },
    ['level up'] =        { 02, 250 },
    ['greater heal'] =    { 05, 200 },
    ['haste'] =           { 04, 190 },
    ['restore'] =         { 14, 130 },
    ['blind'] =           { 04, 5 },
    ['nope'] =            { 01, 5 },
    [0] = 'confuse',
    [1] = 'paralyze',
    [2] = 'poison',
    [3] = 'strength',
    [4] = 'truesight',
    [5] = 'healing',
    [6] = 'detect monster',
    [7] = 'detect treasure',
    [8] = 'level up',
    [9] = 'greater heal',
    [10] = 'haste',
    [11] = 'restore',
    [12] = 'blind',
    [13] = 'nope'
  },
  Ring = {
    -- probability, worth
    ['protection'] =        { 09, 400 },
    ['add strength'] =      { 09, 400 },
    ['sustain strength'] =  { 05, 280 },
    ['searching'] =         { 10, 240 },
    ['truesight'] =         { 10, 310 },
    ['adornment'] =         { 01, 10 },
    ['aggro monster'] =     { 10, 10 },
    ['dexterity'] =         { 08, 440 },
    ['boost damage'] =      { 08, 400 },
    ['regeneration'] =      { 04, 460 },
    ['slow digestion'] =    { 09, 240 },
    ['teleportation'] =     { 05, 30 },
    ['stealth'] =           { 07, 470 },
    ['maintain armor'] =    { 05, 380 },
    [0] = 'protection',
    [1] = 'add strength',
    [2] = 'sustain strength',
    [3] = 'searching',
    [4] = 'truesight',
    [5] = 'adornment',
    [6] = 'aggro monster',
    [7] = 'dexterity',
    [8] = 'boost damage',
    [9] = 'regeneration',
    [10] = 'slow digestion',
    [11] = 'teleportation',
    [12] = 'stealth',
    [13] = 'maintain armor'
  },
  Scroll = {
    ['monster confusion'] =   { 08, 140 },
    ['magic mapping'] =       { 05, 150 },
    ['hold monster'] =        { 03, 180 },
    ['sleep'] =               { 05, 5 },
    ['enchant armor'] =       { 08, 160 },
    ['identify'] =            { 27, 100},
    ['scare monster'] =       { 04, 200 },
    ['gold detection'] =      { 04, 50 },
    ['teleportation'] =       { 07, 165 },
    ['enchant weapon'] =      { 10, 150 },
    ['create monster'] =      { 05, 75 },
    ['remove curse'] =        { 08, 105 },
    ['aggro monsters'] =      { 04, 20},
    ['blank paper'] =         { 01, 5 },
    ['genocide'] =            { 01, 300 },
    [0] = 'monster confusion',
    [1] = 'magic mapping',
    [2] = 'hold monster',
    [3] = 'sleep',
    [4] = 'enchant armor',
    [5] = 'identify',
    [6] = 'scare monster',
    [7] = 'gold detection',
    [8] = 'teleportation',
    [9] = 'enchant weapon',
    [10] = 'create monster',
    [11] = 'remove curse',
    [12] = 'aggro monsters',
    [13] = 'blank paper',
    [14] = 'genocide'
  },
  Wand = {
    ['light'] =           { 12, 250 },
    ['striking'] =        { 09, 75 },
    ['lightning'] =       { 03, 330 },
    ['fire'] =            { 03, 330 },
    ['cold'] =            { 03, 330 },
    ['polymorph'] =       { 15, 310 },
    ['magic missle'] =    { 10, 170 },
    ['haste monster'] =   { 09, 5 },
    ['slow monster'] =    { 11, 350 },
    ['drain life'] =      { 09, 300 },
    ['nothing'] =         { 01, 5 },
    ['teleport away'] =   { 05, 340 },
    ['teleport to'] =     { 05, 50 },
    ['cancellation'] =    { 05, 280 },
    [0] = 'light',
    [1] = 'striking',
    [2] = 'lightning',
    [3] = 'fire',
    [4] = 'cold',
    [5] = 'polymorph',
    [6] = 'magic missle',
    [7] = 'haste monster',
    [8] = 'slow monster',
    [9] = 'drain life',
    [10] = 'nothing',
    [11] = 'teleport away',
    [12] = 'teleport to',
    [13] = 'cancellation'
  }
}

-- randomly generated stuff
Potions = {}
Rings = {}
Scrolls = {}
Wands = {}

-- we got the level
Level = {
  map = {},
  map_data = {},
  numTraps = 0,
  room = {}
}

-- actions (everything here is a tick on the clock)
Action = {
  -- std key, action name
  ['identify'] = { '/', 'identify object' },
  ['left'] = { 'left', 'go left' },
  ['down'] = { 'down', 'go down' },
  ['right'] = { 'right', 'go right' },
  ['up'] = { 'up', 'go up' },
  ['up/left'] = { '^left', 'go up & left' },
  ['down/left'] = { '%left', 'go down & left' },
  ['up/right'] = { '^right', 'go up & right' },
  ['down/right'] = { '%right', 'go down & right' },
  ['left!'] = { '+left', 'run left' },
  ['down!'] = { '+down', 'run down' },
  ['right!'] = { '+right', 'run right' },
  ['up!'] = { '+up', 'run up' },
  ['up/left!'] = { '+^left', 'run up & left' },
  ['down/left!'] = { '%+left', 'run down & left' },
  ['up/right!'] = { '+^right', 'run up & right' },
  ['down/right!'] = { '%+right', 'run down & right' },
  ['zap'] = { 'z', 'zap wand'},
  ['throw'] = { 't', 'throw something'},
  ['idtrap'] = { '^', 'identify trap'},
  ['search'] = { 's', 'search trap/secret door'},
  ['/down'] = { '>', 'go down a staircase'},
  ['/up'] = { '<', 'go up a staircase'},
  ['rest'] = { '.', 'rest a while'},
  ['quaff'] = { 'q', 'quaff potion'},
  ['eat'] = { 'e', 'eat food'},
  ['read'] = { 'r', 'read paper'},
  ['wield'] = { 'w', 'wield weapon'},
  ['wear'] = { '+w', 'wear armor'},
  ['drop'] = { 'd', 'drop object'},
  ['remove'] = { '+d', 'remove(drop) armor'},
  ['break'] = { 'b', 'break/bust/clear (chests, webs)'}
}

-- inputs that don't tick the clock
Command = {
  ['call'] = { 'c', 'call object'},
  ['options'] = { 'o', 'show/set options'},
  ['esc'] = { 'escape', 'cancel command'},
  ['shell'] = { '!', 'shell escape'},
  ['save'] = { '+s', 'save game'},
  ['quit'] = { '+q', 'quit'},
  ['inv'] = { 'i', 'inventory'},
  ['inv+'] = { '+i', 'inventory single item'},
  ['help'] = { '?', 'show help'}
}

-- monsters
Monster = {
          -- carry, flags, stats (str, exp, level, armor, dmg ), tile
  ['ant (giant)'] = { 0, { [_ID.isMean] = true }, { 10, 9, 2, 3, '1d6' }, 70 },
  ['bat'] = { 0, { [_ID.isFlying] = true }, { 10, 1, 1, 3, '1d2' }, 71 },
  ['centaur'] = { 0, {}, { 10, 15, 4, 4, '1d6/1d6' }, 72 },
  ['dragon'] = { 100, { [_ID.isMean] = true }, { 10, 6800, 10, -1, '1d8/1d8/3d10' }, 73 },
  ['floating eye'] = { 0, {}, { 10, 5, 1, 9, '0d0' }, 74 },
  ['violet fungi'] = { 0, { [_ID.isMean] = true }, { 10, 80, 8, 3, '%%%d0' }, 75 },
  ['gnome'] = { 10, {}, { 10, 7, 1, 5, '1d6' }, 76 },
  ['hobgoblin'] = { 0, { [_ID.isMean] = true }, { 10, 3, 1, 5, '1d8' }, 77 },
  ['invisible stalker'] = { 0, { [_ID.isInvisible] = true }, { 10, 120, 8, 3, '4d4' }, 78 },
  ['jackal'] = { 0, { [_ID.isMean] = true }, { 10, 2, 1, 7, '1d2' }, 79 },
  ['kobold'] = { 0, { [_ID.isMean] = true }, { 10, 1, 1, 7, '1d4' }, 80 },
  ['leprechaun'] = { 0, {}, { 10, 10, 3, 8, '1d1' }, 81 },
  ['mimic'] = { 30, {}, { 10, 100, 7, 7, '3d4' }, 82 },
  ['nymph'] = { 100, {}, { 10, 37, 3, 9, '0d0' }, 83 },
  ['orc'] = { 0, { [_ID.isGreedy] = true }, { 10, 5, 1, 6, '1d8' }, 84 },
  ['purple worm'] = { 70, {}, { 10, 4000, 15, 6, '2d12/2d4' }, 85 },
  ['quasit'] = { 30, { [_ID.isMean] = true, [_ID.isFlying] = true }, { 10, 32, 3, 2, '1d2/1d2/1d4' }, 86 },
  ['rust monster'] = { 0, { [_ID.isMean] = true }, { 10, 20, 5, 2, '0d0/0d0' }, 87 },
  ['snake'] = { 0, { [_ID.isMean] = true }, { 10, 2, 1, 5, '1d3' }, 88 },
  ['troll'] = { 50, { [_ID.isMean] = true, [_ID.isImmortal] = true }, { 10, 120, 6, 4, '1d8/1d8/2d6' }, 89 },
  ['umber hulk'] = { 40, { [_ID.isMean] = true }, { 10, 200, 8, 2, '3d4/3d4/2d5' }, 90 },
  ['vampire'] = { 20, { [_ID.isMean] = true, [_ID.isImmortal] = true }, { 10, 350, 8, 1, '1d10' }, 91 },
  ['wraith'] = { 0, {}, { 10, 55, 5, 4, '1d6' }, 92 },
  ['xorn'] = { 0, { [_ID.isMean] = true }, { 10, 190, 7, -2, '1d3/1d3/1d3/4d6' }, 93 },
  ['yeti'] = { 30, {}, { 10, 50, 4, 6, '1d6/1d6' }, 94 },
  ['zombie'] = { 0, { [_ID.isMean] = true }, { 10, 6, 2, 8, '1d8' }, 95 },
  [0] = 'ant (giant)',
  [1] = 'bat',
  [2] = 'centaur',
  [3] = 'dragon',
  [4] = 'floating eye',
  [5] = 'violet fungi',
  [6] = 'gnome',
  [7] = 'hobgoblin',
  [8] = 'invisible stalker',
  [9] = 'jackal',
  [10] = 'kobold',
  [11] = 'leprechaun',
  [12] = 'mimic',
  [13] = 'nymph',
  [14] = 'orc',
  [15] = 'purple worm',
  [16] = 'quasit',
  [17] = 'rust monster',
  [18] = 'snake',
  [19] = 'troll',
  [20] = 'umber hulk',
  [21] = 'vampire',
  [22] = 'wraith',
  [23] = 'xorn',
  [24] = 'yeti',
  [25] = 'zombie',
  ['A'] = 'ant (giant)',
  ['B'] = 'bat',
  ['C'] = 'centaur',
  ['D'] = 'dragon',
  ['E'] = 'floating eye',
  ['F'] = 'violet fungi',
  ['G'] = 'gnome',
  ['H'] = 'hobgoblin',
  ['I'] = 'invisible stalker',
  ['J'] = 'jackal',
  ['K'] = 'kobold',
  ['L'] = 'leprechaun',
  ['M'] = 'mimic',
  ['N'] = 'nymph',
  ['O'] = 'orc',
  ['P'] = 'purple worm',
  ['Q'] = 'quasit',
  ['R'] = 'rust monster',
  ['S'] = 'snake',
  ['T'] = 'troll',
  ['U'] = 'umber hulk',
  ['V'] = 'vampire',
  ['W'] = 'wraith',
  ['X'] = 'xorn',
  ['Y'] = 'yeti',
  ['Z'] = 'zombie',
}

-- all event handlers (each a table of functions to be called when X happens)
EventHandler = {
  ['game start'] = {},
  ['game over'] = {},
  ['game save'] = {},
  ['game load'] = {},
  ['gen gold'] = {},
  ['gen room'] = {},
  ['gen level'] = {},
  ['gen monster'] = {},
}

function CallHandlers(name,...)
  for _,v in pairs(EventHandler[name]) do
    if type(v) == 'table' then v:handle(name,...)
    else v(name,...)
    end
  end
end
