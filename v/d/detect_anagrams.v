module detect_anagrams

const max_string_length = 16
const max_candidates = 16
const max_input_length = 290

fn is_ascii_letter(value i64) bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

fn lower_ascii(value i64) i64 {
	if value >= 65 && value <= 90 { return value + 32 }
	return value
}

@[export: 'detect_anagrams']
pub fn detect_anagrams(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 2 || length > max_input_length || unsafe { input == nil } { return -1 }
	unsafe {
		count := int(length)
		subject_length_value := input[0]
		if subject_length_value < 0 || subject_length_value > max_string_length { return -1 }
		subject_length := int(subject_length_value)
		if subject_length + 1 >= count { return -1 }
		mut position := 1
		mut subject_counts := [26]int{}
		for index in 0 .. subject_length {
			value := input[position + index]
			if !is_ascii_letter(value) { return -1 }
			subject_counts[int(lower_ascii(value) - 97)]++
		}
		position += subject_length
		if position >= count { return -1 }
		candidate_count_value := input[position]
		if candidate_count_value < 0 || candidate_count_value > max_candidates { return -1 }
		candidate_count := int(candidate_count_value)
		position++
		mut candidate_starts := [max_candidates]int{}
		mut candidate_lengths := [max_candidates]int{}
		mut selected := [max_candidates]bool{}
		mut match_count := 0
		mut output_length := 0
		for candidate in 0 .. candidate_count {
			if position >= count { return -1 }
			candidate_length_value := input[position]
			if candidate_length_value < 0 || candidate_length_value > max_string_length { return -1 }
			candidate_length := int(candidate_length_value)
			position++
			if candidate_length > count - position { return -1 }
			candidate_starts[candidate] = position
			candidate_lengths[candidate] = candidate_length
			mut candidate_counts := [26]int{}
			mut same_identity := candidate_length == subject_length
			for index in 0 .. candidate_length {
				value := input[position + index]
				if !is_ascii_letter(value) { return -1 }
				candidate_counts[int(lower_ascii(value) - 97)]++
				if same_identity && lower_ascii(value) != lower_ascii(input[1 + index]) { same_identity = false }
			}
			mut same_signature := true
			for letter in 0 .. 26 {
				if candidate_counts[letter] != subject_counts[letter] { same_signature = false }
			}
			if same_signature && !same_identity {
				selected[candidate] = true
				match_count++
				output_length += candidate_length + 1
			}
			position += candidate_length
		}
		if position != count { return -1 }
		required := usize(output_length + 1)
		if capacity < required || unsafe { output == nil } { return -2 }
		mut written := 0
		for candidate in 0 .. candidate_count {
			if selected[candidate] {
				for index in 0 .. candidate_lengths[candidate] {
					output[written] = u8(input[candidate_starts[candidate] + index])
					written++
				}
				output[written] = 10
				written++
			}
		}
		output[written] = 0
		return i64(match_count)
	}
}
