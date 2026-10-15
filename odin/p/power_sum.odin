package power_sum

import "core:c"

power_sum_search :: proc(target, power, base, current_sum: i64) -> i64 {
	term: i64 = 1
	for exponent: i64 = 0; exponent < power; exponent += 1 {
		term *= base
	}
	new_sum := current_sum + term
	if new_sum == target do return 1
	if new_sum > target do return 0
	return power_sum_search(target, power, base + 1, new_sum) + power_sum_search(target, power, base + 1, current_sum)
}

@(export)
power_sum :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
	if length != 2 do return -1
	target := packed[0]
	power := packed[1]
	if target < 1 || target > 1000 || power < 2 || power > 10 do return -1
	return power_sum_search(target, power, 1, 0)
}
