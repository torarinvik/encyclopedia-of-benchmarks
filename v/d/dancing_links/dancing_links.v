module dancing_links

// Choose the uncovered column with the fewest compatible rows, then branch on it.
fn search(columns int, row_count int, rows [8]u64, covered u64, selected u64,
	mut found [256]bool, mut solution_count int) {
	full_mask := (u64(1) << columns) - u64(1)
	if covered == full_mask {
		index := int(selected)
		if !found[index] {
			found[index] = true
			solution_count++
		}
		return
	}
	mut best_column := columns
	mut best_count := row_count + 1
	for column in 0 .. columns {
		bit := u64(1) << column
		if covered & bit != 0 { continue }
		mut candidates := 0
		for row in 0 .. row_count {
			if rows[row] & bit != 0 && rows[row] & covered == 0 { candidates++ }
		}
		if candidates == 0 { return }
		if candidates < best_count {
			best_column = column
			best_count = candidates
		}
	}
	bit := u64(1) << best_column
	for row in 0 .. row_count {
		row_mask := rows[row]
		if row_mask & bit != 0 && row_mask & covered == 0 {
			search(columns, row_count, rows, covered | row_mask,
				selected | (u64(1) << row), mut found, mut solution_count)
		}
	}
}

// Count exact covers and emit selected-row bitmasks in ascending order.
@[export: 'dancing_links']
pub fn dancing_links(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 10 { return -1 }
	universe_value := unsafe { input[0] }
	row_count_value := unsafe { input[1] }
	if universe_value < 1 || universe_value > 8 || row_count_value < 0 || row_count_value > 8 { return -1 }
	universe := int(universe_value)
	row_count := int(row_count_value)
	if length != usize(row_count + 2) { return -1 }
	full_mask := i64((1 << universe) - 1)
	mut rows := [8]u64{}
	for row in 0 .. row_count {
		mask := unsafe { input[row + 2] }
		if mask <= 0 || (mask & ~full_mask) != 0 { return -1 }
		rows[row] = u64(mask)
	}
	mut found := [256]bool{}
	mut solution_count := 0
	search(universe, row_count, rows, 0, 0, mut found, mut solution_count)
	if output_capacity < usize(solution_count) || (solution_count > 0 && unsafe { output == nil }) { return -2 }
	mut position := 0
	for selection in 0 .. 256 {
		if found[selection] {
			unsafe { output[position] = u8(selection) }
			position++
		}
	}
	return i64(solution_count)
}
