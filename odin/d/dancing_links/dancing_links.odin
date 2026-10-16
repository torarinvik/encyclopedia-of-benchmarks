package dancing_links

import "core:c"

// Count exact covers and emit selected-row bitmasks in ascending order.
@(export)
dancing_links :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	universe_value := input[0]
	row_count_value := input[1]
	if universe_value < 1 || universe_value > 8 || row_count_value < 0 || row_count_value > 8 do return -1
	universe := c.size_t(universe_value)
	row_count := c.size_t(row_count_value)
	if length != row_count + 2 do return -1
	full_mask := (i64(1) << universe) - 1
	for row: c.size_t = 0; row < row_count; row += 1 {
		mask := input[row + 2]
		if mask <= 0 || (mask & ~full_mask) != 0 do return -1
	}
	selection_limit := c.size_t(1) << row_count
	solution_count: c.size_t = 0
	for selection: c.size_t = 0; selection < selection_limit; selection += 1 {
		covered: i64 = 0
		valid := true
		for row: c.size_t = 0; row < row_count; row += 1 {
			if (selection & (c.size_t(1) << row)) == 0 do continue
			mask := input[row + 2]
			if (covered & mask) != 0 { valid = false; break }
			covered |= mask
		}
		if valid && covered == full_mask do solution_count += 1
	}
	if output_capacity < solution_count || (solution_count > 0 && output == nil) do return -2
	position: c.size_t = 0
	for selection: c.size_t = 0; selection < selection_limit; selection += 1 {
		covered: i64 = 0
		valid := true
		for row: c.size_t = 0; row < row_count; row += 1 {
			if (selection & (c.size_t(1) << row)) == 0 do continue
			mask := input[row + 2]
			if (covered & mask) != 0 { valid = false; break }
			covered |= mask
		}
		if valid && covered == full_mask {
			output[position] = u8(selection)
			position += 1
		}
	}
	return i64(solution_count)
}
