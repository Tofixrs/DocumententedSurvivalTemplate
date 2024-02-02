---@class BaseCharacterCl
---@field waterMovementSpeedFraction number Movement multiplier in water

---@class BaseCharacterSv


---@class BaseCharacter : CharacterClass
---@field cl BaseCharacterCl
---@field sv BaseCharacterSv
---@field graphicsLoaded boolean
BaseCharacter = class(nil)
function BaseCharacter:server_onCreate()
    self.character.publicData = {}
    self.sv = {}
end

---Inits the client data and sets player nametag
function BaseCharacter:client_onCreate()
    --init data
    self.character.clientPublicData = {}
    self.cl = {
        waterMovementSpeedFraction = 1.0
    }

    --set player nametag
    local player = self.character:getPlayer()
    if sm.exists(player) then
        if player ~= sm.localPlayer.getPlayer() then
            local name = player:getName()
            self.character:setNameTag(name)
        else
            -- if setNameTag is called here you will be able to see your own name, can be changed during runtime
        end
    end
end

---Transfer server public data of water movement to client
function BaseCharacter:server_onFixedUpdate()
    self.cl.waterMovementSpeedFraction = 1.0
    if self.character.publicData and self.character.publicData.waterMovementSpeedFraction then
        self.cl.waterMovementSpeedFraction = self.character.publicData.waterMovementSpeedFraction
    end
end

function BaseCharacter:client_onGraphicsLoaded()
    self.graphicsLoaded = true
end

function BaseCharacter:client_onGraphicsUnloaded()
    self.graphicsLoaded = false
end

---Updates self.cl.waterMovementSpeedFraction with clientPublicData
function BaseCharacter:client_onFixedUpdate()
    if not sm.isHost then
        self.cl.waterMovementSpeedFraction = 1.0
        if self.character.clientPublicData and self.character.clientPublicData.waterMovementSpeedFraction then
            self.cl.waterMovementSpeedFraction = self.character.clientPublicData.waterMovementSpeedFraction
        end
    end
end

function BaseCharacter:client_onUpdate()
    local totalMovementSpeedFraction = self.cl.waterMovementSpeedFraction
    self.character.movementSpeedFraction = totalMovementSpeedFraction

    if not self.graphicsLoaded then
        return
    end
end
