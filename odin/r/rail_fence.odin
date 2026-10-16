package rail_fence

import "core:c"

rail_for_position :: proc(position, rails: int) -> int {
	period := 2 * (rails - 1)
	phase := position % period
	if phase < rails do return phase
	return period - phase
}

@(export)
rail_fence :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 260 do return -1
	if input[0] < 0 || input[0] > 1 || input[1] < 2 || input[1] > 8 do return -1
	if input[2] < 0 || input[2] > 256 do return -1
	mode := int(input[0])
	rails := int(input[1])
	n := int(input[2])
	if length != c.size_t(n + 3) do return -1
	for i := 0; i < n; i += 1 {
		if input[i + 3] < 0 || input[i + 3] > 127 do return -1
	}
	if output == nil || output_capacity < c.size_t(n) do return -2

	if mode == 0 {
		out_index := 0
		for rail := 0; rail < rails; rail += 1 {
			for position := 0; position < n; position += 1 {
				if rail_for_position(position, rails) == rail {
					output[out_index] = u8(input[position + 3])
					out_index += 1
				}
			}
		}
	} else {
		counts: [8]int = {}
		starts: [8]int = {}
		used: [8]int = {}
		for position := 0; position < n; position += 1 {
			counts[rail_for_position(position, rails)] += 1
		}
		for rail := 1; rail < rails; rail += 1 {
			starts[rail] = starts[rail - 1] + counts[rail - 1]
		}
		for position := 0; position < n; position += 1 {
			rail := rail_for_position(position, rails)
			output[position] = u8(input[3 + starts[rail] + used[rail]])
			used[rail] += 1
		}
	}
	return i64(n)
}
