package mibench_automotive_basicmath_isqrt

import "core:c"

@(export)
mibench_automotive_basicmath_isqrt :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	if input[0] < 0 || input[0] > 65535 do return -1
	x := u32(input[0])
	root: u32 = 0
	remainder: u32 = 0
	for step := 0; step < 32; step += 1 {
		remainder = (remainder << 2) + (x >> 30)
		x <<= 2
		root <<= 1
		trial := (root << 1) + 1
		if remainder >= trial {
			remainder -= trial
			root += 1
		}
	}
	return i64(root)
}
