package number_of_subarrays_with_odd_sum

import "core:c"

// Count subarrays with an odd sum, modulo 1,000,000,007.
@(export)
number_of_subarrays_with_odd_sum :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length > 100_000 do return -1
	even_prefixes := i64(1)
	odd_prefixes := i64(0)
	result := i64(0)
	parity := i64(0)
	for index := 0; index < int(length); index += 1 {
		value := values[index]
		if value < -2_147_483_648 || value > 2_147_483_647 do return -1
		if value % 2 != 0 do parity = 1 - parity
		if parity == 0 {
			result = (result + odd_prefixes) % 1_000_000_007
			even_prefixes += 1
		} else {
			result = (result + even_prefixes) % 1_000_000_007
			odd_prefixes += 1
		}
	}
	return result
}
