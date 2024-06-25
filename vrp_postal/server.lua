
local vrp_postal = class("vrp_postal", vRP.Extension)

function vrp_postal:__construct()
	vRP.Extension.__construct(self)
end

local payments = {}

vrp_postal.tunnel = {}

function vrp_postal.tunnel:FinishMission(mission)
    local source = source
    local user = vRP.users_by_source[source]
    if payments[user.cid] then 
        payments[user.cid] = payments[user.cid] + mission.pay 
    else
        payments[user.cid] = mission.pay 
    end
end

function vrp_postal.tunnel:getPayment()
    local source = source
    local user = vRP.users_by_source[source]
    if payments[user.cid] and payments[user.cid] > 0 then 
        return payments[user.cid]
    else
        return 0
    end
end

function vrp_postal.tunnel:ReceivePayout()
    local source = source
    local user = vRP.users_by_source[source]
    if payments[user.cid] and payments[user.cid] > 0 then 
        user:giveWallet(payments[user.cid])
        TriggerClientEvent("Notify",user.source,"importante","Você recebeu <b>$"..payments[user.cid].."</b> pela entrega de correpondencias")
        payments[user.cid] = nil
        TriggerClientEvent("vrp_postal:payoutAnim",user.source)
    else
        TriggerClientEvent("Notify",user.source,"negado","Você não tem dinheiro a receber por nenhuma entrega")
    end
end

RegisterServerEvent("vrp_postal:Uniform")
AddEventHandler("vrp_postal:Uniform",function(value,sex)
    local source = source
    local user = vRP.users_by_source[source]
    if not sex or not value then
        user:removeCloak()
    else
        user:setCloak(sex)  
    end
end)

vRP:registerExtension(vrp_postal)