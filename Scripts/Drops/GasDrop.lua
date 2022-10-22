dofile("$CONTENT_DATA/Scripts/Drops/Drop.lua")

GasDrop = class( Drop )

local despawnHeight = 69
local skyboxLimit = 1000

function GasDrop:server_onCreate()
    Drop.server_onCreate(self)
    self.startHeight = self.shape.worldPosition.z
end

function GasDrop:server_onFixedUpdate()
    Drop.server_onFixedUpdate(self)

    local mass = self.shape:getBody().mass
    local jitter = sm.vec3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5)
    sm.physics.applyImpulse(self.shape, sm.vec3.new(0,0,1) * mass/3.4 + jitter*1, true)

    local height = self.shape.worldPosition.z 
    if height > skyboxLimit or (height - self.startHeight) > despawnHeight then
        self.shape:destroyShape(0)
    end
end