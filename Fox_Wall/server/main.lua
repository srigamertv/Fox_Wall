local activePlayers = {}
local requestTimers = {}
local VorpCore = nil
local RSGCore = nil

local function debugPrint(message)
    if Config.Debug then
        print(('[Fox_Wall] %s'):format(message))
    end
end

local function detectFramework()
    local configured = string.lower(Config.Framework or 'auto')
    if configured ~= 'auto' then return configured end
    if GetResourceState('rsg-core') == 'started' then return 'rsg' end
    if GetResourceState('vorp_core') == 'started' then return 'vorp' end
    return 'standalone'
end

local function getVorpCore()
    if VorpCore then return VorpCore end
    if GetResourceState('vorp_core') ~= 'started' then return nil end
    local ok, core = pcall(function() return exports.vorp_core:GetCore() end)
    if ok then VorpCore = core end
    return VorpCore
end

local function getRsgCore()
    if RSGCore then return RSGCore end
    if GetResourceState('rsg-core') ~= 'started' then return nil end
    local ok, core = pcall(function() return exports['rsg-core']:GetCoreObject() end)
    if ok then RSGCore = core end
    return RSGCore
end

local function readValue(container, key)
    if not container then return nil end
    local value = container[key]
    if type(value) ~= 'function' then return value end
    local ok, result = pcall(value)
    if ok and result ~= nil then return result end
    ok, result = pcall(value, container)
    if ok then return result end
    return nil
end

local function getVorpUser(src)
    local core = getVorpCore()
    if not core or type(core.getUser) ~= 'function' then return nil end
    local ok, user = pcall(core.getUser, src)
    if ok and user then return user end
    ok, user = pcall(core.getUser, core, src)
    return ok and user or nil
end

local function getVorpCharacter(user)
    if not user then return nil end
    local character = user.getUsedCharacter
    if type(character) ~= 'function' then return character end
    local ok, result = pcall(character)
    if ok and result then return result end
    ok, result = pcall(character, user)
    return ok and result or nil
end

local function isAllowedPermission(value, allowed)
    if value == nil then return false end
    local key = tostring(value):lower()
    return allowed and allowed[key] == true
end

local function hasVorpPermission(src)
    local settings = Config.Permission.VORP or {}
    local user = getVorpUser(src)
    if not user then return false end

    if settings.CheckUserGroup ~= false then
        local userGroup = readValue(user, 'getGroup') or readValue(user, 'group')
        if isAllowedPermission(userGroup, settings.Groups) then
            return true
        end
    end

    if settings.CheckCharacterGroup ~= false then
        local character = getVorpCharacter(user)
        local characterGroup = readValue(character, 'group')
        if isAllowedPermission(characterGroup, settings.Groups) then
            return true
        end
    end

    return false
end

local function getRsgDatabaseRole(src)
    local settings = Config.Permission.RSG or {}
    if settings.CheckAdminRolesTable ~= true then return nil end
    if GetResourceState('oxmysql') ~= 'started' then return nil end

    local core = getRsgCore()
    local player = core and core.Functions and core.Functions.GetPlayer(src) or nil
    local citizenId = player and player.PlayerData and player.PlayerData.citizenid or nil
    if not citizenId then return nil end

    local tableName = tostring(settings.AdminRolesTable or 'admin_roles')
    if not tableName:match('^[%w_]+$') then
        debugPrint('Nome inválido em Config.Permission.RSG.AdminRolesTable.')
        return nil
    end

    local ok, role = pcall(function()
        return exports.oxmysql:scalar_async(
            ('SELECT `role` FROM `%s` WHERE `citizenid` = ? LIMIT 1'):format(tableName),
            { citizenId }
        )
    end)

    if not ok then
        debugPrint('Não foi possível consultar a tabela de cargos administrativos do RSG.')
        return nil
    end

    return role
end

local function hasRsgPermission(src)
    local settings = Config.Permission.RSG or {}
    local core = getRsgCore()
    if not core then return false end

    if settings.CheckCorePermission ~= false and core.Functions and core.Functions.HasPermission then
        for permission, enabled in pairs(settings.Permissions or {}) do
            if enabled and core.Functions.HasPermission(src, permission) then
                return true
            end
        end
    end

    local databaseRole = getRsgDatabaseRole(src)
    if isAllowedPermission(databaseRole, settings.Roles) then
        return true
    end

    return false
end

local function hasPermission(src)
    if src == 0 then return true end
    if not Config.Permission.Enabled then return true end

    if Config.Permission.Ace and Config.Permission.Ace ~= '' and IsPlayerAceAllowed(src, Config.Permission.Ace) then
        return true
    end

    local framework = detectFramework()

    if framework == 'vorp' then
        return hasVorpPermission(src)
    end

    if framework == 'rsg' then
        return hasRsgPermission(src)
    end

    return false
end

local function getPlayerData(src)
    local fallbackName = GetPlayerName(src) or 'Desconhecido'
    local framework = detectFramework()

    if framework == 'rsg' then
        local core = getRsgCore()
        local player = core and core.Functions.GetPlayer(src)
        local data = player and player.PlayerData or nil
        local charinfo = data and data.charinfo or {}
        local job = data and data.job or {}
        return {
            source = src,
            firstname = tostring(charinfo.firstname or fallbackName),
            lastname = tostring(charinfo.lastname or ''),
            job = tostring(job.label or job.name or 'Sem emprego'),
            name = fallbackName
        }
    end

    if framework == 'vorp' then
        local character = getVorpCharacter(getVorpUser(src))
        local firstName = readValue(character, 'firstname') or readValue(character, 'firstName') or fallbackName
        local lastName = readValue(character, 'lastname') or readValue(character, 'lastName') or ''
        local job = readValue(character, 'jobLabel') or readValue(character, 'job') or 'Sem emprego'
        return {
            source = src,
            firstname = tostring(firstName),
            lastname = tostring(lastName),
            job = tostring(job),
            name = fallbackName
        }
    end

    return { source = src, firstname = fallbackName, lastname = '', job = 'Sem emprego', name = fallbackName }
end

local function isWithinRange(requester, target)
    if not Config.ServerDistanceFilter or requester == target then return true end
    local p1, p2 = GetPlayerPed(requester), GetPlayerPed(target)
    if p1 == 0 or p2 == 0 then return true end
    local c1, c2 = GetEntityCoords(p1), GetEntityCoords(p2)
    local dx, dy, dz = c1.x-c2.x, c1.y-c2.y, c1.z-c2.z
    return math.sqrt(dx*dx + dy*dy + dz*dz) <= (Config.DrawDistance + Config.ServerDistanceBuffer)
end

local function buildPlayers(requester)
    local players = {}
    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        if src and isWithinRange(requester, src) then
            players[#players+1] = getPlayerData(src)
        end
    end
    table.sort(players, function(a,b) return a.source < b.source end)
    return players
end

local function canRequest(src)
    local now = GetGameTimer()
    local last = requestTimers[src]
    if last and now-last < Config.MinimumRequestInterval then return false end
    requestTimers[src] = now
    return true
end

local function sendPlayers(src)
    if not activePlayers[src] then return end
    if not hasPermission(src) then
        activePlayers[src] = nil
        TriggerClientEvent('Fox_Wall:client:setActive', src, false)
        return
    end
    if not canRequest(src) then return end
    TriggerClientEvent('Fox_Wall:client:updatePlayers', src, buildPlayers(src))
end

RegisterCommand(Config.Command, function(src)
    if src == 0 then
        print(('[Fox_Wall] /%s só pode ser usado dentro do jogo.'):format(Config.Command))
        return
    end

    if not hasPermission(src) then
        TriggerClientEvent('Fox_Wall:client:notify', src, Config.Messages.NoPermission)
        return
    end

    activePlayers[src] = not activePlayers[src]
    requestTimers[src] = nil
    TriggerClientEvent('Fox_Wall:client:setActive', src, activePlayers[src])
    TriggerClientEvent('Fox_Wall:client:notify', src, activePlayers[src] and Config.Messages.Enabled or Config.Messages.Disabled)
    if activePlayers[src] then sendPlayers(src) end
end, false)

RegisterNetEvent('Fox_Wall:server:requestPlayers', function()
    sendPlayers(source)
end)

AddEventHandler('playerDropped', function()
    activePlayers[source] = nil
    requestTimers[source] = nil
end)

CreateThread(function()
    Wait(1000)
    debugPrint('Framework detectado: ' .. detectFramework())
end)
