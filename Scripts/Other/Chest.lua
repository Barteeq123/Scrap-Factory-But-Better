dofile("$SURVIVAL_DATA/Scripts/game/survival_loot.lua")

Chest = class(nil)

function Chest.server_onCreate(self)
	local container = self.shape.interactable:getContainer(0)
	if not container then
		container = self.shape:getInteractable():addContainer(0, self.data.slots, 9999)
	elseif self.shape.body:isOnLift() then
		sm.container.beginTransaction()
		for i = 0, container.size, 1 do
			sm.container.setItem(container, i, sm.uuid.getNil(), 0)
		end
		sm.container.endTransaction()
	end

	self.sv = {}
	self.sv.container = container
	self.sv.lootList = {}
	self.sv.pos = self.shape.worldPosition
end

function Chest:server_onFixedUpdate()
	if not sm.exists(self.shape) then return end

	self.sv.lootList = {}

	for i = 0, self.sv.container.size, 1 do
		local item = self.sv.container:getItem(i)
		if item.uuid ~= sm.uuid.getNil() then
			self.sv.lootList[#self.sv.lootList + 1] = item
		end
	end
end

function Chest.server_onDestroy(self)
	SpawnLoot(sm.player.getAllPlayers()[1], self.sv.lootList, self.sv.pos)
end

function Chest.server_canErase(self)
	return self.sv.container:isEmpty()
end

function Chest:client_onCreate()
	self.cl = {}
	self.cl.container = self.shape.interactable:getContainer(0)
end

function Chest.client_onInteract(self, character, state)
	if state == true then
		if self.cl.container then
			self.cl.containerGui = sm.gui.createContainerGui(true)
			self.cl.containerGui:setText("UpperName", "#{CONTAINER_TITLE_GENERIC}")
			self.cl.containerGui:setVisible("TakeAll", true)
			self.cl.containerGui:setContainer("UpperGrid", self.shape.interactable:getContainer(0));
			self.cl.containerGui:setText("LowerName", "#{INVENTORY_TITLE}")
			self.cl.containerGui:setContainer("LowerGrid", sm.localPlayer.getInventory())
			self.cl.containerGui:open()
		end
	end
end

function Chest.client_onDestroy(self)
	if self.cl.containerGui then
		if sm.exists(self.cl.containerGui) then
			self.cl.containerGui:close()
			self.cl.containerGui:destroy()
		end
	end
end
