package excess_3_code

import "core:c"

@(export)
excess_3_code :: proc "c" (value: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	number: u64 = 0
	if value >= 0 { number = u64(value) }
	digits: [19]u8
	count := 0
	for number > 0 {
		digits[count] = u8(number % 10)
		count += 1
		number /= 10
	}
	if count == 0 { digits[0] = 0; count = 1 }
	output_length := 2 + 4 * count
	if output == nil || output_capacity < c.size_t(output_length) { return -2 }
	output[0] = u8('0')
	output[1] = u8('b')
	position := 2
	for count > 0 {
		count -= 1
		nibble := u32(digits[count]) + 3
		for bit := 3; bit >= 0; bit -= 1 {
			if nibble & (u32(1) << u32(bit)) != 0 { output[position] = u8('1') } else { output[position] = u8('0') }
			position += 1
		}
	}
	return i64(output_length)
}
