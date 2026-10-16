package jaro_winkler_distance

import "core:c"

MAX_STRING_LENGTH :: 32
MAX_INPUT_LENGTH :: 2 + 2 * MAX_STRING_LENGTH
SCALE: i64 = 1_000_000_000

@(export)
jaro_winkler_distance :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	first_length_value := input[0]
	if first_length_value < 0 || first_length_value > MAX_STRING_LENGTH do return -1
	first_length := int(first_length_value)
	second_length_index := 1 + first_length
	if c.size_t(second_length_index) >= length do return -1
	second_length_value := input[second_length_index]
	if second_length_value < 0 || second_length_value > MAX_STRING_LENGTH || first_length_value < second_length_value ||
		length != c.size_t(second_length_index + 1 + int(second_length_value)) do return -1
	second_length := int(second_length_value)

	for i := 0; i < first_length; i += 1 {
		if input[1 + i] < 0 || input[1 + i] > 127 do return -1
	}
	for i := 0; i < second_length; i += 1 {
		index := second_length_index + 1 + i
		if input[index] < 0 || input[index] > 127 do return -1
	}
	if first_length == second_length {
		equal := true
		for i := 0; i < first_length; i += 1 {
			if input[1 + i] != input[second_length_index + 1 + i] { equal = false; break }
		}
		if equal do return 0
	}
	if second_length == 0 do return SCALE

	half := first_length / 2
	radius := half > 0 ? half - 1 : 0
	first_matched: [MAX_STRING_LENGTH]bool
	second_matched: [MAX_STRING_LENGTH]bool
	match_count := 0
	for i := 0; i < first_length; i += 1 {
		start := i > radius ? i - radius : 0
		ending := i + radius
		if ending >= second_length do ending = second_length - 1
		if start > ending do continue
		for j := start; j <= ending; j += 1 {
			if input[1 + i] == input[second_length_index + 1 + j] && !second_matched[j] {
				first_matched[i] = true
				second_matched[j] = true
				match_count += 1
				break
			}
		}
	}
	if match_count == 0 do return SCALE

	second_index := 0
	mismatched_pairs := 0
	for i := 0; i < first_length; i += 1 {
		if !first_matched[i] do continue
		for second_index < second_length && !second_matched[second_index] { second_index += 1 }
		if second_index == second_length do return -1
		if input[1 + i] != input[second_length_index + 1 + second_index] do mismatched_pairs += 1
		second_index += 1
	}

	matches := i64(match_count)
	first_size := i64(first_length)
	second_size := i64(second_length)
	transpositions := i64(mismatched_pairs / 2)
	jaro_numerator := matches * matches * second_size + matches * matches * first_size +
		(matches - transpositions) * first_size * second_size
	jaro_denominator := i64(3) * first_size * second_size * matches

	prefix_length := 0
	prefix_limit := second_length < 4 ? second_length : 4
	for prefix_length < prefix_limit && input[1 + prefix_length] == input[second_length_index + 1 + prefix_length] {
		prefix_length += 1
	}
	denominator := i64(10) * jaro_denominator
	numerator := i64(10 - prefix_length) * (jaro_denominator - jaro_numerator)
	return (numerator * SCALE + denominator / 2) / denominator
}
