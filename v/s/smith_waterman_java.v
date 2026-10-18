const max_sequence_length = 16
const max_parseable_input_length = 38
const score_stride = 17

@[export: 'smith_waterman_java']
pub fn smith_waterman_java(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_parseable_input_length { return -1 }
		query_length_value, subject_length_value := input[0], input[1]
		match_score, mismatch_score, gap_score := input[2], input[3], input[4]
		if query_length_value < 0 || query_length_value > max_sequence_length ||
			subject_length_value < 0 || subject_length_value > max_sequence_length ||
			match_score < 1 || match_score > 5 || mismatch_score < -5 || mismatch_score > -1 ||
			gap_score < -5 || gap_score > -1 { return -1 }
		query_length, subject_length := int(query_length_value), int(subject_length_value)
		if length != usize(5 + query_length + subject_length) { return -1 }
		for index in 5 .. length {
			value := input[index]
			if !((value >= `A` && value <= `Z`) || (value >= `a` && value <= `z`) || value == `-`) { return -1 }
		}
		mut scores := [score_stride * score_stride]i64{}
		mut maximum := i64(0)
		for row in 1 .. query_length + 1 {
			for column in 1 .. subject_length + 1 {
				query_char, subject_char := input[4 + row], input[4 + query_length + column]
				pair_score := if query_char == subject_char { match_score } else { mismatch_score }
				diagonal := scores[(row - 1) * score_stride + column - 1] + pair_score
				above := scores[(row - 1) * score_stride + column] + gap_score
				left := scores[row * score_stride + column - 1] + gap_score
				value := max(i64(0), max(diagonal, max(above, left)))
				scores[row * score_stride + column] = value
				if value > maximum { maximum = value }
			}
		}
		return maximum
	}
}
