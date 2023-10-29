function pom_getDistancePlayer(player1, player2)
	local pom_player1 = pom_getPlayer(player1);
	local pom_player2 = pom_getPlayer(player2);
    return pom_getDistance2D(pom_player1.x, pom_player1.y, pom_player2.x, pom_player2.y);
end

function pom_getDistance2D(_x1, _y1, _x2, _y2)
	local absX = math.abs(_x2 - _x1);
	local absY = math.abs(_y2 - _y1);
	return math.sqrt(absX^2 + absY^2);
end

function pom_absolute(num)
    return ((num < 0) and num*-1 or num);
end

function pom_getPlayer(player)
    local vehicle = player:getVehicle();
    local faction = Faction.getPlayerFaction(player);

    local pom_player = {};
    pom_player.id = player:getOnlineID();
    pom_player.num = player:getPlayerNum();
    pom_player.username = player:getUsername();
    pom_player.invisible = player:isInvisible();
    pom_player.alive = player:isAlive();
    pom_player.x = (vehicle and vehicle:getX() or player:getX());
    pom_player.y = (vehicle and vehicle:getY() or player:getY());
    pom_player.z = (vehicle and vehicle:getZ() or player:getZ());
    pom_player.faction_name = (faction and faction:getName() or nil);

    return pom_player;
end

function pom_getLocalPlayers()
    local pom_players = { count = getNumActivePlayers(), players = {} };

    for i = 0, getNumActivePlayers()-1 do
        pom_players.players[i] = pom_getPlayer(getSpecificPlayer(i));
    end

    return pom_players;
end

function pom_getPlayers(cache)
    if ((not isClient()) and (not isServer())) then
        return pom_getLocalPlayers();
    end

    local players = getOnlinePlayers();
    local pom_players = { count = players:size(), players = {} };

    for i = 0, players:size()-1 do
        local player_id = players:get(i):getOnlineID();
        local b0 = (cache and cache[player_id]); --Check if player info is cached
        local b1 = (b0 and (pom_absolute((os.time() - cache[player_id].time)*1000) < 500)); --Check if info is not outdated

        if (b1) then pom_players.players[i] = cache[player_id]; end --Use cache info if it is fresh
        if (not b1) then pom_players.players[i] = pom_getPlayer(players:get(i)); end --Otherwise update it
    end

    return pom_players;
end