package pairwise_iteration

import "core:c"

@(export)
pairwise_iteration :: proc "c" (v: [^]i64, n: c.size_t, out: [^]u8, cap: c.size_t) -> i64 {
	if v == nil || n < 1 || n > 129 || v[0] < 0 || v[0] > 128 || n != c.size_t(v[0] + 1) do return -1
	count := int(v[0])
	for i := 0; i < count; i += 1 { if v[i + 1] < -1000000 || v[i + 1] > 1000000 do return -1 }
	pairs := count - 1; if pairs < 0 do pairs = 0
	bytes := pairs * 16
	if c.size_t(bytes) > cap || (bytes > 0 && out == nil) do return -2
	k := 0
	for i := 0; i < pairs; i += 1 {
		for j := 0; j < 2; j += 1 {
			x := u64(v[i + j + 1])
			for b := 0; b < 8; b += 1 { out[k] = u8((x >> (8 * b)) & 255); k += 1 }
		}
	}
	return i64(bytes)
}
