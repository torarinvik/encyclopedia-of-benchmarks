package binary_twos_complement

import "core:c"

@(export)
twos_complement :: proc "c" (value: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if value > 0 do return -1
	if value == 0 {
		if output == nil || output_capacity < 3 do return -2
		output[0] = 48; output[1] = 98; output[2] = 48
		return 3
	}
	magnitude := u64(-(value + 1)) + 1
	bit_length := 0
	for remaining := magnitude; remaining > 0; remaining >>= 1 { bit_length += 1 }
	suffix := magnitude
	if bit_length < 64 do suffix = (u64(1) << u32(bit_length)) - magnitude
	bits: [64]u8
	bit_count := 0
	for remaining := suffix; remaining > 0; remaining >>= 1 {
		bits[bit_count] = u8(48) + u8(remaining & 1)
		bit_count += 1
	}
	required := bit_length + 3
	if output == nil || output_capacity < c.size_t(required) do return -2
	position := 0
	output[position] = 48; position += 1
	output[position] = 98; position += 1
	output[position] = 49; position += 1
	for zero := bit_count; zero < bit_length; zero += 1 { output[position] = 48; position += 1 }
	for bit_count > 0 {
		bit_count -= 1
		output[position] = bits[bit_count]
		position += 1
	}
	return i64(position)
}
