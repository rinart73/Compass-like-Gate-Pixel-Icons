dirs = -- overridden
{
	{name = "E",    angle = math.pi * 2 * 0 / 16},
	{name = "ENE",  angle = math.pi * 2 * 1 / 16},
	{name = "NE",   angle = math.pi * 2 * 2 / 16},
	{name = "NNE",  angle = math.pi * 2 * 3 / 16},
	{name = "N",    angle = math.pi * 2 * 4 / 16},
	{name = "NNW",  angle = math.pi * 2 * 5 / 16},
	{name = "NW",   angle = math.pi * 2 * 6 / 16},
	{name = "WNW",  angle = math.pi * 2 * 7 / 16},
	{name = "W",    angle = math.pi * 2 * 8 / 16},
	{name = "WSW",  angle = math.pi * 2 * 9 / 16},
	{name = "SW",   angle = math.pi * 2 * 10 / 16},
	{name = "SSW",  angle = math.pi * 2 * 11 / 16},
	{name = "S",    angle = math.pi * 2 * 12 / 16},
	{name = "SSE",  angle = math.pi * 2 * 13 / 16},
	{name = "SE",   angle = math.pi * 2 * 14 / 16},
	{name = "ESE",  angle = math.pi * 2 * 15 / 16},
	{name = "E",    angle = math.pi * 2 * 16 / 16}
}

local compassLikeGPI_disabled -- server
local compassLikeGPI_secure, compassLikeGPI_restore -- overridden functions

function Gate.getGateName(isDisabled) -- overridden
    local x, y = Sector():getCoordinates()
    local tx, ty = WormHole():getTargetCoordinates()
    local specs = SectorSpecifics(tx, ty, getGameSeed())

    -- find "sky" direction to name the gate
    local ownAngle = math.atan2(ty - y, tx - x) + math.pi * 2
    if ownAngle > math.pi * 2 then ownAngle = ownAngle - math.pi * 2 end
    if ownAngle < 0 then ownAngle = ownAngle + math.pi * 2 end

    local dirString, iconPath = "", ""
    local min = 3.0
    for _, dir in pairs(dirs) do
        local d = math.abs(ownAngle - dir.angle)
        if d < min then
            min = d
            if isDisabled then -- Integration: Gate Founder
                iconPath = "data/textures/icons/gatepixelicons/gateNA.png"
                if Gate.compassLikeGPI_disableMeshes then
                    Gate.compassLikeGPI_disableMeshes() -- disable portal render
                end
            else
                iconPath = "data/textures/icons/gatepixelicons/gate"..dir.name..".png"
                if Gate.compassLikeGPI_enableMeshes then
                    Gate.compassLikeGPI_enableMeshes() -- re-enable portal render
                end
            end
            dirString = (dir.name .. " /*direction*/")%_t
        end
    end

    return iconPath, "${dir} Gate to ${sector}"%_t % {dir = dirString, sector = specs.name}
end

function Gate.initialize() -- overridden
    local entity = Entity()
    local wormhole = entity:getWormholeComponent()

    local tx, ty = wormhole:getTargetCoordinates()
    local x, y = Sector():getCoordinates()

    local d = distance(vec2(x, y), vec2(tx, ty))

    local cx = (x + tx) / 2
    local cy = (y + ty) / 2

    base = math.ceil(d * 30 * Balancing_GetSectorRichnessFactor(cx, cy))

    if onServer() then
        -- get callbacks for sector readiness
        entity:registerCallback("destinationSectorReady", "updateTooltip")

        Gate.updateTooltip()
    else
        EntityIcon().icon, Entity().title = Gate.getGateName()

        invokeServerFunction("updateTooltip")
        entity:registerCallback("onSelected", "updateTooltip")
    end
end

function Gate.updateTooltip(ready, saveOrDisabled) -- overridden
    if onServer() then
        -- on the server, check if the sector is ready,
        -- then invoke client sided tooltip update with the ready variable
        local entity = Entity()
        local wormhole = entity:getWormholeComponent()
        local transferrer = EntityTransferrer(entity.index)
        if saveOrDisabled then -- Save wormhole state (to turn gates on and off)
            compassLikeGPI_disabled = not wormhole.enabled
        end

        ready = transferrer.sectorReady

        if not callingPlayer then
            broadcastInvokeClientFunction("updateTooltip", ready, not wormhole.enabled)
        else
            invokeClientFunction(Player(callingPlayer), "updateTooltip", ready, not wormhole.enabled)
        end
    else
        if type(ready) == "boolean" then
            gateReady = ready
        end

        -- on the client, calculate the fee and update the tooltip
        local user = Player()
        local ship = Sector():getEntity(user.craftIndex)

        -- during login/loading screen it's possible that the player still has to be placed in his drone, so ship is nil
        if not ship then return end

        local shipFaction = Faction(ship.factionIndex)
        if shipFaction then
            user = shipFaction
        end

        local fee = math.ceil(base * Gate.factor(Faction(), user))
        local tooltip = EntityTooltip(Entity().index)

        tooltip:setDisplayTooltip(0, "Fee"%_t, tostring(fee) .. "$")

        if not gateReady then
            tooltip:setDisplayTooltip(1, "Status"%_t, "Not Ready"%_t)
        else
            tooltip:setDisplayTooltip(1, "Status"%_t, "Ready"%_t)
        end

        EntityIcon().icon = Gate.getGateName(saveOrDisabled)
    end
end

if onServer() then


compassLikeGPI_secure = secure
function Gate.secure()
    local data = {}
    if compassLikeGPI_secure then
        data = compassLikeGPI_secure()
    end
    data.disabled = compassLikeGPI_disabled
    return data
end

compassLikeGPI_restore = restore
function Gate.restore(data)
    compassLikeGPI_disabled = data.disabled
    local wormhole = Entity():getWormholeComponent()
    if not compassLikeGPI_disabled ~= wormhole.enabled then -- game resets wormholes to 'enabled' when sector is loaded
        wormhole.enabled = not compassLikeGPI_disabled
        Gate.updateTooltip()
    end
    if compassLikeGPI_restore then
        compassLikeGPI_restore(data)
    end
end


else -- onClient


function Gate.compassLikeGPI_disableMeshes()
    local mesh = PlanMesh()

    mesh:disableMesh(BlockShading.WormHole, MaterialType.Iron)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Titanium)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Naonite)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Trinium)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Xanion)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Ogonite)
    mesh:disableMesh(BlockShading.WormHole, MaterialType.Avorion)
end

function Gate.compassLikeGPI_enableMeshes()
    local mesh = PlanMesh()
    mesh:enableAll()
end



end