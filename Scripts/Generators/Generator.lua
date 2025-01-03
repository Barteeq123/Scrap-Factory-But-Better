dofile("$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

---A Generator produces power. Additionally it can also store power.
---@class Generator : ShapeClass
---@field data GeneratorData script data from the json file
---@field sv GeneratorSv
---@field cl GeneratorCl
Generator = class(nil)

--------------------
-- #region Server
--------------------

local currentGenertors = 0

function Generator:server_onCreate()
    self.sv = self.sv or {}

    currentGenertors = currentGenertors + 1

    if self.data.power then
        ---@diagnostic disable-next-line: assign-type-mismatch
        self.data.power = tonumber(self.data.power)
    end

    if self.data.powerStorage then
        ---@diagnostic disable-next-line: assign-type-mismatch
        self.data.powerStorage = tonumber(self.data.powerStorage)
        PowerManager.sv_changePowerStorage(self.data.powerStorage)
    end
end

function Generator:server_onDestroy()
    currentGenertors = currentGenertors - 1

    if self.data.powerStorage then
        PowerManager.sv_changePowerStorage(-self.data.powerStorage)
    end
end

function Generator:server_onFixedUpdate()
    if self.data.power and sm.game.getCurrentTick() % 40 == 0 then
        local power = self:sv_getPower()
        PowerManager.sv_changePower(power)
        self.network:setClientData({ power = tostring(power) })
    end
end

---How much power the Generator is producing currently
---@return number
function Generator:sv_getPower()
    return self.data.power
end

-- #endregion

--------------------
-- #region Client
--------------------

function Generator:client_onCreate()
    self.cl = {}
    self.cl.power = 0

    if not sm.isHost then
        currentGenertors = currentGenertors + 1
    end
end

function Generator:client_onClientDataUpdate(data)
    if data.power then
        ---@diagnostic disable-next-line: assign-type-mismatch
        self.cl.power = tonumber(data.power)
    end
end

function Generator:client_canInteract()
    local o1 = "<p textShadow='false' bg='gui_keybinds_bg_orange' color='#4f4f4f' spacing='9'>"
    local o2 = "</p>"
    sm.gui.setInteractionText(language_tag("PowerOutput"),
        o1 .. format_number({ format = "power", value = self.cl.power, color = "#4f4f4f" }) .. o2)
    return true
end

function Generator:client_onDestroy()
    if not sm.isHost then
        currentGenertors = currentGenertors + 1
    end
end

-- #endregion

--------------------
-- #region Types
--------------------

---@class GeneratorSv
---@field data GeneratorData

---@class GeneratorData
---@field power number how much power is produced by default
---@field powerStorage number if it is a Battery class, the max capacity

---@class GeneratorSv

---@class GeneratorCl
---@field power number current power output set by clientData

-- #endregion
