Tunnel = module("vrp","lib/Tunnel")
Proxy = module("vrp","lib/Proxy")

local cvRP = module("vrp", "client/vRP")
vRP = cvRP() 

local vrp_postal = class("vrp_postal", vRP.Extension)
local Centrais = {
	{coords=vector3(-422.09115600586,6135.763671875,31.877313613892),heading=163.98,garage={-432.11645507812,6134.484375,31.377746582031,224.65},van="boxville4",pmodel="s_m_m_ups_02",estoque=vector3(-437.85546875,6147.8676757812,31.478212356567)},
	{coords=vector3(78.497062683105,111.82454681396,81.168190002441),heading=251.33,garage={73.214248657227,123.23969268799,79.099815368652,338.89},van="boxville2",pmodel="s_m_m_postal_02",estoque=vector3(113.33866882324,103.77201843262,81.169395446777)}
} 
local trabalhando = false
local selfVan = nil
local emServico = false
local centralAtual = nil
local blip = nil
local destinoantigo = nil
local estoqueBlip = nil
local peds = {}

local northMission = {
	{coords=vector3(21.498975753784,6567.361328125,31.35368347168),estacionar=vector3(28.026630401611,6571.40234375,31.217586517334),type="carta",pay=14},
	{coords=vector3(-36.889472961426,6632.8994140625,30.281930923462),estacionar=vector3(-47.752220153809,6616.171875,29.805145263672),type="pacote",pay=11},
	{coords=vector3(1507.2479248047,6327.7724609375,24.016279220581),estacionar=vector3(1500.8770751953,6331.0830078125,23.910417556763),type="pacote",pay=30},
	{coords=vector3(1827.2171630859,3891.9638671875,33.554592132568),estacionar=vector3(1836.5699462891,3891.0732421875,33.390758514404),type="carta",pay=30},
	{coords=vector3(1639.9468994141,3731.7170410156,35.067142486572),estacionar=vector3(1646.3070068359,3734.3068847656,34.272079467773),type="pacote",pay=34},
	{coords=vector3(1446.3842773438,3649.3793945312,34.489151000977),estacionar=vector3(1449.791015625,3656.7524414062,34.264308929443),type="carta",pay=30},
	{coords=vector3(-1593.9378662109,5192.3764648438,4.3100881576538),estacionar=vector3(-1575.97265625,5170.0795898438,19.462814331055),type="pacote",pay=30},
	{coords=vector3(1880.5743408203,3888.4079589844,33.02702331543),estacionar=vector3(1874.6241455078,3893.2490234375,32.90686416626),type="carta",pay=30},
}

local southMission = {
	{coords=vector3(-698.09790039062,45.763751983643,44.034057617188),estacionar=vector3(-688.47082519531,43.169586181641,43.108669281006),type="pacote",pay=14},
	{coords=vector3(-574.10046386719,409.44281005859,100.512550354),estacionar=vector3(-582.18072509766,410.2883605957,100.55785369873),type="carta",pay=11},
	{coords=vector3(-1599.0407714844,-365.93423461914,44.809772491455),estacionar=vector3(-1595.9165039062,-378.46875,43.953769683838),type="carta",pay=40},
	{coords=vector3(-903.0673828125,191.5577545166,69.445983886719),estacionar=vector3(-928.87377929688,176.30931091309,66.324478149414),type="pacote",pay=14},
	{coords=vector3(327.40805053711,503.58285522461,152.10403442383),estacionar=vector3(329.77478027344,496.53897094727,151.64530944824),type="carta",pay=40},
	{coords=vector3(248.44808959961,-1729.2562255859,29.331663131714),estacionar=vector3(241.13723754883,-1720.3128662109,28.859605789185),type="pacote",pay=40},
	{coords=vector3(430.96856689453,-1725.8013916016,29.601461410522),estacionar=vector3(416.43469238281,-1716.2891845703,29.059787750244),type="pacote",pay=40},
	{coords=vector3(191.51940917969,-1884.6512451172,24.691139221191),estacionar=vector3(190.34574890137,-1898.2308349609,23.64271736145),type="pacote",pay=40},
}

local uniformes = {
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
    for k,v in pairs(Centrais) do
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
						event = "vrp_postal:trabalhar",
						icon = "fas fa-file-signature",
						label = "Trabalhar",
						central = k,
						trabalho = true,
                        canInteract = function(entity)
                            if not trabalhando then
                                return true
                            else
                                return false
                            end
                        end,
					},
					{
						event = "vrp_postal:trabalhar",
						icon = "fas fa-file-signature",
						label = "Demitir-se",
						trabalho = false,
						central = k,
                        canInteract = function(entity)
                            if trabalhando then
                                return true
                            else
                                return false
                            end
                        end,
					},
					{
						event = "vrp_postal:service",
						icon = "fas fa-file-contract",
						label = "Iniciar Serviço",
						central = k,
                        canInteract = function(entity)
                            if trabalhando and not emServico then
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
						central = k,
                        canInteract = function(entity)
                            if trabalhando then
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
						central = k,
                        canInteract = function(entity)
                            if trabalhando and not selfVan then
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
        if selfVan and centralAtual then
            if GetVehiclePedIsIn(PlayerPedId(),false) == selfVan then
				local gx,gy,gz,gh = table.unpack(Centrais[centralAtual].garage)
                local distance = GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(-1)),gx,gy,gz)
                if distance <= 3 then
                    DisplayHelpText("Pressione ~INPUT_PICKUP~ para guardar van")
                    if IsControlJustPressed(1,38) then
                        SetVehicleHasBeenOwnedByPlayer(selfVan,false)
                        SetEntityAsMissionEntity(selfVan, false, true)
                        SetVehicleAsNoLongerNeeded(Citizen.PointerValueIntInitialized(selfVan))
                        DoScreenFadeOut(250)
                        while not IsScreenFadedOut() do
                        Citizen.Wait(10)
                        end
                        DeleteVehicle(selfVan)
                        selfVan = nil
                        Citizen.Wait(150)
                        DoScreenFadeIn(250)


						-- Cancela missão
						RemoveBlip(blip)
						RemoveBlip(estoqueBlip)
						emServico = false
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

	if data.central ~= centralAtual then
		TriggerEvent("Notify","aviso","Você não foi contratado por esta central")
		return
	end

    self.remote.ReceberPagamento()
end)

RegisterNetEvent("vrp_postal:trabalhar")
AddEventHandler("vrp_postal:trabalhar",function(data)
    if data.trabalho and not trabalhando then
        trabalhando = true
		centralAtual = data.central
		CriarEstoqueBlip(Centrais[centralAtual].estoque.x,Centrais[centralAtual].estoque.y,Centrais[centralAtual].estoque.z)
        -- setar uniforme
        DoScreenFadeOut(250)
        while not IsScreenFadedOut() do
        Citizen.Wait(10)
        end
        if IsPedModel(PlayerPedId(), 'mp_m_freemode_01') then
            TriggerServerEvent("vrp_postal:Uniforme",true,uniformes["male"])
        else
            TriggerServerEvent("vrp_postal:Uniforme",true,uniformes["female"])
        end
        Citizen.Wait(150)
        DoScreenFadeIn(250)
        TriggerEvent("Notify","importante","Você foi contratado para trabalhar como <b>carteiro</b>")
    elseif not data.trabalho and trabalhando then

		if data.central ~= centralAtual then
			TriggerEvent("Notify","aviso","Você não foi contratado por esta central")
			return
		end

        trabalhando = false
		centralAtual = nil
		RemoveBlip(blip)
		RemoveBlip(estoqueBlip)
		emServico = false

		-- Deleta Van
		if selfVan then
			SetVehicleHasBeenOwnedByPlayer(selfVan,false)
			SetEntityAsMissionEntity(selfVan, false, true)
			SetVehicleAsNoLongerNeeded(Citizen.PointerValueIntInitialized(selfVan))                                   
			DeleteVehicle(selfVan)
			selfVan = nil
		end

        -- retira uniforme
        DoScreenFadeOut(250)
        while not IsScreenFadedOut() do
        Citizen.Wait(10)
        end
        TriggerServerEvent("vrp_postal:Uniforme",false)
        Citizen.Wait(150)
        DoScreenFadeIn(250)
        TriggerEvent("Notify","importante","Você se demitiu do serviço")
    end
end)




RegisterNetEvent("vrp_postal:service")
AddEventHandler("vrp_postal:service",function(data)

	if data.central ~= centralAtual then
		TriggerEvent("Notify","aviso","Você não foi contratado por esta central")
		return
	end

	if not selfVan then
		TriggerEvent("Notify","aviso","Você precisa retirar sua van")
		return
	end

    if trabalhando and not emServico then
		emServico = true
		local mission = nil
		local caixas = 0
		local maxCaixas = 10
		local carregandoCaixa = false
		local caixaProp = nil
		local ped = PlayerPedId()
		local entregando = false
		local pegarEncomenda = false
		
		if centralAtual == 1 then
			mission = northMission
		elseif centralAtual == 2 then
			mission = southMission
		end

		local MissionID = math.random(1,#mission)
		destinoantigo = MissionID
		CriarBlip(mission[MissionID].estacionar.x,mission[MissionID].estacionar.y,mission[MissionID].estacionar.z,"Entrega de Correspondencia")
		TriggerEvent("Notify","importante","Serviço Iniciado, Pegue as Correspondencias do estoque e carregue na van")
		while emServico and selfVan do
			Citizen.Wait(1)


			if caixas <= maxCaixas then
				DrawMarker(21, Centrais[centralAtual].estoque.x,Centrais[centralAtual].estoque.y,Centrais[centralAtual].estoque.z, 0, 0, 0, 180.0, 0, 0, 0.4, 0.4, 0.4, 207, 158, 25, 150, 0, 0, 0, 1)

				local distance = GetDistanceBetweenCoords(GetEntityCoords(ped),Centrais[centralAtual].estoque.x,Centrais[centralAtual].estoque.y,Centrais[centralAtual].estoque.z,true)
                if distance <= 2 then
					DisplayHelpText("Pressione ~INPUT_PICKUP~ para pegar correspondencia")
					if IsControlJustPressed(1,38) then
						if caixas ~= maxCaixas then
							carregandoCaixa = true
							-- pegar caixa
							local coords = GetOffsetFromEntityInWorldCoords(ped,0.0,0.0,-5.0)
							caixaProp = CreateObject(GetHashKey("prop_cs_cardbox_01"),coords.x,coords.y,coords.z,true,true,true)
							SetEntityCollision(caixaProp,false,false)
							AttachEntityToEntity(caixaProp,ped,GetPedBoneIndex(ped,28422),nil,nil,nil,nil,nil,nil,true,true,false,true,1,true)
							SetTimeout(500,function()
								SetVehicleDoorOpen(selfVan,2,false,false)
								SetVehicleDoorOpen(selfVan,3,false,false)
								SetVehicleDoorOpen(selfVan,5,false,false)
							end)
						else
							TriggerEvent("Notify","aviso","Sua van esta cheia")
						end
					end
				end			
			end
			
			if GetVehiclePedIsIn(ped, false) == selfVan then
				drawTx("Sua Van Possui: "..caixas.." Correspondencias",4,0.9,0.93,0.50,255,255,255,180)
				local estDis = GetDistanceBetweenCoords(GetEntityCoords(ped),mission[MissionID].estacionar.x,mission[MissionID].estacionar.y,mission[MissionID].estacionar.z,true)
				if estDis <= 15 and not pegarEncomenda and not entregando then
					DrawMarker(21, mission[MissionID].estacionar.x,mission[MissionID].estacionar.y,mission[MissionID].estacionar.z, 0, 0, 0, 180.0, 0, 0, 0.4, 0.4, 0.4, 207, 158, 25, 150, 0, 0, 0, 1)
				end

				if estDis <= 4 and not pegarEncomenda and not entregando then

                    DisplayHelpText("Pressione ~INPUT_PICKUP~ para estacionar van")
                    if IsControlJustPressed(1,38) then
						if caixas < 1 then
							TriggerEvent("Notify","aviso","Você não possui correspondencias para efetuar esta entrega")
						else		
							FreezeEntityPosition(GetVehiclePedIsIn(ped, false),true)
							TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 0)  
							SetTimeout(1000,function()
								SetVehicleDoorOpen(selfVan,2,false,false)
								SetVehicleDoorOpen(selfVan,3,false,false)
								SetVehicleDoorOpen(selfVan,5,false,false)
							end)
							pegarEncomenda = true
							RemoveBlip(blip)
							CriarBlip(mission[MissionID].coords.x,mission[MissionID].coords.y,mission[MissionID].coords.z,"Entrega de Correspondencia")
							if mission[MissionID].type == "pacote" then
							 	TriggerEvent("Notify","importante","Pegue o pacote na van e o entregue no local demarcado")
							elseif mission[MissionID].type == "carta" then
								TriggerEvent("Notify","importante","Pegue a carta na van e o entregue na caixa de correio")
							end

						end
                    end
                end
			end

				if pegarEncomenda then
					local distance2 = #(GetEntityCoords(ped) - GetWorldPositionOfEntityBone(selfVan,GetEntityBoneIndexByName(selfVan,"door_dside_r")))
					local xa,ya,za = table.unpack(GetWorldPositionOfEntityBone(selfVan,GetEntityBoneIndexByName(selfVan,"door_dside_r")))

					local distance2 = #(GetEntityCoords(ped) - GetWorldPositionOfEntityBone(selfVan,GetEntityBoneIndexByName(selfVan,"door_pside_r")))
					local xb,yb,zb = table.unpack(GetWorldPositionOfEntityBone(selfVan,GetEntityBoneIndexByName(selfVan,"door_pside_r")))

					local x = (xa+xb)/2
					local y = (ya+yb)/2
					local z = (za+zb)/2

					local distance = #(GetEntityCoords(ped) - vector3(x,y,z-1.0))

					if distance <= 1.5  then
						DisplayHelpText("Pressione ~INPUT_PICKUP~ para pegar correspondencia")
						if IsControlJustPressed(1,38) then

							if mission[MissionID].type == "pacote" then
								TaskPlayAnim(PlayerPedId(-1), 'anim@heists@box_carry@', 'idle', 1.0, -1.0,-1,50,0,0, 0,0)
								local coords = GetOffsetFromEntityInWorldCoords(ped,0.0,0.0,-5.0)
								caixaProp = CreateObject(GetHashKey("prop_cs_cardbox_01"),coords.x,coords.y,coords.z,true,true,true)
								SetEntityCollision(caixaProp,false,false)
								AttachEntityToEntity(caixaProp,ped,GetPedBoneIndex(ped,28422),nil,nil,nil,nil,nil,nil,true,true,false,true,1,true)
								entregando = true
								pegarEncomenda = false
								SetTimeout(2000,function()
									SetVehicleDoorShut(selfVan,2,false)
									SetVehicleDoorShut(selfVan,3,false)
									SetVehicleDoorShut(selfVan,5,false)
								end)
							elseif mission[MissionID].type == "carta" then
								RequestAnimDict("mp_common")
    							while (not HasAnimDictLoaded("mp_common")) do Citizen.Wait(0) end
								TaskPlayAnim(PlayerPedId(), "mp_common", "givetake1_a", 3.5, -8, -1, 2, 0, 0, 0, 0, 0)
								Wait(1500)
								ClearPedTasksImmediately(PlayerPedId())
								entregando = true
								pegarEncomenda = false
								SetTimeout(2000,function()
									SetVehicleDoorShut(selfVan,2,false)
									SetVehicleDoorShut(selfVan,3,false)
									SetVehicleDoorShut(selfVan,5,false)
								end)
							end
						end		
					end
				end

				if entregando then
					local entregaDis = GetDistanceBetweenCoords(GetEntityCoords(ped),mission[MissionID].coords.x,mission[MissionID].coords.y,mission[MissionID].coords.z,true)


					if mission[MissionID].type == "pacote" then
						if entregaDis <= 15 then
							DrawMarker(21, mission[MissionID].coords.x,mission[MissionID].coords.y,mission[MissionID].coords.z, 0, 0, 0, 180.0, 0, 0, 0.4, 0.4, 0.4, 207, 158, 25, 150, 0, 0, 0, 1)
							if entregaDis <= 2 then
								DisplayHelpText("Pressione ~INPUT_PICKUP~ entregar correspondencia")
								if IsControlJustPressed(1,38) then
									TriggerEvent("cancelando",true)
									FreezeEntityPosition(ped,true)
									TriggerEvent("progress",5000,"Entregando Pacote")
									Citizen.Wait(5000)
									TriggerServerEvent("trydeleteobj",ObjToNet(caixaProp))
									ClearPedTasks(ped)
									caixaProp = nil
									local postalBox = CreateObject(GetHashKey('prop_cs_cardbox_01'), mission[MissionID].coords.x,mission[MissionID].coords.y,mission[MissionID].coords.z, 0, 0, 1)
									PlaceObjectOnGroundProperly(postalBox)
									FreezeEntityPosition(postalBox,true)
									FreezeEntityPosition(ped,false)
									TriggerEvent("cancelando",false)
									TriggerEvent("Notify","sucesso","Correspondencia entregue")
									entregando = false
									SetTimeout(30000,function()
										DeleteObject(postalBox)
									end)
									FreezeEntityPosition(selfVan,false)
									caixas = caixas - 1
									self.remote.FinalizaMissao(mission[MissionID])
									while true do
										Citizen.Wait(10)
										if destinoantigo == MissionID then
											MissionID = math.random(1,#mission)
										else
											RemoveBlip(blip)
											CriarBlip(mission[MissionID].estacionar.x,mission[MissionID].estacionar.y,mission[MissionID].estacionar.z,"Entrega de Correspondencia")
											destinoantigo = MissionID
											Citizen.Wait(1000)
											break
										end
										Citizen.Wait(1)
									end
								end
							end
						end
					elseif mission[MissionID].type == "carta" then
						if entregaDis <= 10 then
							DrawMarker(21, mission[MissionID].coords.x,mission[MissionID].coords.y,mission[MissionID].coords.z, 0, 0, 0, 180.0, 0, 0, 0.4, 0.4, 0.4, 207, 158, 25, 150, 0, 0, 0, 1)
							if entregaDis <= 1 then
								DisplayHelpText("Pressione ~INPUT_PICKUP~ para entregar correspondencia")
								if IsControlJustPressed(1,38) then
									TriggerEvent("cancelando",true)
									RequestAnimDict("mp_safehouselost@")
									while (not HasAnimDictLoaded("mp_safehouselost@")) do Citizen.Wait(0) end
									TaskPlayAnim(PlayerPedId(-1), "mp_safehouselost@", "package_dropoff", 1.0, -1.0,-1,0,0,0, 0,0)
									Citizen.Wait(1000)
									TriggerEvent("Notify","sucesso","Correspondencia entregue")
									TriggerEvent("cancelando",false)
									entregando = false
									FreezeEntityPosition(selfVan,false)
									caixas = caixas - 1
									self.remote.FinalizaMissao(mission[MissionID])
									while true do
										Citizen.Wait(10)
										if destinoantigo == MissionID then
											MissionID = math.random(1,#mission)
										else
											RemoveBlip(blip)
											CriarBlip(mission[MissionID].estacionar.x,mission[MissionID].estacionar.y,mission[MissionID].estacionar.z,"Entrega de Correspondencia")
											destinoantigo = MissionID
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

			if carregandoCaixa then

				-- carregar caixa anim
				if not IsEntityPlayingAnim(ped, 'anim@heists@box_carry@', 'idle', 3) then
					if not HasAnimDictLoaded("anim@heists@box_carry@") then
						RequestAnimDict("anim@heists@box_carry@")
					end
					while not HasAnimDictLoaded("anim@heists@box_carry@") do
						Citizen.Wait(0)
					end
					TaskPlayAnim(PlayerPedId(-1), 'anim@heists@box_carry@', 'idle', 1.0, -1.0,-1,50,0,0, 0,0)
				end

				local distance2 = #(GetEntityCoords(ped) - GetWorldPositionOfEntityBone(selfVan,GetEntityBoneIndexByName(selfVan,"door_dside_r")))
				local xa,ya,za = table.unpack(GetWorldPositionOfEntityBone(selfVan,GetEntityBoneIndexByName(selfVan,"door_dside_r")))

				local distance2 = #(GetEntityCoords(ped) - GetWorldPositionOfEntityBone(selfVan,GetEntityBoneIndexByName(selfVan,"door_pside_r")))
				local xb,yb,zb = table.unpack(GetWorldPositionOfEntityBone(selfVan,GetEntityBoneIndexByName(selfVan,"door_pside_r")))

				local x = (xa+xb)/2
				local y = (ya+yb)/2
				local z = (za+zb)/2

				local distance = #(GetEntityCoords(ped) - vector3(x,y,z-1.0))

				if distance <= 1.5  then
					DisplayHelpText("Pressione ~INPUT_PICKUP~ para colocar correspondencia")
					if IsControlJustPressed(1,38) then
						caixas = caixas + 1
						carregandoCaixa = false
						TriggerServerEvent("trydeleteobj",ObjToNet(caixaProp))
                        caixaProp = nil
						ClearPedTasks(ped)
						SetTimeout(600,function()
							SetVehicleDoorShut(selfVan,2,false)
							SetVehicleDoorShut(selfVan,3,false)
							SetVehicleDoorShut(selfVan,5,false)
						end)
					end
				end				
			end


		end
		destinoantigo = nil
		TriggerServerEvent("trydeleteobj",ObjToNet(caixaProp))
		ClearPedTasks(ped)
	end
end)

end


RegisterNetEvent("vrp_postal:pagamentoAnim")
AddEventHandler("vrp_postal:pagamentoAnim",function()
    RequestAnimDict("mp_common")
    while (not HasAnimDictLoaded("mp_common")) do Citizen.Wait(0) end
    TaskPlayAnim(PlayerPedId(), "mp_common", "givetake1_a", 3.5, -8, -1, 2, 0, 0, 0, 0, 0)
    TaskPlayAnim(peds[centralAtual], "mp_common", "givetake1_a", 3.5, -8, -1, 2, 0, 0, 0, 0, 0)
    Wait(1500)
    ClearPedTasksImmediately(PlayerPedId())
    ClearPedTasksImmediately(peds[centralAtual])
end)


RegisterNetEvent('vrp_postal:spawnvan')
AddEventHandler('vrp_postal:spawnvan',function(data)

	if data.central ~= centralAtual then
		TriggerEvent("Notify","aviso","Você não foi contratado por esta central")
		return
	end

	local mhash = GetHashKey(Centrais[centralAtual].van)
	while not HasModelLoaded(mhash) do
		RequestModel(mhash)
		Citizen.Wait(10)
	end
	local gx,gy,gz,gh = table.unpack(Centrais[centralAtual].garage)

    if not IsAnyVehicleNearPoint(gx,gy,gz,3.0) then

        if HasModelLoaded(mhash) then
            local ped = PlayerPedId()
            selfVan = CreateVehicle(mhash,gx,gy,gz,gh,true,false)
            SetVehicleIsStolen(selfVan,false)
            SetVehicleOnGroundProperly(selfVan)
            SetEntityInvincible(selfVan,false)
            Citizen.InvokeNative(0xAD738C3085FE7E11,selfVan,true,true)
            SetVehicleHasBeenOwnedByPlayer(selfVan,true)
            SetVehicleDirtLevel(selfVan,0.0)
            SetVehRadioStation(selfVan,"OFF")
            SetVehicleDoorsLocked(selfVan,1)
            SetVehicleDoorsLockedForAllPlayers(selfVan,false)
            SetVehicleDoorsLockedForPlayer(selfVan,PlayerId(),false)
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

function CriarBlip(x,y,z,text)
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

function CriarEstoqueBlip(x,y,z)
	estoqueBlip = AddBlipForCoord(x,y,z)
	SetBlipSprite(estoqueBlip,478)
	SetBlipColour(estoqueBlip,3)
	SetBlipScale(estoqueBlip,0.6)
	SetBlipAsShortRange(estoqueBlip,true)
	SetBlipRoute(estoqueBlip,false)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Estoque Correio")
	EndTextCommandSetBlipName(estoqueBlip)
end


vRP:registerExtension(vrp_postal)