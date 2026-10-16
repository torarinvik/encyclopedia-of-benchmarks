module jaro_winkler_distance

const max_string_length = 32
const max_input_length = 2 + 2 * max_string_length
const scale = i64(1_000_000_000)

// C#-faithful Jaro-Winkler distance in billionths, rounded to nearest (ties upward).
@[export: 'jaro_winkler_distance']
pub fn jaro_winkler_distance(input &i64, length usize) i64 {
	if input == nil || length < 2 || length > max_input_length { return -1 }
	unsafe {
		first_length_value := input[0]
		if first_length_value < 0 || first_length_value > max_string_length { return -1 }
		first_length := int(first_length_value)
		second_length_index := 1 + first_length
		if second_length_index >= int(length) { return -1 }
		second_length_value := input[second_length_index]
		if second_length_value < 0 || second_length_value > max_string_length ||
			first_length_value < second_length_value ||
			length != usize(second_length_index + 1 + int(second_length_value)) { return -1 }
		second_length := int(second_length_value)

		for i in 0 .. first_length {
			value := input[1 + i]
			if value < 0 || value > 127 { return -1 }
		}
		for i in 0 .. second_length {
			value := input[second_length_index + 1 + i]
			if value < 0 || value > 127 { return -1 }
		}

		if first_length == second_length {
			equal := true
			for i in 0 .. first_length {
				if input[1 + i] != input[second_length_index + 1 + i] {
					equal = false
					break
				}
			}
			if equal { return 0 }
		}
		if second_length == 0 { return scale }

		half := first_length / 2
		radius := if half > 0 { half - 1 } else { 0 }
		mut first_matched := []bool{len: max_string_length}
		mut second_matched := []bool{len: max_string_length}
		mut match_count := 0
		for i in 0 .. first_length {
			start := if i > radius { i - radius } else { 0 }
			mut ending := i + radius
			if ending >= second_length { ending = second_length - 1 }
			if start > ending { continue }
			for j := start; j <= ending; j++ {
				if input[1 + i] == input[second_length_index + 1 + j] && !second_matched[j] {
					first_matched[i] = true
					second_matched[j] = true
					match_count++
					break
				}
			}
		}
		if match_count == 0 { return scale }

		mut second_index := 0
		mut mismatched_pairs := 0
		for i in 0 .. first_length {
			if !first_matched[i] { continue }
			for second_index < second_length && !second_matched[second_index] { second_index++ }
			if second_index == second_length { return -1 }
			if input[1 + i] != input[second_length_index + 1 + second_index] { mismatched_pairs++ }
			second_index++
		}

		matches := i64(match_count)
		first_size := i64(first_length)
		second_size := i64(second_length)
		transpositions := i64(mismatched_pairs / 2)
		jaro_numerator := matches * matches * second_size + matches * matches * first_size +
			(matches - transpositions) * first_size * second_size
		jaro_denominator := i64(3) * first_size * second_size * matches

		mut prefix_length := 0
		prefix_limit := if second_length < 4 { second_length } else { 4 }
		for prefix_length < prefix_limit && input[1 + prefix_length] == input[second_length_index + 1 + prefix_length] {
			prefix_length++
		}
		denominator := i64(10) * jaro_denominator
		numerator := i64(10 - prefix_length) * (jaro_denominator - jaro_numerator)
		return (numerator * scale + denominator / 2) / denominator
	}
}
