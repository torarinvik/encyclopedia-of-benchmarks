module check_anagram

const max_string_length = 1024
const max_input_length = 2050

fn letter_index(value i64) int {
	if value >= 97 && value <= 122 { return int(value - 97) }
	if value >= 65 && value <= 90 { return int(value - 65) }
	return -1
}

// Case-insensitive anagram check for distinct ASCII alphabetic strings.
@[export: 'check_anagram']
pub fn check_anagram(input &i64, length usize) i64 {
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
		letter := letter_index(unsafe { input[2 + index] })
		if letter < 0 { return -1 }
		first_counts[letter]++
	}
	for index in 0 .. second_length {
		letter := letter_index(unsafe { input[2 + first_length + index] })
		if letter < 0 { return -1 }
		second_counts[letter]++
	}
	if first_length != second_length { return 0 }
	mut different_after_normalization := false
	for index in 0 .. first_length {
		if letter_index(unsafe { input[2 + index] }) != letter_index(unsafe { input[2 + first_length + index] }) {
			different_after_normalization = true
		}
	}
	if !different_after_normalization { return 0 }
	for letter in 0 .. 26 {
		if first_counts[letter] != second_counts[letter] { return 0 }
	}
	return 1
}
