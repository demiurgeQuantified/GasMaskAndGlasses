--[[GAS MASK AND GLASSES
    Copyright (C) 2022 albion

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

local bodyLocations = {"MaskEyes","MaskFull","FullHat","FullSuitHead","FullTop"}

local group = BodyLocations.getGroup("Human")

group:getOrCreateLocation("Glasses")
for _,v in ipairs(bodyLocations) do
    group:setHideModel(v, "Eyes") -- models are hidden based on the BodyLocation they're supposed to be in, not the one they are in
end

local function getCoveringItem(character)
    for _,location in ipairs(bodyLocations) do
        local wornItem = character:getWornItem(location)
        if wornItem then return wornItem end
    end
    return false
end

local old_perform = ISWearClothing.perform

function ISWearClothing:perform() -- hijacks new items into the glasses slot
    if self.item:getBodyLocation() == "Eyes" then
        self.item:setJobDelta(0.0);

        if self:isAlreadyEquipped(self.item) then
            ISBaseTimedAction.perform(self);
            return
        end
    
        self.item:getContainer():setDrawDirty(true);

        self.character:setWornItem("Glasses", self.item)

        triggerEvent("OnClothingUpdated", self.character)
        ISBaseTimedAction.perform(self)
    else
        old_perform(self)
    end
end

local function onClothingUpdated(character) -- makes glasses unable to fall off while covered
    local glasses = character:getWornItem("Glasses")
    if glasses then
        if getCoveringItem(character) then
            local modData = glasses:getModData()
            if not modData["origFallChance"] then
                modData["origFallChance"] = glasses:getChanceToFall()
            end
            glasses:setChanceToFall(0)
        else
            local fallChance = glasses:getModData()["origFallChance"] or false
            if fallChance then glasses:setChanceToFall(fallChance) end
        end
    end
end

Events.OnClothingUpdated.Add(onClothingUpdated)

local function onGameStart() -- moves items spawned with into the glasses slot
    local character = getPlayer()
    local glasses = character:getWornItem("Eyes")
    if glasses then
        character:setWornItem("Glasses", glasses)
        triggerEvent("OnClothingUpdated", character)
    end
end

Events.OnGameStart.Add(onGameStart)

-- automatically unequip and reequip covering items when trying to put on/take off glasses

local old_start = ISWearClothing.start

function ISWearClothing:start()
    if self.item:getBodyLocation() == "Eyes" then
        local blockingItem = getCoveringItem(self.character)
        if blockingItem then
            self:stop()

            ISTimedActionQueue.add(ISUnequipAction:new(self.character, blockingItem, 50))
            ISTimedActionQueue.add(ISWearClothing:new(self.character, self.item, 50))
            ISTimedActionQueue.add(ISWearClothing:new(self.character, blockingItem, 50))
        end
    end
    old_start(self)
end

local old_unequipStart = ISUnequipAction.start

function ISUnequipAction:start()
    if self.item:getBodyLocation() == "Eyes" then
        local blockingItem = getCoveringItem(self.character)
        if blockingItem then
            self:stop()

            ISTimedActionQueue.add(ISUnequipAction:new(self.character, blockingItem, 50))
            ISTimedActionQueue.add(ISUnequipAction:new(self.character, self.item, 50))
            ISTimedActionQueue.add(ISWearClothing:new(self.character, blockingItem, 50))
        end
    end
    old_unequipStart(self)
end