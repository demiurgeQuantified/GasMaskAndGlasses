--[[GAS MASK AND GLASSES
    Copyright (C) 2023 albion

    This program is free software: you can redistribute it and/or modify
    it under the terms of Version 3 of the GNU Affero General Public License as published
    by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

    For any questions, contact me through steam or on Discord - albion#0123
]]
local Foraging = {}

--- Valid Glasses slot items to be wearing to remove the shortsighted foraging debuff
---@type table<string, boolean>
Foraging.visualAids = {
    ["Base.Glasses_Normal"] = true,
    ["Base.Glasses_Reading"] = true,
}

--- Fix shortsighted glasses check
---@return boolean
local function tryAddShortsighted()
    local shortSighted = forageSkills.ShortSighted
    if not shortSighted then return false end
    
    local origTest = shortSighted.testFuncs[1]
    if not origTest then return false end
    
    --- Returns false if the character is wearing an item from visualAids in the Glasses slot
    ---@param character IsoGameCharacter
    ---@param skillDef table
    ---@param bonusEffect string
    ---@return boolean
    Foraging.testShortsighted = function(character, skillDef, bonusEffect)
        ---@type boolean
        local result = origTest(character, skillDef, bonusEffect)
        
        if result and bonusEffect == "visionBonus" then
            local wornItem = character:getWornItem("Glasses");
            if wornItem and Foraging.visualAids[wornItem:getFullType()] then
                return false
            end
        end
        
        return result
    end
    
    shortSighted.testFuncs[1] = Foraging.testShortsighted
    return true
end

--- Whether or not the shortsighted debuff was hooked
local shortsightedLoaded = tryAddShortsighted()

--- Whether or not the shortsighted debuff was hooked. Check this before attempting to access testShortsighted
Foraging.isShortsightedLoaded = function()
    return shortsightedLoaded
end

if not Foraging.isShortsightedLoaded() then
    print("GasMaskAndGlasses WARN: could not hook shortsighted foraging debuff")
end

return Foraging