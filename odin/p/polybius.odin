package polybius

import "core:c"

@(export)
polybius :: proc "c" (v: [^]i64, n: c.size_t, out: [^]u8, cap: c.size_t) -> i64 {
	if v == nil || n < 1 || n > 65 || v[0] < 0 || v[0] > 64 || n != c.size_t(v[0] + 1) do return -1
	count := int(v[0]); needed := count * 2
	if needed > int(cap) || (needed > 0 && out == nil) do return -2
	for i := 0; i < count; i += 1 {
		x := v[i + 1]
		if x >= 97 && x <= 122 do x -= 32
		if x < 65 || x > 90 || x == 74 do return -1
		index := x - 65
		if x > 74 do index -= 1
		out[i * 2] = u8(65 + index / 5)
		out[i * 2 + 1] = u8(65 + index % 5)
	}
	return i64(needed)
}
