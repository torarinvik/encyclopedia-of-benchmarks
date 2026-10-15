module close_strings

// Check lowercase strings for equal letter sets and frequency multisets.
@[export: 'close_strings']
pub fn close_strings(input &i64, length usize) i64 {
	if length < 2 || length > 514 { return -1 }
	unsafe {
		first_length_value := input[0]
		second_length_value := input[1]
		if first_length_value < 0 || first_length_value > 256 || second_length_value < 0 || second_length_value > 256 { return -1 }
		first_length := int(first_length_value)
		second_length := int(second_length_value)
		if length != usize(2 + first_length + second_length) { return -1 }
		mut first := [26]i64{}
		mut second := [26]i64{}
		for index in 0 .. first_length {
			value := input[index + 2]
			if value < 97 || value > 122 { return -1 }
			first[int(value - 97)]++
		}
		second_start := 2 + first_length
		for index in 0 .. second_length {
			value := input[second_start + index]
			if value < 97 || value > 122 { return -1 }
			second[int(value - 97)]++
		}
		if first_length != second_length { return 0 }
		mut first_frequencies := [257]i64{}
		mut second_frequencies := [257]i64{}
		for letter in 0 .. 26 {
			if (first[letter] == 0) != (second[letter] == 0) { return 0 }
			first_frequencies[int(first[letter])]++
			second_frequencies[int(second[letter])]++
		}
		return if first_frequencies == second_frequencies { 1 } else { 0 }
	}
}
