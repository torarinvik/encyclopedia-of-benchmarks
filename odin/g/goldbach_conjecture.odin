package goldbach_conjecture

import "core:c"

// Return the first source-ordered Goldbach pair as two little-endian i32 values.
goldbach_is_prime :: proc "contextless" (value: i64) -> bool {
	if value == 2 do return true
	if value < 2 || value % 2 == 0 do return false
	for divisor := i64(3); divisor <= value / divisor; divisor += 2 {
		if value % divisor == 0 do return false
	}
	return true
}

@(export)
goldbach_conjecture :: proc "c" (number: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if number < 4 || number > 4096 || number % 2 != 0 do return -1
	if output == nil || output_capacity < 8 do return -2
	for first := i64(0); first <= number / 2; first += 1 {
		second := number - first
		if goldbach_is_prime(first) && goldbach_is_prime(second) {
			pair := [2]u32{u32(first), u32(second)}
			for j := c.size_t(0); j < 2; j += 1 {
				for b := c.size_t(0); b < 4; b += 1 {
					output[4 * j + b] = u8((pair[j] >> (8 * b)) & 0xff)
				}
			}
			return 8
		}
	}
	return -1
}
