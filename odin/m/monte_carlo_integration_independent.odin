package monte_carlo_integration_independent

import "core:c"

MAX_N :: i64(16)
MIN_BOUND :: i64(-10_000_000)
MAX_BOUND :: i64(10_000_000)
MAX_UNIFORM :: i64(999_999)
INVALID_RESULT :: f64 = -1.0e300

@(export)
monte_carlo_integration_independent :: proc "c" (packed: [^]i64, length: c.size_t) -> f64 {
	if packed == nil || length < 3 || length > 20 do return INVALID_RESULT
	n := packed[2]
	if n < 1 || n > MAX_N || length != c.size_t(3 + n) do return INVALID_RESULT
	a_raw := packed[0]
	b_raw := packed[1]
	if a_raw < MIN_BOUND || a_raw > MAX_BOUND || b_raw < MIN_BOUND || b_raw > MAX_BOUND || a_raw >= b_raw do return INVALID_RESULT
	for index := c.size_t(3); index < length; index += 1 {
		if packed[index] < 0 || packed[index] > MAX_UNIFORM do return INVALID_RESULT
	}

	a := f64(a_raw) / 1_000_000.0
	b := f64(b_raw) / 1_000_000.0
	interval := b - a
	delta := interval / f64(n)
	total := f64(0)
	for index := i64(0); index < n; index += 1 {
		u := f64(packed[3 + index]) / 1_000_000.0
		x := a + interval * u
		total += x * x
	}
	return delta * total
}
