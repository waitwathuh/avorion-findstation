--[[

FINDSTATION MOD

version: alpha3
author: w00zla

file: lib/findstation/common.lua
desc: library script for findstation commands

]]--

package.path = package.path .. ";data/scripts/lib/?.lua"

-- include libraries
require("utility")
require("stringutility")


local paramtypelabels = { pnum="Number", path="Path" }


-- validate parameter values based on their type
function validateParameter(paramval, paramtype)

	-- paramvalidate config paramvalues by type
	if paramval and paramval ~= "" then
		if paramtype == "pnum" then
			-- positive number paramvalues
			local pnum = tonumber(configparamval)
			if pnum and pnum >= 0 then
				return pnum
			end
		elseif paramtype == "path" then
			-- path value
			-- append ending backslash
			if not string.ends(paramval, "\\") then
				paramval = paramval .. "\\"				
			end
			return paramval
		end
		-- paramvalid generic string paramvalue
		return paramval
	end
	
end


-- get nice titles for parameter-types
function getParamTypeLabel(paramtype)

	local paramtypelabel = paramtype
	if paramtypelabels[paramtype] then
		paramtypelabel = paramtypelabels[paramtype]
	end
	return paramtypelabel
	
end


-- attaches script to entity if not already existing
function ensureEntityScript(entity, entityscript)
	
	if entity and not entity:hasScript(entityscript) then
		entity:addScriptOnce(entityscript)
	end

end


-- get distance to players current sector
function getCurrentCoordsDistance(x, y)

	local vecSector = vec2(Sector():getCoordinates())
	local vecCoords = vec2(x, y)
	local dist = distance(vecSector, vecCoords)

	return dist

end


-- get distance between coordinates
function getCoordsDistance(x1, y1, x2, y2)

	local vecs1 = vec2(x1, y1)
	local vecs2 = vec2(x2, y2)
	local dist = distance(vecs1, vecs2)

	return dist

end


-- sort table items by their key values
function pairsByKeys (t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end


-- gets all existing files  
function scandir(directory, pattern)
    local i, t, popen = 0, {}, io.popen
    --local BinaryFormat = package.cpath:match("%p[\\|/]?%p(%a+)")
	local BinaryFormat = string.sub(package.cpath,-3)
	local cmd = ""
	if pattern then 
		if not string.ends(directory, "\\") then
			directory = directory .. "\\"				
		end
		directory = directory .. pattern
	end
    if BinaryFormat == "dll" then
		cmd =   'dir "'..directory..'" /b /a-d'
    else
		cmd = 'ls -a "'..directory..'"'
    end
	--print(string.format("DEBUG findstation-scandir => cmd: %s", cmd))
    local pfile = popen(cmd)
    for filename in pfile:lines() do
		i = i + 1
		t[i] = filename
    end
    pfile:close()
    return t
end


function sortSectorsByDistance(sectors, refsector)
	
	local sectorsByDist = {}
	local sorted = {}
	
	for _, coords in pairs(sectors) do 
		local dist = getCoordsDistance(refsector.x, refsector.y, coords.x, coords.y)
		if not sectorsByDist[dist] then
			sectorsByDist[dist] = {}
		end
		table.insert(sectorsByDist[dist], coords)
	end
	
	for d, v1 in pairsByKeys(sectorsByDist) do
		for _, v2 in pairs(v1) do
			table.insert(sorted, v2)
		end
	end

	return sorted
	
end


function getExistingSectors(galaxypath)

	local sectorspath = galaxypath .. "sectors\\"
	local sectors = {}
	
	-- scan directory for sector XML files 
	local secfiles = scandir(sectorspath, "*v")
	for _, v in pairs(secfiles) do 
		--print(string.format("DEBUG findstation => found sector file: %s", v))
		local secx, secy = parseSectorFilename(v)
		table.insert(sectors, { x=secx, y=secy })
	end

	return sectors
	
end


-- parse "XXX_YYY" style string for sector coordinates
function parseSectorFilename(filename)
	local coordX, coordY = string.match(filename, "([%d%-]+)_([%d%-]+)")
	if coordY and coordX then	
		return coordX, coordY
	end
end
