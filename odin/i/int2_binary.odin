package int2_binary

import "core:c"

// Encode the C# uint overload as exactly 32 ASCII binary digits.
@(export)
int2_binary :: proc "c" (value: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if value < 0 || value > 4_294_967_295 do return -1
	if output == nil || output_capacity < 32 do return -2

	remaining := u32(value)
	most_significant_bit := u32(0x80000000)
	for i := c.size_t(0); i < 32; i += 1 {
		if remaining >= most_significant_bit {
			output[i] = u8(49)
			remaining -= most_significant_bit
		} else {
			output[i] = u8(48)
		}
		most_significant_bit /= 2
	}
	return 32
}
