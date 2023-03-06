dofile("$CONTENT_DATA/Scripts/Other/Belt.lua")
---An Upgrader has an areaTrigger that interacts with a `Drop` and can modify its value
---@class Upgrader : ShapeClass
---@field cl UpgraderCl
---@field data UpgraderData
---@field powerUtil PowerUtility
Upgrader = class()
Upgrader.maxParentCount = 1
Upgrader.maxChildCount = 0
Upgrader.connectionInput = sm.interactable.connectionType.logic
Upgrader.connectionOutput = sm.interactable.connectionType.none
Upgrader.colorNormal = sm.color.new(0x00dd00ff)
Upgrader.colorHighlight = sm.color.new(0x00ff00ff)

--------------------
-- #region Server
--------------------

---@class Params
---@field filters number|nil filters of the areaTrigger
---@param params Params
function Upgrader:server_onCreate(params)
    if self.data.belt then
        --create Belt
        Belt.server_onCreate(self)
        self.sv_onStay = Belt.sv_onStay
    else
        PowerUtility.sv_init(self)
    end

    --create areaTrigger
    params = params or {}
    local size, offset = self:get_size_and_offset()

    self.upgradeTrigger = sm.areaTrigger.createAttachedBox(self.interactable, size / 2, offset, sm.quat.identity(),
        params.filters or sm.areaTrigger.filter.dynamicBody)
    self.upgradeTrigger:bindOnEnter("sv_onEnter")
end

function Upgrader:server_onFixedUpdate()
    if self.data.belt then
        Belt.server_onFixedUpdate(self)
    else
        PowerUtility.sv_fixedUpdate(self, nil)
    end
end

function Upgrader:sv_onEnter(trigger, results)
    if not self.powerUtil.active then return end
    for _, result in ipairs(results) do
        if not sm.exists(result) then goto continue end
        if type(result) ~= "Body" then goto continue end

        for k, shape in ipairs(result:getShapes()) do
            local interactable = shape:getInteractable()
            if not interactable then return end
            local data = interactable:getPublicData()
            if not data or not data.value then return end

            local uuid = tostring(self.shape.uuid)
            if self.data.upgrade.cap and data.value > self.data.upgrade.cap then goto continue end
            if self.data.upgrade.limit and data.upgrades[uuid] and data.upgrades[uuid] >= self.data.upgrade.limit then goto continue end

            --valid drop
            self:sv_onUpgrade(shape, data)
        end
        ::continue::
    end
end

---Upgrade a drop shape
---@param shape Shape the shape to be upgraded
---@param data table the public data of the shape to be upgraded
function Upgrader:sv_onUpgrade(shape, data)
    local uuid = tostring(self.shape.uuid)

    data.upgrades[uuid] = data.upgrades[uuid] and data.upgrades[uuid] + 1 or 1
    shape.interactable:setPublicData(data)
end

-- #endregion

--------------------
-- #region Client
--------------------

function Upgrader:client_onCreate()
    if self.data.belt then
        Belt.client_onCreate(self)
    else
        self.cl = {}
    end

    self:cl_createUpgradeEffect()
end

function Upgrader:client_onUpdate(dt)
    Belt.client_onUpdate(self, dt)
end

---create effect to visualize the upgrade areaTrigger
function Upgrader:cl_createUpgradeEffect()
    local size, offset = self:get_size_and_offset()

    local effect = self.data.effect
    local uuid = effect and effect.uuid and sm.uuid.new(effect.uuid) or
    sm.uuid.new("5f41af56-df4c-4837-9b3c-10781335757f")
    local color = effect and effect.color and sm.color.new(effect.color.r, effect.color.g, effect.color.b) or
    sm.color.new(1, 1, 1)

    self.cl.effect = sm.effect.createEffect(uuid and "ShapeRenderable" or effect.name, self.interactable)
    self.cl.effect:setParameter("color", color)

    if uuid then
        self.cl.effect:setParameter("uuid", uuid)
        self.cl.effect:setScale(size)
        self.cl.effect:setOffsetPosition(offset)
    end
    self.cl.effect:start()
end

---toggle the effects depending on the current power state
function Upgrader:cl_toggleEffects(active)
    Belt.cl_toggleEffects(self, active)
    if active and not self.cl.effect:isPlaying() then
        self.cl.effect:start()
    else
        self.cl.effect:stop()
    end
end

-- #endregion

---get the size and offset for the areaTrigger based on the script data
---@return Vec3 size
---@return Vec3 offset
function Upgrader:get_size_and_offset()
    local size = sm.vec3.new(self.data.upgrade.box.x, self.data.upgrade.box.y, self.data.upgrade.box.z)
    local offset = sm.vec3.new(self.data.upgrade.offset.x, self.data.upgrade.offset.y, self.data.upgrade.offset.z)
    return size, offset
end

--------------------
-- #region Types
--------------------

---@class UpgraderData
---@field belt boolean wether the Upgrader has a belt or not
---@field upgrade UpgraderUpgrade the upgrade data of the Upgrader
---@field effect UpgraderDataEffect

---@class UpgraderUpgrade
---@field cap number|nil the upgrader can only upgrade drops under this limit
---@field limit number|nil the maximum amount of times this upgrader can be applied to a drop
---@field box table<string, number> dimensions x, y, z for the areaTrigger
---@field offset table<string, number> offset x, y, z for the areaTrigger

---@class UpgraderDataEffect
---@field name string the name of the upgrade effect
---@field color table<string, number> r, g, b values for the color of the effect
---@field uuid string uuid used for ShapeRenderable effect

---@class UpgraderCl
---@field effect Effect the effect that visualizes the areaTrigger of the Upgrader

-- #endregion
