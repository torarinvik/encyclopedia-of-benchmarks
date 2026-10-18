module smith_waterman_python

const max_sequence_length = 16
const max_parseable_input_length = 38
const score_stride = 17
const max_output_bytes = 1233

fn put_u32_le(mut output &u8, offset int, value u32) {
	mut bits := value
	unsafe {
		for byte in 0 .. 4 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

fn put_i32_le(mut output &u8, offset int, value i64) {
	put_u32_le(mut output, offset, u32(i32(value)))
}

@[export: 'smith_waterman_python']
pub fn smith_waterman_python(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 5 || input_length > max_parseable_input_length { return -1 }
		query_length_value, subject_length_value := input[0], input[1]
		match_score, mismatch_score, gap_score := input[2], input[3], input[4]
		if query_length_value < 0 || query_length_value > max_sequence_length ||
			subject_length_value < 0 || subject_length_value > max_sequence_length ||
			match_score < 1 || match_score > 5 || mismatch_score < -5 || mismatch_score > -1 ||
			gap_score < -5 || gap_score > -1 { return -1 }
		query_length, subject_length := int(query_length_value), int(subject_length_value)
		if input_length != usize(5 + query_length + subject_length) { return -1 }

		mut query := [max_sequence_length]u8{}
		mut subject := [max_sequence_length]u8{}
		for index in 0 .. query_length + subject_length {
			mut value := input[5 + index]
			if !((value >= 65 && value <= 90) || (value >= 97 && value <= 122) || value == 45) { return -1 }
			if value >= 97 && value <= 122 { value -= 32 }
			if index < query_length { query[index] = u8(value) } else { subject[index - query_length] = u8(value) }
		}

		mut scores := [score_stride * score_stride]i64{}
		for row in 1 .. query_length + 1 {
			for column in 1 .. subject_length + 1 {
				query_char, subject_char := query[row - 1], subject[column - 1]
				mut pair_score := mismatch_score
				if query_char == u8('-') || subject_char == u8('-') { pair_score = gap_score }
				else if query_char == subject_char { pair_score = match_score }
				diagonal := scores[(row - 1) * score_stride + column - 1] + pair_score
				above := scores[(row - 1) * score_stride + column] + gap_score
				left := scores[row * score_stride + column - 1] + gap_score
				scores[row * score_stride + column] = max(i64(0), max(diagonal, max(above, left)))
			}
		}

		mut maximum := i64(-1)
		mut maximum_row, maximum_column := 0, 0
		for row in 0 .. query_length + 1 {
			for column in 0 .. subject_length + 1 {
				value := scores[row * score_stride + column]
				if value > maximum { maximum = value; maximum_row = row; maximum_column = column }
			}
		}

		mut trace_query := [2 * max_sequence_length]u8{}
		mut trace_subject := [2 * max_sequence_length]u8{}
		mut trace_length := 0
		mut row, mut column := maximum_row, maximum_column
		for row > 0 && column > 0 {
			query_char, subject_char := query[row - 1], subject[column - 1]
			mut pair_score := i64(-1)
			if query_char == u8('-') || subject_char == u8('-') { pair_score = -2 }
			else if query_char == subject_char { pair_score = 1 }
			diagonal_score := scores[(row - 1) * score_stride + column - 1] + pair_score
			current_score := scores[row * score_stride + column]
			if current_score == diagonal_score {
				trace_query[trace_length], trace_subject[trace_length] = query_char, subject_char
				row--; column--
			} else if current_score == scores[(row - 1) * score_stride + column] - 2 {
				trace_query[trace_length], trace_subject[trace_length] = query_char, u8('-')
				row--
			} else {
				trace_query[trace_length], trace_subject[trace_length] = u8('-'), subject_char
				column--
			}
			trace_length++
		}

		mut staged := [max_output_bytes]u8{}
		mut position := 0
		put_u32_le(mut staged[0], position, u32(query_length + 1))
		position += 4
		put_u32_le(mut staged[0], position, u32(subject_length + 1))
		position += 4
		for row in 0 .. query_length + 1 {
			for column in 0 .. subject_length + 1 {
				put_i32_le(mut staged[0], position, scores[row * score_stride + column])
				position += 4
			}
		}
		alignment_length := if trace_length == 0 { 0 } else { 2 * trace_length + 1 }
		put_u32_le(mut staged[0], position, u32(alignment_length))
		position += 4
		for index in 0 .. trace_length {
			staged[position] = trace_query[trace_length - 1 - index]
			position++
		}
		if trace_length > 0 { staged[position] = u8('\n'); position++ }
		for index in 0 .. trace_length {
			staged[position] = trace_subject[trace_length - 1 - index]
			position++
		}

		if output == nil || output_capacity < usize(position) { return -2 }
		for index in 0 .. position { output[index] = staged[index] }
		return i64(position)
	}
}
