package kth_root_integer

import "core:c"

power_at_most :: proc(base, exponent_input, limit: i64) -> bool {
	if base == 0 do return true
	product: i64 = 1
	exponent := exponent_input
	for exponent > 0 {
		if product > limit / base do return false
		product *= base
		exponent -= 1
	}
	return true
}

@(export)
kth_root_integer :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	number, degree := input[0], input[1]
	if number < 0 || degree < 1 || degree > 64 do return -1

	low: i64 = 0
	high := number
	for low < high {
		difference := high - low
		candidate := low + difference / 2 + difference % 2
		if power_at_most(candidate, degree, number) do low = candidate else high = candidate - 1
	}
	return low
}
