module main

const max_text_length = 64
const max_input_length = max_text_length + 1
const max_parseable_input_length = max_input_length + 2
const max_output_bytes = 4

fn is_ascii_letter(value i64) bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

fn digit_for(input_value i64) i64 {
	mut value := input_value
	if value >= 65 && value <= 90 { value += 32 }
	if value == 97 || value == 101 || value == 105 || value == 111 || value == 117 || value == 121 { return 0 }
	if value == 104 || value == 119 { return 8 }
	if value == 98 || value == 102 || value == 112 || value == 118 { return 1 }
	if value == 99 || value == 103 || value == 106 || value == 107 || value == 113 || value == 115 || value == 120 || value == 122 { return 2 }
	if value == 100 || value == 116 { return 3 }
	if value == 108 { return 4 }
	if value == 109 || value == 110 { return 5 }
	if value == 114 { return 6 }
	return -1
}

@[export: 'soundex_encoder']
pub fn soundex_encoder(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 1 || length > max_parseable_input_length { return -1 }
	unsafe {
		if values == nil { return -1 }
		text_length := values[0]
		if text_length < 1 || text_length > max_text_length || length > max_input_length || length != usize(text_length + 1) { return -1 }
		for index in 1 .. int(length) {
			if !is_ascii_letter(values[index]) { return -1 }
		}

		mut mapped := [64]i64{}
		mut mapped_count := 0
		for index in 1 .. int(length) {
			mut letter := values[index]
			if letter >= 65 && letter <= 90 { letter += 32 }
			if letter == 104 || letter == 119 { continue }
			digit := digit_for(letter)
			if mapped_count == 0 || mapped[mapped_count - 1] != digit {
				mapped[mapped_count] = digit
				mapped_count++
			}
		}

		mut code_count := 0
		for index in 0 .. mapped_count {
			if mapped[index] != 0 {
				mapped[code_count] = mapped[index]
				code_count++
			}
		}
		if code_count == 0 { return -1 }

		mut first_letter := values[1]
		if first_letter >= 65 && first_letter <= 90 { first_letter += 32 }
		mut start := 0
		if mapped[0] == digit_for(first_letter) {
			if code_count == 1 { return -1 }
			start = 1
		}

		mut encoded := [4]u8{}
		mut initial := values[1]
		if initial >= 97 && initial <= 122 { initial -= 32 }
		encoded[0] = u8(initial)
		for index in 0 .. 3 {
			mut digit := i64(0)
			if start + index < code_count { digit = mapped[start + index] }
			encoded[index + 1] = u8(48 + digit)
		}

		if output == nil || output_capacity < max_output_bytes { return -2 }
		for index in 0 .. max_output_bytes { output[index] = encoded[index] }
		return max_output_bytes
	}
}
