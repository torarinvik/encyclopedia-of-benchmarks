module dancing_links

// Count exact covers and emit selected-row bitmasks in ascending order.
@[export: 'dancing_links']
pub fn dancing_links(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	universe_value := unsafe { input[0] }
	row_count_value := unsafe { input[1] }
	if universe_value < 1 || universe_value > 8 || row_count_value < 0 || row_count_value > 8 { return -1 }
	universe := int(universe_value)
	row_count := int(row_count_value)
	if length != usize(row_count + 2) { return -1 }
	full_mask := i64((1 << universe) - 1)
	for row in 0 .. row_count {
		mask := unsafe { input[row + 2] }
		if mask <= 0 || (mask & ~full_mask) != 0 { return -1 }
	}
	selection_limit := 1 << row_count
	mut solution_count := 0
	for selection in 0 .. selection_limit {
		mut covered := i64(0)
		mut valid := true
		for row in 0 .. row_count {
			if (selection & (1 << row)) == 0 { continue }
			mask := unsafe { input[row + 2] }
			if (covered & mask) != 0 { valid = false; break }
			covered |= mask
		}
		if valid && covered == full_mask { solution_count++ }
	}
	if output_capacity < usize(solution_count) || (solution_count > 0 && unsafe { output == nil }) { return -2 }
	mut position := 0
	for selection in 0 .. selection_limit {
		mut covered := i64(0)
		mut valid := true
		for row in 0 .. row_count {
			if (selection & (1 << row)) == 0 { continue }
			mask := unsafe { input[row + 2] }
			if (covered & mask) != 0 { valid = false; break }
			covered |= mask
		}
		if valid && covered == full_mask {
			unsafe { output[position] = u8(selection) }
			position++
		}
	}
	return i64(solution_count)
}
