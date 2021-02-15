--[[
MIT License

The game in love2d

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

_APP = {
  NAME = 'Rogue-lua',
  VERSION = "alpha 0.1",
  useLÖVE = true }

require 'rgame'

console = require 'lib.console.console'

once = true

function echo(txt)
	for line in string.gmatch(txt,"([^\r\n]*)[\r\n]?") do
   print(line)
	end
end

function echoln(t)
	for i,v in ipairs(t) do
		print(tostring(i)..'] '..v)
	end
end

function love.load(args)
	echo("Welcome to " .. _APP.NAME .. " " .. _APP.VERSION)

end

function love.update(dt)
	if once then console.show() once = false end
end

function love.draw()
end

function love.textinput(text)
end

function love.threaderror(thread, errorstr)
	err("Thread error " .. tostring(thread) .. ": ")
	for line in string.gmatch(errorstr,"([^\r\n]*)[\r\n]?") do
   print("\t" .. line)
	end
end

function love.keypressed(key, scancode, isrepeat)
	if (key == console.toggle_key) then
		console.toggle()
	else
	end
end

function love.resize(w, h)
end

function love.keyreleased(key, scancode)
end
