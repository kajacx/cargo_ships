require("logic.ship_placement")
require("logic.long_reach")
require("logic.bridge_logic")
local choices = require("choices")

-- spawn additioanl invisible enties
function onEntityBuild(e)
	-- 
	local ent = e.created_entity
	if ent.name == "indep-boat" then

		CheckBoatPlacement(ent, e.player_index)
	elseif ent.type == "cargo-wagon" or ent.type == "fluid-wagon" or ent.type == "locomotive" or ent.type == "artillery-wagon" then
		--game.players[1].print(ent.collision_mask)
		local engine = nil
		if ent.name == "cargo_ship" or ent.name == "oil_tanker" or ent.name == "train_carrier" then
			local pos, dir = localize_engine(ent)
			engine = ent.surface.create_entity{name = "cargo_ship_engine", position = pos, direction = dir, force = ent.force}
		elseif ent.name == "boat"  then
			local pos, dir = localize_engine(ent)
			engine = ent.surface.create_entity{name = "boat_engine", position = pos, direction = dir, force = ent.force}
		end
		-- check placement in next tick 
		table.insert(global.check_entity_placement, {ent, engine, e.player_index})

	-- add oilrig slave entity
	elseif ent.name == "oil_rig" then
		local pos =  ent.position
		local or_power = ent.surface.create_entity{name = "or_power", position = pos, force = ent.force}
		table.insert(global.or_generators,or_power)
		ent.surface.create_entity{name = "or_pole", position = pos, force = ent.force}
		ent.surface.create_entity{name = "or_radar", position = pos, force = ent.force}
		ent.surface.create_entity{name = "or_lamp", position = {pos.x - 3, pos.y -3}, force = ent.force}
		ent.surface.create_entity{name = "or_lamp", position = {pos.x + 3, pos.y -3}, force = ent.force}
		ent.surface.create_entity{name = "or_lamp", position = {pos.x + 3, pos.y + 3}, force = ent.force}
		ent.surface.create_entity{name = "or_lamp", position = {pos.x - 3, pos.y + 3}, force = ent.force}
	-- create bridge
	elseif ent.name == "bridge_base" then
		CreateBridge(ent, e.player_index)	

	-- make waterway not collide with boats by replacing it with entity that does not have "ground-tile" in its collison mask
	elseif ent.name == "straight-water-way" or ent.name == "curved-water-way" then
		local p = ent.position
		local n = ent.name .. "-placed"
		local f = ent.force
		local s = ent.surface
		local d = ent.direction
		ent.destroy() --destroy old
		--check for allready placed entites
		local c = 0
		local prev = game.surfaces[1].find_entities_filtered{position = p, name = n}
		for _,pr in pairs(prev) do
			if pr.direction == d then
				c = pr.name == "straight-water-way-placed" and 1 or 4 
				break
			end
		end
		if c>0 then
			if e.player_index then
				game.players[e.player_index].insert{name="water-way", count=c}
			end
		else
			WW = s.create_entity{name= n, position = p, direction = d, force = f} -- create new
			-- make waterway indistructable 
	 		if(WW) then
				WW.destructible = false
			end
		end
	end
end

-- destroy waterways when landfill is build ontop 
function onTileBuild(e)
	if e.item and e.item.name == "landfill" then
		--game.players[1].print("build landfill")
		for _, tile in pairs(e.tiles) do
			local x = tile.position.x
			local y = tile.position.y
			local sww = game.surfaces[e.surface_index].find_entities_filtered{area={{x-0.5, y-0.5},{x+1,y+1}}, name="straight-water-way-placed"}
			local cww = game.surfaces[e.surface_index].find_entities_filtered{area={{x-1.5, y-1.5},{x+1.5,y+1.5}}, name="curved-water-way-placed"}
	
			for _, ww in pairs(sww) do
				ww.destroy()
			end
			for _, ww in pairs(cww) do
				ww.destroy()
			end
		end		
	end
end
--

-- enter or leave ship
function OnEnterShip(e)
	local player_index = e.player_index
	local X = game.players[player_index].position.x
	local Y = game.players[player_index].position.y

	if game.players[player_index].vehicle == nil then
		for dis = 1,10 do
			local indep_boat = game.players[player_index].surface.find_entities_filtered{area={{X-dis, Y-dis}, {X+dis, Y+dis}}, name="indep-boat", limit=1}
			if indep_boat[1] ~= nil then	
				indep_boat[1].set_driver(game.players[player_index])
				break
			end
			local boat = game.players[player_index].surface.find_entities_filtered{area={{X-dis, Y-dis}, {X+dis, Y+dis}}, name="boat_engine", limit=1}
			if boat[1] ~= nil then	
				boat[1].set_driver(game.players[player_index])
				break
			end
			local ship_engine = game.players[player_index].surface.find_entities_filtered{area={{X-dis, Y-dis}, {X+dis, Y+dis}}, name="cargo_ship_engine", limit=1}
			if ship_engine[1] ~= nil then	
				ship_engine[1].set_driver(game.players[player_index])
				break
			end
			--[[
			local ship = game.players[player_index].surface.find_entities_filtered{area={{X-dis, Y-dis}, {X+dis, Y+dis}}, name="cargo_ship", limit=1}
			if ship[1] ~= nil then	
				ship[1].set_driver(game.players[player_index])
				break
			end
			local tanker = game.players[player_index].surface.find_entities_filtered{area={{X-dis, Y-dis}, {X+dis, Y+dis}}, name="oil_tanker", limit=1}
			if tanker[1] ~= nil then	
				tanker[1].set_driver(game.players[player_index])
				break
			end
			]]
		end
	else
		for dis = 1,10 do
			local land = game.players[player_index].surface.find_tiles_filtered{area={{X-dis, Y-dis}, {X+dis, Y+dis}}, collision_mask ="ground-tile"}
 			if land[1] ~= nil then
	 			game.players[player_index].vehicle.set_driver(nil)
	 			game.players[player_index].driving = false
	 			game.players[player_index].teleport(land[1].position)
	 			break
			end
		end
	end
end

-- delete invisible entities if master entity is destroyed
function OnDeleted(e)
	if(e.entity) then
		local ent = e.entity
		if ent.name == "cargo_ship" or ent.name == "oil_tanker" or ent.name == "train_carrier" or ent.name == "boat" then
			if ent.train ~= nil then

				if ent.train.back_stock ~= nil then
					if ent.train.back_stock.name == "cargo_ship_engine" or ent.train.back_stock.name == "boat_engine" then
						ent.train.back_stock.destroy()
					end
				end
				if ent.train.front_stock ~= nil then
					if ent.train.front_stock.name == "cargo_ship_engine" or ent.train.front_stock.name == "boat_engine" then
						ent.train.front_stock.destroy()
					end
				end
			end

		elseif ent.name == "cargo_ship_engine" or ent.name == "boat_engine" then
			if ent.train ~= nil then
				if ent.train.front_stock ~= nil then
					if ent.train.front_stock.name == "cargo_ship"
							or ent.train.front_stock.name == "oil_tanker"
							or ent.train.front_stock.name == "train_carrier"
							or ent.train.front_stock.name == "boat" then
						ent.train.front_stock.destroy()
					end
				end
			end


		elseif ent.name == "oil_rig" then
			local pos = ent.position
			or_inv = game.surfaces[1].find_entities_filtered{area =  {{pos.x-4, pos.y-4},{pos.x+4, pos.y+4}},  name="or_power"}
			for i = 1, #or_inv do
				or_inv[i].destroy()
			end
			or_inv = game.surfaces[1].find_entities_filtered{area =  {{pos.x-4, pos.y-4},{pos.x+4, pos.y+4}},  name="or_lamp"}
			for i = 1, #or_inv do
				or_inv[i].destroy()
			end
			or_inv = game.surfaces[1].find_entities_filtered{area =  {{pos.x-4, pos.y-4},{pos.x+4, pos.y+4}},  name="or_pole"}
			for i = 1, #or_inv do
				or_inv[i].destroy()
			end
			or_inv = game.surfaces[1].find_entities_filtered{area =  {{pos.x-4, pos.y-4},{pos.x+4, pos.y+4}},  name="or_radar"}
			for i = 1, #or_inv do
				or_inv[i].destroy()
			end
		

		elseif string.match(ent.name, "bridge_") then
			DeleteBridge(ent)
		end 
	end
end

-- recover fuel of cargo ship engine
function OnMined(e)
	if(e.entity) then
		if e.entity.name == "cargo_ship" or e.entity.name == "oil_tanker" or e.entity.name == "train_carrier" or e.entity.name == "boat" then
			local ent = e.entity
			local player_index = e.player_index
			local engine
			if ent.train ~= nil then
				if ent.train.back_stock ~= nil then
					if ent.train.back_stock.name == "cargo_ship_engine" or ent.train.back_stock.name == "boat_engine"  then
						local fuel = ent.train.back_stock.get_fuel_inventory().get_contents()
						for f_type,f_amount in pairs(fuel) do
							game.players[player_index].insert{name=f_type, count=f_amount}
						end
					end
				end
				if ent.train.front_stock ~= nil then
					if ent.train.front_stock.name == "cargo_ship_engine" or ent.train.front_stock.name == "boat_engine"  then
						local fuel = ent.train.front_stock.get_fuel_inventory().get_contents()
						for f_type,f_amount in pairs(fuel) do
							game.players[player_index].insert{name=f_type, count=f_amount}
						end
					end
				end
			end
		end
	end
	-- destroy
	OnDeleted(e)
end

-- creat deep sea oil
function placeDeepOil(e)
	local deep_tiles = 0
	if game.active_mods["SeaBlock"] then
		deep_tiles = game.surfaces[1].count_tiles_filtered{area=e.area,name={"water","water-green","deepwater","deepwater-green"}}
	else
		deep_tiles = game.surfaces[1].count_tiles_filtered{area=e.area, name = "deepwater"}
	end
	math.randomseed(e.tick)
	if deep_tiles == 1024 then

		freq = 0.03
		if settings.global["oil_frequency"].value == choices.oil_freq.none then
			freq = 0		
		elseif settings.global["oil_frequency"].value == choices.oil_freq.minimal then
			freq = 0.0008
		elseif settings.global["oil_frequency"].value == choices.oil_freq.v_v_low then
			freq = 0.0025
		elseif settings.global["oil_frequency"].value == choices.oil_freq.v_low then
			freq = 0.0075
		elseif settings.global["oil_frequency"].value == choices.oil_freq.low then
			freq = 0.015
		elseif settings.global["oil_frequency"].value == choices.oil_freq.high then
			freq = 0.06
		elseif settings.global["oil_frequency"].value == choices.oil_freq.v_high then
			freq = 0.12
		end
		freq = freq 	
		mult = 1
		if settings.global["oil_richness"].value == choices.oil_rich.v_poor then
			mult = 0.3
		elseif settings.global["oil_richness"].value == choices.oil_rich.poor then
			mult = 0.7
		elseif settings.global["oil_richness"].value == choices.oil_rich.good then
			mult = 1.8
		elseif settings.global["oil_richness"].value == choices.oil_rich.v_good then
			mult = 3
		end


		local m_x = e.area.left_top.x +16
		local m_y = e.area.left_top.y + 16
		local distance = math.sqrt(m_x*m_x + m_y*m_y)
		distance_mult = 0.5 + distance/4000

		r = math.random()
		if r < freq then
			-- create oil in inner part of tile to avoid deep oil too close to land
			local x = math.random(-10,10)
			local y = math.random(-10,10)
			local pos = {m_x+x, m_y+y}
			local a = (1+freq/(r+(freq/50)))*750000*mult*distance_mult
			game.surfaces[1].create_entity{name="deep_oil", amount=a, position=pos}
		end
	end
end

function powerOilRig(e)
	if e.tick % 120 == 0 then
		if global.or_generators == nil then
			global.or_generators = {}
			for _, generator in pairs(game.surfaces[1].find_entities_filtered{name="or_power"}) do
				table.insert(global.or_generators, generator)
			end
		end
		for i, generator in pairs(global.or_generators) do
			if(generator.valid) then
				generator.fluidbox[1] = {name="steam", amount = 200, temperature=165}
			else
				--game.players[1].print("found ivalid")
				table.remove(global.or_generators,i)
			end
		end
	end
end

function init()
	if global.check_entity_placement == nil then
		global.check_entity_placement = {}
		global.csp = false
	end
	if global.bridges == nil then
		global.bridges = {}
	end
end

function onTick(e)
	powerOilRig(e)
	checkPlacement()
	ManageBridges(e)
end

-- init
script.on_init(init)
script.on_configuration_changed(init)

-- custom commands 
script.on_event("enter_ship", OnEnterShip)

-- delete invisibles
script.on_event(defines.events.on_entity_died, OnDeleted)
script.on_event(defines.events.on_player_mined_entity, OnMined)
script.on_event(defines.events.on_robot_mined_entity, OnDeleted)

--place deep oil
script.on_event(defines.events.on_chunk_generated, placeDeepOil)
-- entity created
script.on_event(defines.events.on_player_built_tile, onTileBuild)
script.on_event(defines.events.on_built_entity, onEntityBuild)
script.on_event(defines.events.on_robot_built_entity, onEntityBuild)
--power oil rig
script.on_event(defines.events.on_tick, onTick)

-- long reach
script.on_event(defines.events.on_runtime_mod_setting_changed, applyChanges)
script.on_event(defines.events.on_player_cursor_stack_changed, increaseReach)
script.on_event(defines.events.on_player_died, deadReach)
