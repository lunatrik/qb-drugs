RegisterServerEvent('qb-drugs:server:updateDealerItems')
AddEventHandler('qb-drugs:server:updateDealerItems', function(itemData, amount, dealer)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Config.Dealers[dealer]["products"][itemData.slot].amount - 1 >= 0 then
        Config.Dealers[dealer]["products"][itemData.slot].amount = Config.Dealers[dealer]["products"][itemData.slot].amount - amount
        TriggerClientEvent('qb-drugs:client:setDealerItems', -1, itemData, amount, dealer)
    else
        Player.Functions.RemoveItem(itemData.name, amount)
        Player.Functions.AddMoney('cash', amount * Config.Dealers[dealer]["products"][itemData.slot].price)

        TriggerClientEvent("QBCore:Notify", src, QBCore.Shared._U(Locales, "server_deliveries_event_updateDealerItems_notify_1"), "error")
    end
end)

RegisterServerEvent('qb-drugs:server:giveDeliveryItems')
AddEventHandler('qb-drugs:server:giveDeliveryItems', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    Player.Functions.AddItem('weed_brick', amount)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["weed_brick"], "add")
end)

QBCore.Functions.CreateCallback('qb-drugs:server:RequestConfig', function(source, cb)
    cb(Config.Dealers)
end)

RegisterServerEvent('qb-drugs:server:succesDelivery')
AddEventHandler('qb-drugs:server:succesDelivery', function(deliveryData, inTime)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local curRep = Player.PlayerData.metadata["dealerrep"]

    if inTime then
        if Player.Functions.GetItemByName('weed_brick') ~= nil and Player.Functions.GetItemByName('weed_brick').amount >= deliveryData["amount"] then
            Player.Functions.RemoveItem('weed_brick', deliveryData["amount"])
            local cops = GetCurrentCops()
            local price = 3000
            if cops == 1 then
                price = 4000
            elseif cops == 2 then
                price = 5000
            elseif cops >= 3 then
                price = 6000
            end
            if curRep < 10 then
                Player.Functions.AddMoney('cash', (deliveryData["amount"] * price / 100 * 8), "dilvery-drugs")
            elseif curRep >= 10 then
                Player.Functions.AddMoney('cash', (deliveryData["amount"] * price / 100 * 10), "dilvery-drugs")
            elseif curRep >= 20 then
                Player.Functions.AddMoney('cash', (deliveryData["amount"] * price / 100 * 12), "dilvery-drugs")
            elseif curRep >= 30 then
                Player.Functions.AddMoney('cash', (deliveryData["amount"] * price / 100 * 15), "dilvery-drugs")
            elseif curRep >= 40 then
                Player.Functions.AddMoney('cash', (deliveryData["amount"] * price / 100 * 18), "dilvery-drugs")
            end

            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["weed_brick"], "remove")
            TriggerClientEvent('QBCore:Notify', src, QBCore.Shared._U(Locales, "server_deliveries_event_updateDealerItems_notify_2"), 'success')

            SetTimeout(math.random(5000, 10000), function()
                TriggerClientEvent('qb-drugs:client:sendDeliveryMail', src, 'perfect', deliveryData)

                Player.Functions.SetMetaData('dealerrep', (curRep + 1))
            end)
        else
            TriggerClientEvent('QBCore:Notify', src, QBCore.Shared._U(Locales, "server_deliveries_event_updateDealerItems_notify_3"), 'error')

            if Player.Functions.GetItemByName('weed_brick').amount ~= nil then
                Player.Functions.RemoveItem('weed_brick', Player.Functions.GetItemByName('weed_brick').amount)
                Player.Functions.AddMoney('cash', (Player.Functions.GetItemByName('weed_brick').amount * 6000 / 100 * 5))
            end

            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["weed_brick"], "remove")

            SetTimeout(math.random(5000, 10000), function()
                TriggerClientEvent('qb-drugs:client:sendDeliveryMail', src, 'bad', deliveryData)

                if curRep - 1 > 0 then
                    Player.Functions.SetMetaData('dealerrep', (curRep - 1))
                else
                    Player.Functions.SetMetaData('dealerrep', 0)
                end
            end)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, QBCore.Shared._U(Locales, "server_deliveries_event_updateDealerItems_notify_4"), 'error')

        Player.Functions.RemoveItem('weed_brick', deliveryData["amount"])
        Player.Functions.AddMoney('cash', (deliveryData["amount"] * 6000 / 100 * 4), "dilvery-drugs-too-late")

        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items["weed_brick"], "remove")

        SetTimeout(math.random(5000, 10000), function()
            TriggerClientEvent('qb-drugs:client:sendDeliveryMail', src, 'late', deliveryData)

            if curRep - 1 > 0 then
                Player.Functions.SetMetaData('dealerrep', (curRep - 1))
            else
                Player.Functions.SetMetaData('dealerrep', 0)
            end
        end)
    end
end)

RegisterServerEvent('qb-drugs:server:callCops')
AddEventHandler('qb-drugs:server:callCops', function(streetLabel, coords)
    local msg = QBCore.Shared._U(Locales, "server_deliveries_event_callCops_msg",streetLabel)
    local alertData = {
        title = QBCore.Shared._U(Locales, "server_deliveries_event_callCops_title"),
        coords = {x = coords.x, y = coords.y, z = coords.z},
        description = msg
    }
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            if (Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty) then
                TriggerClientEvent("qb-drugs:client:robberyCall", Player.PlayerData.source, msg, streetLabel, coords)
                TriggerClientEvent("qb-phone:client:addPoliceAlert", Player.PlayerData.source, alertData)
            end
        end
	end
end)

function GetCurrentCops()
    local amount = 0
    for k, v in pairs(QBCore.Functions.GetPlayers()) do
        local Player = QBCore.Functions.GetPlayer(v)
        if Player ~= nil then 
            if (Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty) then
                amount = amount + 1
            end
        end
    end
    return amount
end

QBCore.Commands.Add("newdealer", QBCore.Shared._U(Locales, "server_deliveries_command_newdealer") , {
    {name = "name", help = QBCore.Shared._U(Locales, "server_deliveries_command_commons_name")},
    {name = "min", help = QBCore.Shared._U(Locales, "server_deliveries_command_newdealer_min")},
    {name = "max", help = QBCore.Shared._U(Locales, "server_deliveries_command_newdealer_max")},
}, true, function(source, args)
    local dealerName = args[1]
    local mintime = tonumber(args[2])
    local maxtime = tonumber(args[3])

    TriggerClientEvent('qb-drugs:client:CreateDealer', source, dealerName, mintime, maxtime)
end, "admin")

QBCore.Commands.Add("deletedealer", QBCore.Shared._U(Locales, "server_deliveries_command_deletedealer"), {
    {name = "name", help = QBCore.Shared._U(Locales, "server_deliveries_command_commons_name") },
}, true, function(source, args)
    local dealerName = args[1]
    
    exports.ghmattimysql:execute('SELECT * FROM dealers WHERE name=@name', {['@name'] = dealerName}, function(result)
        if result[1] ~= nil then
            exports.ghmattimysql:execute('DELETE FROM dealers WHERE name=@name', {['@name'] = dealerName})
            Config.Dealers[dealerName] = nil
            TriggerClientEvent('qb-drugs:client:RefreshDealers', -1, Config.Dealers)
            TriggerClientEvent('QBCore:Notify', source, QBCore.Shared._U(Locales, "server_deliveries_command_deletedealer_notify_1", dealerName), "success")
        else
            TriggerClientEvent('QBCore:Notify', source, QBCore.Shared._U(Locales, "server_deliveries_command_deletedealer_notify_2", dealerName), "error")
        end
    end)
end, "admin")

QBCore.Commands.Add("dealers", QBCore.Shared._U(Locales, "server_deliveries_command_dealers"), {}, false, function(source, args)
    local DealersText = ""
    if Config.Dealers ~= nil and next(Config.Dealers) ~= nil then
        for k, v in pairs(Config.Dealers) do
            DealersText = DealersText .. "Name: " .. v["name"] .. "<br>"
        end
        TriggerClientEvent('chat:addMessage', source, {
            template = QBCore.Shared._U(Locales, "server_deliveries_command_dealers_template", DealersText),
            args = {}
        })
    else
        TriggerClientEvent('QBCore:Notify', source, QBCore.Shared._U(Locales, "server_deliveries_command_dealers_notify_1"), 'error')
    end
end, "admin")

QBCore.Commands.Add("dealergoto", QBCore.Shared._U(Locales, "server_deliveries_command_dealergoto"), {{name = "name", help = QBCore.Shared._U(Locales, "server_deliveries_command_commons_name")}}, true, function(source, args)
    local DealerName = tostring(args[1])

    if Config.Dealers[DealerName] ~= nil then
        TriggerClientEvent('qb-drugs:client:GotoDealer', source, Config.Dealers[DealerName])
    else
        TriggerClientEvent('QBCore:Notify', source, QBCore.Shared._U(Locales, "server_deliveries_command_dealergoto_notify_1") , 'error')
    end
end, "admin")

Citizen.CreateThread(function()
    Wait(500)
    exports.ghmattimysql:execute('SELECT * FROM dealers', function(dealers)
        if dealers[1] ~= nil then
            for k, v in pairs(dealers) do
                local coords = json.decode(v.coords)
                local time = json.decode(v.time)

                Config.Dealers[v.name] = {
                    ["name"] = v.name,
                    ["coords"] = {
                        ["x"] = coords.x,
                        ["y"] = coords.y,
                        ["z"] = coords.z,
                    },
                    ["time"] = {
                        ["min"] = time.min,
                        ["max"] = time.max,
                    },
                    ["products"] = Config.Products,
                }
            end
        end
        TriggerClientEvent('qb-drugs:client:RefreshDealers', -1, Config.Dealers)
    end)
end)

RegisterServerEvent('qb-drugs:server:CreateDealer')
AddEventHandler('qb-drugs:server:CreateDealer', function(DealerData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    exports.ghmattimysql:execute('SELECT * FROM dealers WHERE name=@name', {['@name'] = DealerData.name}, function(result)
        if result[1] ~= nil then
            TriggerClientEvent('QBCore:Notify', src, "A dealer already exists with this name..", "error")
        else
            exports.ghmattimysql:execute('INSERT INTO dealers (name, coords, time, createdby) VALUES (@name, @coords, @time, @createdby)', {
                ['@name'] = DealerData.name,
                ['@coords'] = json.encode(DealerData.pos),
                ['@time'] = json.encode(DealerData.time),
                ['@createdby'] = Player.PlayerData.citizenid
            }, function()
                Config.Dealers[DealerData.name] = {
                    ["name"] = DealerData.name,
                    ["coords"] = {
                        ["x"] = DealerData.pos.x,
                        ["y"] = DealerData.pos.y,
                        ["z"] = DealerData.pos.z,
                    },
                    ["time"] = {
                        ["min"] = DealerData.time.min,
                        ["max"] = DealerData.time.max,
                    },
                    ["products"] = Config.Products,
                }

                TriggerClientEvent('qb-drugs:client:RefreshDealers', -1, Config.Dealers)
            end)
        end
    end)
end)

function GetDealers()
    return Config.Dealers
end
