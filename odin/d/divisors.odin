package divisors

import "core:c"

// Encode the source divisor list in a lossless positive signed-i64 bit mask.
@(export)
divisors :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 1 do return -1
	n := values[0]
	if n < 1 || n > 62 do return -1
	mask := u64(0)
	for divisor := i64(1); divisor <= n; divisor += 1 {
		if n % divisor == 0 do mask |= u64(1) << u32(divisor)
	}
	return i64(mask)
}
