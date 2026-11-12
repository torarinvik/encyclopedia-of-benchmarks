module smawk_row_minima

const max_rows = 16
const max_columns = 16
const max_input_length = 260

fn smawk(input &i64, column_count int, mut row_work [2 * max_rows]i32,
	row_offset int, row_count int, mut column_work [3 * max_columns]i32,
	input_column_offset int, input_column_count int, output_column_offset int,
	mut minima [max_rows]i32) {
	if row_count == 0 { return }
	if row_count == 1 {
		row := int(row_work[row_offset])
		mut best := int(column_work[input_column_offset])
		for j in 1 .. input_column_count {
			candidate := int(column_work[input_column_offset + j])
			if unsafe { input[2 + row * column_count + candidate] < input[2 + row * column_count + best] } { best = candidate }
		}
		minima[row] = i32(best)
		return
	}

	mut reduced_count := 0
	for j in 0 .. input_column_count {
		candidate := column_work[input_column_offset + j]
		for reduced_count > 0 {
			comparison_row := int(row_work[row_offset + reduced_count - 1])
			previous := int(column_work[output_column_offset + reduced_count - 1])
			if unsafe { input[2 + comparison_row * column_count + int(candidate)] < input[2 + comparison_row * column_count + previous] } { reduced_count-- }
			else { break }
		}
		if reduced_count < row_count {
			column_work[output_column_offset + reduced_count] = candidate
			reduced_count++
		}
	}

	odd_offset := row_offset + row_count
	mut odd_count := 0
	for i := 1; i < row_count; i += 2 {
		row_work[odd_offset + odd_count] = row_work[row_offset + i]
		odd_count++
	}
	child_output_offset := output_column_offset + reduced_count
	smawk(input, column_count, mut row_work, odd_offset, odd_count,
		mut column_work, output_column_offset, reduced_count, child_output_offset, mut minima)

	mut start_cursor := 0
	mut end_cursor := 0
	for i := 0; i < row_count; i += 2 {
		mut start := 0
		if i > 0 {
			target := minima[int(row_work[row_offset + i - 1])]
			for start_cursor < reduced_count && column_work[output_column_offset + start_cursor] != target { start_cursor++ }
			start = if start_cursor < reduced_count { start_cursor } else { reduced_count - 1 }
		}
		mut last := reduced_count - 1
		if i + 1 < row_count {
			target := minima[int(row_work[row_offset + i + 1])]
			if end_cursor < start { end_cursor = start }
			for end_cursor < reduced_count && column_work[output_column_offset + end_cursor] != target { end_cursor++ }
			last = if end_cursor < reduced_count { end_cursor } else { reduced_count - 1 }
		}
		row := int(row_work[row_offset + i])
		mut best := int(column_work[output_column_offset + start])
		for position := start + 1; position <= last; position++ {
			candidate := int(column_work[output_column_offset + position])
			if unsafe { input[2 + row * column_count + candidate] < input[2 + row * column_count + best] } { best = candidate }
		}
		minima[row] = i32(best)
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) } }
}

@[export: 'smawk_row_minima']
pub fn smawk_row_minima(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input_length { return -1 }
		if input[0] < 1 || input[0] > max_rows || input[1] < 1 || input[1] > max_columns { return -1 }
		row_count := int(input[0])
		column_count := int(input[1])
		if length != 2 + row_count * column_count { return -1 }

		mut row_work := [2 * max_rows]i32{}
		mut column_work := [3 * max_columns]i32{}
		mut minima := [max_rows]i32{}
		for i in 0 .. row_count { row_work[i] = i32(i) }
		for j in 0 .. column_count { column_work[j] = i32(j) }
		smawk(input, column_count, mut row_work, 0, row_count,
			mut column_work, 0, column_count, max_columns, mut minima)

		output_bytes := row_count * 8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut staged := [8 * max_rows]u8{}
		for i in 0 .. row_count { store_i64_le(mut &staged[0], i * 8, i64(minima[i])) }
		for i in 0 .. output_bytes { output[i] = staged[i] }
		return i64(output_bytes)
	}
}
