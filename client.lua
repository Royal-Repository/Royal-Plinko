local QBCore = exports['qb-core']:GetCoreObject()
local isUiOpen = false

-- 1. Spawn the Casino Dealer Ped
-- 1. Spawn the Plinko Machine Prop
CreateThread(function()
    local model = Config.SlotMachine.model
    local coords = Config.SlotMachine.coords
    
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(1) end

    -- Create Object
    local slotObject = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(slotObject, coords.w)
    FreezeEntityPosition(slotObject, true)
    
    -- 2. Add Target Interaction (ox_target)
    exports.ox_target:addLocalEntity(slotObject, {
        {
            name = 'play_plinko',
            icon = Config.SlotMachine.icon,
            label = Config.SlotMachine.label,
            onSelect = function()
                OpenPlinko()
            end,
            distance = 2.5
        }
    })

    -- 3. Marker Logic (Sky Blue Modern Visual)
    CreateThread(function()
        -- Marker floats slightly above the machine
        local markerCoords = vec3(coords.x, coords.y, coords.z + 2.3) 
        
        while true do
            local sleep = 1500
            local plyPed = PlayerPedId()
            local dist = #(GetEntityCoords(plyPed) - markerCoords)

            if dist < 30.0 then
                sleep = 0
                -- Draw Sky Blue Marker (Down Arrow or Chevron)
                -- Type 2 = Chevron Down? No, Type 1 = Cylinder, Type 29 = Dollar?
                -- Let's use Type 0 (Upside Down Cone) or Type 20 (Chevron Uo).
                -- Type 2 (Chevron Down) is good for "Here".
                -- Color: SkyBlue (0, 204, 255)
                DrawMarker(20, markerCoords.x, markerCoords.y, markerCoords.z, 
                    0.0, 0.0, 0.0, 
                    180.0, 0.0, 0.0, -- Rotate to point down if needed, usually 20 is up/down? 
                    0.5, 0.5, 0.5,   -- Scale
                    0, 204, 255, 200, -- Sky Blue
                    true, true, 2, 
                    true, nil, nil, false
                )
            end
            Wait(sleep)
        end
    end)
end)

-- 3. Function to Open UI
function OpenPlinko()
    if isUiOpen then return end
    isUiOpen = true
    SetNuiFocus(true, true)
    
    -- Send Open Signal + Current Cash to HTML
    SendNUIMessage({
        action = 'open',
        balance = QBCore.Functions.GetPlayerData().money.cash
    })
end

-- 4. NUI Callbacks

-- Close Button
RegisterNUICallback('close', function(data, cb)
    isUiOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Play Button (Starts Game Logic)
RegisterNUICallback('play', function(data, cb)
    -- Asks server to validate bet and calculate results
    QBCore.Functions.TriggerCallback('plinko:server:play', function(result)
        cb(result)
    end, data)
end)

-- Game Over (Called by JS when animation finishes)
-- This is the "Bridge" that tells the server: "Visuals are done, give the item/money now."
RegisterNUICallback('gameover', function(data, cb)
    TriggerServerEvent('plinko:server:payout')
    cb('ok')
end)