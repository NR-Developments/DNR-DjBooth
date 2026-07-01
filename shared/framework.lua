Framework = {}

function Framework.IsPlayerLoggedIn()
    if LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn then
        return true
    end

    if ESX and ESX.PlayerLoaded then
        return true
    end

    if not (GetResourceState("qb-core") == "started"
        or GetResourceState("es_extended") == "started"
        or GetResourceState("qbx_core") == "started") then
        return true
    end

    return false
end


