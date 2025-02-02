ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

AddEventHandler('esx:playerLoaded',function(playerId, xPlayer)
    local sourcePlayer = playerId
    local identifier = xPlayer.getIdentifier()

    getOrGeneratePhoneNumber(identifier, function(myPhoneNumber)
    end)

    getOrGenerateIBAN(identifier, function(iban)
    end)
end)

RegisterCommand('telal', function (source)
    local Player = ESX.GetPlayerFromId(source)
    local phoneNumber =  getPhoneRandomNumber()
    Player.addInventoryItem('phone', 1, nil, {phone = phoneNumber, owner = Player.identifier})
    MySQL.Async.execute('INSERT INTO phones (owner, phone_number) VALUES (@owner, @phone_number)',
	{
		['@owner']   	= Player.identifier,
        ['@phone_number']  = phoneNumber,
	})
end)

local MIPhone = {}
local Tweets = {}
local AppAlerts = {}
local MentionedTweets = {}
local Hashtags = {}
local Calls = {}
local Adverts = {}
local GeneratedPlates = {}

-- Number and IBAN Generate Stuff 
function getPhoneRandomNumber()
    local numBase0 = 0
    local numBase1 = 6
    local numBase2 = math.random(11111111, 99999999)
    local num = string.format(numBase0 .. "" .. numBase1 .. "" .. numBase2 .. "")
    return num
end

function generateIBAN()
    local numBase0 = math.random(100, 999)
    local num = string.format(numBase0)

	return num
end

function getNumberPhone(identifier)
    local result = MySQL.Sync.fetchAll("SELECT users.phone FROM users WHERE users.identifier = @identifier", {
        ['@identifier'] = identifier
    })
    if result[1] ~= nil then
        return result[1].phone
    end
    return nil
end

function getIBAN(identifier)
    local result = MySQL.Sync.fetchAll("SELECT users.iban FROM users WHERE users.identifier = @identifier", {
        ['@identifier'] = identifier
    })
    if result[1] ~= nil then
        return result[1].iban
    end
    return nil
end

function getOrGenerateIBAN(identifier, cb)
    local identifier = identifier
    local myIBAN = getIBAN(identifier)

    if myIBAN == '0' or myIBAN == nil then
        repeat
            myIBAN = generateIBAN()
            local id = getPlayerFromIBAN(myIBAN)

        until id == nil

        MySQL.Async.insert("UPDATE users SET iban = @myIBAN WHERE identifier = @identifier", { 
            ['@myIBAN'] = myIBAN,
            ['@identifier'] = identifier

        }, function()
            cb(myIBAN)
        end)
    else
        cb(myIBAN)
    end
end

function getOrGeneratePhoneNumber(identifier, cb)
    local identifier = identifier
    local myPhoneNumber = getNumberPhone(identifier)

    if myPhoneNumber == '0' or myPhoneNumber == nil then
        repeat
            myPhoneNumber = getPhoneRandomNumber()
            local id = GetPlayerFromPhone(myPhoneNumber)

        until id == nil

        MySQL.Async.insert("UPDATE users SET phone = @myPhoneNumber WHERE identifier = @identifier", { 
            ['@myPhoneNumber'] = myPhoneNumber,
            ['@identifier'] = identifier

        }, function()
            cb(myPhoneNumber)
        end)
    else
        cb(myPhoneNumber)
    end
end


RegisterServerEvent('qb-phone:saveTwitterToDatabase')
AddEventHandler('qb-phone:saveTwitterToDatabase', function(firstName, lastname, message, url, time, picture)
	MySQL.Async.execute('INSERT INTO twitter_tweets (firstname, lastname, message, url, time, picture, owner, owner_phone) VALUES (@firstname, @lastname, @message, @url, @time, @picture, @owner, @owner_phone)',
	{
		['@firstname']   	= firstName,
		['@lastname']   	= lastname,
		['@message'] 	= message,
        ['@url']       = url,
		['@time']  = time,
        ['@picture'] 		= picture,
        ['@owner'] 		= currentOwner,
        ['@owner_phone'] = currentNumber
	})
end)

RegisterServerEvent("qb-phone:WhatsappActions")
AddEventHandler("qb-phone:WhatsappActions", function(data)
        if data.type == "whatsapp-clear-chat" then
            print(data.number)
            print(currentNumber)
            print("qwe")
                exports.ghmattimysql:execute("UPDATE phone_messages SET `messages` = '[]' WHERE owner_number = '" .. currentNumber.. "' AND number = '" ..data.number.. "'")
            -- end)
        elseif data.type == "delete-message" then

        else
            exports.ghmattimysql:execute("DELETE FROM phone_messages WHERE owner_number = '" .. currentNumber.. "' AND number = '" ..data.number.. "'")
        end
end)

RegisterServerEvent('qb-phone:saveMessageToDatabase')
AddEventHandler('qb-phone:saveMessageToDatabase', function(messagess, ChatNumber)
    print(messagess)
    MySQL.Async.execute('INSERT INTO phone_messages (number, messages, identifier, owner_number) VALUES (@number, @messages, @identifier, @owner_number)',
	{
		['@number'] = ChatNumber,
		['@messages'] = message,
        ['@identifier'] = currentOwner,
        ['@owner_number'] = currentNumber
	})
end)

RegisterServerEvent('qb-phone:server:AddAdvert')
AddEventHandler('qb-phone:server:AddAdvert', function(msg)
    local src = source
    local Player = ESX.GetPlayerFromId(src)
    local Identifier = Player.identifier
    local character = GetCharacter(src)

    if Adverts[Identifier] ~= nil then
        Adverts[Identifier].message = msg
        Adverts[Identifier].name = "@" .. character.firstname .. "" .. character.lastname
        Adverts[Identifier].number = character.phone
        Adverts[Identifier].image = image ~= nil and image or false
    else
        Adverts[Identifier] = {
            message = msg,
            name = "@" .. character.firstname .. "_" .. character.lastname,
            number = character.phone,
            image = image ~= nil and image or false
        }
    end

    TriggerClientEvent('qb-phone:client:UpdateAdverts', -1, Adverts, "@" .. character.firstname .. "" .. character.lastname)
end)

function GetOnlineStatus(number)
    local Target = GetPlayerFromPhone(number)
    local retval = false
    if Target ~= nil then retval = true end
    return retval
end

RegisterServerEvent('qb-phone:server:updateForEveryone')
AddEventHandler('qb-phone:server:updateForEveryone', function(newTweet)
    local src = source
    TriggerClientEvent('qb-phone:updateForEveryone', -1, newTweet)
end)

RegisterServerEvent('qb-phone:server:updateidForEveryone')
AddEventHandler('qb-phone:server:updateidForEveryone', function()
    TriggerClientEvent('qb-phone:updateidForEveryone', -1)
end)


ESX.RegisterUsableItem('phone', function (source, item)
    openPhone(source, item)
    getCurrentPhoneNumber(source, item)
    getCurrentOwner(source, item)
end)

currentNumber = nil
function getCurrentPhoneNumber(source, item)
    currentNumber = item.info.phone
    print('Telefon num: '..currentNumber)
    return currentNumber
end

currentOwner = nil
function getCurrentOwner(source, item)
    currentOwner = item.info.owner
    print('Telefon sahibi: '..currentOwner)
    return currentOwner
end

function openPhone(source, item)
    local src = source


    local owner = item.info.owner
    local number = item.info.phone

    local PhoneData = {
        Applications = {},
        PlayerContacts = {},
        MentionedTweets = {},
        Chats = {},
        Hashtags = {},
        SelfTweets = {},
        Invoices = {},
        Garage = {},
        Mails = {},
        Adverts = {},
        CryptoTransactions = {},
        Tweets = {},
        Number = number,
        Owner = owner
    }
    PhoneData.Adverts = Adverts

    ExecuteSql(false, "SELECT * FROM player_contacts WHERE `phone_number` = '"..number.."' ORDER BY `name` ASC", function(result)
        local Contacts = {}
        if result[1] ~= nil then
            for k, v in pairs(result) do
                v.status = GetOnlineStatus(v.number)
            end
            PhoneData.PlayerContacts = result
        else 
            PhoneData.PlayerContacts = {}
        end
        

        ExecuteSql(false, "SELECT * FROM twitter_tweets", function(result)
            if result[1] ~= nil then
                PhoneData.Tweets = result
            else
                PhoneData.Tweets = {}
            end


            ExecuteSql(false, "SELECT * FROM twitter_tweets WHERE owner_phone = '"..number.."'", function(result)
                if result ~= nil then
                    PhoneData.SelfTweets = result
                else
                    PhoneData.SelfTweets = {}
                end
        ExecuteSql(false, "SELECT * FROM owned_vehicles WHERE `owner` = '"..number.."'", function(garageresult)

            if garageresult[1] ~= nil then
                PhoneData.Garage = garageresult
            else
                PhoneData.Garage = {}
            end

            ExecuteSql(false, 'SELECT * FROM `player_mails` WHERE `phone_number` = "'..number..'" ORDER BY `date` ASC', function(mails)

                if mails[1] ~= nil then
                    for k, v in pairs(mails) do
                        if mails[k].button ~= nil then
                            mails[k].button = json.decode(mails[k].button)
                        end
                    end
                    PhoneData.Mails = mails
                end

                ExecuteSql(false, "SELECT * FROM phone_messages WHERE `owner_number` = '"..number.."'", function(messages)
                    if messages ~= nil and next(messages) ~= nil then 
                        PhoneData.Chats = messages
                    else
                        PhoneData.Chats = {}
                    end

                    if AppAlerts[number] ~= nil then 
                        PhoneData.Applications = AppAlerts[number]
                    else 
                        PhoneData.Applications = {}
                    end
                   
                    if MentionedTweets[number] ~= nil then 
                        PhoneData.MentionedTweets = MentionedTweets[number]
                    else
                        PhoneData.MentionedTweets = {}
                    end

                    if Hashtags ~= nil and next(Hashtags) ~= nil then
                        PhoneData.Hashtags = Hashtags
                    end

                    PhoneData.charinfo = GetCharacter(src)

                    if Config.UseESXBilling then
                        ExecuteSql(false, "SELECT * FROM billing  WHERE `identifier` = '"..owner.."'", function(invoices)
                            if invoices[1] ~= nil then
                                for k, v in pairs(invoices) do
                                    ExecuteSql(true, "SELECT phone_number FROM `phones` WHERE `owner` = '"..v.sender.."' AND `active` = 1", function(res)
                                        if res[1] ~= nil then
                                            v.number = res[1].phone_number
                                        end
                                    end)
                                end
                                PhoneData.Invoices = invoices
                            end
                            TriggerClientEvent('almez-phone:client:openPhone', source, PhoneData)
                        end)
                    else 
                        PhoneData.Invoices = {}
                        TriggerClientEvent('almez-phone:client:openPhone', source, PhoneData)
                    end
                end)
            end)
            end) 
        end)
    end)
    end)

end

RegisterServerEvent('qb-phone:deleteTweet')
AddEventHandler('qb-phone:deleteTweet', function(id)
    MySQL.Async.execute('DELETE FROM twitter_tweets WHERE owner = @owner AND id = @id', {['@owner'] = currentOwner, ['@id'] = id})
end)


ESX.RegisterServerCallback('qb-phone:server:GetCallState', function(source, cb, ContactData)
    local Target = GetPlayerFromPhone(ContactData.number)

    if Target ~= nil then
        if Calls[Target.identifier] ~= nil then
            if Calls[Target.identifier].inCall then
                cb(false, true)
            else
                cb(true, true)
            end
        else
            cb(true, true)
        end
    else
        cb(false, false)
    end
end)

RegisterServerEvent('qb-phone:server:SetCallState')
AddEventHandler('qb-phone:server:SetCallState', function(bool)
    local src = source
    local Ply = ESX.GetPlayerFromId(src)

    if Calls[Ply.identifier] ~= nil then
        Calls[Ply.identifier].inCall = bool
    else
        Calls[Ply.identifier] = {}
        Calls[Ply.identifier].inCall = bool
    end
end)

RegisterServerEvent('qb-phone:server:RemoveMail')
AddEventHandler('qb-phone:server:RemoveMail', function(MailId)
    local src = source
    ExecuteSql(false, 'DELETE FROM `player_mails` WHERE `mailid` = "'..MailId..'" AND `phone_number` = "'..currentNumber..'"')
    SetTimeout(100, function()
        ExecuteSql(false, 'SELECT * FROM `player_mails` WHERE `phone_number` = "'..currentNumber..'" ORDER BY `date` ASC', function(mails)
            if mails[1] ~= nil then
                for k, v in pairs(mails) do
                    if mails[k].button ~= nil then
                        mails[k].button = json.decode(mails[k].button)
                    else
                        mails[k].button = {}
                    end
                end
            end
    
            TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
        end)
    end)
end)

function GenerateMailId()
    return math.random(111111, 999999)
end

RegisterServerEvent('qb-phone:server:sendNewMail')
AddEventHandler('qb-phone:server:sendNewMail', function(mailData)
    local src = source
    local Player = ESX.GetPlayerFromId(src)
    if mailData.button == nil then
        ExecuteSql(false, "INSERT INTO `player_mails` (`phone_number`, `sender`, `messageUrl`, `subject`, `message`, `mailid`, `read`) VALUES ('"..currentNumber.."', '"..mailData.sender.."', '" ..mailData.messageUrl.. "', '"..mailData.subject.."', '"..mailData.message.."', '"..GenerateMailId().."', '0')")
    else
        ExecuteSql(false, "INSERT INTO `player_mails` (`phone_number`, `sender`, `messageUrl`, `subject`, `message`, `mailid`, `read`, `button`) VALUES ('"..currentNumber.."', '"..mailData.sender.."',  '"..mailData.messageUrl.."', '"..mailData.subject.."', '"..mailData.message.."', '"..GenerateMailId().."', '0', '"..json.encode(mailData.button).."')")
    end
    TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)

    SetTimeout(200, function()
        ExecuteSql(false, 'SELECT * FROM `player_mails` WHERE `phone_number` = "'..currentNumber..'" ORDER BY `date` DESC', function(mails)
            if mails[1] ~= nil then
                for k, v in pairs(mails) do
                    if mails[k].button ~= nil then
                        mails[k].button = json.decode(mails[k].button)
                    end
                end
            end
    
            TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
        end)
    end)
end)

RegisterServerEvent('qb-phone:server:sendNewMailToOffline')
AddEventHandler('qb-phone:server:sendNewMailToOffline', function(steam, mailData)
    local Player = ESX.GetPlayerFromIdentifier(steam)

    if Player ~= nil then
        local src = Player.source

        if mailData.button == nil then
            ExecuteSql(false, "INSERT INTO `player_mails` (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES ('"..Player.identifier.."', '"..mailData.sender.."', '"..mailData.subject.."', '"..mailData.message.."', '"..GenerateMailId().."', '0')")
            TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
        else
            ExecuteSql(false, "INSERT INTO `player_mails` (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES ('"..Player.identifier.."', '"..mailData.sender.."', '"..mailData.subject.."', '"..mailData.message.."', '"..GenerateMailId().."', '0', '"..json.encode(mailData.button).."')")
            TriggerClientEvent('qb-phone:client:NewMailNotify', src, mailData)
        end

        SetTimeout(200, function()
            ExecuteSql(false, 'SELECT * FROM `player_mails` WHERE `phone_number` = "'..currentNumber..'" ORDER BY `date` DESC', function(mails)
                if mails[1] ~= nil then
                    for k, v in pairs(mails) do
                        if mails[k].button ~= nil then
                            mails[k].button = json.decode(mails[k].button)
                        end
                    end
                end
        
                TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
            end)
        end)
    else
        if mailData.button == nil then
            ExecuteSql(false, "INSERT INTO `player_mails` (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES ('"..identifier.."', '"..mailData.sender.."', '"..mailData.subject.."', '"..mailData.message.."', '"..GenerateMailId().."', '0')")
        else
            ExecuteSql(false, "INSERT INTO `player_mails` (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES ('"..identifier.."', '"..mailData.sender.."', '"..mailData.subject.."', '"..mailData.message.."', '"..GenerateMailId().."', '0', '"..json.encode(mailData.button).."')")
        end
    end
end)

RegisterServerEvent('qb-phone:server:sendNewEventMail')
AddEventHandler('qb-phone:server:sendNewEventMail', function(steam, mailData)
    if mailData.button == nil then
        ExecuteSql(false, "INSERT INTO `player_mails` (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`) VALUES ('"..identifier.."', '"..mailData.sender.."', '"..mailData.subject.."', '"..mailData.message.."', '"..GenerateMailId().."', '0')")
    else
        ExecuteSql(false, "INSERT INTO `player_mails` (`identifier`, `sender`, `subject`, `message`, `mailid`, `read`, `button`) VALUES ('"..identifier.."', '"..mailData.sender.."', '"..mailData.subject.."', '"..mailData.message.."', '"..GenerateMailId().."', '0', '"..json.encode(mailData.button).."')")
    end
    SetTimeout(200, function()
        ExecuteSql(false, 'SELECT * FROM `player_mails` WHERE `phone_number` = "'..currentNumber..'" ORDER BY `date` DESC', function(mails)
            if mails[1] ~= nil then
                for k, v in pairs(mails) do
                    if mails[k].button ~= nil then
                        mails[k].button = json.decode(mails[k].button)
                    end
                end
            end
    
            TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
        end)
    end)
end)

RegisterServerEvent('qb-phone:server:ClearButtonData')
AddEventHandler('qb-phone:server:ClearButtonData', function(mailId)
    local src = source
    local Player = ESX.GetPlayerFromId(src)

    ExecuteSql(false, 'UPDATE `player_mails` SET `button` = "" WHERE `mailid` = "'..mailId..'" AND `phone_number` = "'..currentNumber..'"')
    SetTimeout(200, function()
        ExecuteSql(false, 'SELECT * FROM `player_mails` WHERE `phone_number` = "'..currentNumber..'" ORDER BY `date` DESC', function(mails)
            if mails[1] ~= nil then
                for k, v in pairs(mails) do
                    if mails[k].button ~= nil then
                        mails[k].button = json.decode(mails[k].button)
                    end
                end
            end
    
            TriggerClientEvent('qb-phone:client:UpdateMails', src, mails)
        end)
    end)
end)

RegisterServerEvent('qb-phone:server:MentionedPlayer')
AddEventHandler('qb-phone:server:MentionedPlayer', function(firstName, lastName, TweetMessage)
    for k, v in pairs(ESX.GetPlayers()) do
        local Player = ESX.GetPlayerFromId(v)
        local character = GetCharacter(v)

        if Player ~= nil then
            if (character.firstname == firstName and character.lastname == lastName) then
                MIPhone.SetPhoneAlerts(Player.identifier, "twitter")
   
                MIPhone.AddMentionedTweet(Player.identifier, TweetMessage)
                TriggerClientEvent('qb-phone:client:GetMentioned', Player.source, TweetMessage, AppAlerts[Player.identifier]["twitter"])

            else
                ExecuteSql(false, "SELECT * FROM `users` WHERE `firstname`='"..firstName.."' AND `lastname`='"..lastName.."'", function(result)
                    if result[1] ~= nil then
                        local MentionedTarget = result[1].identifier
                        MIPhone.SetPhoneAlerts(MentionedTarget, "twitter")
                        charAt.AddMentionedTweet(MentionedTarget, TweetMessage)
                    end
                end)
            end
        end
	end
end)

RegisterServerEvent('qb-phone:server:CallContact')
AddEventHandler('qb-phone:server:CallContact', function(TargetData, CallId, AnonymousCall)
    local src = source
    local Ply = ESX.GetPlayerFromId(src)
    local Target = GetPlayerFromPhone(TargetData.number)
    local character = GetCharacter(src)

    if Target ~= nil then
        TriggerClientEvent('qb-phone:client:GetCalled', Target.source, character.phone, CallId, AnonymousCall)
    end
end)

ESX.RegisterServerCallback('almez-phone:isPhoneRealOwner', function(source,cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer.identifier == currentOwner then 
        cb(true)
    else 
        cb(false)
    end
end)

-- ESX(V1_Final) Fix
ESX.RegisterServerCallback('qb-phone:server:GetBankData', function(source, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local character = GetCharacter(src)

    cb({bank = xPlayer.getAccount('bank').money, iban = character.iban})
end)

-- ESX(V1_Final) Fix
ESX.RegisterServerCallback('qb-phone:server:CanPayInvoice', function(source, cb, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    cb(xPlayer.getAccount('bank').money >= amount)
end)

ESX.RegisterServerCallback('qb-phone:server:GetInvoices', function(source, cb)
    ExecuteSql(false, "SELECT * FROM billing  WHERE `identifier` = '"..currentOwner.."'", function(invoices)
        if invoices[1] ~= nil then
            for k, v in pairs(invoices) do
                local Ply = ESX.GetPlayerFromIdentifier(v.sender)

                if Ply ~= nil then
                    v.number = GetCharacter(Ply.source).phone
                else
                    ExecuteSql(true, "SELECT * FROM `users` WHERE `identifier` = '"..v.sender.."'", function(res)
                        if res[1] ~= nil then
                            v.number = res[1].phone
                        else
                            v.number = nil
                        end
                    end)
                end
            end
            PhoneData.Invoices = invoices
            cb(invoices)
        else
            cb({})
        end
    end)
end)

RegisterServerEvent('qb-phone:server:UpdateHashtags')
AddEventHandler('qb-phone:server:UpdateHashtags', function(Handle, messageData)
    if Hashtags[Handle] ~= nil and next(Hashtags[Handle]) ~= nil then
        table.insert(Hashtags[Handle].messages, messageData)
    else
        Hashtags[Handle] = {
            hashtag = Handle,
            messages = {}
        }
        table.insert(Hashtags[Handle].messages, messageData)
    end
    TriggerClientEvent('qb-phone:client:UpdateHashtags', -1, Handle, messageData)
end)

MIPhone.AddMentionedTweet = function(identifier, TweetData)
    if MentionedTweets[identifier] == nil then MentionedTweets[identifier] = {} end
    table.insert(MentionedTweets[identifier], TweetData)
end

MIPhone.SetPhoneAlerts = function(identifier, app, alerts)
    if identifier ~= nil and app ~= nil then
        if AppAlerts[identifier] == nil then
            AppAlerts[identifier] = {}
            if AppAlerts[identifier][app] == nil then
                if alerts == nil then
                    AppAlerts[identifier][app] = 1
                else
                    AppAlerts[identifier][app] = alerts
                end
            end
        else
            if AppAlerts[identifier][app] == nil then
                if alerts == nil then
                    AppAlerts[identifier][app] = 1
                else
                    AppAlerts[identifier][app] = 0
                end
            else
                if alerts == nil then
                    AppAlerts[identifier][app] = AppAlerts[identifier][app] + 1
                else
                    AppAlerts[identifier][app] = AppAlerts[identifier][app] + 0
                end
            end
        end
    end
end

ESX.RegisterServerCallback('qb-phone:server:GetContactPictures', function(source, cb, Chats)
    for k, v in pairs(Chats) do
        local Player = ESX.GetPlayerFromIdentifier(v.number)
        local character = GetCharacter(source)
        picture = character.profilepicture
        print(picture)
    end
    SetTimeout(100, function()
        cb(Chats)
    end)
end)

ESX.RegisterServerCallback('qb-phone:server:GetContactPicture', function(source, cb, Chat)
    ExecuteSql(false, "SELECT * FROM `users` WHERE `phone`='" .. Chat.number .. "'", function(result)
        if result[1] and result[1].background then
            Chat.picture = result[1].background
            cb(Chat)
        else
            Chat.picture = "default"
            cb(Chat)
        end
    end)
end)

ESX.RegisterServerCallback('qb-phone:server:GetPicture', function(source, cb, number)
    local Player = GetPlayerFromPhone(number)
    local Picture = nil

    ExecuteSql(false, "SELECT * FROM `users` WHERE `identifier`='"..currentOwner.."'", function(result)
        if result[1] ~= nil then
            if result[1].profilepicture ~= nil then
                Picture = result[1].profilepicture
            else
                Picture = "default"
            end
            cb(Picture)
        else
            cb(nil)
        end
    end)
end)

RegisterServerEvent('qb-phone:server:SetPhoneAlerts')
AddEventHandler('qb-phone:server:SetPhoneAlerts', function(app, alerts)
    local src = source
    local Identifier = ESX.GetPlayerFromId(src).identifier
    MIPhone.SetPhoneAlerts(Identifier, app, alerts)
end)

RegisterServerEvent('qb-phone:server:UpdateTweets')
AddEventHandler('qb-phone:server:UpdateTweets', function(TweetData, type)
    Tweets = NewTweets
    local TwtData = TweetData
    local src = source
    TriggerClientEvent('qb-phone:client:UpdateTweets', -1, src, TwtData, type)
end)




RegisterServerEvent('qb-phone:server:TransferMoney')
AddEventHandler('qb-phone:server:TransferMoney', function(iban, amount)
    local src = source
    local sender = ESX.GetPlayerFromId(src)

    ExecuteSql(false, "SELECT * FROM `users` WHERE `iban`='"..iban.."'", function(result)
        if result[1] ~= nil then
            local recieverSteam = ESX.GetPlayerFromIdentifier(result[1].identifier)

            if recieverSteam ~= nil then
                local PhoneItem = recieverSteam.getInventoryItem("phone").count and recieverSteam.getInventoryItem("phone").count > 0
                recieverSteam.addAccountMoney('bank', amount)
                sender.removeAccountMoney('bank', amount)

                if PhoneItem ~= nil then
                    TriggerClientEvent('qb-phone:client:TransferMoney', recieverSteam.source, amount, recieverSteam.getAccount('bank').money)

                    ExecuteSql(false, "SELECT * FROM `users` WHERE `identifier`='"..ESX.GetPlayerFromId(src).identifier.."'", function(result)
                        TriggerClientEvent('rp_notify:client:SendAlert', sender.source, { type = 'inform', text = 'Para transferi başarılı!'})
                        TriggerClientEvent('rp_notify:client:SendAlert',  recieverSteam.source, { type = 'inform', text = 'Hesabına para transferi yapıldı: $' .. amount .. ', yatıran IBAN: ' .. result[1].iban .. ''})
                    end)
                end
            
            else
                ExecuteSql(false, "UPDATE `users` SET `bank` = '"..result[1].bank + amount.."' WHERE `identifier` = '"..result[1].identifier.."'")
                sender.removeAccountMoney('bank', amount)
            end
        else
            TriggerClientEvent('rp_notify:client:SendAlert', src, { type = 'inform', text = 'Bu IBAN mevcut değil!'})
        end
    end)
end)


RegisterServerEvent('qb-phone:server:EditContact')
AddEventHandler('qb-phone:server:EditContact', function(newName, newNumber, newIban, oldName, oldNumber, oldIban)
    local src = source
    local Player = ESX.GetPlayerFromId(src)
    ExecuteSql(false, "UPDATE `player_contacts` SET `name` = '"..newName.."', `number` = '"..newNumber.."', `iban` = '"..newIban.."' WHERE `phone_number` = '"..currentNumber.."' AND `name` = '"..oldName.."' AND `number` = '"..oldNumber.."'")
end)

RegisterServerEvent('qb-phone:server:RemoveContact')
AddEventHandler('qb-phone:server:RemoveContact', function(Name, Number)
    local src = source
    local Player = ESX.GetPlayerFromId(src)
    
    ExecuteSql(false, "DELETE FROM `player_contacts` WHERE `name` = '"..Name.."' AND `number` = '"..Number.."' AND `phone_number` = '"..currentNumber.."'")
end)

RegisterServerEvent('qb-phone:server:AddNewContact')
AddEventHandler('qb-phone:server:AddNewContact', function(name, number, iban)
    local src = source
    local Player = ESX.GetPlayerFromId(src)
    ExecuteSql(false, "INSERT INTO `player_contacts` (`phone_number`, `name`, `number`, `iban`) VALUES ('"..currentNumber.."', '"..tostring(name).."', '"..tostring(number).."', '"..tostring(iban).."')")
end)

RegisterServerEvent('qb-phone:server:UpdateMessages')
AddEventHandler('qb-phone:server:UpdateMessages', function(ChatMessages, ChatNumber, New)
    local src = source
    local src = source
    local SenderData = ESX.GetPlayerFromId(src)
    local SenderCharacter = GetCharacter(src)
    print(ChatNumber)
    print(ChatNumber)
    print(ChatNumber)
    print(New)
    ExecuteSql(false, "SELECT * FROM `phones` WHERE `phone_number`= '"..ChatNumber.."'", function(Player)
        if Player[1] ~= nil then
            local TargetData = ESX.GetPlayerFromIdentifier(Player[1].owner)

            if TargetData ~= nil then
                ExecuteSql(false, "SELECT * FROM `phone_messages` WHERE `identifier` = '"..currentOwner.."' AND `number` = '"..ChatNumber.."'", function(Chat)
                    if Chat[1] ~= nil then
                        print("786")
                        print(json.encode(ChatMessages))
                        print(Player[1].owner)
                        print(ChatNumber)
                        exports["ghmattimysql"]:execute("UPDATE `phone_messages` SET `messages` = @messages WHERE `identifier` = @identifier AND `number` = @number", {
                            ["@identifier"] = Player[1].owner,
                            ["@messages"] = json.encode(ChatMessages),
                            ["@number"] = currentNumber,
                            ["@owner_number"] = ChatNumber
                        })
                        exports["ghmattimysql"]:execute("UPDATE `phone_messages` SET `messages` = @messages WHERE`identifier` = @identifier AND `number` = @number", {
                            ["@identifier"] = currentOwner,
                            ["@messages"] = json.encode(ChatMessages),
                            ["@number"] = ChatNumber,
                            ["@owner_number"] = currentNumber
                        })
                        TriggerClientEvent('qb-phone:client:UpdateMessages', TargetData.source, ChatMessages, currentNumber, false)
                    else
                        print("801")
                        exports["ghmattimysql"]:execute("INSERT INTO `phone_messages` (`identifier`, `number`, `messages`) VALUES (@identifier, @number, @messages)", {
                            ["@identifier"] = Player[1].owner,
                            ["@number"] = Player[1].owner_number,
                            ["@messages"] = json.encode(ChatMessages),
                            ["@owner_number"] = currentNumber
                        })
                        -- Insert for sender
                        exports["ghmattimysql"]:execute("INSERT INTO `phone_messages` (`identifier`, `number`, `messages`) VALUES (@identifier, @number, @messages)", {
                            ["@identifier"] = currentOwner,
                            ["@number"] = Player[1].owner_number,
                            ["@messages"] = json.encode(ChatMessages),
                            ["@owner_number"] = currentNumber
                        })
                        print("doğru yer")
                        TriggerClientEvent('qb-phone:client:UpdateMessages', TargetData.source, ChatMessages, currentNumber, true)
                    end
                end)
            else
                ExecuteSql(false, "SELECT * FROM `phone_messages` WHERE `identifier` = '"..currentOwner.."' AND `number` = '"..Player[1].phone_number.."'", function(Chat)
                    if Chat[1] ~= nil then
                        -- Update for target
                        print("823")
                        --QBCore.Functions.ExecuteSql(false, "UPDATE `phone_messages` SET `messages` = '"..json.encode(ChatMessages).."' WHERE `identifier` = '"..Player[1].citizenid.."' AND `number` = '"..SenderData.PlayerData.phone.."'")
                        exports["ghmattimysql"]:execute("UPDATE `phone_messages` SET `messages` = @messages WHERE `identifier` = @identifier AND `number` = @number", {
                            ["@identifier"] = Player[1].owner,
                            ["@messages"] = json.encode(ChatMessages),
                            ["@number"] =  currentNumber,
                            ["@owner_number"] = Player[1].phone_number
                        })
                        -- Update for sender
                       -- QBCore.Functions.ExecuteSql(false, "UPDATE `phone_messages` SET `messages` = '"..json.encode(ChatMessages).."' WHERE `identifier` = '"..currentOwner.."' AND `number` = '"..Player[1].phone.."'")
                        exports["ghmattimysql"]:execute("UPDATE `phone_messages` SET `messages` = @messages WHERE`identifier` = @identifier AND `number` = @number", {
                            ["@identifier"] = currentOwner,
                            ["@messages"] = json.encode(ChatMessages),
                            ["@number"] = Player[1].phone_number,
                            ["@owner_number"] = currentNumber
                        })
                    else
                        print("doğru yer2")
                        -- Insert for target
                        --QBCore.Functions.ExecuteSql(false, "INSERT INTO `phone_messages` (`identifier`, `number`, `messages`) VALUES ('"..Player[1].citizenid.."', '"..SenderData.PlayerData.phone.."', '"..json.encode(ChatMessages).."')")
                        exports["ghmattimysql"]:execute("INSERT INTO `phone_messages` (`identifier`, `number`, `messages`, `owner_number`) VALUES (@identifier, @number, @messages, @owner_number)", {
                            ["@identifier"] = Player[1].owner,
                            ["@number"] = currentNumber,
                            ["@messages"] = json.encode(ChatMessages),
                            ["@owner_number"] = Player[1].phone_number
                        })
                        -- Insert for sender
                        --QBCore.Functions.ExecuteSql(false, "INSERT INTO `phone_messages` (`identifier`, `number`, `messages`) VALUES ('"..currentOwner.."', '"..Player[1].phone.."', '"..json.encode(ChatMessages).."')")
                        exports["ghmattimysql"]:execute("INSERT INTO `phone_messages` (`identifier`, `number`, `messages`, `owner_number`) VALUES (@identifier, @number, @messages, @owner_number)", {
                            ["@identifier"] = currentOwner,
                            ["@number"] = Player[1].phone_number,
                            ["@messages"] = json.encode(ChatMessages),
                            ["@owner_number"] = currentNumber
                        })
                    end
                end)
            end
        end
    end)
end)

RegisterServerEvent('qb-phone:server:AddRecentCall')
AddEventHandler('qb-phone:server:AddRecentCall', function(type, data)
    local src = source
    local Ply = ESX.GetPlayerFromId(src)
    local character = GetCharacter(src)

    local Hour = os.date("%H")
    local Minute = os.date("%M")
    local label = Hour..":"..Minute

    TriggerClientEvent('qb-phone:client:AddRecentCall', src, data, label, type)

    local Trgt = GetPlayerFromPhone(data.number)
    if Trgt ~= nil then
        TriggerClientEvent('qb-phone:client:AddRecentCall', Trgt.source, {
            name = character.firstname .. " " ..character.lastname,
            number = character.phone,
            anonymous = anonymous
        }, label, "outgoing")
    end
end)

RegisterServerEvent('qb-phone:server:CancelCall')
AddEventHandler('qb-phone:server:CancelCall', function(ContactData)
    local Ply = GetPlayerFromPhone(ContactData.TargetData.number)

    if Ply ~= nil then
        TriggerClientEvent('qb-phone:client:CancelCall', Ply.source)
    end
end)

RegisterServerEvent('qb-phone:server:AnswerCall')
AddEventHandler('qb-phone:server:AnswerCall', function(CallData)
    local Ply = GetPlayerFromPhone(CallData.TargetData.number)

    if Ply ~= nil then
        TriggerClientEvent('qb-phone:client:AnswerCall', Ply.source)
    end
end)

RegisterServerEvent('qb-phone:server:SaveMetaData')
AddEventHandler('qb-phone:server:SaveMetaData', function(column,data)
    local src = source

    if data and column then
        if type(data) == 'table' then
            ExecuteSql(false, "UPDATE `users` SET `" .. column .. "` = '".. json.encode(data) .."' WHERE `identifier` = '"..currentOwner.."'")
        else
            ExecuteSql(false, "UPDATE `users` SET `" .. column .. "` = '".. data .."' WHERE `identifier` = '"..currentOwner.."'")
        end
    end
end)

function escape_sqli(source)
    local replacements = { ['"'] = '\\"', ["'"] = "\\'" }
    return source:gsub( "['\"]", replacements ) -- or string.gsub( source, "['\"]", replacements )
end

ESX.RegisterServerCallback('qb-phone:server:FetchResult', function(source, cb, search)
    local src = source
    local search = escape_sqli(search)
    local searchData = {}
    local ApaData = {}
    local character = GetCharacter(src)
    ExecuteSql(false, "SELECT * FROM `users` WHERE firstname LIKE '%"..search.."%'", function(result)
        if result[1] ~= nil then
            for k, v in pairs(result) do
                local driverlicense = false
                local weaponlicense = false
                local doingSomething = true

                if Config.UseESXLicense then
                    CheckLicense(v.identifier, 'weapon', function(has)
                        if has then
                            weaponlicense = true
                        end

                        CheckLicense(v.identifier, 'drive', function(has)
                            if has then
                                driverlicense = true
                            end
                            
                            doingSomething = false
                        end)
                    end)
                else
                    doingSomething = false
                end


                while doingSomething do Wait(1) end
                
                table.insert(searchData, {
                    identifier = v.identifier,
                    firstname = character.firstname,
                    lastname = character.lastname,
                    birthdate = character.dateofbirth,
                    phone = character.phone,
                    gender = character.sex,
                    weaponlicense = weaponlicense,
                    driverlicense = driverlicense,
                })
            end
            cb(searchData)
        else
            cb(nil)
        end
    end)
end)

function CheckLicense(target, type, cb)
	local target = target

	if target then
		MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM user_licenses WHERE type = @type AND owner = @owner', {
			['@type'] = type,
			['@owner'] = target
		}, function(result)
			if tonumber(result[1].count) > 0 then
				cb(true)
			else
				cb(false)
			end
		end)
	else
		cb(false)
	end
end

ESX.RegisterServerCallback('qb-phone:server:GetVehicleSearchResults', function(source, cb, search)
    local src = source
    local search = escape_sqli(search)
    local searchData = {}
    local character = GetCharacter(src)

    ExecuteSql(false, 'SELECT * FROM `owned_vehicles` WHERE `plate` LIKE "%'..search..'%" OR `owner` = "'..search..'"', function(result)
        if result[1] ~= nil then
            for k, v in pairs(result) do
                ExecuteSql(true, 'SELECT * FROM `users` WHERE `identifier` = "'..result[k].identifier..'"', function(player)
                    if player[1] ~= nil then 
                        local vehicleInfo = { ['name'] = json.decode(result[k].vehicle).model }
                        if vehicleInfo ~= nil then 
                            table.insert(searchData, {
                                plate = result[k].plate,
                                status = true,
                                owner = character.firstname .. " " .. character.lastname,
                                identifier = result[k].identifier,
                                label = vehicleInfo["name"]
                            })
                        else
                            table.insert(searchData, {
                                plate = result[k].plate,
                                status = true,
                                owner = character.firstname .. " " .. character.lastname,
                                identifier = result[k].identifier,
                                label = "Name not found"
                            })
                        end
                    end
                end)
            end
        elseif GeneratedPlates[search] ~= nil then
            table.insert(searchData, {
                plate = GeneratedPlates[search].plate,
                status = GeneratedPlates[search].status,
                owner = GeneratedPlates[search].owner,
                identifier = GeneratedPlates[search].identifier,
                label = "Brand unknown.."
            })
        else
            local ownerInfo = GenerateOwnerName()
            GeneratedPlates[search] = {
                plate = search,
                status = true,
                owner = ownerInfo.name,
                identifier = ownerInfo.identifier,
            }
            table.insert(searchData, {
                plate = search,
                status = true,
                owner = ownerInfo.name,
                identifier = ownerInfo.identifier,
                label = "Brand unknown .."
            })
        end
        cb(searchData)
    end)
end)

ESX.RegisterServerCallback('qb-phone:server:ScanPlate', function(source, cb, plate)
    local src = source
    local vehicleData = {}
    local character = GetCharacter(src)
    if plate ~= nil then 
        ExecuteSql(false, 'SELECT * FROM `owned_vehicles` WHERE `plate` = "'..plate..'"', function(result)
            if result[1] ~= nil then
                ExecuteSql(true, 'SELECT * FROM `users` WHERE `identifier` = "'..result[1].identifier..'"', function(player)
                    vehicleData = {
                        plate = plate,
                        status = true,
                        owner = character.firstname .. " " .. character.lastname,
                        identifier = result[1].identifier,
                    }
                end)
            elseif GeneratedPlates ~= nil and GeneratedPlates[plate] ~= nil then 
                vehicleData = GeneratedPlates[plate]
            else
                local ownerInfo = GenerateOwnerName()
                GeneratedPlates[plate] = {
                    plate = plate,
                    status = true,
                    owner = ownerInfo.name,
                    identifier = ownerInfo.identifier,
                }
                vehicleData = {
                    plate = plate,
                    status = true,
                    owner = ownerInfo.name,
                    identifier = ownerInfo.identifier,
                }
            end
            cb(vehicleData)
        end)
    else
        TriggerClientEvent('notification', src, Lang('NO_VEHICLE'), 2)
        cb(nil)
    end
end)

function GenerateOwnerName()
    local names = {
        [1] = { name = "Jan Bloksteen", identifier = "DSH091G93" },
        [2] = { name = "Jay Dendam", identifier = "AVH09M193" },
        [3] = { name = "Ben Klaariskees", identifier = "DVH091T93" },
        [4] = { name = "Karel Bakker", identifier = "GZP091G93" },
        [5] = { name = "Klaas Adriaan", identifier = "DRH09Z193" },
        [6] = { name = "Nico Wolters", identifier = "KGV091J93" },
        [7] = { name = "Mark Hendrickx", identifier = "ODF09S193" },
        [8] = { name = "Bert Johannes", identifier = "KSD0919H3" },
        [9] = { name = "Karel de Grote", identifier = "NDX091D93" },
        [10] = { name = "Jan Pieter", identifier = "ZAL0919X3" },
        [11] = { name = "Huig Roelink", identifier = "ZAK09D193" },
        [12] = { name = "Corneel Boerselman", identifier = "POL09F193" },
        [13] = { name = "Hermen Klein Overmeen", identifier = "TEW0J9193" },
        [14] = { name = "Bart Rielink", identifier = "YOO09H193" },
        [15] = { name = "Antoon Henselijn", identifier = "QBC091H93" },
        [16] = { name = "Aad Keizer", identifier = "YDN091H93" },
        [17] = { name = "Thijn Kiel", identifier = "PJD09D193" },
        [18] = { name = "Henkie Krikhaar", identifier = "RND091D93" },
        [19] = { name = "Teun Blaauwkamp", identifier = "QWE091A93" },
        [20] = { name = "Dries Stielstra", identifier = "KJH0919M3" },
        [21] = { name = "Karlijn Hensbergen", identifier = "ZXC09D193" },
        [22] = { name = "Aafke van Daalen", identifier = "XYZ0919C3" },
        [23] = { name = "Door Leeferds", identifier = "ZYX0919F3" },
        [24] = { name = "Nelleke Broedersen", identifier = "IOP091O93" },
        [25] = { name = "Renske de Raaf", identifier = "PIO091R93" },
        [26] = { name = "Krisje Moltman", identifier = "LEK091X93" },
        [27] = { name = "Mirre Steevens", identifier = "ALG091Y93" },
        [28] = { name = "Joosje Kalvenhaar", identifier = "YUR09E193" },
        [29] = { name = "Mirte Ellenbroek", identifier = "SOM091W93" },
        [30] = { name = "Marlieke Meilink", identifier = "KAS09193" },
    }
    return names[math.random(1, #names)]
end





ESX.RegisterServerCallback('qb-phone:server:GetGarageVehicles', function(source, cb)
    local Player = ESX.GetPlayerFromId(source)
    local Vehicles = {}

    ExecuteSql(false, "SELECT * FROM `owned_vehicles` WHERE `owner` = '"..currentOwner.."'", function(result)
        if result[1] ~= nil then
            for k, v in pairs(result) do

                if v.garage == "OUT" then
                    VehicleState = "OUT"
                else
                    VehicleState = "Garage"
                end

                local vehdata = {}

                vehdata = {
                    model = json.decode(result[k].vehicle).model,
                    plate = v.plate,
                    garage = v.garage,
                }
                table.insert(Vehicles, vehdata)
            end
            cb(Vehicles)
        else
            cb(nil)
        end
    end)
end)

ESX.RegisterServerCallback('qb-phone:server:GetCharacterData', function(source, cb,id)
    local src = source or id
    local xPlayer = ESX.GetPlayerFromId(source)
    
    cb(GetCharacter(src))
end)

-- Inventory Fix
ESX.RegisterServerCallback('qb-phone:server:HasPhone', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer ~= nil then
        local HasPhone = xPlayer.getQuantity("phone")

        if HasPhone >= 1 then
            cb(true)
        else
            cb(false)
        end
    end
end)

RegisterServerEvent('qb-phone:server:GiveContactDetails')
AddEventHandler('qb-phone:server:GiveContactDetails', function(PlayerId)
    local src = source
    local Player = ESX.GetPlayerFromId(src)
    local character = GetCharacter(src)

    local SuggestionData = {
        name = {
            [1] = character.firstname,
            [2] = character.lastname
        },
        number = character.phone,
        bank = Player.getAccount('bank').money,
    }

    TriggerClientEvent('qb-phone:client:AddNewSuggestion', PlayerId, SuggestionData)
end)

RegisterServerEvent('qb-phone:server:AddTransaction')
AddEventHandler('qb-phone:server:AddTransaction', function(data)
    local src = source
    local Player = ESX.GetPlayerFromId(src)

    ExecuteSql(false, "INSERT INTO `crypto_transactions` (`identifier`, `title`, `message`) VALUES ('"..Player.identifier.."', '"..escape_sqli(data.TransactionTitle).."', '"..escape_sqli(data.TransactionMessage).."')")
end)

ESX.RegisterServerCallback('qb-phone:server:GetCurrentpolices', function(source, cb)
    local polices = {}
    for k, v in pairs(ESX.GetPlayers()) do
        local character = GetCharacter(v)
        local xPlayer = ESX.GetPlayerFromId(v)
        if xPlayer ~= nil then
            if xPlayer.getJob().name == "police" then
                table.insert(polices, {
                    firstname = character.firstname,
                    lastname = character.lastname,
                    phone = character.phone,
                })
            end
        end
    end
    cb(polices)
end)

ESX.RegisterServerCallback('qb-phone:server:GetCurrentArrests', function(source, cb)
    MySQL.Async.fetchAll("SELECT * FROM epc_bolos order by id", {}, function(c)
        cb(c)
    end)
end)

ESX.RegisterServerCallback('qb-phone:server:GetCurrentLawyers', function(source, cb)
    local Lawyers = {}
    for k, v in pairs(ESX.GetPlayers()) do
        local character = GetCharacter(v)
        local xPlayer = ESX.GetPlayerFromId(v)
        if xPlayer ~= nil then
            if xPlayer.getJob().name == "lawyer" then
                table.insert(Lawyers, {
                    firstname = character.firstname,
                    lastname = character.lastname,
                    phone = character.phone,
                })
            end
        end
    end
    cb(Lawyers)
end)


ESX.RegisterServerCallback('qb-phone:server:GetCurrentFoodWorker', function(source, cb, jobName)
    print(jobName)
    local workers = {}
    for k, v in pairs(ESX.GetPlayers()) do
        local character = GetCharacter(v)
        local xPlayer = ESX.GetPlayerFromId(v)
        if xPlayer ~= nil then
            if xPlayer.getJob().name == jobName then
                table.insert(workers, {
                    name = character.firstname .. " " ..character.lastname,
                    setjob = jobName,
                    phone = character.phone,
                })
            end
        end
    end
    cb(workers)
end)

ESX.RegisterServerCallback('qb-phone:server:GetCurrentJobsWorker', function(source, cb, jobName)
    print(jobName)
    local jobworkers = {}
    for k, v in pairs(ESX.GetPlayers()) do
        local character = GetCharacter(v)
        local xPlayer = ESX.GetPlayerFromId(v)
        if xPlayer ~= nil then
            if xPlayer.getJob().name == jobName then
                table.insert(jobworkers, {
                    name = character.firstname .. " " ..character.lastname,
                    setjob = jobName,
                    phone = character.phone,
                })
            end
        end
    end
    cb(jobworkers)
end)

ESX.RegisterServerCallback('qb-phone:server:GetCurrentDrivers', function(source, cb)
    local drivers = {}
    for k, v in pairs(ESX.GetPlayers()) do
        local character = GetCharacter(v)
        local xPlayer = ESX.GetPlayerFromId(v)
        if xPlayer ~= nil then
            if xPlayer.getJob().name == "taxi" then
                table.insert(drivers, {
                    firstname = character.firstname,
                    lastname = character.lastname,
                    phone = character.phone,
                })
            end
        end
    end
    cb(drivers)
end)

ESX.RegisterServerCallback('qb-phone:server:GetCurrentMecano', function(source, cb)
    local mecano = {}
    for k, v in pairs(ESX.GetPlayers()) do
        local character = GetCharacter(v)
        local xPlayer = ESX.GetPlayerFromId(v)
        if xPlayer ~= nil then
            if xPlayer.getJob().name == "mechanic1" then
                table.insert(mecano, {
                    firstname = character.firstname,
                    lastname = character.lastname,
                    phone = character.phone,
                })
            end
        end
    end
    cb(mecano)
end)

ESX.RegisterServerCallback('qb-phone:server:GetCurrentDoctor', function(source, cb)
    local doctor = {}
    for k, v in pairs(ESX.GetPlayers()) do
        local character = GetCharacter(v)
        local xPlayer = ESX.GetPlayerFromId(v)
        if xPlayer ~= nil then
            if xPlayer.getJob().name == "ambulance" then
                table.insert(doctor, {
                    firstname = character.firstname,
                    lastname = character.lastname,
                    phone = character.phone,
                })
            end
        end
    end
    cb(doctor)
end)

ESX.RegisterServerCallback('qb-phone:server:GetCurrentWeazel', function(source, cb)
    local news = {}
    for k, v in pairs(ESX.GetPlayers()) do
        local character = GetCharacter(v)
        local xPlayer = ESX.GetPlayerFromId(v)
        if xPlayer ~= nil then
            if xPlayer.getJob().name == "weazel" then
                table.insert(news, {
                    firstname = character.firstname,
                    lastname = character.lastname,
                    phone = character.phone,
                })
            end
        end
    end
    cb(news)
end)

-- ESX(V1_Final) Fix
function GetCharacter(source)
	local result = MySQL.Sync.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {
		['@identifier'] = currentOwner
	})

    return result[1]
end

function GetPlayerFromPhone(phone)
    local result = MySQL.Sync.fetchAll('SELECT * FROM users WHERE phone = @phone', {
		['@phone'] = phone
    })
    
    if result[1] and result[1].identifier then
        return ESX.GetPlayerFromIdentifier(result[1].identifier)
    end

    return nil
end


function getPlayerFromIBAN(iban)
    local result = MySQL.Sync.fetchAll('SELECT * FROM users WHERE iban = @iban', {
		['@iban'] = iban
    })
    
    if result[1] and result[1].identifier then
        return ESX.GetPlayerFromIdentifier(result[1].identifier)
    end

    return nil
end

function ExecuteSql(wait, query, cb)
	local rtndata = {}
	local waiting = true
	MySQL.Async.fetchAll(query, {}, function(data)
		if cb ~= nil and wait == false then
			cb(data)
		end
		rtndata = data
		waiting = false
	end)
	if wait then
		while waiting do
			Citizen.Wait(5)
		end
		if cb ~= nil and wait == true then
			cb(rtndata)
		end
    end
    
	return rtndata
end

function Lang(item)
    local lang = Config.Languages[Config.Language]

    if lang and lang[item] then
        return lang[item]
    end

    return item
end