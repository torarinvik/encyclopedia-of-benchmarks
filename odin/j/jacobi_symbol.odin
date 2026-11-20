package jacobi_symbol

import "core:c"

MAX_MODULUS :: i64(1_000_000_000)
MAX_LENGTH :: 3

reciprocity :: proc(numerator, denominator: i64) -> i64 {
	a := numerator
	n := denominator
	sign := i64(1)
	for a != 0 {
		for (a & 1) == 0 {
			a /= 2
			if n % 8 == 3 || n % 8 == 5 { sign = -sign }
		}
		if a % 4 == 3 && n % 4 == 3 { sign = -sign }
		old_a := a
		a = n
		n = old_a
		a %= n
	}
	if n == 1 do return sign
	return 0
}

@(export)
jacobi_symbol :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	numerator := input[0]
	denominator := input[1]
	if denominator < 1 || denominator > MAX_MODULUS || (denominator & 1) == 0 do return -1
	if numerator < 0 || numerator >= denominator do return -1
	return reciprocity(numerator, denominator) + 1
}
