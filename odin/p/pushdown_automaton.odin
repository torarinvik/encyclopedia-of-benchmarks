package pushdown_automaton

import "core:c"

MAX_BYTE_LENGTH :: 256
MAX_INPUT_LENGTH :: 257

// Recognize the bounded language (1|2)^n 0^n with a pushdown-style counter.
@(export)
pushdown_automaton :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	byte_length := values[0]
	if byte_length < 0 || byte_length > MAX_BYTE_LENGTH do return -1
	count := int(byte_length)
	if length != c.size_t(count + 1) do return -1

	for index := 0; index < count; index += 1 {
		if values[index + 1] < 48 || values[index + 1] > 50 do return -1
	}
	if count == 0 || count % 2 != 0 do return 0

	half := count / 2
	for index := 0; index < half; index += 1 {
		if values[index + 1] != 49 && values[index + 1] != 50 do return 0
	}
	for index := half; index < count; index += 1 {
		if values[index + 1] != 48 do return 0
	}
	return 1
}
