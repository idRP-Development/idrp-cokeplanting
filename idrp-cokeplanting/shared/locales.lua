local Locales = {
	['place_sapling'] = 'Placing Sapling..',
	['canceled'] = 'Canceled..',
	['place_or_cancel'] = '[E] - Place Plant / [G] - Cancel',
	['missing_filling_water'] = 'You are missing something to fill the water..',
	['missing_water'] = 'You are missing something to water the plant..',
	['missing_fertilizer'] = 'You don\'t have any fertilizer..',
	['missing_mseed'] = 'You don\'t have a male seed..',
	['clear_plant'] = 'Clearing Plant..',
	['harvesting_plant'] = 'Harvesting Plant..',
	['watering_plant'] = 'Watering Plant..',
	['filling_water'] = 'Filling Water..',
	['fertilizing_plant'] = 'Adding fertilizer to the plant..',
	['check_plant'] = 'Check Plant',
	['plant_header'] = 'Coca Plant',
	['empty_watering_can_header'] = 'Watering Can',
	['esc_to_close'] = 'ESC or Click to Close',
	['filled_can'] = 'You\'ve filled the watering can..',
	['watered_plant'] = 'You\'ve watered the plant..',
	['fertilizer_added'] = 'You\'ve added fertilizer to the plant..',
	['ready_for_harvest'] = 'This plant is ready for harvest!',
	['clear_plant_header'] = 'Clear Plant',
	['fill_can_header'] = 'Fill watering can',
	['fill_can_text'] = 'Fill the watering can with water..',
	['clear_plant_text'] = 'The plant is dead..',
	['destroy_plant'] = 'Destroy Plant',
	['add_water'] = 'Add water to this plant',
	['add_fertilizer'] = 'Add fertilizer to the plant',
	['police_burn'] = 'Burn the plant.',
}

function _U(entry)
	return Locales[entry]
end
