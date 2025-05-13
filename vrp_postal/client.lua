Tunnel = module("vrp","lib/Tunnel")
Proxy = module("vrp","lib/Proxy")

local cvRP = module("vrp", "client/vRP")
vRP = cvRP() 

local vrp_postal = class("vrp_postal", vRP.Extension)
local Offices = {
	{coords=vector3(-422.09115600586,6135.763671875,31.877313613892),heading=163.98,garage={-432.11645507812,6134.484375,31.377746582031,224.65},van="boxville4",pmodel="s_m_m_ups_02",stock=vector3(-437.85546875,6147.8676757812,31.478212356567)},
	{coords=vector3(78.497062683105,111.82454681396,81.168190002441),heading=251.33,garage={73.214248657227,123.23969268799,79.099815368652,338.89},van="boxville2",pmodel="s_m_m_postal_02",stock=vector3(113.33866882324,103.77201843262,81.169395446777)}
} 
local onDuty = false
local workVan = nil
local isWorking = false
local currentOffice = nil
local blip = nil
local lastDeliveryID = nil
local officeBlip = nil
local peds = {}

local northMission = {
	{coords=vector3(21.498975753784,6567.361328125,31.35368347168),parkingSpot=vector3(28.026630401611,6571.40234375,31.217586517334),type="letter",pay=14},
	{coords=vector3(-36.889472961426,6632.8994140625,30.281930923462),parkingSpot=vector3(-47.752220153809,6616.171875,29.805145263672),type="package",pay=11},
	{coords=vector3(1507.2479248047,6327.7724609375,24.016279220581),parkingSpot=vector3(1500.8770751953,6331.0830078125,23.910417556763),type="package",pay=30},
	{coords=vector3(1827.2171630859,3891.9638671875,33.554592132568),parkingSpot=vector3(1836.5699462891,3891.0732421875,33.390758514404),type="letter",pay=30},
	{coords=vector3(1639.9468994141,3731.7170410156,35.067142486572),parkingSpot=vector3(1646.3070068359,3734.3068847656,34.272079467773),type="package",pay=34},
	{coords=vector3(1446.3842773438,3649.3793945312,34.489151000977),parkingSpot=vector3(1449.791015625,3656.7524414062,34.264308929443),type="letter",pay=30},
	{coords=vector3(-1593.9378662109,5192.3764648438,4.3100881576538),parkingSpot=vector3(-1575.97265625,5170.0795898438,19.462814331055),type="package",pay=30},
	{coords=vector3(1880.5743408203,3888.4079589844,33.02702331543),parkingSpot=vector3(1874.6241455078,3893.2490234375,32.90686416626),type="letter",pay=30},
}

local southMission = {
	{coords=vector3(-698.09790039062,45.763751983643,44.034057617188),parkingSpot=vector3(-688.47082519531,43.169586181641,43.108669281006),type="package",pay=14},
	{coords=vector3(-574.10046386719,409.44281005859,100.512550354),parkingSpot=vector3(-582.18072509766,410.2883605957,100.55785369873),type="letter",pay=11},
	{coords=vector3(-1599.0407714844,-365.93423461914,44.809772491455),parkingSpot=vector3(-1595.9165039062,-378.46875,43.953769683838),type="letter",pay=40},
	{coords=vector3(-903.0673828125,191.5577545166,69.445983886719),parkingSpot=vector3(-928.87377929688,176.30931091309,66.324478149414),type="package",pay=14},
	{coords=vector3(327.40805053711,503.58285522461,152.10403442383),parkingSpot=vector3(329.77478027344,496.53897094727,151.64530944824),type="letter",pay=40},
	{coords=vector3(248.44808959961,-1729.2562255859,29.331663131714),parkingSpot=vector3(241.13723754883,-1720.3128662109,28.859605789185),type="package",pay=40},
	{coords=vector3(430.96856689453,-1725.8013916016,29.601461410522),parkingSpot=vector3(416.43469238281,-1716.2891845703,29.059787750244),type="package",pay=40},
	{coords=vector3(191.51940917969,-1884.6512451172,24.691139221191),parkingSpot=vector3(190.34574890137,-1898.2308349609,23.64271736145),type="package",pay=40},
}

local uniforms = {
    ["male"] = {
        ["drawable:1"] = {0,0}, 
        ["drawable:8"] = {15,0},
        ["drawable:3"] = {0,0},
        ["drawable:4"] = {12,0}, 
        ["drawable:6"] = {48,0},
        ["drawable:5"] = {0,0},
        ["drawable:11"] = {241,0},
        ["prop:0"] = {58,0},
    },
    ["female"] = {
	    ["drawable:1"] = {0,0},
        ["drawable:8"] = {1,0},
        ["drawable:3"] = {14,0},
        ["drawable:4"] = {47,0}, 
        ["drawable:6"] = {27,0}, 
        ["drawable:5"] = {0,0},
        ["drawable:11"] = {249,0},
        ["prop:0"] = {58,0},
    },
}


Citizen.CreateThread(function()
    for k,v in pairs(Offices) do
			RequestModel(GetHashKey(v.pmodel))
	
			while not HasModelLoaded(GetHashKey(v.pmodel)) do
				Wait(1)
			end

			local npc = CreatePed(4, GetHashKey(v.pmodel), v.coords.x, v.coords.y, v.coords.z-1, v.heading, false, true)
			SetEntityHeading(npc, v.heading)
			FreezeEntityPosition(npc, true)
			SetEntityInvincible(npc, true)
			SetBlockingOfNonTemporaryEvents(npc, true)

			exports['qtarget']:AddEntityZone("pedpostal"..k, npc, {
				name = "pedpostal"..k,
				heading=GetEntityHeading(npc),
				debugPoly=false,
			}, {
				options = {
					{
						event = "vrp_postal:job",
						icon = "fas fa-file-signature",
						label = "Trabalhar",
						office = k,
						job = true,
                        canInteract = function(entity)
                            if not onDuty then
                                return true
                            else
                                return false
                            end
                        end,
					},
					{
						event = "vrp_postal:job",
						icon = "fas fa-file-signature",
						label = "Demitir-se",
						job = false,
						office = k,
                        canInteract = function(entity)
                            if onDuty then
                                return true
                            else
                                return false
                            end
                        end,
					},
					{
						event = "vrp_postal:workMission",
						icon = "fas fa-file-contract",
						label = "Iniciar Serviço",
						office = k,
                        canInteract = function(entity)
                            if onDuty and not isWorking then
                                return true
                            else
                                return false
                            end
                        end,
					},
					{
						event = "vrp_postal:ReceivePayment",
						icon = "fas fa-file-invoice-dollar",
						label = "Receber Pagamento",
						office = k,
                        canInteract = function(entity)
                            if onDuty then
                                return true
                            else
                                return false
                            end
                        end,
					},
					{
						event = "vrp_postal:spawnvan",
						icon = "fas fa-shuttle-van",
						label = "Retirar van",
						office = k,
                        canInteract = function(entity)
                            if onDuty and not workVan then
                                return true
                            else
                                return false
                            end
                        end,
					},
				},
				distance = 3.0
			})
			table.insert(peds,npc)

    end

	while true do 
        Citizen.Wait(5)
        if workVan and currentOffice then
            if GetVehiclePedIsIn(PlayerPedId(),false) == workVan then
				local gx,gy,gz,gh = table.unpack(Offices[currentOffice].garage)
                local distance = GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)),gx,gy,gz)
                if distance <= 3 then
                    DisplayHelpText("Pressione ~INPUT_PICKUP~ para guardar van")
                    if IsControlJustPressed(1,38) then
                        SetVehicleHasBeenOwnedByPlayer(workVan,false)
                        SetEntityAsMissionEntity(workVan, false, true)
                        SetVehicleAsNoLongerNeeded(Citizen.PointerValueIntInitialized(workVan))
                        DoScreenFadeOut(250)
                        while not IsScreenFadedOut() do
                        Citizen.Wait(10)
                        end
                        DeleteVehicle(workVan)
                        workVan = nil
                        Citizen.Wait(150)
                        DoScreenFadeIn(250)


						-- Cancel mission
						RemoveBlip(blip)
						RemoveBlip(officeBlip)
						isWorking = false
                    end
                end
            end

        end
    end

end)

function vrp_postal:__construct()
	vRP.Extension.__construct(self)


RegisterNetEvent("vrp_postal:ReceivePayment")
AddEventHandler("vrp_postal:ReceivePayment",function(data)

	if data.office ~= currentOffice then
		TriggerEvent("Notify","aviso","Você não foi contratado por esta central")
		return
	end

    self.remote.ReceivePayout()
end)

RegisterNetEvent("vrp_postal:job")
AddEventHandler("vrp_postal:job",function(data)
    if data.job and not onDuty then
        onDuty = true
		currentOffice = data.office
		CreateOfficeBlip(Offices[currentOffice].stock.x,Offices[currentOffice].stock.y,Offices[currentOffice].stock.z)
        -- wear uniform
        DoScreenFadeOut(250)
        while not IsScreenFadedOut() do
        Citizen.Wait(10)
        end
        if IsPedModel(PlayerPedId(), 'mp_m_freemode_01') then
            TriggerServerEvent("vrp_postal:Uniform",true,uniforms["male"])
        else
            TriggerServerEvent("vrp_postal:Uniform",true,uniforms["female"])
        end
        Citizen.Wait(150)
        DoScreenFadeIn(250)
        TriggerEvent("Notify","importante","Você foi contratado para trabalhar como <b>carteiro</b>")
    elseif not data.job and onDuty then

		if data.office ~= currentOffice then
			TriggerEvent("Notify","aviso","Você não foi contratado por esta central")
			return
		end

        onDuty = false
		currentOffice = nil
		RemoveBlip(blip)
		RemoveBlip(officeBlip)
		isWorking = false

		-- Delete work Van
		if workVan then
			SetVehicleHasBeenOwnedByPlayer(workVan,false)
			SetEntityAsMissionEntity(workVan, false, true)
			SetVehicleAsNoLongerNeeded(Citizen.PointerValueIntInitialized(workVan))                                   
			DeleteVehicle(workVan)
			workVan = nil
		end

        -- remove uniform
        DoScreenFadeOut(250)
        while not IsScreenFadedOut() do
        Citizen.Wait(10)
        end
        TriggerServerEvent("vrp_postal:Uniform",false)
        Citizen.Wait(150)
        DoScreenFadeIn(250)
        TriggerEvent("Notify","importante","Você se demitiu do serviço")
    end
end)




RegisterNetEvent("vrp_postal:workMission")
AddEventHandler("vrp_postal:workMission",function(data)

	if data.office ~= currentOffice then
		TriggerEvent("Notify","aviso","Você não foi contratado por esta central")
		return
	end

	if not workVan then
		TriggerEvent("Notify","aviso","Você precisa retirar sua van")
		return
	end

    if onDuty and not isWorking then
		isWorking = true
		local mission = nil
		local boxes = 0
		local maxBoxes = 10
		local carryingBox = false
		local boxProp = nil
		local ped = PlayerPedId()
		local delivering = false
		local takeMail = false
		
		if currentOffice == 1 then
			mission = northMission
		elseif currentOffice == 2 then
			mission = southMission
		end

		local MissionID = math.random(1,#mission)
		lastDeliveryID = MissionID
		CreateBlip(mission[MissionID].parkingSpot.x,mission[MissionID].parkingSpot.y,mission[MissionID].parkingSpot.z,"Entrega de Correspondencia")
		TriggerEvent("Notify","importante","Serviço Iniciado, Pegue as Correspondencias do estoque e carregue na van")
		while isWorking and workVan do
			Citizen.Wait(1)


			if boxes <= maxBoxes then
				DrawMarker(21, Offices[currentOffice].stock.x,Offices[currentOffice].stock.y,Offices[currentOffice].stock.z, 0, 0, 0, 180.0, 0, 0, 0.4, 0.4, 0.4, 207, 158, 25, 150, 0, 0, 0, 1)

				local distance = GetDistanceBetweenCoords(GetEntityCoords(ped),Offices[currentOffice].stock.x,Offices[currentOffice].stock.y,Offices[currentOffice].stock.z,true)
                if distance <= 2 then
					DisplayHelpText("Pressione ~INPUT_PICKUP~ para pegar correspondencia")
					if IsControlJustPressed(1,38) then
						if boxes ~= maxBoxes then
							carryingBox = true
							-- take box
							local coords = GetOffsetFromEntityInWorldCoords(ped,0.0,0.0,-5.0)
							boxProp = CreateObject(GetHashKey("prop_cs_cardbox_01"),coords.x,coords.y,coords.z,true,true,true)
							SetEntityCollision(boxProp,false,false)
							AttachEntityToEntity(boxProp,ped,GetPedBoneIndex(ped,28422),nil,nil,nil,nil,nil,nil,true,true,false,true,1,true)
							SetTimeout(500,function()
								SetVehicleDoorOpen(workVan,2,false,false)
								SetVehicleDoorOpen(workVan,3,false,false)
								SetVehicleDoorOpen(workVan,5,false,false)
							end)
						else
							TriggerEvent("Notify","aviso","Sua van esta cheia")
						end
					end
				end			
			end
			
			if GetVehiclePedIsIn(ped, false) == workVan then
				drawTx("Sua Van Possui: "..boxes.." Correspondencias",4,0.9,0.93,0.50,255,255,255,180)
				local estDis = GetDistanceBetweenCoords(GetEntityCoords(ped),mission[MissionID].parkingSpot.x,mission[MissionID].parkingSpot.y,mission[MissionID].parkingSpot.z,true)
				if estDis <= 15 and not takeMail and not delivering then
					DrawMarker(21, mission[MissionID].parkingSpot.x,mission[MissionID].parkingSpot.y,mission[MissionID].parkingSpot.z, 0, 0, 0, 180.0, 0, 0, 0.4, 0.4, 0.4, 207, 158, 25, 150, 0, 0, 0, 1)
				end

				if estDis <= 4 and not takeMail and not delivering then

                    DisplayHelpText("Pressione ~INPUT_PICKUP~ para estacionar van")
                    if IsControlJustPressed(1,38) then
						if boxes < 1 then
							TriggerEvent("Notify","aviso","Você não possui correspondencias para efetuar esta entrega")
						else		
							FreezeEntityPosition(GetVehiclePedIsIn(ped, false),true)
							TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 0)  
							SetTimeout(1000,function()
								SetVehicleDoorOpen(workVan,2,false,false)
								SetVehicleDoorOpen(workVan,3,false,false)
								SetVehicleDoorOpen(workVan,5,false,false)
							end)
							takeMail = true
							RemoveBlip(blip)
							CreateBlip(mission[MissionID].coords.x,mission[MissionID].coords.y,mission[MissionID].coords.z,"Entrega de Correspondencia")
							if mission[MissionID].type == "package" then
							 	TriggerEvent("Notify","importante","Pegue o pacote na van e o entregue no local demarcado")
							elseif mission[MissionID].type == "letter" then
								TriggerEvent("Notify","importante","Pegue a carta na van e o entregue na caixa de correio")
							end

						end
                    end
                end
			end

				if takeMail then
					local distance2 = #(GetEntityCoords(ped) - GetWorldPositionOfEntityBone(workVan,GetEntityBoneIndexByName(workVan,"door_dside_r")))
					local xa,ya,za = table.unpack(GetWorldPositionOfEntityBone(workVan,GetEntityBoneIndexByName(workVan,"door_dside_r")))

					local distance2 = #(GetEntityCoords(ped) - GetWorldPositionOfEntityBone(workVan,GetEntityBoneIndexByName(workVan,"door_pside_r")))
					local xb,yb,zb = table.unpack(GetWorldPositionOfEntityBone(workVan,GetEntityBoneIndexByName(workVan,"door_pside_r")))

					local x = (xa+xb)/2
					local y = (ya+yb)/2
					local z = (za+zb)/2

					local distance = #(GetEntityCoords(ped) - vector3(x,y,z-1.0))

					if distance <= 1.5  then
						DisplayHelpText("Pressione ~INPUT_PICKUP~ para pegar correspondencia")
						if IsControlJustPressed(1,38) then

							-- check the type of mail to play carryAnim
							if mission[MissionID].type == "package" then
								TaskPlayAnim(PlayerPedId(-1), 'anim@heists@box_carry@', 'idle', 1.0, -1.0,-1,50,0,0, 0,0)
								local coords = GetOffsetFromEntityInWorldCoords(ped,0.0,0.0,-5.0)
								boxProp = CreateObject(GetHashKey("prop_cs_cardbox_01"),coords.x,coords.y,coords.z,true,true,true)
								SetEntityCollision(boxProp,false,false)
								AttachEntityToEntity(boxProp,ped,GetPedBoneIndex(ped,28422),nil,nil,nil,nil,nil,nil,true,true,false,true,1,true)
								delivering = true
								takeMail = false
								SetTimeout(2000,function()
									SetVehicleDoorShut(workVan,2,false)
									SetVehicleDoorShut(workVan,3,false)
									SetVehicleDoorShut(workVan,5,false)
								end)
							elseif mission[MissionID].type == "letter" then
								RequestAnimDict("mp_common")
    							while (not HasAnimDictLoaded("mp_common")) do Citizen.Wait(0) end
								TaskPlayAnim(PlayerPedId(), "mp_common", "givetake1_a", 3.5, -8, -1, 2, 0, 0, 0, 0, 0)
								Wait(1500)
								ClearPedTasksImmediately(PlayerPedId())
								delivering = true
								takeMail = false
								SetTimeout(2000,function()
									SetVehicleDoorShut(workVan,2,false)
									SetVehicleDoorShut(workVan,3,false)
									SetVehicleDoorShut(workVan,5,false)
								end)
							end
						end		
					end
				end

				if delivering then
					local deliveryDis = GetDistanceBetweenCoords(GetEntityCoords(ped),mission[MissionID].coords.x,mission[MissionID].coords.y,mission[MissionID].coords.z,true)

					-- Check type of mail for delivery style
					if mission[MissionID].type == "package" then
						if deliveryDis <= 15 then
							DrawMarker(21, mission[MissionID].coords.x,mission[MissionID].coords.y,mission[MissionID].coords.z, 0, 0, 0, 180.0, 0, 0, 0.4, 0.4, 0.4, 207, 158, 25, 150, 0, 0, 0, 1)
							if deliveryDis <= 2 then
								DisplayHelpText("Pressione ~INPUT_PICKUP~ entregar correspondencia")
								if IsControlJustPressed(1,38) then
									TriggerEvent("cancelando",true)
									FreezeEntityPosition(ped,true)
									TriggerEvent("progress",5000,"Entregando Pacote")
									Citizen.Wait(5000)
									TriggerServerEvent("trydeleteobj",ObjToNet(boxProp))
									ClearPedTasks(ped)
									boxProp = nil
									local postalBox = CreateObject(GetHashKey('prop_cs_cardbox_01'), mission[MissionID].coords.x,mission[MissionID].coords.y,mission[MissionID].coords.z, 0, 0, 1)
									PlaceObjectOnGroundProperly(postalBox)
									FreezeEntityPosition(postalBox,true)
									FreezeEntityPosition(ped,false)
									TriggerEvent("cancelando",false)
									TriggerEvent("Notify","sucesso","Correspondencia entregue")
									delivering = false
									SetTimeout(30000,function()
										DeleteObject(postalBox)
									end)
									FreezeEntityPosition(workVan,false)
									boxes = boxes - 1
									self.remote.FinishMission(mission[MissionID])
									while true do
										Citizen.Wait(10)
										if lastDeliveryID == MissionID then
											MissionID = math.random(1,#mission)
										else
											RemoveBlip(blip)
											CreateBlip(mission[MissionID].parkingSpot.x,mission[MissionID].parkingSpot.y,mission[MissionID].parkingSpot.z,"Entrega de Correspondencia")
											lastDeliveryID = MissionID
											Citizen.Wait(1000)
											break
										end
										Citizen.Wait(1)
									end
								end
							end
						end
					elseif mission[MissionID].type == "letter" then
						if deliveryDis <= 10 then
							DrawMarker(21, mission[MissionID].coords.x,mission[MissionID].coords.y,mission[MissionID].coords.z, 0, 0, 0, 180.0, 0, 0, 0.4, 0.4, 0.4, 207, 158, 25, 150, 0, 0, 0, 1)
							if deliveryDis <= 1 then
								DisplayHelpText("Pressione ~INPUT_PICKUP~ para entregar correspondencia")
								if IsControlJustPressed(1,38) then
									TriggerEvent("cancelando",true)
									RequestAnimDict("mp_safehouselost@")
									while (not HasAnimDictLoaded("mp_safehouselost@")) do Citizen.Wait(0) end
									TaskPlayAnim(PlayerPedId(-1), "mp_safehouselost@", "package_dropoff", 1.0, -1.0,-1,0,0,0, 0,0)
									Citizen.Wait(1000)
									TriggerEvent("Notify","sucesso","Correspondencia entregue")
									TriggerEvent("cancelando",false)
									delivering = false
									FreezeEntityPosition(workVan,false)
									boxes = boxes - 1
									self.remote.FinishMission(mission[MissionID])
									while true do
										Citizen.Wait(10)
										if lastDeliveryID == MissionID then
											MissionID = math.random(1,#mission)
										else
											RemoveBlip(blip)
											CreateBlip(mission[MissionID].parkingSpot.x,mission[MissionID].parkingSpot.y,mission[MissionID].parkingSpot.z,"Entrega de Correspondencia")
											lastDeliveryID = MissionID
											Citizen.Wait(1000)
											break
										end
										Citizen.Wait(1)
									end
								end
							end
						end
					end

				end

			if carryingBox then

				-- carrying box anim
				if not IsEntityPlayingAnim(ped, 'anim@heists@box_carry@', 'idle', 3) then
					if not HasAnimDictLoaded("anim@heists@box_carry@") then
						RequestAnimDict("anim@heists@box_carry@")
					end
					while not HasAnimDictLoaded("anim@heists@box_carry@") do
						Citizen.Wait(0)
					end
					TaskPlayAnim(PlayerPedId(-1), 'anim@heists@box_carry@', 'idle', 1.0, -1.0,-1,50,0,0, 0,0)
				end

				local distance2 = #(GetEntityCoords(ped) - GetWorldPositionOfEntityBone(workVan,GetEntityBoneIndexByName(workVan,"door_dside_r")))
				local xa,ya,za = table.unpack(GetWorldPositionOfEntityBone(workVan,GetEntityBoneIndexByName(workVan,"door_dside_r")))

				local distance2 = #(GetEntityCoords(ped) - GetWorldPositionOfEntityBone(workVan,GetEntityBoneIndexByName(workVan,"door_pside_r")))
				local xb,yb,zb = table.unpack(GetWorldPositionOfEntityBone(workVan,GetEntityBoneIndexByName(workVan,"door_pside_r")))

				local x = (xa+xb)/2
				local y = (ya+yb)/2
				local z = (za+zb)/2

				local distance = #(GetEntityCoords(ped) - vector3(x,y,z-1.0))

				if distance <= 1.5  then
					DisplayHelpText("Pressione ~INPUT_PICKUP~ para colocar correspondencia")
					if IsControlJustPressed(1,38) then
						boxes = boxes + 1
						carryingBox = false
						TriggerServerEvent("trydeleteobj",ObjToNet(boxProp))
                        boxProp = nil
						ClearPedTasks(ped)
						SetTimeout(600,function()
							SetVehicleDoorShut(workVan,2,false)
							SetVehicleDoorShut(workVan,3,false)
							SetVehicleDoorShut(workVan,5,false)
						end)
					end
				end				
			end


		end
		lastDeliveryID = nil
		TriggerServerEvent("trydeleteobj",ObjToNet(boxProp))
		ClearPedTasks(ped)
	end
end)

end


RegisterNetEvent("vrp_postal:payoutAnim")
AddEventHandler("vrp_postal:payoutAnim",function()
    RequestAnimDict("mp_common")
    while (not HasAnimDictLoaded("mp_common")) do Citizen.Wait(0) end
    TaskPlayAnim(PlayerPedId(), "mp_common", "givetake1_a", 3.5, -8, -1, 2, 0, 0, 0, 0, 0)
    TaskPlayAnim(peds[currentOffice], "mp_common", "givetake1_a", 3.5, -8, -1, 2, 0, 0, 0, 0, 0)
    Wait(1500)
    ClearPedTasksImmediately(PlayerPedId())
    ClearPedTasksImmediately(peds[currentOffice])
end)


RegisterNetEvent('vrp_postal:spawnvan')
AddEventHandler('vrp_postal:spawnvan',function(data)

	if data.office ~= currentOffice then
		TriggerEvent("Notify","aviso","Você não foi contratado por esta central")
		return
	end

	local mhash = GetHashKey(Offices[currentOffice].van)
	while not HasModelLoaded(mhash) do
		RequestModel(mhash)
		Citizen.Wait(10)
	end
	local gx,gy,gz,gh = table.unpack(Offices[currentOffice].garage)

    if not IsAnyVehicleNearPoint(gx,gy,gz,3.0) then

        if HasModelLoaded(mhash) then
            local ped = PlayerPedId()
            workVan = CreateVehicle(mhash,gx,gy,gz,gh,true,false)
            SetVehicleIsStolen(workVan,false)
            SetVehicleOnGroundProperly(workVan)
            SetEntityInvincible(workVan,false)
            Citizen.InvokeNative(0xAD738C3085FE7E11,workVan,true,true)
            SetVehicleHasBeenOwnedByPlayer(workVan,true)
            SetVehicleDirtLevel(workVan,0.0)
            SetVehRadioStation(workVan,"OFF")
            SetVehicleDoorsLocked(workVan,1)
            SetVehicleDoorsLockedForAllPlayers(workVan,false)
            SetVehicleDoorsLockedForPlayer(workVan,PlayerId(),false)
            SetVehicleEngineOn(GetVehiclePedIsIn(ped,false),true)
            SetModelAsNoLongerNeeded(mhash)
            
            TriggerEvent("Notify","sucesso","Sua van foi retirada")
        end
    else
        TriggerEvent("Notify","negado","vaga esta ocupada")
    end
end)

function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0,0,1,-1)
end

function CreateBlip(x,y,z,text)
	blip = AddBlipForCoord(x,y,z)
	SetBlipSprite(blip,1)
	SetBlipColour(blip,5)
	SetBlipScale(blip,0.6)
	SetBlipAsShortRange(blip,false)
	SetBlipRoute(blip,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(text)
	EndTextCommandSetBlipName(blip)
end

function drawTx(text,font,x,y,scale,r,g,b,a)
	SetTextFont(font)
	SetTextScale(scale,scale)
	SetTextColour(r,g,b,a)
	SetTextOutline()
	SetTextCentre(1)
	SetTextEntry("STRING")
	AddTextComponentString(text)
	DrawText(x,y)
end

function CreateOfficeBlip(x,y,z)
	officeBlip = AddBlipForCoord(x,y,z)
	SetBlipSprite(officeBlip,478)
	SetBlipColour(officeBlip,3)
	SetBlipScale(officeBlip,0.6)
	SetBlipAsShortRange(officeBlip,true)
	SetBlipRoute(officeBlip,false)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Central Correio")
	EndTextCommandSetBlipName(officeBlip)
end


vRP:registerExtension(vrp_postal)
