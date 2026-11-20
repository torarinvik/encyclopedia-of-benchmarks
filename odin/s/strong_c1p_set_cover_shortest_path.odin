package strong_c1p_set_cover_shortest_path

import "core:c"

MAX_ROWS :: 8
MAX_COLUMNS :: 10
MAX_INPUT :: c.size_t(21)
INF :: i64(1_000_000_000)

store_i64_le :: proc(output: [^]u8, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[byte] = u8(bits & 255)
		bits >>= 8
	}
}

solve :: proc(rows, columns: int, weights: [MAX_COLUMNS]i64,
	row_left, row_right: [MAX_ROWS]int) -> i64 {
	order: [MAX_ROWS]int = {}
	for row := 0; row < rows; row += 1 { order[row] = row }
	for i := 1; i < rows; i += 1 {
		value := order[i]
		j := i
		for j > 0 && row_left[order[j - 1]] > row_left[value] {
			order[j] = order[j - 1]
			j -= 1
		}
		order[j] = value
	}
	grouped_left, grouped_right: [MAX_ROWS]int = {}, {}
	groups := 0
	for i := 0; i < rows; i += 1 {
		row := order[i]
		if groups == 0 || grouped_left[groups - 1] != row_left[row] {
			grouped_left[groups], grouped_right[groups] = row_left[row], row_right[row]
			groups += 1
		} else if row_right[row] < grouped_right[groups - 1] {
			grouped_right[groups - 1] = row_right[row]
		}
	}
	retained_left, retained_right: [MAX_ROWS]int = {}, {}
	retained := 0
	suffix_minimum := columns
	for offset := 0; offset < groups; offset += 1 {
		i := groups - 1 - offset
		if grouped_right[i] < suffix_minimum {
			retained_left[retained], retained_right[retained] = grouped_left[i], grouped_right[i]
			retained += 1
			suffix_minimum = grouped_right[i]
		}
	}
	column_start, column_end: [MAX_COLUMNS]int = {}, {}
	for column := 0; column < columns; column += 1 {
		column_start[column], column_end[column] = -1, -1
	}
	for reduced_row := 0; reduced_row < retained; reduced_row += 1 {
		source := retained - 1 - reduced_row
		for column := retained_left[source]; column <= retained_right[source]; column += 1 {
			if column_start[column] < 0 { column_start[column] = reduced_row }
			column_end[column] = reduced_row
		}
	}
	distance: [MAX_COLUMNS]i64 = {}
	for column := 0; column < columns; column += 1 {
		distance[column] = INF
		if column_start[column] == 0 { distance[column] = 0 }
	}
	best := INF
	for from := 0; from < columns; from += 1 {
		if distance[from] == INF do continue
		if column_end[from] == retained - 1 && distance[from] + weights[from] < best {
			best = distance[from] + weights[from]
		}
		for to := from + 1; to < columns; to += 1 {
			if column_start[to] >= 0 && column_start[to] <= column_end[from] + 1 {
				candidate := distance[from] + weights[from]
				if candidate < distance[to] { distance[to] = candidate }
			}
		}
	}
	if best == INF { return -1 }
	return best
}

@(export)
strong_c1p_set_cover_shortest_path :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	rows_raw, columns_raw := input[0], input[1]
	if rows_raw < 1 || rows_raw > MAX_ROWS || columns_raw < 1 || columns_raw > MAX_COLUMNS do return -1
	rows, columns := int(rows_raw), int(columns_raw)
	if length != c.size_t(2 + rows + columns) do return -1
	weights: [MAX_COLUMNS]i64 = {}
	for column := 0; column < columns; column += 1 {
		weight := input[2 + column]
		if weight < 1 || weight > 20 do return -1
		weights[column] = weight
	}
	allowed := (u64(1) << columns) - 1
	masks: [MAX_ROWS]u64 = {}
	row_left, row_right: [MAX_ROWS]int = {}, {}
	infeasible := false
	for row := 0; row < rows; row += 1 {
		raw := input[2 + columns + row]
		if raw < 0 || (u64(raw) & ~allowed) != 0 do return -1
		masks[row] = u64(raw)
		row_left[row], row_right[row] = columns, -1
		seen_one, seen_zero_after := false, false
		for column := 0; column < columns; column += 1 {
			if masks[row] & (u64(1) << column) != 0 {
				if seen_zero_after do return -1
				seen_one = true
				if row_left[row] == columns { row_left[row] = column }
				row_right[row] = column
			} else if seen_one { seen_zero_after = true }
		}
		if masks[row] == 0 { infeasible = true }
	}
	result := i64(-1)
	if !infeasible { result = solve(rows, columns, weights, row_left, row_right) }
	if output == nil || capacity < 8 do return -2
	store_i64_le(output, result)
	return 8
}
