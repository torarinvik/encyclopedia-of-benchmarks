package dancing_links

import "core:c"

search :: proc "contextless" (columns, row_count: int, rows: ^[8]u64,
        covered, selected: u64, found: ^[256]bool, solution_count: ^int) {
	full_mask := (u64(1) << u32(columns)) - 1
	if covered == full_mask {
		index := int(selected)
		if !found^[index] {
			found^[index] = true
			solution_count^ += 1
		}
		return
	}
	best_column := columns
	best_count := row_count + 1
	for column := 0; column < columns; column += 1 {
		bit := u64(1) << u32(column)
		if covered & bit != 0 do continue
		candidates := 0
		for row := 0; row < row_count; row += 1 {
			if rows^[row] & bit != 0 && rows^[row] & covered == 0 do candidates += 1
		}
		if candidates == 0 do return
		if candidates < best_count { best_column = column; best_count = candidates }
	}
	bit := u64(1) << u32(best_column)
	for row := 0; row < row_count; row += 1 {
		if rows^[row] & bit != 0 && rows^[row] & covered == 0 {
			search(columns, row_count, rows, covered | rows^[row],
				selected | (u64(1) << u32(row)), found, solution_count)
		}
	}
}

// Count exact covers with Algorithm X's minimum-column recursion.
@(export)
dancing_links :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 10 do return -1
	universe_value := input[0]
	row_count_value := input[1]
	if universe_value < 1 || universe_value > 8 || row_count_value < 0 || row_count_value > 8 do return -1
	if length != c.size_t(row_count_value + 2) do return -1
	columns := int(universe_value)
	row_count := int(row_count_value)
	full_mask := (u64(1) << u32(columns)) - 1
	rows: [8]u64 = {}
	for row := 0; row < row_count; row += 1 {
		value := input[row + 2]
		if value <= 0 || u64(value) & ~full_mask != 0 do return -1
		rows[row] = u64(value)
	}
	found: [256]bool = {}
	solution_count := 0
	search(columns, row_count, &rows, 0, 0, &found, &solution_count)
	if output_capacity < c.size_t(solution_count) || (solution_count > 0 && output == nil) do return -2
	position := 0
	for selection := 0; selection < 256; selection += 1 {
		if found[selection] {
			output[position] = u8(selection)
			position += 1
		}
	}
	return i64(solution_count)
}
