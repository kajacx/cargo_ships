
-- change collision mask of boat if it was changed by hovercraft mod:

data.raw["car"]["indep-boat"].collision_mask = {"ground-tile", "train-layer", "layer-13"}


-- adjust layers of all train entites to either collide with closed or open bridge
for i,loco in pairs(data.raw["locomotive"]) do
	if loco.name == "boat_engine" or loco.name == "cargo_ship_engine" then
		if(loco.collision_mask) then
			loco.collision_mask[#loco.collision_mask+1] = "layer-14"
		else
			collision_mask = {"layer-14"}
		end
	else
		if(loco.collision_mask) then
			loco.collision_mask[#loco.collision_mask+1] = "layer-13"
		else
			collision_mask = {"layer-13"}
		end
	end
end

for i,cargo in pairs(data.raw["cargo-wagon"]) do
	if cargo.name == "cargo_ship" or cargo.name == "boat" or cargo.name == "train_carrier" then
		if(cargo.collision_mask) then
			cargo.collision_mask[#cargo.collision_mask+1] = "layer-14"
		else
			collision_mask = {"layer-14"}
		end
	else
		if(cargo.collision_mask) then
			cargo.collision_mask[#cargo.collision_mask+1] = "layer-13"
		else
			collision_mask = {"layer-13"}
		end
	end
end

for i,tanker in pairs(data.raw["fluid-wagon"]) do
	if tanker.name == "tanker_ship" then
		if(tanker.collision_mask) then
			tanker.collision_mask[#tanker.collision_mask+1] = "layer-14"
		else
			collision_mask = {"layer-14"}
		end
	else
		if(tanker.collision_mask) then
			tanker.collision_mask[#tanker.collision_mask+1] = "layer-13"
		else
			collision_mask = {"layer-13"}
		end
	end
end


