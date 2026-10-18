package smith_waterman_rust

import "core:c"

MAX_SEQUENCE_LENGTH :: 16
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(38)
MAX_OUTPUT_BYTES :: 1233
MATRIX_STRIDE :: 17
MATRIX_CELLS :: 289
MAX_TRACE_STEPS :: 32

write_u32_le :: proc(output: [^]u8, offset: int, value: u32) {
	bits := value
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

write_i32_le :: proc(output: [^]u8, offset: int, value: i64) {
	write_u32_le(output, offset, u32(i32(value)))
}

@(export)
smith_waterman_rust :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	query_length_value, subject_length_value := input[0], input[1]
	match_score, mismatch_score, gap_score := input[2], input[3], input[4]
	if query_length_value < 0 || query_length_value > MAX_SEQUENCE_LENGTH ||
		subject_length_value < 0 || subject_length_value > MAX_SEQUENCE_LENGTH ||
		match_score < 1 || match_score > 5 || mismatch_score < -5 || mismatch_score > -1 ||
		gap_score < -5 || gap_score > -1 do return -1
	query_length, subject_length := int(query_length_value), int(subject_length_value)
	if length != c.size_t(5 + query_length + subject_length) do return -1

	var query: [16]u8
	var subject: [16]u8
	for index := 0; index < query_length + subject_length; index += 1 {
		value := input[index + 5]
		if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122) || value == 45) do return -1
		upper := value
		if value >= 97 do upper -= 32
		if index < query_length {
			query[index] = u8(upper)
		} else {
			subject[index-query_length] = u8(upper)
		}
	}

	var scores: [MATRIX_CELLS]i64
	for row := 1; row < query_length + 1; row += 1 {
		for column := 1; column < subject_length + 1; column += 1 {
			query_char, subject_char := i64(query[row-1]), i64(subject[column-1])
			pair_score := mismatch_score
			if query_char == 45 || subject_char == 45 {
				pair_score = gap_score
			} else if query_char == subject_char {
				pair_score = match_score
			}
			diagonal := scores[(row-1)*MATRIX_STRIDE+column-1] + pair_score
			above := scores[(row-1)*MATRIX_STRIDE+column] + gap_score
			left := scores[row*MATRIX_STRIDE+column-1] + gap_score
			value := i64(0)
			if diagonal > value do value = diagonal
			if above > value do value = above
			if left > value do value = left
			scores[row*MATRIX_STRIDE+column] = value
		}
	}

	maximum := i64(0)
	maximum_row, maximum_column := 0, 0
	for row := 0; row < query_length + 1; row += 1 {
		for column := 0; column < subject_length + 1; column += 1 {
			value := scores[row*MATRIX_STRIDE+column]
			if value > maximum {
				maximum = value
				maximum_row, maximum_column = row, column
			}
		}
	}

	var align_query: [MAX_TRACE_STEPS]u8
	var align_subject: [MAX_TRACE_STEPS]u8
	trace_count := 0
	row, column := maximum_row, maximum_column
	for row > 0 && column > 0 && scores[row*MATRIX_STRIDE+column] > 0 {
		current := scores[row*MATRIX_STRIDE+column]
		query_char, subject_char := i64(query[row-1]), i64(subject[column-1])
		pair_score := mismatch_score
		if query_char == 45 || subject_char == 45 {
			pair_score = gap_score
		} else if query_char == subject_char {
			pair_score = match_score
		}
		diagonal := scores[(row-1)*MATRIX_STRIDE+column-1] + pair_score
		if current == diagonal {
			align_query[trace_count] = query[row-1]
			align_subject[trace_count] = subject[column-1]
			row -= 1
			column -= 1
		} else if current == scores[(row-1)*MATRIX_STRIDE+column] + gap_score {
			align_query[trace_count] = query[row-1]
			align_subject[trace_count] = u8(45)
			row -= 1
		} else {
			align_query[trace_count] = u8(45)
			align_subject[trace_count] = subject[column-1]
			column -= 1
		}
		trace_count += 1
	}

	rows, columns := query_length+1, subject_length+1
	alignment_length := 0
	if trace_count > 0 do alignment_length = trace_count*2 + 1
	payload_length := 8 + rows*columns*4 + 4 + alignment_length
	if payload_length > MAX_OUTPUT_BYTES do return -1
	if output == nil || output_capacity < c.size_t(payload_length) do return -2

	var payload: [MAX_OUTPUT_BYTES]u8
	position := 0
	write_u32_le(&payload[0], position, u32(rows))
	position += 4
	write_u32_le(&payload[0], position, u32(columns))
	position += 4
	for matrix_row := 0; matrix_row < rows; matrix_row += 1 {
		for matrix_column := 0; matrix_column < columns; matrix_column += 1 {
			write_i32_le(&payload[0], position, scores[matrix_row*MATRIX_STRIDE+matrix_column])
			position += 4
		}
	}
	write_u32_le(&payload[0], position, u32(alignment_length))
	position += 4
	if trace_count > 0 {
		for index := 0; index < trace_count; index += 1 {
			payload[position+index] = align_query[trace_count-index-1]
		}
		payload[position+trace_count] = u8(10)
		for index := 0; index < trace_count; index += 1 {
			payload[position+trace_count+1+index] = align_subject[trace_count-index-1]
		}
	}
	for index := 0; index < payload_length; index += 1 {
		output[index] = payload[index]
	}
	return i64(payload_length)
}
