package seven_sided_dice_from_five_sided_dice

import "core:c"

MAX_DRAWS :: 256
MAX_INPUT_LENGTH :: MAX_DRAWS + 2

@(export)
seven_sided_dice_from_five_sided_dice :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	draw_count_value := input[0]
	if draw_count_value < 0 || draw_count_value > MAX_DRAWS ||
		length != c.size_t(draw_count_value + 1) do return -1
	draw_count := int(draw_count_value)
	for index := 0; index < draw_count; index += 1 {
		if input[index + 1] < 0 || input[index + 1] > 4 do return -1
	}

	staged: [MAX_DRAWS]u8
	written := 0
	value: i64 = 0
	state_range: i64 = 1
	for index := 0; index < draw_count; index += 1 {
		value = 5 * value + input[index + 1]
		state_range *= 5
		for state_range >= 7 {
			accepted := state_range - state_range % 7
			if value < accepted {
				staged[written] = u8(value % 7 + 1)
				written += 1
				value /= 7
				state_range = accepted / 7
			} else {
				value -= accepted
				state_range -= accepted
			}
		}
	}

	if output == nil || capacity < c.size_t(written) do return -2
	for index := 0; index < written; index += 1 {
		output[index] = staged[index]
	}
	return i64(written)
}
