package print_reverse

import "core:c"

MAX_VALUES :: 256
MAX_PARSEABLE_INPUT_LENGTH :: MAX_VALUES + 2
MAX_OUTPUT_BYTES :: 3836
I32_MIN_VALUE :: -2147483648
I32_MAX_VALUE :: 2147483647

append_decimal :: proc "contextless" (buffer: [^]u8, position: ^int, value: i64) {
	digits: [10]u8
	count := 0
	var magnitude: u64
	if value < 0 {
		buffer[position^] = 45
		position^ += 1
		magnitude = u64(-value)
	} else {
		magnitude = u64(value)
	}
	for {
		digits[count] = u8(48 + magnitude % 10)
		count += 1
		magnitude /= 10
		if magnitude == 0 do break
	}
	for count > 0 {
		count -= 1
		buffer[position^] = digits[count]
		position^ += 1
	}
}

@(export)
print_reverse :: proc "c" (values: [^]i64, length: c.size_t,
							output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) || length > c.size_t(MAX_VALUES) do return -1
	if length > 0 && values == nil do return -1
	for index in 0..<int(length) {
		value := values[index]
		if value < I32_MIN_VALUE || value > I32_MAX_VALUE do return -1
	}

	encoded: [MAX_OUTPUT_BYTES]u8
	written := 0
	remaining := int(length)
	for remaining > 0 {
		remaining -= 1
		if written > 0 {
			encoded[written] = 32
			encoded[written + 1] = 60
			encoded[written + 2] = 45
			encoded[written + 3] = 32
			written += 4
		}
		append_decimal(&encoded[0], &written, values[remaining])
	}

	if output == nil || output_capacity < c.size_t(written) do return -2
	for index in 0..<written do output[index] = encoded[index]
	return i64(written)
}
