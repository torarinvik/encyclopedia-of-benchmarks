package acronym

import "core:c"

MAX_PHRASE_LENGTH :: 79

@(export)
acronym :: proc "c" (phrase: [^]i64, length: c.size_t,
                      output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > MAX_PHRASE_LENGTH do return -1
	required := c.size_t(0)
	for index := c.size_t(0); index < length; index += 1 {
		value := phrase[index]
		if value < 1 || value > 127 do return -1
		if value != 32 && (index == 0 || phrase[index - 1] == 32) { required += 1 }
	}
	if output_capacity < required do return -2
	written := c.size_t(0)
	for index := c.size_t(0); index < length; index += 1 {
		value := phrase[index]
		if value != 32 && (index == 0 || phrase[index - 1] == 32) {
			if value >= 97 && value <= 122 do value -= 32
			output[written] = u8(value)
			written += 1
		}
	}
	return i64(written)
}
