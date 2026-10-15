package title_case_conversion

import "core:c"

MAX_LENGTH :: 256

// Apply the pinned JavaScript title-case behavior to bounded ASCII words.
@(export)
title_case_conversion :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length == 0 || length > c.size_t(MAX_LENGTH + 1) do return -1
	declared := input[0]
	if declared < 0 || declared > MAX_LENGTH || length != c.size_t(declared) + 1 do return -1
	for index := 0; index < int(declared); index += 1 {
		value := input[index + 1]
		letter := (value >= 65 && value <= 90) || (value >= 97 && value <= 122)
		if !letter && value != 32 do return -1
		if value == 32 && (index == 0 || index + 1 == int(declared) || input[index] == 32) do return -1
	}
	if output_capacity < c.size_t(declared) + 1 do return -2
	at_word_start := true
	for index := 0; index < int(declared); index += 1 {
		value := input[index + 1]
		if value == 32 {
			at_word_start = true
		} else if at_word_start {
			if value >= 97 && value <= 122 do value -= 32
			at_word_start = false
		} else if value >= 65 && value <= 90 do value += 32
		output[index] = u8(value)
	}
	output[int(declared)] = 0
	return declared
}
