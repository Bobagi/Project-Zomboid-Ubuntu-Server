require "ISUI/ISCollapsableWindow"
CoordsWindow = ISCollapsableWindow:derive("CoordsWindow");

function CoordsWindow:initialise()
	ISCollapsableWindow.initialise(self);
end

function CoordsWindow:new(x, y, width, height)
	local o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self)
	self.__index = self
	o.title = "GPS";
	o.pin = true;
	o.resizable = false;
	o.backgroundColor = {r=0, g=0, b=0, a=0.8};
	return o;
end

function CoordsWindow:createChildren()
	ISCollapsableWindow.createChildren(self);
	
	self.CoordsBody = ISRichTextPanel:new(0, 16, 120, 40);
	self.CoordsBody:initialise();
	self.CoordsBody.marginTop = 3;
	self.CoordsBody.marginLeft = 25;
	self.CoordsBody.marginBottom = 0;
	self.CoordsBody.marginRight = 0;
	self:addChild(self.CoordsBody);
	
end

function CoordsWindowCreate()
	CoordsWindow = CoordsWindow:new(220, 0, 120, 40);
	CoordsWindow:addToUIManager();
	CoordsWindow:setVisible(false);
	CoordsWindow.pin = true;
	CoordsWindow.resizable = false;
end

function CoordsUpdate()
	local player = getSpecificPlayer(0);
	if player then
		local x = round(player:getX());
		local y = round(player:getY());
		local pos = x .. ", " .. y;
		CoordsWindow.CoordsBody.text = pos;
		CoordsWindow.CoordsBody:paginate();
		CoordsWindow:setVisible(true);
	end
end

Events.OnGameStart.Add(CoordsWindowCreate);
Events.OnPlayerUpdate.Add(CoordsUpdate);