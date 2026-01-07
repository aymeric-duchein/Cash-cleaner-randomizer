---@diagnostic disable: lowercase-global

local ArchipelagoLists = require "ArchipelagoLists"

local Archipelago = {}
local AP = require "lua-apclientpp"
local Utils = require "utils"

-- global to this mod
local game_name = "Cash cleaner simulator"
local items_handling = 7  -- full remote
local client_version = {0, 5, 1}  -- optional, defaults to lib version
local message_format = AP.RenderFormat.TEXT
---@type APClient
local ap = nil


-- TODO: user input
Archipelago.host = ""
Archipelago.slot = ""
Archipelago.password = ""
local playerId = 0

function Archipelago:Init(ctx)
    self.Reward = ctx.Reward
    self.Save = ctx.Save
    self.MarketLogic = ctx.MarketLogic
    self:ReadConfig()
end

Archipelago.CheckedLocation = {}
function Archipelago:SetCheckedLocation(locations)
    self.CheckedLocation = locations
end

Archipelago.CONFIG_PATH = "ue4ss/Mods/Randomizer/Saved/ap_config.lua"
function Archipelago:ReadConfig()
    local ok, data = pcall(dofile, self.CONFIG_PATH)
    if ok and type(data) == "table" then
        self.host = data.host
        self.slot = data.player
        self.password = data.password
        self.MarketLogic:SetMarketSeed(math.tointeger(math.fmod(data.seed, math.maxinteger)))
    end
end

function Archipelago:Connect(server, slot, password)
    print("we are calling archipelago.lua connect")
    local on_socket_connected = function()

        print("Socket connected" )
    end

    local on_socket_error = function(msg)
       print("Socket error: " .. msg)
    end

    local on_socket_disconnected = function()
        print("Socket disconnected")
    end

    local on_room_info = function()
        print("Room info")
        ap:ConnectSlot(slot, password, items_handling, {"Lua-APClientPP"}, client_version)
    end

    local on_slot_connected = function(slot_data)
        print("Slot connected")
        playerId = ap:get_player_number()

        ap:Say("Hello World!")
        ap:ConnectUpdate(nil, {"Lua-APClientPP"})
        -- ap:LocationChecks({0x88888888})  
    end


    local on_slot_refused = function(reasons)
        print("Slot refused: " .. table.concat(reasons, ", "))
    end 

    local on_items_received = function(items)
        ExecuteInGameThread( function() 
            print("Items received:", type(items), #items)
            for _, item in ipairs(items) do
                -- Could use to display player X sent you print("item player", item.player)

                local reward = ArchipelagoLists.APItemIdToName[item.item]
                print(item.item, reward)
                local location
                local player = nil
                if item.player == playerId then
                    location = ArchipelagoLists.APLocationIdToName[item.location]
                else
                    location = item.player .. "-" .. item.location
                    player = ap:get_player_alias(item.player)
                end
                print(item.location, location)
                if not self.CheckedLocation[location] then
                    Utils.ThrottledCall(function()
                        self.Reward:Award(reward, location, player)
                    end)
                    self.CheckedLocation[location] = true
                    self.Save:OnChange()
                end
            end
        end)
    end

    local on_location_info = function(items)
        print("Locations scouted:")
        for _, item in ipairs(items) do
            print(item.item)
        end
    end

    local on_location_checked = function(locations)
        print("calling location checked")
        print("Locations checked:" .. table.concat(locations, ", "))
        print("Checked locations: " .. table.concat(ap.checked_locations, ", "))
    end 

    local on_data_package_changed = function(data_package)
        print("Data package changed:")
        print(data_package)
    end 

    local on_print = function(msg)
        print(msg)
    end 

    local on_print_json = function(msg, extra)
        print(ap:render_json(msg, message_format))
        for key, value in pairs(extra) do
            -- print("  " .. key .. ": " .. tostring(value))
        end
    end 

    local on_bounced = function(bounce)
        print("Bounced:")
        print(bounce)
    end 
    local on_retrieved = function(map, keys, extra)
        print("Retrieved:")
        -- since lua tables won't contain nil values, we can use keys array
        for _, key in ipairs(keys) do
            print("  " .. key .. ": " .. tostring(map[key]))
        end
        -- extra will include extra fields from Get
        print("Extra:")
        for key, value in pairs(extra) do
            print("  " .. key .. ": " .. tostring(value))
        end
        -- both keys and extra are optional
    end 

    local on_set_reply = function(message)
        print("Set Reply:")
        for key, value in pairs(message) do
            print("  " .. key .. ": " .. tostring(value))
            if key == "value" and type(value) == "table" then
                for subkey, subvalue in pairs(value) do
                    print("    " .. subkey .. ": " .. tostring(subvalue))
                end
            end
        end
    end


    local uuid = ""
    ap = AP(uuid, game_name, server);
    print("Connecting to " .. server .. " ...")
    ap:set_socket_connected_handler(on_socket_connected)
    ap:set_socket_error_handler(on_socket_error)
    ap:set_socket_disconnected_handler(on_socket_disconnected)
    ap:set_room_info_handler(on_room_info)
    ap:set_slot_connected_handler(on_slot_connected)
    ap:set_slot_refused_handler(on_slot_refused)
    ap:set_items_received_handler(on_items_received)
    ap:set_location_info_handler(on_location_info)
    ap:set_location_checked_handler(on_location_checked)
    ap:set_data_package_changed_handler(on_data_package_changed)
    ap:set_print_handler(on_print)
    ap:set_print_json_handler(on_print_json)
    ap:set_bounced_handler(on_bounced)
    ap:set_retrieved_handler(on_retrieved)
    ap:set_set_reply_handler(on_set_reply)
end

function Archipelago:ConnectToAp()
    ExecuteAsync(function ()
        self:Connect(self.host, self.slot, self.password)
        LoopAsync(500, function()
            while ap do
                ap:poll()
            end
        end)
        
    end)
    Utils.OnQuit(function()
        self:Disconnect()
    end)
end

function Archipelago:Disconnect()
    ap = nil
    collectgarbage("collect")
end

function Archipelago:SendLocationFromName(locationName)
    local locationID = self:GetAPLocationIDfromName(locationName)
    if ap == nil then
        print("AP client not connected, cannot send location")
        return
    end
     
    if locationID == nil then
        print("Location name:"..locationName.."Is not valid.")
        return
    end
    print("Sending location name: "..locationName)    
    ap:LocationChecks({tonumber(locationID)})
end


function Archipelago:GetAPLocationIDfromName(locationName)
    return ArchipelagoLists.LocationNameToAPId[locationName]
end

return Archipelago