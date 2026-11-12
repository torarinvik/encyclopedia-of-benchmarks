package enumerate_quotients

import "core:c"

@(export)
enumerate_quotients :: proc "c" (value: i64, output: [^]u8,
	output_capacity: c.size_t) -> i64 {
	if value < 1 || value > 100_000 do return -1
	n := u64(value)
	count: c.size_t = 0
	for left := u64(1); left <= n; {
		quotient := n / left
		count += 1
		left = n / quotient + 1
	}
	byte_count := (count + 1) * 8
	if output == nil || output_capacity < byte_count do return -2
	count_word := u64(count)
	for byte := 0; byte < 8; byte += 1 {
		output[byte] = u8((count_word >> u64(byte*8)) & 255)
	}
	index: c.size_t = 0
	for left := u64(1); left <= n; {
		quotient := n / left
		for byte := 0; byte < 8; byte += 1 {
			output[(index+1)*8+c.size_t(byte)] = u8((quotient >> u64(byte*8)) & 255)
		}
		index += 1
		left = n / quotient + 1
	}
	return i64(byte_count)
}
