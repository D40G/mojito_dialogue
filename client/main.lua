local prefix <const> = '__mojito_dialogue__'
local Peds = {}
local inside = false
local interactingWith = nil
local currentCam = nil


---Creates a new NPC interaction
---@param ped {number}: Hash of the ped model
---@param coords {vec3}: Coordinates to spawn the ped
---@param radius {number}: Radius at which the ped will be created
---@param options {table}: Options for the NPC dialogue
---@param callback {function}: Callback function will be triggered when an option is complete with p0 being the selection
---@return void
local function NewDialogue(ped, coords, radius, options, callback)
    local index = #Peds + 1
    local zone = CircleZone:Create(coords, radius, {
        name = prefix .. index,
        debugPoly = true
    })
    Peds[index] = {
        zone = zone,
        model = ped,
        coords = coords,
        entity = nil,
        cb = callback,
        options = options
    }

    AddEventHandler(prefix .. index .. 'ped_event', HandleTalk)
end

exports('NewDialogue', NewDialogue)

CreateThread(function()
    while true do
        Wait(500)
        local ply = PlayerPedId()
        local coords = GetEntityCoords(ply)

        for i = 1, #Peds do
            local Ped = Peds[i]
            if Ped.zone:isPointInside(coords) then
                inside = true
                interactingWith = i

                if not DoesEntityExist(Ped.entity) then
                    if not IsModelInCdimage(Ped.model) then 
                        print(("^1[ERROR]^0: Invalid model %s used, please contact the server owner."):format(Ped.model))
                        return
                    end
                    
                    RequestModel(Ped.model)
                    while not HasModelLoaded(Ped.model) do
                       Wait(10) 
                    end

                    local PedCoords = Ped.coords
                    Ped.entity = CreatePed(1, Ped.model, PedCoords.x, PedCoords.y, PedCoords.z, 0.0, false, true)
                    SetBlockingOfNonTemporaryEvents(Ped.entity, true)
                    SetPedDiesWhenInjured(Ped.entity, false)
                    SetEntityInvincible(Ped.entity, true)

                    exports['qb-target']:AddEntityZone(prefix .. i,  Ped.entity, {
                        name = prefix .. i
                    }, {
                        distance = 2.0,
                        options = {
                            {
                                event = prefix .. i .. 'ped_event',
                                icon = 'fas fa-comments',
                                label = 'Talk to NPC',
                            }
                        }
                    })
                end

                while inside == true do
                    if not Ped.zone:isPointInside(GetEntityCoords(ply)) then
                        inside = false
                        interactingWith = nil

                        exports['qb-target']:RemoveTargetEntity(Ped.entity)
                        if DoesEntityExist(Ped.entity) then
                            DeletePed(Ped.entity)
                        end
                    end

                    Wait(5)
                end
            end
        end
    end
end)

function HandleTalk()
    local Ped = Peds[interactingWith]
    local ply = PlayerPedId()
    
    TaskTurnPedToFaceEntity(Ped.entity, ply, 0.0)
    TaskTurnPedToFaceEntity(ply, Ped.entity, 0.0)

    Wait(1000)
    FreezeEntityPosition(ply, true)
    FreezeEntityPosition(Ped.entity, true)

    local offsetCoords = GetOffsetFromEntityInWorldCoords(ply, 1.0, 0.0, 0.6) -- Put camera over the player's shoulder
    local currentRot = GetGameplayCamRot()
    currentCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", offsetCoords.x, offsetCoords.y, offsetCoords.z, currentRot.x, currentRot.y, currentRot.z, 60.00, false, 0)
    SetCamCoord(offsetCoords.x, offsetCoords.y, offsetCoords.z)
    SetCamActive(currentCam, true)
    RenderScriptCams(1, true, 500, true, true)
    PointCamAtEntity(currentCam, Ped.entity, 1.0, 0.0, 0.6, true) -- Angle the camera at the target entity

    SendNUIMessage({
        type = "newDialogue",
        title = Ped.options.title,
        items = Ped.options.items
    })
    SetNuiFocus(true, true)
end

local function ExitDialogue()
    local Ped = Peds[interactingWith]
    local ply = PlayerPedId()
    if DoesEntityExist(Ped.entity) then
        FreezeEntityPosition(Ped.entity, false)
        ClearPedTasks(Ped.entity)
    end

    FreezeEntityPosition(ply, false)
    ClearPedTasks(ply)

    SetCamActive(currentCam, false)
    RenderScriptCams(0, true, 500, true, true)
    DestroyCam(currentCam)
    currentCam = nil

    SetNuiFocus(false, false)
end

RegisterCommand("exitdialogue", ExitDialogue)
RegisterKeyMapping("exitdialogue", "Exit current dialogue interaction", "keyboard", "BACK") -- Default key to exit as backspace

RegisterNUICallback('select', function(data, cb)
    local selection = data.option
    Peds[interactingWith].cb(selection)

    ExitDialogue()
    cb({})
end)