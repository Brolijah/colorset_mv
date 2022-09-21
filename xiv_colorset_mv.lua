-- Required stuff. Don't touch.
local Path = require('path')
local Buffer = require("./modules/BufferExtended.lua")
local TgaTexture = require("./modules/TgaTexture.lua")

local COLROWS = {
    0,      -- Row 1
    17,     -- Row 2
    34,     -- Row 3
    51,     -- Row 4
    68,     -- Row 5
    85,     -- Row 6
    102,    -- Row 7
    119,    -- Row 8
    136,    -- Row 9
    153,    -- Row 10
    170,    -- Row 11
    187,    -- Row 12
    204,    -- Row 13
    221,    -- Row 14
    238,    -- Row 15
    255     -- Row 16
}

function IdentifyColorsetRow(alpha)
    -- start here, because if it's not greater than this, then def is 1
    local row = 0
    for i=1, #COLROWS do
        if alpha >= COLROWS[i] then
            row = row + 1
        else break end
    end
    
    return row
end

--[[ This tests the above function
for i=0, 255 do
    local row = IdentifyColorsetRow(i)
    print("Alpha = " .. i .. ". Row = " .. row)
end --]]

-----------------------------------------
--              MAIN CODE              --
-----------------------------------------
CURRENT_DIR = Path.resolve("")

inputFile  = CURRENT_DIR .. '\\source_orig.tga'
outputFile = CURRENT_DIR .. '\\output_flipped_rows.tga'

print("Opening TGA texture!")
sourceTga = TgaTexture:open(inputFile)
print(
"Texture Information:\n" ..
"  Width:  " .. sourceTga.width .. "\n" ..
"  Height: " .. sourceTga.height .. "\n" ..
"  Buffer Length:  " .. sourceTga.pixels.length)

copyTga = sourceTga:duplicate()

colsetRowRemap = {}
colsetRowRemap[1] = 15
colsetRowRemap[2] = 16
colsetRowRemap[3] = 14  -- luh-mao two pixels are in row 3

-- assumes BGRA byte order
for i=0, (sourceTga.width*sourceTga.height)-1 do
    local pix_off = i*4 + 1
    local a = sourceTga.pixels:readUInt8(pix_off + 3)
    local srcRow = IdentifyColorsetRow(a)
    local newRow = colsetRowRemap[srcRow]
    if newRow then
        if newRow == 16 then
            copyTga.pixels:writeUInt8(pix_off+3, 255) -- cap this value
        else
            if newRow == 14 then
                newRow = 15
                print("Correcting weird pixel[" .. i .. "]: Alpha = " .. a)
            end
            if copyTga.pixels:readUInt8(pix_off) == 0 then
                print("Fixing weird black pixel[" .. i .. "]")
                copyTga.pixels:writeUInt8(pix_off+0, 255)
                copyTga.pixels:writeUInt8(pix_off+1, 128)
                copyTga.pixels:writeUInt8(pix_off+2, 128)
            end
            local intensity = a % 17
            local newAlpha = ((newRow-1)*17) + intensity
            copyTga.pixels:writeUInt8(pix_off+3, newAlpha)
        end
    else 
        print("Warning: Pixel[" .. i .. "] contains unexpected Alpha " .. a .. "(Row " .. srcRow .. ")")
    end
end

print("Alphas are remapped to new texture. Saving output...")
copyTga:save(outputFile)
