local FileSystem = require('fs')
local Buffer = require('./BufferExtended.lua')

-- copied from http://lua-users.org/wiki/CopyTable
function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local TgaTexture = {}
--[[ member variables
    ._initialized = boolean
    .width  = number
    .height = number
    .pixels = Buffer
]]

-- returns the new opened object if uninitialized
-- returns nil if already initialized and you reset
function TgaTexture:open(file_in, overwrite)
    assert(file_in and type(file_in)=='string', "\nTgaTexture:open() - Invalid file_in arg type!")
    assert(FileSystem.existsSync(file_in), "\nTgaTexture:open() - Input file does not exist!!")
    if self._initialized then -- we need to reset
        assert(overwrite, "\nTgaTexture:open() - Attempted on already initialized table!")
        self.width = 0
        self.height = 0
        self.pixels = nil
        self._initialized = false
    end
    
    local inputBuffer = Buffer:new(FileSystem.readFileSync(file_in))
    local tgaNew = deepCopy(self)   -- stackoverflow if self.pixels exists
    tgaNew.width  = inputBuffer:readUInt16LE(13)
    tgaNew.height = inputBuffer:readUInt16LE(15)
    tgaNew.pixels = Buffer:new(inputBuffer:toString(19, 18 + (tgaNew.width*tgaNew.height*4)))
    
    if not overwrite then
        tgaNew._initialized = true
        return tgaNew
    else
        self.width = tgaNew.width
        self.height = tgaNew.height
        self.pixels = tgaNew.pixels
        self._initialized = true
    end
end

function TgaTexture:duplicate()
    assert(self._initialized, "\nTgaTexture:duplicate() - Attempted on uninitialized table!")
    
    local bufTemp = self.pixels
    self.pixels = nil
    local tgaNew = deepCopy(self) -- stackoverflow if we don't hide pixels first
    self.pixels = bufTemp
    tgaNew.pixels = Buffer:new(self.pixels:toString())
    
    return tgaNew
end

function TgaTexture:save(file_out) -- Cuz I'm lazy
    assert(file_out and type(file_out)=='string', "\nTgaTexture:save() - Invalid file_in arg type!")
    assert(self._initialized, "\nTgaTexture:save() - Attempted on uninitialized table!")
    
    local header = self:createHeader(self.width, self.height)
    FileSystem.writeFileSync(file_out, (header .. self.pixels))
end

-- Byte Order: BGRA
function TgaTexture:createHeader(w,h)
    local hBuff = Buffer:new(18)
    hBuff:memset(0, nil, 'uint8') -- Make everything a zero
    hBuff:writeUInt8(1, 0) -- IDLength
    hBuff:writeUInt8(2, 0) -- ColorMapType
    hBuff:writeUInt8(3, 2) -- ImageType (idk)
    -- struct ColorMapSpecification
    hBuff:writeUInt16LE(4, 0) -- FirstIndexEntry
    hBuff:writeUInt16LE(6, 0) -- ColorMapLength 
    hBuff:writeUInt8(8, 0)    -- ColorMapEntrySize
    -- struct ImageSpecification
    hBuff:writeUInt16LE(9, 0)   -- XOrigin (TopLeft / 0)
    hBuff:writeUInt16LE(11, h)  -- YOrigin (TopLeft / height)
    hBuff:writeUInt16LE(13, w)  -- Width
    hBuff:writeUInt16LE(15, h)  -- Height
    hBuff:writeUInt8(17, 32)    -- PixelDepth / BitDepth
    hBuff:writeUInt8(18, 40)    -- ImageDescriptor (idk)
    return hBuff
end

return TgaTexture
