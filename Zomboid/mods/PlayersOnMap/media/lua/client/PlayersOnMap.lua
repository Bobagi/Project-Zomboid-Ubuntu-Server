local ISWorldMap_render = ISWorldMap.render;
local ISMiniMapOuter_render = ISMiniMapOuter.render;
local ISWorldMap_instance = nil;
local ISMiniMap_instance = nil;
local ISWorldMap_players = true;
local ISMiniMap_players = true;
local pom_max_distance = 100;
local pom_sync_distance = 10;
local pom_players = nil;
local pom_dot_color = { r = 0, g = 1, b = 0, a = 1 };
local pom_dot_size = 3;
local saved_time = os.time();

local function pom_checkDistance(player, o_player, me_player)
    if (not o_player) then return false end

    local dist1 = pom_getDistancePlayer(me_player, o_player);
    local pom_player = pom_getPlayer(o_player);
    local dist2 = pom_getDistance2D(pom_player.x, pom_player.y, player.x, player.y);

    return (math.abs(dist1 - dist2) < pom_sync_distance);
end

local function drawPlayerOnMap(map, player, isMinimap)
    --Get myself player
    local me_player = getPlayer();

    --Check if the player drawn on map is me
    local isMe = (isClient() and (player.id == me_player:getOnlineID())); --Check if is me in online
    local isMe = (isMe or ((not isClient()) and (player.num == me_player:getPlayerNum()))); --Check if is me in local (split screen)

    --If online then get and update online player
    local o_player = nil;
    if (isClient()) then o_player = getPlayerByOnlineID(player.id); end
    local b0 = (o_player and pom_checkDistance(player, o_player, me_player));
    if (b0 and (pom_getDistancePlayer(me_player, o_player) < pom_max_distance)) then player = pom_getPlayer(o_player) end

    --If offline then get and update local player
    local l_player = nil;
    if (not isClient()) then l_player = getSpecificPlayer(player.num); end
    if (l_player) then player = pom_getPlayer(l_player) end

    --If map is minimap then use inner map
    if (map.inner) then map = map.inner; end

    --Don't draw invisible players if not admin or me
    if (player.invisible and (not isAdmin()) and (not isMe)) then return end

    --Don't draw dead players if not admin or me and option is enabled
    if ((not player.alive) and (not SandboxVars.PlayersOnMap.ShowDeadPlayers) and (not isAdmin()) and (not isMe)) then return end

    --Don't draw for myself at this zoom because then the player model is drawed
    --Not needed because default drawing is disabled with this mod
    --if (isMe and (map.mapAPI:getZoomF() >= 20)) then return end

    --Don't render player if player is too far
    local me_pom_player = pom_getPlayer(me_player);
    local distance = pom_getDistance2D(me_pom_player.x, me_pom_player.y, player.x, player.y);
    if ((not isMe) and (not isAdmin()) and (SandboxVars.PlayersOnMap.MaxDistance >= 0) and (distance > SandboxVars.PlayersOnMap.MaxDistance)) then return end

    --Check if we are in the same faction as other player
    --Of course if we are not drawing ourself and faction option is enabled
    local faction = Faction.getPlayerFaction(me_player);
    if (SandboxVars.PlayersOnMap.ShowOnlyFaction and (not isAdmin()) and (not faction) and (not isMe)) then return end
    if (SandboxVars.PlayersOnMap.ShowOnlyFaction and (not isAdmin()) and faction and (faction:getName() ~= player.faction_name)) then return end

    --Get position where to draw
    local x = math.floor(map.mapAPI:worldToUIX(player.x, player.y));
    local y = math.floor(map.mapAPI:worldToUIY(player.x, player.y));

    --Draw player dot on a map
    map:drawRect(x-pom_dot_size, y-pom_dot_size, pom_dot_size*2-1, pom_dot_size*2-1, pom_dot_color.a, pom_dot_color.r, pom_dot_color.g, pom_dot_color.b);
    map:drawRectBorder(x-pom_dot_size, y-pom_dot_size, pom_dot_size*2, pom_dot_size*2, 1, 0, 0, 0);

    --Check if we should draw player name
    local bPlayerNames = true;
    if (isMe and (not SandboxVars.PlayersOnMap.ShowMyName)) then return end --Don't draw my name if setting is disabled
    if (ISWorldMap_instance) then bPlayerNames = ISWorldMap_instance.mapAPI:getBoolean("PlayerNames"); end --Get client setting if to draw player names
    if ((not bPlayerNames) or (not SandboxVars.PlayersOnMap.ShowPlayerNames)) then return end --Don't draw name if disabled by server or client settings

    --Draw player name on a map
    if (isMinimap and SandboxVars.PlayersOnMap.FontDebugConsole) then
        local width = getTextManager():MeasureStringX(UIFont.DebugConsole, player.username)+8;
        local height = getTextManager():MeasureStringY(UIFont.DebugConsole, player.username);
        map:drawRect(x-width/2, y+pom_dot_size*2-2, width, height+1, 0.5, 0.5, 0.5, 0.5);
        map:drawText(player.username, x+4-width/2, y-2+pom_dot_size*2, 0, 0, 0, 1, UIFont.DebugConsole);
    else
        local width = getTextManager():MeasureStringX(UIFont.Small, player.username)+8;
        local height = getTextManager():MeasureStringY(UIFont.Small, player.username);
        map:drawRect(x-width/2, y+pom_dot_size*2-2, width, height+1, 0.5, 0.5, 0.5, 0.5);
        map:drawText(player.username, x+4-width/2, y-3+pom_dot_size*2, 0, 0, 0, 1, UIFont.Small);
    end

    --Original games rect size, I think it was too big
    --local width = getTextManager():MeasureStringX(UIFont.Small, player.username)+16;
    --local height = getTextManager():MeasureStringY(UIFont.Small, player.username);
    --map:drawRect(x-width/2, y+pom_dot_size*2-2, width, height+5, 0.5, 0.5, 0.5, 0.5);
    --map:drawText(player.username, x+9-width/2, y+pom_dot_size*2, 0, 0, 0, 1, UIFont.Small);
end

function ISWorldMap:render(...)
    ISWorldMap_instance = self;
    ISWorldMap_render(self, ...); --putting this at the end will not fix drawing over buttons

    if (not isClient()) then pom_players = pom_getPlayers(); end
    if ((not pom_players) or (not ISWorldMap_players)) then return end
    if (not SandboxVars.PlayersOnMap.Enabled) then return end

    for _, player in pairs(pom_players.players) do
        drawPlayerOnMap(self, player, false);
    end
end

function ISMiniMapOuter:render(...)
    ISMiniMap_instance = self;
    ISMiniMapOuter_render(self, ...);

    if (not isClient()) then pom_players = pom_getPlayers(); end
    if ((not pom_players) or (not ISWorldMap_players)) then return end
    if (not SandboxVars.PlayersOnMap.Enabled) then return end

    self.inner:setStencilRect(0, 0, self:getWidth(), self:getHeight());

    for _, player in pairs(pom_players.players) do
        drawPlayerOnMap(self, player, true);
    end

    self.inner:clearStencilRect();
end

local function OnServerCommand(module, command, args)
    if ((module ~= "PlayersOnMap") or (command ~= "players")) then return end
    --print("PlayersOnMap: OnServerCommand -> ", module, " ", command, " ", args);
    pom_players = args;
end

local function OnPreUIDraw()
    if (not SandboxVars.PlayersOnMap.Enabled) then return end

	if (ISWorldMap_instance) then
        ISWorldMap_players = ISWorldMap_instance.mapAPI:getBoolean("Players");
        ISWorldMap_instance.mapAPI:setBoolean("Players", false);
    end

	if (ISMiniMap_instance) then
        ISMiniMap_players = ISMiniMap_instance.inner.mapAPI:getBoolean("Players");
        ISMiniMap_instance.inner.mapAPI:setBoolean("Players", false);
    end
end

local function OnPostUIDraw()
    if (not SandboxVars.PlayersOnMap.Enabled) then return end

	if (ISWorldMap_instance and (ISWorldMap_players ~= nil)) then
        ISWorldMap_instance.mapAPI:setBoolean("Players", ISWorldMap_players);
    end

	if (ISMiniMap_instance and (ISMiniMap_players ~= nil)) then
        ISMiniMap_instance.inner.mapAPI:setBoolean("Players", ISMiniMap_players);
    end
end

local function OnTick(tick)
    if ((not isClient()) or (getPlayer() == nil)) then return end
    if (pom_absolute((os.time() - saved_time)*1000) < 100) then return end
    saved_time = os.time();
    sendClientCommand("PlayersOnMap", "player", pom_getPlayer(getPlayer()));
end

Events.OnTick.Add(OnTick);
Events.OnServerCommand.Add(OnServerCommand);
Events.OnPreUIDraw.Add(OnPreUIDraw);
Events.OnPostUIDraw.Add(OnPostUIDraw);