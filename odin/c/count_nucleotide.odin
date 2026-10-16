package count_nucleotide

import "core:c"

MAX_SEQUENCE_LENGTH :: 1000

decimal_length :: proc(value: i64) -> usize {
	current := value
	length := usize(1)
	for current >= 10 {
		current /= 10
		length += 1
	}
	return length
}

write_decimal :: proc(output: [^]u8, offset: usize, value: i64) -> usize {
	divisor := i64(1)
	for value / divisor >= 10 { divisor *= 10 }
	current := value
	position := offset
	for divisor > 0 {
		output[position] = u8(48 + current / divisor)
		position += 1
		current %= divisor
		divisor /= 10
	}
	return position
}

@(export)
count_nucleotide :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 1001 do return -1
	count_value := values[0]
	if count_value < 0 || count_value > MAX_SEQUENCE_LENGTH || length != c.size_t(count_value + 1) do return -1
	count_a := i64(0)
	count_c := i64(0)
	count_g := i64(0)
	count_t := i64(0)
	for i := 0; i < int(count_value); i += 1 {
		codepoint := values[1 + i]
		if codepoint < 0 || codepoint > 127 do return -1
		if codepoint == 65 do count_a += 1
		else if codepoint == 67 do count_c += 1
		else if codepoint == 71 do count_g += 1
		else if codepoint == 84 do count_t += 1
	}
	output_length := decimal_length(count_a) + decimal_length(count_c) + decimal_length(count_g) + decimal_length(count_t) + 3
	if output == nil || capacity < c.size_t(output_length) do return -2
	offset := write_decimal(output, 0, count_a); output[offset] = 32; offset += 1
	offset = write_decimal(output, offset, count_c); output[offset] = 32; offset += 1
	offset = write_decimal(output, offset, count_g); output[offset] = 32; offset += 1
	offset = write_decimal(output, offset, count_t)
	return i64(offset)
}
