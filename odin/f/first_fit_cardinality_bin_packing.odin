package first_fit_cardinality_bin_packing

import "core:c"

put_i64 :: proc(out: [^]u8, at: int, value: i64) {
	bits := cast(u64)value
	for b := 0; b < 8; b += 1 { out[at*8+b] = u8((bits >> u64(8*b)) & 255) }
}

first_fit_cardinality_bin_packing :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 35 do return -1
	n0, limit, cap := input[0], input[1], input[2]
	if n0 < 1 || n0 > 32 || limit < 1 || limit > 32 || cap < 1 || cap > 10000 || length != c.size_t(n0+3) do return -1
	n := int(n0)
	for i := 0; i < n; i += 1 { if input[3+i] < 1 || input[3+i] > cap do return -1 }
	loads: [32]i64; used: [32]i64; owners: [32]i64
	bins := 0
	for i := 0; i < n; i += 1 {
		size := input[3+i]
		b := 0
		for b < bins && (used[b] >= limit || loads[b] > cap-size) { b += 1 }
		if b == bins { bins += 1 }
		loads[b] += size; used[b] += 1; owners[i] = i64(b)
	}
	bytes := 8 * (n + 1)
	if output == nil || capacity < c.size_t(bytes) do return -2
	put_i64(output, 0, i64(bins))
	for i := 0; i < n; i += 1 { put_i64(output, i+1, owners[i]) }
	return i64(bytes)
}
