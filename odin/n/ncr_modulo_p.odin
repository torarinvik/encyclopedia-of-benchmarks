package ncr_modulo_p

import "core:c"

INVALID_RESULT :: i64 = -9_223_372_036_854_775_808

inverse :: proc(a, m: i64) -> i64 {
	old_r, r := a, m
	old_s, s := i64(1), i64(0)
	for r != 0 {
		quotient := old_r / r
		next_r := old_r - quotient * r
		next_s := old_s - quotient * s
		old_r, r = r, next_r
		old_s, s = s, next_s
	}
	if old_r == 1 do return (old_s + m) % m
	return -1
}

@(export)
ncr_modulo_p :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length != 4 || values == nil do return INVALID_RESULT
	size, p, n, r := values[0], values[1], values[2], values[3]
	if size < 0 || size > 64 || p < 2 || p > 1009 || n < 0 || n > size || r < 0 || r > 64 do return INVALID_RESULT
	fac: [65]i64
	fac[0] = 1
	for i := i64(1); i <= size; i += 1 {
		fac[i] = (fac[i - 1] * i) % p
	}
	if r > n do return 0
	if r == 1 do return n % p
	if r == 0 || r == n do return 1
	denominator := (fac[r] * fac[n - r]) % p
	denominator_inv := inverse(denominator, p)
	if denominator_inv < 0 do return -1
	return (fac[n] * denominator_inv) % p
}
