local CurrentAction, CurrentActionMsg, CurrentActionData = nil, "", {}
local HasAlreadyEnteredMarker, LastHospital, LastPart, LastPartNum
local IsBusy = false
local spawnedVehicles, isInShopMenu = {}, false
function OpenAmbulanceActionsMenu()
    local elements = {
        {label = _U("cloakroom"), value = "cloakroom"}
    }
    if Config.EnablePlayerManagement and ASD.PlayerData.job.grade_name == "boss" then
        table.insert(elements, {label = _U("boss_actions"), value = "boss_actions"})
    end
    ASD.UI.Menu.CloseAll()
    ASD.UI.Menu.Open(
        "default",
        GetCurrentResourceName(),
        "ambulance_actions",
        {
            title = _U("ambulance"),
            align = "top-right",
            elements = elements
        },
        function(data, menu)
            if data.current.value == "cloakroom" then
                OpenCloakroomMenu()
            elseif data.current.value == "boss_actions" then
                TriggerEvent(
                    "society:openBossMenu",
                    "ambulance",
                    function(data, menu)
                        menu.close()
                    end,
                    {wash = false}
                )
            end
        end,
        function(data, menu)
            menu.close()
        end
    )
end
function OpenMobileAmbulanceActionsMenu()
    ASD.UI.Menu.CloseAll()
    ASD.UI.Menu.Open(
        "default",
        GetCurrentResourceName(),
        "mobile_ambulance_actions",
        {
            title = _U("ambulance"),
            align = "top-right",
            elements = {
                {label = _U("ems_menu"), value = "citizen_interaction"}
            }
        },
        function(data, menu)
            if data.current.value == "citizen_interaction" then
                ASD.UI.Menu.Open(
                    "default",
                    GetCurrentResourceName(),
                    "citizen_interaction",
                    {
                        title = _U("ems_menu_title"),
                        align = "top-right",
                        elements = {
                            {label = _U("id_card"), value = "identity_card"},
                            {label = _U("ems_menu_revive"), value = "revive"},
                            {label = "Hospital Menu", value = "sendto_hostiptal"},
                            {label = _U("ems_menu_small"), value = "small"},
                            {label = _U("ems_menu_big"), value = "big"},
                            {label = _U("ems_menu_putincar"), value = "put_in_vehicle"},
                            {label = _U("out_the_vehicle"), value = "out_the_vehicle"}
                        }
                    },
                    function(data, menu)
                        if IsBusy then
                            return
                        end
                        local closestPlayer, closestDistance = ASD.Game.GetClosestPlayer()
                        if closestPlayer == -1 or closestDistance > 1.0 then
                            ASD.ShowNotification(_U("no_players"))
                        else
                            if data.current.value == "revive" then
                                IsBusy = true
                                ASD.TriggerServerCallback(
                                    "asd_ambulancejob:getItemAmount",
                                    function(quantity)
                                        if quantity > 0 then
                                            local closestPlayerPed = GetPlayerPed(closestPlayer)
                                            if IsPedDeadOrDying(closestPlayerPed, 1) then
                                                local playerPed = PlayerPedId()
                                                ASD.ShowNotification(_U("revive_inprogress"))
                                                local lib, anim = "mini@cpr@char_a@cpr_str", "cpr_pumpchest"
                                                for i = 1, 15, 1 do
                                                    Citizen.Wait(900)

                                                    ASD.Streaming.RequestAnimDict(
                                                        lib,
                                                        function()
                                                            TaskPlayAnim(
                                                                PlayerPedId(),
                                                                lib,
                                                                anim,
                                                                8.0,
                                                                -8.0,
                                                                -1,
                                                                0,
                                                                0,
                                                                false,
                                                                false,
                                                                false
                                                            )
                                                        end
                                                    )
                                                end
                                                TriggerServerEvent("asd_ambulancejob:removeItem", "medkit")
                                                TriggerServerEvent(
                                                    "asd_ambulancejob:7774831",
                                                    GetPlayerServerId(closestPlayer)
                                                )
                                                ASD.ShowNotification(
                                                    _U("revive_complete", GetPlayerName(closestPlayer))
                                                )
                                            else
                                                ASD.ShowNotification(_U("player_not_unconscious"))
                                            end
                                        else
                                            ASD.ShowNotification(_U("not_enough_medkit"))
                                        end
                                        IsBusy = false
                                    end,
                                    "medkit"
                                )
                            elseif data.current.value == "bones" then
                                local playerPed = PlayerPedId()
                                TaskStartScenarioInPlace(playerPed, "CODE_HUMAN_MEDIC_TEND_TO_DEAD", 0, true)
                                exports["taskbar"]:taskBar(10000, "Helping Player")
                                --Citizen.Wait(10000)
                                ClearPedTasks(playerPed)
                                TriggerServerEvent("lolhealhaha", GetPlayerServerId(closestPlayer))
                                ASD.ShowNotification("You healed the players bones", GetPlayerName(closestPlayer))
                            elseif data.current.value == "small" then
                                ASD.TriggerServerCallback(
                                    "asd_ambulancejob:getItemAmount",
                                    function(quantity)
                                        if quantity > 0 then
                                            local closestPlayerPed = GetPlayerPed(closestPlayer)
                                            local health = GetEntityHealth(closestPlayerPed)
                                            if health > 0 then
                                                local playerPed = PlayerPedId()
                                                IsBusy = true
                                                ASD.ShowNotification(_U("heal_inprogress"))
                                                TaskStartScenarioInPlace(
                                                    playerPed,
                                                    "CODE_HUMAN_MEDIC_TEND_TO_DEAD",
                                                    0,
                                                    true
                                                )
                                                exports["taskbar"]:taskBar(10000, "Helping Player")
                                                --Citizen.Wait(10000)
                                                ClearPedTasks(playerPed)
                                                TriggerServerEvent("asd_ambulancejob:removeItem", "bandage")
                                                TriggerServerEvent(
                                                    "asd_ambulancejob:heal",
                                                    GetPlayerServerId(closestPlayer),
                                                    "small"
                                                )
                                                ASD.ShowNotification(_U("heal_complete", GetPlayerName(closestPlayer)))
                                                IsBusy = false
                                            else
                                                ASD.ShowNotification(_U("player_not_conscious"))
                                            end
                                        else
                                            ASD.ShowNotification(_U("not_enough_bandage"))
                                        end
                                    end,
                                    "bandage"
                                )
                            elseif data.current.value == "big" then
                                ASD.TriggerServerCallback(
                                    "asd_ambulancejob:getItemAmount",
                                    function(quantity)
                                        if quantity > 0 then
                                            local closestPlayerPed = GetPlayerPed(closestPlayer)
                                            local health = GetEntityHealth(closestPlayerPed)
                                            if health > 0 then
                                                local playerPed = PlayerPedId()
                                                IsBusy = true
                                                ASD.ShowNotification(_U("heal_inprogress"))
                                                TaskStartScenarioInPlace(
                                                    playerPed,
                                                    "CODE_HUMAN_MEDIC_TEND_TO_DEAD",
                                                    0,
                                                    true
                                                )
                                                exports["taskbar"]:taskBar(10000, "Helping Player")
                                                --Citizen.Wait(10000)
                                                ClearPedTasks(playerPed)
                                                TriggerServerEvent("asd_ambulancejob:removeItem", "medkit")
                                                TriggerServerEvent(
                                                    "asd_ambulancejob:heal",
                                                    GetPlayerServerId(closestPlayer),
                                                    "big"
                                                )
                                                ASD.ShowNotification(_U("heal_complete", GetPlayerName(closestPlayer)))
                                                IsBusy = false
                                            else
                                                ASD.ShowNotification(_U("player_not_conscious"))
                                            end
                                        else
                                            ASD.ShowNotification(_U("not_enough_medkit"))
                                        end
                                    end,
                                    "medkit"
                                )
                            elseif data.current.value == "sendto_hostiptal" then
                                menu.close()
                                OpenHospitalMenu()
                            elseif data.current.value == "put_in_vehicle" then
                                TriggerServerEvent("asd_ambulancejob:putInVehicle", GetPlayerServerId(closestPlayer))
                            elseif action == "out_the_vehicle" then
                                TriggerServerEvent("asd_policejob:OutVehicle", GetPlayerServerId(closestPlayer))
                            elseif action == "identity_card" then
                                OpenIdentityCardMenu(closestPlayer)
                            end
                        end
                    end,
                    function(data, menu)
                        menu.close()
                    end
                )
            end
        end,
        function(data, menu)
            menu.close()
        end
    )
end
function FastTravel(coords, heading)
    local playerPed = PlayerPedId()
    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do
        Citizen.Wait(500)
    end
    ASD.Game.Teleport(
        playerPed,
        coords,
        function()
            DoScreenFadeIn(800)
            if heading then
                SetEntityHeading(playerPed, heading)
            end
        end
    )
end
-- Draw markers & Marker logic
Citizen.CreateThread(
    function()
        while true do
            Citizen.Wait(0)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local letSleep, isInMarker, hasExited = true, false, false
            local currentHospital, currentPart, currentPartNum
            for hospitalNum, hospital in pairs(Config.Hospitals) do
                -- Ambulance Actions
                for k, v in ipairs(hospital.AmbulanceActions) do
                    local distance = GetDistanceBetweenCoords(playerCoords, v, true)
                    if distance < Config.DrawDistance then
                        DrawMarker(
                            Config.Marker.type,
                            v,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            Config.Marker.x,
                            Config.Marker.y,
                            Config.Marker.z,
                            Config.Marker.r,
                            Config.Marker.g,
                            Config.Marker.b,
                            Config.Marker.a,
                            false,
                            false,
                            2,
                            Config.Marker.rotate,
                            nil,
                            nil,
                            false
                        )
                        letSleep = false
                    end
                    if distance < Config.Marker.x then
                        isInMarker, currentHospital, currentPart, currentPartNum =
                            true,
                            hospitalNum,
                            "AmbulanceActions",
                            k
                    end
                end
                -- Pharmacies
                for k, v in ipairs(hospital.Pharmacies) do
                    local distance = GetDistanceBetweenCoords(playerCoords, v, true)
                    if distance < Config.DrawDistance then
                        DrawMarker(
                            Config.Marker.type,
                            v,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            Config.Marker.x,
                            Config.Marker.y,
                            Config.Marker.z,
                            Config.Marker.r,
                            Config.Marker.g,
                            Config.Marker.b,
                            Config.Marker.a,
                            false,
                            false,
                            2,
                            Config.Marker.rotate,
                            nil,
                            nil,
                            false
                        )
                        letSleep = false
                    end
                    if distance < Config.Marker.x then
                        isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, "Pharmacy", k
                    end
                end
                -- Vehicle Spawners
                for k, v in ipairs(hospital.Vehicles) do
                    local distance = GetDistanceBetweenCoords(playerCoords, v.Spawner, true)
                    if distance < Config.DrawDistance then
                        DrawMarker(
                            v.Marker.type,
                            v.Spawner,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            v.Marker.x,
                            v.Marker.y,
                            v.Marker.z,
                            v.Marker.r,
                            v.Marker.g,
                            v.Marker.b,
                            v.Marker.a,
                            false,
                            false,
                            2,
                            v.Marker.rotate,
                            nil,
                            nil,
                            false
                        )
                        letSleep = false
                    end
                    if distance < v.Marker.x then
                        isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, "Vehicles", k
                    end
                end
                -- Helicopter Spawners
                for k, v in ipairs(hospital.Helicopters) do
                    local distance = GetDistanceBetweenCoords(playerCoords, v.Spawner, true)
                    if distance < Config.DrawDistance then
                        DrawMarker(
                            v.Marker.type,
                            v.Spawner,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            v.Marker.x,
                            v.Marker.y,
                            v.Marker.z,
                            v.Marker.r,
                            v.Marker.g,
                            v.Marker.b,
                            v.Marker.a,
                            false,
                            false,
                            2,
                            v.Marker.rotate,
                            nil,
                            nil,
                            false
                        )
                        letSleep = false
                    end
                    if distance < v.Marker.x then
                        isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, "Helicopters", k
                    end
                end
                -- Fast Travels
                for k, v in ipairs(hospital.FastTravels) do
                    local distance = GetDistanceBetweenCoords(playerCoords, v.From, true)
                    if distance < Config.DrawDistance then
                        DrawMarker(
                            v.Marker.type,
                            v.From,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            v.Marker.x,
                            v.Marker.y,
                            v.Marker.z,
                            v.Marker.r,
                            v.Marker.g,
                            v.Marker.b,
                            v.Marker.a,
                            false,
                            false,
                            2,
                            v.Marker.rotate,
                            nil,
                            nil,
                            false
                        )
                        letSleep = false
                    end
                    if distance < v.Marker.x then
                        FastTravel(v.To.coords, v.To.heading)
                    end
                end
                -- Fast Travels (Prompt)
                for k, v in ipairs(hospital.FastTravelsPrompt) do
                    local distance = GetDistanceBetweenCoords(playerCoords, v.From, true)
                    if distance < Config.DrawDistance then
                        DrawMarker(
                            v.Marker.type,
                            v.From,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            0.0,
                            v.Marker.x,
                            v.Marker.y,
                            v.Marker.z,
                            v.Marker.r,
                            v.Marker.g,
                            v.Marker.b,
                            v.Marker.a,
                            false,
                            false,
                            2,
                            v.Marker.rotate,
                            nil,
                            nil,
                            false
                        )
                        letSleep = false
                    end
                    if distance < v.Marker.x then
                        isInMarker, currentHospital, currentPart, currentPartNum =
                            true,
                            hospitalNum,
                            "FastTravelsPrompt",
                            k
                    end
                end
            end
            -- Logic for exiting & entering markers
            if
                isInMarker and not HasAlreadyEnteredMarker or
                    (isInMarker and
                        (LastHospital ~= currentHospital or LastPart ~= currentPart or LastPartNum ~= currentPartNum))
             then
                if
                    (LastHospital ~= nil and LastPart ~= nil and LastPartNum ~= nil) and
                        (LastHospital ~= currentHospital or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
                 then
                    TriggerEvent("asd_ambulancejob:hasExitedMarker", LastHospital, LastPart, LastPartNum)
                    hasExited = true
                end
                HasAlreadyEnteredMarker, LastHospital, LastPart, LastPartNum =
                    true,
                    currentHospital,
                    currentPart,
                    currentPartNum
                TriggerEvent("asd_ambulancejob:hasEnteredMarker", currentHospital, currentPart, currentPartNum)
            end
            if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
                HasAlreadyEnteredMarker = false
                TriggerEvent("asd_ambulancejob:hasExitedMarker", LastHospital, LastPart, LastPartNum)
            end
            if letSleep then
                Citizen.Wait(500)
            end
        end
    end
)
AddEventHandler(
    "asd_ambulancejob:hasEnteredMarker",
    function(hospital, part, partNum)
        if ASD.PlayerData.job and ASD.PlayerData.job.name == "ambulance" then
            if part == "AmbulanceActions" then
                CurrentAction = part
                CurrentActionMsg = _U("actions_prompt")
                CurrentActionData = {}
            elseif part == "Pharmacy" then
                CurrentAction = part
                CurrentActionMsg = _U("open_pharmacy")
                CurrentActionData = {}
            elseif part == "Vehicles" then
                CurrentAction = part
                CurrentActionMsg = _U("garage_prompt")
                CurrentActionData = {hospital = hospital, partNum = partNum}
            elseif part == "Helicopters" then
                CurrentAction = part
                CurrentActionMsg = _U("helicopter_prompt")
                CurrentActionData = {hospital = hospital, partNum = partNum}
            elseif part == "FastTravelsPrompt" then
                local travelItem = Config.Hospitals[hospital][part][partNum]
                CurrentAction = part
                CurrentActionMsg = travelItem.Prompt
                CurrentActionData = {to = travelItem.To.coords, heading = travelItem.To.heading}
            end
        end
    end
)
AddEventHandler(
    "asd_ambulancejob:hasExitedMarker",
    function(hospital, part, partNum)
        if not isInShopMenu then
            ASD.UI.Menu.CloseAll()
        end
        CurrentAction = nil
    end
)
-- Key Controls
Citizen.CreateThread(
    function()
        while true do
            Citizen.Wait(0)
            if CurrentAction then
                ASD.ShowHelpNotification(CurrentActionMsg)
                if IsControlJustReleased(0, Keys["E"]) then
                    if CurrentAction == "AmbulanceActions" then
                        OpenAmbulanceActionsMenu()
                    elseif CurrentAction == "Pharmacy" then
                        OpenPharmacyMenu()
                    elseif CurrentAction == "Vehicles" then
                        OpenVehicleSpawnerMenu(CurrentActionData.hospital, CurrentActionData.partNum)
                    elseif CurrentAction == "Helicopters" then
                        OpenHelicopterSpawnerMenu(CurrentActionData.hospital, CurrentActionData.partNum)
                    elseif CurrentAction == "FastTravelsPrompt" then
                        FastTravel(CurrentActionData.to, CurrentActionData.heading)
                    end
                    CurrentAction = nil
                end
            elseif ASD.PlayerData.job ~= nil and ASD.PlayerData.job.name == "ambulance" and not IsDead then
                if IsControlJustReleased(0, Keys["F6"]) then
                    OpenMobileAmbulanceActionsMenu()
                end
            else
                Citizen.Wait(500)
            end
        end
    end
)
RegisterNetEvent("asd_ambulancejob:putInVehicle")
AddEventHandler(
    "asd_ambulancejob:putInVehicle",
    function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        if IsAnyVehicleNearPoint(coords, 5.0) then
            local vehicle = GetClosestVehicle(coords, 5.0, 0, 71)
            if DoesEntityExist(vehicle) then
                local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)
                for i = maxSeats - 1, 0, -1 do
                    if IsVehicleSeatFree(vehicle, i) then
                        freeSeat = i
                        break
                    end
                end
                if freeSeat then
                    TaskWarpPedIntoVehicle(playerPed, vehicle, freeSeat)
                end
            end
        end
    end
)
function OpenCloakroomMenu()
    ASD.UI.Menu.Open(
        "default",
        GetCurrentResourceName(),
        "cloakroom",
        {
            title = _U("cloakroom"),
            align = "top-right",
            elements = {
                {label = _U("ems_clothes_civil"), value = "citizen_wear"},
                {label = _U("ems_clothes_ems"), value = "ambulance_wear"}
            }
        },
        function(data, menu)
            if data.current.value == "citizen_wear" then
                ASD.TriggerServerCallback(
                    "asd_skin:getPlayerSkin",
                    function(skin, jobSkin)
                        TriggerEvent("skinchanger:loadSkin", skin)
                    end
                )
            elseif data.current.value == "ambulance_wear" then
                ASD.TriggerServerCallback(
                    "asd_skin:getPlayerSkin",
                    function(skin, jobSkin)
                        if skin.sex == 0 then
                            TriggerEvent("skinchanger:loadClothes", skin, jobSkin.skin_male)
                        else
                            TriggerEvent("skinchanger:loadClothes", skin, jobSkin.skin_female)
                        end
                    end
                )
            end
            menu.close()
        end,
        function(data, menu)
            menu.close()
        end
    )
end
function OpenVehicleSpawnerMenu(hospital, partNum)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local elements = {
        {label = _U("garage_storeditem"), action = "garage"},
        {label = _U("garage_storeitem"), action = "store_garage"},
        {label = _U("garage_buyitem"), action = "buy_vehicle"}
    }
    ASD.UI.Menu.Open(
        "default",
        GetCurrentResourceName(),
        "vehicle",
        {
            title = _U("garage_title"),
            align = "top-right",
            elements = elements
        },
        function(data, menu)
            if data.current.action == "buy_vehicle" then
                local shopCoords = Config.Hospitals[hospital].Vehicles[partNum].InsideShop
                local shopElements = {}
                local authorizedVehicles = Config.AuthorizedVehicles[ASD.PlayerData.job.grade_name]
                if #authorizedVehicles > 0 then
                    for k, vehicle in ipairs(authorizedVehicles) do
                        table.insert(
                            shopElements,
                            {
                                label = ('%s - <span style="color:green;">%s</span>'):format(
                                    vehicle.label,
                                    _U("shop_item", ASD.Math.GroupDigits(vehicle.price))
                                ),
                                name = vehicle.label,
                                model = vehicle.model,
                                price = vehicle.price,
                                type = "car"
                            }
                        )
                    end
                else
                    return
                end
                OpenShopMenu(shopElements, playerCoords, shopCoords)
            elseif data.current.action == "garage" then
                local garage = {}
                ASD.TriggerServerCallback(
                    "asd_vehicleshop:retrieveJobVehicles",
                    function(jobVehicles)
                        if #jobVehicles > 0 then
                            for k, v in ipairs(jobVehicles) do
                                local props = json.decode(v.vehicle)
                                local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(props.model))
                                local label =
                                    ('%s - <span style="color:darkgoldenrod;">%s</span>: '):format(
                                    vehicleName,
                                    props.plate
                                )
                                if v.stored then
                                    label =
                                        label .. ('<span style="color:green;">%s</span>'):format(_U("garage_stored"))
                                else
                                    label =
                                        label ..
                                        ('<span style="color:darkred;">%s</span>'):format(_U("garage_notstored"))
                                end
                                table.insert(
                                    garage,
                                    {
                                        label = label,
                                        stored = v.stored,
                                        model = props.model,
                                        vehicleProps = props
                                    }
                                )
                            end
                            ASD.UI.Menu.Open(
                                "default",
                                GetCurrentResourceName(),
                                "vehicle_garage",
                                {
                                    title = _U("garage_title"),
                                    align = "top-right",
                                    elements = garage
                                },
                                function(data2, menu2)
                                    if data2.current.stored then
                                        local foundSpawn, spawnPoint =
                                            GetAvailableVehicleSpawnPoint(hospital, "Vehicles", partNum)
                                        if foundSpawn then
                                            menu2.close()
                                            ASD.Game.SpawnVehicle(
                                                data2.current.model,
                                                spawnPoint.coords,
                                                spawnPoint.heading,
                                                function(vehicle)
                                                    ASD.Game.SetVehicleProperties(vehicle, data2.current.vehicleProps)
                                                    TriggerServerEvent(
                                                        "asd_vehicleshop:setJobVehicleState",
                                                        data2.current.vehicleProps.plate,
                                                        false
                                                    )
                                                    ASD.ShowNotification(_U("garage_released"))
                                                end
                                            )
                                        end
                                    else
                                        ASD.ShowNotification(_U("garage_notavailable"))
                                    end
                                end,
                                function(data2, menu2)
                                    menu2.close()
                                end
                            )
                        else
                            ASD.ShowNotification(_U("garage_empty"))
                        end
                    end,
                    "car"
                )
            elseif data.current.action == "store_garage" then
                StoreNearbyVehicle(playerCoords)
            end
        end,
        function(data, menu)
            menu.close()
        end
    )
end
function StoreNearbyVehicle(playerCoords)
    local vehicles, vehiclePlates = ASD.Game.GetVehiclesInArea(playerCoords, 30.0), {}
    if #vehicles > 0 then
        for k, v in ipairs(vehicles) do
            -- Make sure the vehicle we're saving is empty, or else it wont be deleted
            if GetVehicleNumberOfPassengers(v) == 0 and IsVehicleSeatFree(v, -1) then
                table.insert(
                    vehiclePlates,
                    {
                        vehicle = v,
                        plate = ASD.Math.Trim(GetVehicleNumberPlateText(v))
                    }
                )
            end
        end
    else
        ASD.ShowNotification(_U("garage_store_nearby"))
        return
    end
    ASD.TriggerServerCallback(
        "asd_ambulancejob:storeNearbyVehicle",
        function(storeSuccess, foundNum)
            if storeSuccess then
                local vehicleId = vehiclePlates[foundNum]
                local attempts = 0
                ASD.Game.DeleteVehicle(vehicleId.vehicle)
                IsBusy = true
                Citizen.CreateThread(
                    function()
                        while IsBusy do
                            Citizen.Wait(0)
                            drawLoadingText(_U("garage_storing"), 255, 255, 255, 255)
                        end
                    end
                )
                -- Workaround for vehicle not deleting when other players are near it.
                while DoesEntityExist(vehicleId.vehicle) do
                    Citizen.Wait(500)
                    attempts = attempts + 1
                    -- Give up
                    if attempts > 30 then
                        break
                    end
                    vehicles = ASD.Game.GetVehiclesInArea(playerCoords, 30.0)
                    if #vehicles > 0 then
                        for k, v in ipairs(vehicles) do
                            if ASD.Math.Trim(GetVehicleNumberPlateText(v)) == vehicleId.plate then
                                ASD.Game.DeleteVehicle(v)
                                break
                            end
                        end
                    end
                end
                IsBusy = false
                ASD.ShowNotification(_U("garage_has_stored"))
            else
                ASD.ShowNotification(_U("garage_has_notstored"))
            end
        end,
        vehiclePlates
    )
end
function GetAvailableVehicleSpawnPoint(hospital, part, partNum)
    local spawnPoints = Config.Hospitals[hospital][part][partNum].SpawnPoints
    local found, foundSpawnPoint = false, nil
    for i = 1, #spawnPoints, 1 do
        if ASD.Game.IsSpawnPointClear(spawnPoints[i].coords, spawnPoints[i].radius) then
            found, foundSpawnPoint = true, spawnPoints[i]
            break
        end
    end
    if found then
        return true, foundSpawnPoint
    else
        ASD.ShowNotification(_U("garage_blocked"))
        return false
    end
end
function OpenHelicopterSpawnerMenu(hospital, partNum)
    local playerCoords = GetEntityCoords(PlayerPedId())
    ASD.PlayerData = ASD.GetPlayerData()
    local elements = {
        {label = _U("helicopter_garage"), action = "garage"},
        {label = _U("helicopter_store"), action = "store_garage"},
        {label = _U("helicopter_buy"), action = "buy_helicopter"}
    }
    ASD.UI.Menu.Open(
        "default",
        GetCurrentResourceName(),
        "helicopter_spawner",
        {
            title = _U("helicopter_title"),
            align = "top-right",
            elements = elements
        },
        function(data, menu)
            if data.current.action == "buy_helicopter" then
                local shopCoords = Config.Hospitals[hospital].Helicopters[partNum].InsideShop
                local shopElements = {}
                local authorizedHelicopters = Config.AuthorizedHelicopters[ASD.PlayerData.job.grade_name]
                if #authorizedHelicopters > 0 then
                    for k, helicopter in ipairs(authorizedHelicopters) do
                        table.insert(
                            shopElements,
                            {
                                label = ('%s - <span style="color:green;">%s</span>'):format(
                                    helicopter.label,
                                    _U("shop_item", ASD.Math.GroupDigits(helicopter.price))
                                ),
                                name = helicopter.label,
                                model = helicopter.model,
                                price = helicopter.price,
                                type = "helicopter"
                            }
                        )
                    end
                else
                    ASD.ShowNotification(_U("helicopter_notauthorized"))
                    return
                end
                OpenShopMenu(shopElements, playerCoords, shopCoords)
            elseif data.current.action == "garage" then
                local garage = {}
                ASD.TriggerServerCallback(
                    "asd_vehicleshop:retrieveJobVehicles",
                    function(jobVehicles)
                        if #jobVehicles > 0 then
                            for k, v in ipairs(jobVehicles) do
                                local props = json.decode(v.vehicle)
                                local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(props.model))
                                local label =
                                    ('%s - <span style="color:darkgoldenrod;">%s</span>: '):format(
                                    vehicleName,
                                    props.plate
                                )
                                if v.stored then
                                    label =
                                        label .. ('<span style="color:green;">%s</span>'):format(_U("garage_stored"))
                                else
                                    label =
                                        label ..
                                        ('<span style="color:darkred;">%s</span>'):format(_U("garage_notstored"))
                                end
                                table.insert(
                                    garage,
                                    {
                                        label = label,
                                        stored = v.stored,
                                        model = props.model,
                                        vehicleProps = props
                                    }
                                )
                            end
                            ASD.UI.Menu.Open(
                                "default",
                                GetCurrentResourceName(),
                                "helicopter_garage",
                                {
                                    title = _U("helicopter_garage_title"),
                                    align = "top-right",
                                    elements = garage
                                },
                                function(data2, menu2)
                                    if data2.current.stored then
                                        local foundSpawn, spawnPoint =
                                            GetAvailableVehicleSpawnPoint(hospital, "Helicopters", partNum)
                                        if foundSpawn then
                                            menu2.close()
                                            ASD.Game.SpawnVehicle(
                                                data2.current.model,
                                                spawnPoint.coords,
                                                spawnPoint.heading,
                                                function(vehicle)
                                                    ASD.Game.SetVehicleProperties(vehicle, data2.current.vehicleProps)
                                                    TriggerServerEvent(
                                                        "asd_vehicleshop:setJobVehicleState",
                                                        data2.current.vehicleProps.plate,
                                                        false
                                                    )
                                                    ASD.ShowNotification(_U("garage_released"))
                                                end
                                            )
                                        end
                                    else
                                        ASD.ShowNotification(_U("garage_notavailable"))
                                    end
                                end,
                                function(data2, menu2)
                                    menu2.close()
                                end
                            )
                        else
                            ASD.ShowNotification(_U("garage_empty"))
                        end
                    end,
                    "helicopter"
                )
            elseif data.current.action == "store_garage" then
                StoreNearbyVehicle(playerCoords)
            end
        end,
        function(data, menu)
            menu.close()
        end
    )
end
function OpenShopMenu(elements, restoreCoords, shopCoords)
    local playerPed = PlayerPedId()
    isInShopMenu = true
    ASD.UI.Menu.Open(
        "default",
        GetCurrentResourceName(),
        "vehicle_shop",
        {
            title = _U("vehicleshop_title"),
            align = "top-right",
            elements = elements
        },
        function(data, menu)
            ASD.UI.Menu.Open(
                "default",
                GetCurrentResourceName(),
                "vehicle_shop_confirm",
                {
                    title = _U("vehicleshop_confirm", data.current.name, data.current.price),
                    align = "top-right",
                    elements = {
                        {label = _U("confirm_no"), value = "no"},
                        {label = _U("confirm_yes"), value = "yes"}
                    }
                },
                function(data2, menu2)
                    if data2.current.value == "yes" then
                        local newPlate = exports["mrp-vehicleshop"]:GeneratePlate()
                        local vehicle = GetVehiclePedIsIn(playerPed, false)
                        local props = ASD.Game.GetVehicleProperties(vehicle)
                        props.plate = newPlate
                        ASD.TriggerServerCallback(
                            "asd_ambulancejob:buyJobVehicle",
                            function(bought)
                                if bought then
                                    ASD.ShowNotification(
                                        _U(
                                            "vehicleshop_bought",
                                            data.current.name,
                                            ASD.Math.GroupDigits(data.current.price)
                                        )
                                    )
                                    isInShopMenu = false
                                    ASD.UI.Menu.CloseAll()

                                    DeleteSpawnedVehicles()
                                    FreezeEntityPosition(playerPed, false)
                                    SetEntityVisible(playerPed, true)

                                    ASD.Game.Teleport(playerPed, restoreCoords)
                                else
                                    ASD.ShowNotification(_U("vehicleshop_money"))
                                    menu2.close()
                                end
                            end,
                            props,
                            data.current.type
                        )
                    else
                        menu2.close()
                    end
                end,
                function(data2, menu2)
                    menu2.close()
                end
            )
        end,
        function(data, menu)
            isInShopMenu = false
            ASD.UI.Menu.CloseAll()
            DeleteSpawnedVehicles()
            FreezeEntityPosition(playerPed, false)
            SetEntityVisible(playerPed, true)
            ASD.Game.Teleport(playerPed, restoreCoords)
        end,
        function(data, menu)
            DeleteSpawnedVehicles()
            WaitForVehicleToLoad(data.current.model)
            ASD.Game.SpawnLocalVehicle(
                data.current.model,
                shopCoords,
                0.0,
                function(vehicle)
                    table.insert(spawnedVehicles, vehicle)
                    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                    FreezeEntityPosition(vehicle, true)
                end
            )
        end
    )
    WaitForVehicleToLoad(elements[1].model)
    ASD.Game.SpawnLocalVehicle(
        elements[1].model,
        shopCoords,
        0.0,
        function(vehicle)
            table.insert(spawnedVehicles, vehicle)
            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
            FreezeEntityPosition(vehicle, true)
        end
    )
end
Citizen.CreateThread(
    function()
        while true do
            Citizen.Wait(0)
            if isInShopMenu then
                DisableControlAction(0, 75, true) -- Disable exit vehicle
                DisableControlAction(27, 75, true) -- Disable exit vehicle
            else
                Citizen.Wait(500)
            end
        end
    end
)
function DeleteSpawnedVehicles()
    while #spawnedVehicles > 0 do
        local vehicle = spawnedVehicles[1]
        ASD.Game.DeleteVehicle(vehicle)
        table.remove(spawnedVehicles, 1)
    end
end
function WaitForVehicleToLoad(modelHash)
    modelHash = (type(modelHash) == "number" and modelHash or GetHashKey(modelHash))
    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Citizen.Wait(0)
            DisableControlAction(0, Keys["TOP"], true)
            DisableControlAction(0, Keys["DOWN"], true)
            DisableControlAction(0, Keys["LEFT"], true)
            DisableControlAction(0, Keys["RIGHT"], true)
            DisableControlAction(0, 176, true) -- ENTER key
            DisableControlAction(0, Keys["BACKSPACE"], true)
            drawLoadingText(_U("vehicleshop_awaiting_model"), 255, 255, 255, 255)
        end
    end
end
function drawLoadingText(text, red, green, blue, alpha)
    SetTextFont(4)
    SetTextScale(0.0, 0.5)
    SetTextColour(red, green, blue, alpha)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.5, 0.5)
end
function OpenPharmacyMenu()
    ASD.UI.Menu.CloseAll()
    ASD.UI.Menu.Open(
        "default",
        GetCurrentResourceName(),
        "pharmacy",
        {
            title = _U("pharmacy_menu_title"),
            align = "top-right",
            elements = {
                {label = _U("pharmacy_take", _U("medkit")), value = "medkit"},
                {label = _U("pharmacy_take", _U("bandage")), value = "bandage"},
                {label = _U("pharmacy_take", _U("bodybandage")), value = "bodybandage"},
                {label = _U("pharmacy_take", _U("neckbrace")), value = "neckbrace"},
                {label = _U("pharmacy_take", _U("armbrace")), value = "armbrace"},
                {label = _U("pharmacy_take", _U("legbrace")), value = "legbrace"}
            }
        },
        function(data, menu)
            TriggerServerEvent("asd_ambulancejob:giveItem", data.current.value)
        end,
        function(data, menu)
            menu.close()
        end
    )
end
function WarpPedInClosestVehicle(ped)
    local coords = GetEntityCoords(ped)
    local vehicle, distance = ASD.Game.GetClosestVehicle(coords)
    if distance ~= -1 and distance <= 5.0 then
        local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)
        for i = maxSeats - 1, 0, -1 do
            if IsVehicleSeatFree(vehicle, i) then
                freeSeat = i
                break
            end
        end
        if freeSeat then
            TaskWarpPedIntoVehicle(ped, vehicle, freeSeat)
        end
    else
        ASD.ShowNotification(_U("no_vehicles"))
    end
end
function OpenHospitalMenu()
    ASD.UI.Menu.Open(
        "default",
        GetCurrentResourceName(),
        "hospital",
        {
            title = "Hospital Menu",
            align = "top-right",
            elements = {
                {label = "Minor Injuries", value = "brokenarm"},
                {label = "Major Injuries", value = "headinjury"},
                {label = "Deceased", value = "dead"}
            }
        },
        function(data, menu)
            menu.close()
            local closestPlayer, closestDistance = ASD.Game.GetClosestPlayer()
            if closestPlayer == -1 or closestDistance > 3.0 then
                ASD.ShowNotification(_U("no_players"))
            else
                if data.current.value == "brokenarm" then
                    --TriggerServerEvent('asd_ambulancejob:7774831', GetPlayerServerId(closestPlayer))
                    TriggerServerEvent(
                        "HOSPITAL:hospitalize",
                        GetPlayerServerId(closestPlayer),
                        "60",
                        "Minor Injuries",
                        0
                    )
                end
                if data.current.value == "headinjury" then
                    --TriggerServerEvent('asd_ambulancejob:7774831', GetPlayerServerId(closestPlayer))
                    TriggerServerEvent(
                        "HOSPITAL:hospitalize",
                        GetPlayerServerId(closestPlayer),
                        "300",
                        "Major Injuries",
                        0
                    )
                end
                if data.current.value == "dead" then
                    --TriggerServerEvent('asd_ambulancejob:7774831', GetPlayerServerId(closestPlayer))
                    TriggerServerEvent("HOSPITAL:hospitalize", GetPlayerServerId(closestPlayer), "600", "Deceased", 0)
                end
            end
        end,
        function(data, menu)
            menu.close()
        end
    )
end
RegisterNetEvent("asd_ambulancejob:heal")
AddEventHandler(
    "asd_ambulancejob:heal",
    function(healType, quiet)
        local playerPed = PlayerPedId()
        local maxHealth = GetEntityMaxHealth(playerPed)
        if healType == "small" then
            local health = GetEntityHealth(playerPed)
            local newHealth = math.min(maxHealth, math.floor(health + maxHealth / 8))
            SetEntityHealth(playerPed, newHealth)
        elseif healType == "big" then
            SetEntityHealth(playerPed, maxHealth)
        end
        if not quiet then
            ASD.ShowNotification(_U("healed"))
        end
    end
)
