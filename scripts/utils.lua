local Utils = {}

function Utils.GuidToString(guid)
    if guid == nil then
        return "nil"
    end
    return string.format("%i_%i_%i_%i", guid.A, guid.B, guid.C, guid.D)
end

function Utils.compareGuids(guid1, guid2)
    if guid1 == nil or guid2 == nil then
        return false
    end
    return guid1.A == guid2.A and guid1.B == guid2.B and guid1.C == guid2.C and guid1.D == guid2.D
end

function Utils.LoopGameplayTagContainer(Container, Callback)
    for i = 1, #Container.GameplayTags do
        local tag = Container.GameplayTags[i]
        Callback(tag, i)
        i = i + 1
    end
end


function Utils.Serialize(value, indent)
    indent = indent or 0
    local spacing = string.rep("  ", indent)

    if type(value) == "table" then
        local result = "{\n"
        for k, v in pairs(value) do
            local key
            if type(k) == "string" then
                key = string.format("[%q]", k)
            else
                key = string.format("[%d]", k)
            end
            result = result .. spacing .. "  " .. key .. " = " ..
                Utils.Serialize(v, indent + 1) .. ",\n"
        end
        return result .. spacing .. "}"
    elseif type(value) == "string" then
        return string.format("%q", value)
    else
        return tostring(value)
    end
end

function Utils.Notify(RichText)
    local smartPhone = FindFirstOf("BP_SmartphoneSubsystem_C")
    pcall(function()
        return smartPhone:PushNotification(FText(RichText), nil, nil, true)
    end)
end

function Utils.OnQuit(Callback)
    local mainGameMode = "/Game/Core/Rules/BP_TheMainGameMode.BP_TheMainGameMode_C"
    RegisterHook(mainGameMode .. ":ReceiveEndPlay", function(_self)
        Callback()
    end)
end

function Utils.OnWakeUp(Callback)
    local mainGameMode = "/Game/Core/Rules/BP_TheMainGameMode.BP_TheMainGameMode_C"
    RegisterHook(mainGameMode .. ":OnWakeUpFinished", function(_self)
        local mainGameModeInstance = _self:get()
        if mainGameModeInstance == nil or not mainGameModeInstance:IsValid() then
            return
        end
        Callback()
    end)
end

return Utils