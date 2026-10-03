local wallActive = false
local wallPlayers = {}
local wallPlayersByServerId = {}
local currentCoords = vector3(0.0, 0.0, 0.0)

local function debugPrint(message)
    if Config.Debug then
        print(('[Fox_Wall] %s'):format(message))
    end
end

local function notify(message)
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 255},
        multiline = true,
        args = {'WALL', tostring(message or '')}
    })
end

local function requestPlayers()
    if wallActive then
        TriggerServerEvent('Fox_Wall:server:requestPlayers')
    end
end

local function drawText3D(x, y, z, text)
    local visible, screenX, screenY = GetScreenCoordFromWorldCoord(x, y, z)
    if not visible then return end

    SetTextScale(0.35, 0.35)
    SetTextFontForCurrentCommand(1)
    SetTextColor(255, 255, 255, 223)
    SetTextCentre(true)
    DisplayText(CreateVarString(10, 'LITERAL_STRING', text), screenX, screenY)
end

local function isCrouched(ped)
    return Citizen.InvokeNative(0xD5FE956C70FF370B, ped)
end

local function isSpeaking(player)
    return Citizen.InvokeNative(0xEF6F2A35FAAF2ED7, player)
end

local function getPlayerName(playerData)
    local firstName = tostring(playerData.firstname or playerData.firstName or '')
    local lastName = tostring(playerData.lastname or playerData.lastName or '')
    local fullName = firstName

    if lastName ~= '' then
        fullName = fullName ~= '' and (fullName .. ' ' .. lastName) or lastName
    end

    if fullName == '' then
        fullName = tostring(playerData.name or 'Desconhecido')
    end

    return fullName
end

local function buildPlayerText(serverId, playerData, player)
    local text = ('ID: %d / Nome: %s\nJob: %s'):format(
        serverId,
        getPlayerName(playerData),
        tostring(playerData.job or 'Sem emprego')
    )

    if Config.ShowTalkingStatus and isSpeaking(player) then
        text = '~d~Falando: ~s~' .. text
    end

    return text
end

local function canDraw(player, ped)
    if not DoesEntityExist(ped) then return false end
    if not Config.ShowLocalPlayer and player == PlayerId() then return false end
    if Config.HideCrouchedPlayers and isCrouched(ped) then return false end
    return true
end

RegisterNetEvent('Fox_Wall:client:setActive', function(active)
    wallActive = type(active) == 'boolean' and active or not wallActive

    if wallActive then
        requestPlayers()
    else
        wallPlayers = {}
        wallPlayersByServerId = {}
    end
end)

RegisterNetEvent('Fox_Wall:client:updatePlayers', function(players)
    wallPlayers = type(players) == 'table' and players or {}
    wallPlayersByServerId = {}

    for _, playerData in ipairs(wallPlayers) do
        local serverId = tonumber(playerData.source or playerData.id)
        if serverId then
            wallPlayersByServerId[serverId] = playerData
        end
    end
end)

RegisterNetEvent('Fox_Wall:client:notify', notify)

CreateThread(function()
    while true do
        if wallActive then
            local localPed = PlayerPedId()
            currentCoords = GetEntityCoords(localPed)

            for _, player in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(player)
                if canDraw(player, ped) then
                    local serverId = GetPlayerServerId(player)
                    local playerData = wallPlayersByServerId[serverId]

                    if playerData then
                        local coords = GetEntityCoords(ped)
                        local distance = #(currentCoords - coords)
                        if distance <= Config.DrawDistance then
                            drawText3D(coords.x, coords.y, coords.z + 1.0, buildPlayerText(serverId, playerData, player))
                        end
                    end
                end
            end

            Wait(Config.RenderInterval)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        if wallActive then
            requestPlayers()
            Wait(Config.RefreshInterval)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'Mostrar/ocultar informações dos jogadores')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    wallActive = false
    wallPlayers = {}
    wallPlayersByServerId = {}
end)
