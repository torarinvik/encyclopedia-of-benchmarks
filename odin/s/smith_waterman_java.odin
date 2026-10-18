package smith_waterman_java

import "core:c"

MAX_SEQUENCE_LENGTH :: 16
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(38)
SCORE_STRIDE :: 17

@(export)
smith_waterman_java :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	query_length_value, subject_length_value := input[0], input[1]
	match_score, mismatch_score, gap_score := input[2], input[3], input[4]
	if query_length_value < 0 || query_length_value > MAX_SEQUENCE_LENGTH ||
		subject_length_value < 0 || subject_length_value > MAX_SEQUENCE_LENGTH ||
		match_score < 1 || match_score > 5 || mismatch_score < -5 || mismatch_score > -1 ||
		gap_score < -5 || gap_score > -1 do return -1
	query_length, subject_length := int(query_length_value), int(subject_length_value)
	if length != c.size_t(5 + query_length + subject_length) do return -1
	for index := 5; index < int(length); index += 1 {
		value := input[index]
		if !((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') || value == '-') do return -1
	}

	scores: [SCORE_STRIDE*SCORE_STRIDE]i64
	maximum := i64(0)
	for row := 1; row <= query_length; row += 1 {
		for column := 1; column <= subject_length; column += 1 {
			query_char, subject_char := input[4+row], input[4+query_length+column]
			pair_score := if query_char == subject_char { match_score } else { mismatch_score }
			diagonal := scores[(row-1)*SCORE_STRIDE+column-1] + pair_score
			above := scores[(row-1)*SCORE_STRIDE+column] + gap_score
			left := scores[row*SCORE_STRIDE+column-1] + gap_score
			value := max(0, max(diagonal, max(above, left)))
			scores[row*SCORE_STRIDE+column] = value
			if value > maximum do maximum = value
		}
	}
	return maximum
}
