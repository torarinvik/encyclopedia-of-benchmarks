module strong_c1p_set_cover_shortest_path

const max_rows = 8
const max_columns = 10
const max_input = 21
const inf = i64(1000000000)

fn store_i64_le(mut output &u8, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[byte] = u8((bits >> (8 * byte)) & 255) }
}

fn solve(rows int, columns int, weights []i64, row_left []int, row_right []int) i64 {
	mut order := []int{len: rows}
	for row in 0 .. rows { order[row] = row }
	for i in 1 .. rows {
		value := order[i]
		mut j := i
		for j > 0 && row_left[order[j - 1]] > row_left[value] {
			order[j] = order[j - 1]
			j--
		}
		order[j] = value
	}
	mut grouped_left := []int{len: max_rows}
	mut grouped_right := []int{len: max_rows}
	mut groups := 0
	for i in 0 .. rows {
		row := order[i]
		if groups == 0 || grouped_left[groups - 1] != row_left[row] {
			grouped_left[groups] = row_left[row]
			grouped_right[groups] = row_right[row]
			groups++
		} else if row_right[row] < grouped_right[groups - 1] {
			grouped_right[groups - 1] = row_right[row]
		}
	}
	mut retained_left := []int{len: max_rows}
	mut retained_right := []int{len: max_rows}
	mut retained := 0
	mut suffix_minimum := columns
	for offset in 0 .. groups {
		i := groups - 1 - offset
		if grouped_right[i] < suffix_minimum {
			retained_left[retained] = grouped_left[i]
			retained_right[retained] = grouped_right[i]
			retained++
			suffix_minimum = grouped_right[i]
		}
	}
	mut column_start := []int{len: max_columns, init: -1}
	mut column_end := []int{len: max_columns, init: -1}
	for reduced_row in 0 .. retained {
		source := retained - 1 - reduced_row
		for column in retained_left[source] .. retained_right[source] + 1 {
			if column_start[column] < 0 { column_start[column] = reduced_row }
			column_end[column] = reduced_row
		}
	}
	mut distance := []i64{len: max_columns, init: inf}
	for column in 0 .. columns {
		if column_start[column] == 0 { distance[column] = 0 }
	}
	mut best := inf
	for from in 0 .. columns {
		if distance[from] == inf { continue }
		if column_end[from] == retained - 1 { best = min(best, distance[from] + weights[from]) }
		for to in from + 1 .. columns {
			if column_start[to] >= 0 && column_start[to] <= column_end[from] + 1 {
				distance[to] = min(distance[to], distance[from] + weights[from])
			}
		}
	}
	if best == inf { return -1 }
	return best
}

@[export: 'strong_c1p_set_cover_shortest_path']
pub fn strong_c1p_set_cover_shortest_path(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > max_input { return -1 }
		rows_raw := input[0]
		columns_raw := input[1]
		if rows_raw < 1 || rows_raw > max_rows || columns_raw < 1 || columns_raw > max_columns ||
			length != usize(2 + rows_raw + columns_raw) { return -1 }
		rows := int(rows_raw)
		columns := int(columns_raw)
		mut weights := []i64{len: max_columns}
		for column in 0 .. columns {
			weight := input[2 + column]
			if weight < 1 || weight > 20 { return -1 }
			weights[column] = weight
		}
		allowed := (u64(1) << columns) - 1
		mut masks := []u64{len: max_rows}
		mut row_left := []int{len: max_rows}
		mut row_right := []int{len: max_rows}
		mut infeasible := false
		for row in 0 .. rows {
			raw := input[2 + columns + row]
			if raw < 0 || (u64(raw) & ~allowed) != 0 { return -1 }
			masks[row] = u64(raw)
			row_left[row] = columns
			row_right[row] = -1
			mut seen_one := false
			mut seen_zero_after := false
			for column in 0 .. columns {
				if (masks[row] & (u64(1) << column)) != 0 {
					if seen_zero_after { return -1 }
					seen_one = true
					if row_left[row] == columns { row_left[row] = column }
					row_right[row] = column
				} else if seen_one { seen_zero_after = true }
			}
			if masks[row] == 0 { infeasible = true }
		}
		result := if infeasible { i64(-1) } else { solve(rows, columns, weights, row_left, row_right) }
		if output == nil || capacity < 8 { return -2 }
		mut bits := u64(result)
		for byte in 0 .. 8 { output[byte] = u8(bits & 255); bits >>= 8 }
		return 8
	}
}
