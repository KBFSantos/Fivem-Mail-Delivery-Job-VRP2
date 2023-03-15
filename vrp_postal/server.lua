
local vrp_postal = class("vrp_postal", vRP.Extension)

function vrp_postal:__construct()
	vRP.Extension.__construct(self)
end

local pagamentos = {}

vrp_postal.tunnel = {}

function vrp_postal.tunnel:FinalizaMissao(mission)
    local source = source
    local user = vRP.users_by_source[source]
    if pagamentos[user.cid] then 
        pagamentos[user.cid] = pagamentos[user.cid] + mission.pay 
    else
        pagamentos[user.cid] = mission.pay 
    end
end

function vrp_postal.tunnel:getPagamento()
    local source = source
    local user = vRP.users_by_source[source]
    if pagamentos[user.cid] and pagamentos[user.cid] > 0 then 
        return pagamentos[user.cid]
    else
        return 0
    end
end

function vrp_postal.tunnel:ReceberPagamento()
    local source = source
    local user = vRP.users_by_source[source]
    if pagamentos[user.cid] and pagamentos[user.cid] > 0 then 
        user:giveWallet(pagamentos[user.cid])
        TriggerClientEvent("Notify",user.source,"importante","Você recebeu <b>$"..pagamentos[user.cid].."</b> pela entrega de correpondencias")
        pagamentos[user.cid] = nil
        TriggerClientEvent("vrp_postal:pagamentoAnim",user.source)
    else
        TriggerClientEvent("Notify",user.source,"negado","Você não tem dinheiro a receber por nenhuma entrega")
    end
end

RegisterServerEvent("vrp_postal:Uniforme")
AddEventHandler("vrp_postal:Uniforme",function(value,sex)
    local source = source
    local user = vRP.users_by_source[source]
    if not sex or not value then
        user:removeCloak()
    else
        user:setCloak(sex)  
    end
end)

vRP:registerExtension(vrp_postal)