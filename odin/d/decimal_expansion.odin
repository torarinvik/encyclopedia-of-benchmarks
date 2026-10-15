package decimal_expansion

import "core:c"

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	if value == -1 {
		for byte := 0; byte < 8; byte += 1 do output[offset + byte] = 0xFF
		return
	}
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> (8 * byte)) & 0xFF)
	}
}

@(export)
decimal_expansion :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length != 3 do return -1
	numerator := values[0]
	denominator := values[1]
	base := values[2]
	if numerator < 0 || denominator < 1 || denominator > 256 ||
		numerator > denominator || base < 2 || base > 10 {
		return -1
	}

	digits: [255]u8
	first_seen: [256]i64
	for index := 0; index < 256; index += 1 do first_seen[index] = -1
	digit_count := 0
	cycle_start: i64 = -1
	remainder := numerator
	for remainder != 0 && numerator != denominator {
		remainder_index := int(remainder)
		if first_seen[remainder_index] >= 0 {
			cycle_start = first_seen[remainder_index]
			break
		}
		first_seen[remainder_index] = i64(digit_count)
		scaled := remainder * base
		digits[digit_count] = u8(scaled / denominator)
		digit_count += 1
		remainder = scaled % denominator
	}

	required := 24 + digit_count
	if output == nil || capacity < c.size_t(required) do return -2
	integer_part := i64(0)
	if numerator == denominator do integer_part = 1
	write_i64_le(output, 0, integer_part)
	write_i64_le(output, 8, i64(digit_count))
	write_i64_le(output, 16, cycle_start)
	for index := 0; index < digit_count; index += 1 do output[24 + index] = digits[index]
	return i64(required)
}
