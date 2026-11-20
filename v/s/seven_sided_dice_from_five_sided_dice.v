module seven_sided_dice_from_five_sided_dice

const max_draws = 256
const max_input_length = max_draws + 2

@[export: 'seven_sided_dice_from_five_sided_dice']
pub fn seven_sided_dice_from_five_sided_dice(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	draw_count_value := unsafe { input[0] }
	if draw_count_value < 0 || draw_count_value > max_draws ||
		length != usize(draw_count_value + 1) { return -1 }
	draw_count := int(draw_count_value)
	for index in 0 .. draw_count {
		draw := unsafe { input[index + 1] }
		if draw < 0 || draw > 4 { return -1 }
	}

	mut staged := []u8{len: max_draws}
	mut written := 0
	mut value := i64(0)
	mut state_range := i64(1)
	for index in 0 .. draw_count {
		draw := unsafe { input[index + 1] }
		value = 5 * value + draw
		state_range *= 5
		for state_range >= 7 {
			accepted := state_range - state_range % 7
			if value < accepted {
				staged[written] = u8(value % 7 + 1)
				written++
				value /= 7
				state_range = accepted / 7
			} else {
				value -= accepted
				state_range -= accepted
			}
		}
	}

	if unsafe { output == nil } || capacity < usize(written) { return -2 }
	unsafe {
		for index in 0 .. written { output[index] = staged[index] }
	}
	return i64(written)
}
