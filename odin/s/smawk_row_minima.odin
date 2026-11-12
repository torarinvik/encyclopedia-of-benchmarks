package smawk_row_minima

import "core:c"

MAX_ROWS :: 16
MAX_COLUMNS :: 16
MAX_INPUT_LENGTH :: 260

smawk :: proc(input: [^]i64, column_count: int,
		row_work: [^]i32, row_offset, row_count: int,
		column_work: [^]i32, input_column_offset, input_column_count: int,
		output_column_offset: int, minima: [^]i32) {
	if row_count == 0 { return }
	if row_count == 1 {
		row := int(row_work[row_offset])
		best := int(column_work[input_column_offset])
		for j := 1; j < input_column_count; j += 1 {
			candidate := int(column_work[input_column_offset+j])
			if input[2+row*column_count+candidate] < input[2+row*column_count+best] { best = candidate }
		}
		minima[row] = i32(best)
		return
	}

	reduced_count := 0
	for j := 0; j < input_column_count; j += 1 {
		candidate := column_work[input_column_offset+j]
		for reduced_count > 0 {
			comparison_row := int(row_work[row_offset+reduced_count-1])
			previous := int(column_work[output_column_offset+reduced_count-1])
			if input[2+comparison_row*column_count+int(candidate)] < input[2+comparison_row*column_count+previous] { reduced_count -= 1 }
			else { break }
		}
		if reduced_count < row_count {
			column_work[output_column_offset+reduced_count] = candidate
			reduced_count += 1
		}
	}

	odd_offset := row_offset + row_count
	odd_count := 0
	for i := 1; i < row_count; i += 2 {
		row_work[odd_offset+odd_count] = row_work[row_offset+i]
		odd_count += 1
	}
	child_output_offset := output_column_offset + reduced_count
	smawk(input, column_count, row_work, odd_offset, odd_count,
		column_work, output_column_offset, reduced_count, child_output_offset, minima)

	start_cursor := 0
	end_cursor := 0
	for i := 0; i < row_count; i += 2 {
		start := 0
		if i > 0 {
			target := minima[int(row_work[row_offset+i-1])]
			for start_cursor < reduced_count && column_work[output_column_offset+start_cursor] != target { start_cursor += 1 }
			start = min(start_cursor, reduced_count-1)
		}
		last := reduced_count - 1
		if i+1 < row_count {
			target := minima[int(row_work[row_offset+i+1])]
			if end_cursor < start { end_cursor = start }
			for end_cursor < reduced_count && column_work[output_column_offset+end_cursor] != target { end_cursor += 1 }
			last = min(end_cursor, reduced_count-1)
		}
		row := int(row_work[row_offset+i])
		best := int(column_work[output_column_offset+start])
		for position := start+1; position <= last; position += 1 {
			candidate := int(column_work[output_column_offset+position])
			if input[2+row*column_count+candidate] < input[2+row*column_count+best] { best = candidate }
		}
		minima[row] = i32(best)
	}
}

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits >> (byte*8)) & 255) }
}

@(export, link_name="smawk_row_minima")
smawk_row_minima :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 1 || input[0] > MAX_ROWS || input[1] < 1 || input[1] > MAX_COLUMNS do return -1
	row_count := int(input[0])
	column_count := int(input[1])
	if length != c.size_t(2+row_count*column_count) do return -1

	row_work: [2*MAX_ROWS]i32
	column_work: [3*MAX_COLUMNS]i32
	minima: [MAX_ROWS]i32
	for i := 0; i < row_count; i += 1 { row_work[i] = i32(i) }
	for j := 0; j < column_count; j += 1 { column_work[j] = i32(j) }
	smawk(input, column_count, &row_work[0], 0, row_count,
		&column_work[0], 0, column_count, MAX_COLUMNS, &minima[0])

	output_bytes := row_count*8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	staged: [8*MAX_ROWS]u8
	for i := 0; i < row_count; i += 1 { store_i64_le(&staged[0], i*8, i64(minima[i])) }
	for i := 0; i < output_bytes; i += 1 { output[i] = staged[i] }
	return i64(output_bytes)
}
