local dirs =
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

function Gate.getGateName()
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
            iconPath = "data/textures/icons/gatepixelicons/gate"..dir.name..".png"
            dirString = (dir.name .. " /*direction*/")%_t
        end
    end

    return iconPath, "${dir} Gate to ${sector}"%_t % {dir = dirString, sector = specs.name}
end

function Gate.initialize()
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