package soundex_encoder

import "core:c"

MAX_TEXT_LENGTH :: 64
MAX_INPUT_LENGTH :: MAX_TEXT_LENGTH + 1
MAX_PARSEABLE_INPUT_LENGTH :: MAX_INPUT_LENGTH + 2
MAX_OUTPUT_BYTES :: 4

is_ascii_letter :: proc(value: i64) -> bool {
	return (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
}

digit_for :: proc(input_value: i64) -> i64 {
	value := input_value
	if value >= 65 && value <= 90 do value += 32
	if value == 97 || value == 101 || value == 105 || value == 111 || value == 117 || value == 121 do return 0
	if value == 104 || value == 119 do return 8
	if value == 98 || value == 102 || value == 112 || value == 118 do return 1
	if value == 99 || value == 103 || value == 106 || value == 107 || value == 113 || value == 115 || value == 120 || value == 122 do return 2
	if value == 100 || value == 116 do return 3
	if value == 108 do return 4
	if value == 109 || value == 110 do return 5
	if value == 114 do return 6
	return -1
}

@(export)
soundex_encoder :: proc "c" (values: [^]i64, length: c.size_t,
							output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length < 1 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) || values == nil do return -1
	text_length := values[0]
	if text_length < 1 || text_length > MAX_TEXT_LENGTH || length > c.size_t(MAX_INPUT_LENGTH) ||
		length != c.size_t(text_length + 1) do return -1
	for index in 1..<int(length) {
		if !is_ascii_letter(values[index]) do return -1
	}

	mapped: [MAX_TEXT_LENGTH]i64
	mapped_count := 0
	for index in 1..<int(length) {
		letter := values[index]
		if letter >= 65 && letter <= 90 do letter += 32
		if letter == 104 || letter == 119 do continue
		digit := digit_for(letter)
		if mapped_count == 0 || mapped[mapped_count - 1] != digit {
			mapped[mapped_count] = digit
			mapped_count += 1
		}
	}

	code_count := 0
	for index in 0..<mapped_count {
		if mapped[index] != 0 {
			mapped[code_count] = mapped[index]
			code_count += 1
		}
	}
	if code_count == 0 do return -1

	first_letter := values[1]
	if first_letter >= 65 && first_letter <= 90 do first_letter += 32
	start := 0
	if mapped[0] == digit_for(first_letter) {
		if code_count == 1 do return -1
		start = 1
	}

	encoded: [MAX_OUTPUT_BYTES]u8
	initial := values[1]
	if initial >= 97 && initial <= 122 do initial -= 32
	encoded[0] = u8(initial)
	for index in 0..<3 {
		digit := i64(0)
		if start + index < code_count do digit = mapped[start + index]
		encoded[index + 1] = u8(48 + digit)
	}

	if output == nil || output_capacity < c.size_t(MAX_OUTPUT_BYTES) do return -2
	for index in 0..<MAX_OUTPUT_BYTES do output[index] = encoded[index]
	return MAX_OUTPUT_BYTES
}
