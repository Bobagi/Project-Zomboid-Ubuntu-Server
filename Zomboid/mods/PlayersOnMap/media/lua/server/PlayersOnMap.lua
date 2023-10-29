local saved_time = os.time();
local player_cache = {};

local function OnTick(tick)
    if (pom_absolute((os.time() - saved_time)*1000) < 100) then return end
    saved_time = os.time();
    sendServerCommand("PlayersOnMap", "players", pom_getPlayers(player_cache));
end

--Cache player info that player are sending
local function OnClientCommand(module, command, player, args)
    if (module ~= "PlayersOnMap") or (command ~= "player") then return end
    args.time = os.time();
    player_cache[args.id] = args;
end

if (isServer()) then
    Events.OnClientCommand.Add(OnClientCommand);
    Events.OnTick.Add(OnTick);
end