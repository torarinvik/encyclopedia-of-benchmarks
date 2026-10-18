package smith_waterman_python

import "core:c"

MAX_SEQUENCE_LENGTH :: 16
MAX_PARSEABLE_INPUT_LENGTH :: 38
SCORE_STRIDE :: 17
MAX_OUTPUT_BYTES :: 1233

put_u32_le :: proc "contextless" (output: [^]u8, position: ^usize, value: u32) {
	bits := value
	for byte := 0; byte < 4; byte += 1 {
		output[position^] = u8(bits & 255)
		position^ += 1
		bits >>= 8
	}
}

put_i32_le :: proc "contextless" (output: [^]u8, position: ^usize, value: i64) {
	put_u32_le(output, position, transmute(u32)i32(value))
}

@(export)
smith_waterman_python :: proc "c" (input: [^]i64, input_length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	query_length_value, subject_length_value := input[0], input[1]
	match_score, mismatch_score, gap_score := input[2], input[3], input[4]
	if query_length_value < 0 || query_length_value > MAX_SEQUENCE_LENGTH ||
		subject_length_value < 0 || subject_length_value > MAX_SEQUENCE_LENGTH ||
		match_score < 1 || match_score > 5 || mismatch_score < -5 || mismatch_score > -1 ||
		gap_score < -5 || gap_score > -1 do return -1
	query_length, subject_length := int(query_length_value), int(subject_length_value)
	if input_length != c.size_t(5 + query_length + subject_length) do return -1

	query: [MAX_SEQUENCE_LENGTH]u8 = {}
	subject: [MAX_SEQUENCE_LENGTH]u8 = {}
	for index := 0; index < query_length + subject_length; index += 1 {
		value := input[5 + index]
		if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122) || value == 45) do return -1
		if value >= 97 && value <= 122 do value -= 32
		if index < query_length do query[index] = u8(value) else subject[index-query_length] = u8(value)
	}

	scores: [SCORE_STRIDE*SCORE_STRIDE]i64 = {}
	for row := 1; row <= query_length; row += 1 {
		for column := 1; column <= subject_length; column += 1 {
			query_char, subject_char := query[row-1], subject[column-1]
			pair_score := mismatch_score
			if query_char == u8('-') || subject_char == u8('-') do pair_score = gap_score
		else if query_char == subject_char do pair_score = match_score
			diagonal := scores[(row-1)*SCORE_STRIDE+column-1] + pair_score
			above := scores[(row-1)*SCORE_STRIDE+column] + gap_score
			left := scores[row*SCORE_STRIDE+column-1] + gap_score
			value := max(0, max(diagonal, max(above, left)))
			scores[row*SCORE_STRIDE+column] = value
		}
	}

	maximum: i64 = -1
	maximum_row, maximum_column := 0, 0
	for row := 0; row <= query_length; row += 1 {
		for column := 0; column <= subject_length; column += 1 {
			value := scores[row*SCORE_STRIDE+column]
			if value > maximum {
				maximum = value
				maximum_row, maximum_column = row, column
			}
		}
	}

	trace_query: [2*MAX_SEQUENCE_LENGTH]u8 = {}
	trace_subject: [2*MAX_SEQUENCE_LENGTH]u8 = {}
	trace_length := 0
	row, column := maximum_row, maximum_column
	for row > 0 && column > 0 {
		query_char, subject_char := query[row-1], subject[column-1]
		pair_score: i64 = -1
		if query_char == u8('-') || subject_char == u8('-') do pair_score = -2
		else if query_char == subject_char do pair_score = 1
		diagonal_score := scores[(row-1)*SCORE_STRIDE+column-1] + pair_score
		current_score := scores[row*SCORE_STRIDE+column]
		if current_score == diagonal_score {
			trace_query[trace_length], trace_subject[trace_length] = query_char, subject_char
			row -= 1
			column -= 1
		} else if current_score == scores[(row-1)*SCORE_STRIDE+column]-2 {
			trace_query[trace_length], trace_subject[trace_length] = query_char, u8('-')
			row -= 1
		} else {
			trace_query[trace_length], trace_subject[trace_length] = u8('-'), subject_char
			column -= 1
		}
		trace_length += 1
	}

	staged: [MAX_OUTPUT_BYTES]u8 = {}
	position: usize = 0
	put_u32_le(&staged[0], &position, u32(query_length+1))
	put_u32_le(&staged[0], &position, u32(subject_length+1))
	for matrix_row := 0; matrix_row <= query_length; matrix_row += 1 {
		for matrix_column := 0; matrix_column <= subject_length; matrix_column += 1 {
			put_i32_le(&staged[0], &position, scores[matrix_row*SCORE_STRIDE+matrix_column])
		}
	}
	alignment_length := 0
	if trace_length > 0 do alignment_length = 2*trace_length + 1
	put_u32_le(&staged[0], &position, u32(alignment_length))
	for index := 0; index < trace_length; index += 1 {
		staged[position] = trace_query[trace_length-1-index]
		position += 1
	}
	if trace_length > 0 {
		staged[position] = u8('\n')
		position += 1
	}
	for index := 0; index < trace_length; index += 1 {
		staged[position] = trace_subject[trace_length-1-index]
		position += 1
	}

	if output == nil || output_capacity < c.size_t(position) do return -2
	for index := 0; index < position; index += 1 { output[index] = staged[index] }
	return i64(position)
}
