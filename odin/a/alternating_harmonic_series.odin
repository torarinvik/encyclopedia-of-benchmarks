package alternating_harmonic_series

import "core:c"

MAX_COUNT :: 1000

// Check whether each rational input approximates its canonical alternating term.
@(export)
alternating_harmonic_series :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	count := input[0]
	if count < 0 || count > MAX_COUNT || length != c.size_t(1+2*count) do return -1
	for index := i64(0); index < count; index += 1 {
		numerator := input[1+2*index]
		denominator := input[2+2*index]
		if numerator < -1000 || numerator > 1000 || denominator < 1 || denominator > 1000 do return -1
		sign := i64(1)
		if index % 2 == 1 do sign = -1
		delta := numerator*(index+1) - sign*denominator
		if delta < 0 do delta = -delta
		if delta*1_000_000_000 > denominator*(index+1) do return 0
	}
	return 1
}
