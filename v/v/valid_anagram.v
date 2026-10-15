module valid_anagram

const max_string_length = 1024
const max_input_length = 2 + 2 * max_string_length

// Compare lowercase ASCII strings by their letter frequencies.
@[export: 'valid_anagram']
pub fn valid_anagram(input &i64, length usize) i64 {
	if length < 2 || length > max_input_length { return -1 }
	first_length_value := unsafe { input[0] }
	second_length_value := unsafe { input[1] }
	if first_length_value < 0 || first_length_value > max_string_length || second_length_value < 0 || second_length_value > max_string_length { return -1 }
	first_length := int(first_length_value)
	second_length := int(second_length_value)
	if int(length) != 2 + first_length + second_length { return -1 }
	mut first_counts := [26]int{init: 0}
	mut second_counts := [26]int{init: 0}
	for index in 0 .. first_length {
		value := unsafe { input[2 + index] }
		if value < 97 || value > 122 { return -1 }
		first_counts[int(value - 97)]++
	}
	for index in 0 .. second_length {
		value := unsafe { input[2 + first_length + index] }
		if value < 97 || value > 122 { return -1 }
		second_counts[int(value - 97)]++
	}
	for letter in 0 .. 26 {
		if first_counts[letter] != second_counts[letter] { return 0 }
	}
	return 1
}
