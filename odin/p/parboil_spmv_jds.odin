package parboil_spmv_jds

import "core:c"

decode :: proc(v: i64) -> f32 { return f32(v) / 1_000_000.0 }
put32 :: proc(out: [^]u8, p: int, x: u32) {
	out[p] = u8(x); out[p+1] = u8(x >> 8); out[p+2] = u8(x >> 16); out[p+3] = u8(x >> 24)
}

@(export)
parboil_spmv_jds :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 164 do return -1
	if input[0] < 1 || input[0] > 8 || input[1] < 1 || input[1] > 8 || input[2] < 1 || input[2] > 64 do return -1
	n, d, z := int(input[0]), int(input[1]), int(input[2])
	if length != c.size_t(4 + 3*n + d + 2*z) do return -1
	row: [8]i64 = {}; perm: [8]i64 = {}; ptr: [9]i64 = {}; col: [64]i64 = {}; data: [64]i64 = {}; vec: [8]i64 = {}
	p := 3
	for i := 0; i < n; i += 1 { if input[p] < 0 || input[p] > i64(d) do return -1; row[i] = input[p]; p += 1 }
	if row[0] != i64(d) do return -1
	for i := 1; i < n; i += 1 { if row[i] > row[i-1] do return -1 }
	for i := 0; i < n; i += 1 { perm[i] = input[p]; p += 1 }
	for i := 0; i < n; i += 1 {
		if perm[i] < 0 || perm[i] >= i64(n) do return -1
		for j := 0; j < i; j += 1 { if perm[i] == perm[j] do return -1 }
	}
	for k := 0; k <= d; k += 1 { ptr[k] = input[p]; p += 1 }
	for j := 0; j < z; j += 1 { col[j] = input[p]; p += 1 }
	for j := 0; j < z; j += 1 { data[j] = input[p]; p += 1 }
	for i := 0; i < n; i += 1 { vec[i] = input[p]; p += 1 }
	if ptr[0] != 0 do return -1
	off := 0
	for k := 0; k < d; k += 1 { count := 0; for i := 0; i < n; i += 1 { if row[i] > i64(k) do count += 1 }; off += count; if ptr[k+1] != i64(off) do return -1 }
	if off != z do return -1
	for j := 0; j < z; j += 1 { if col[j] < 0 || col[j] >= i64(n) || data[j] < -1_000_000 || data[j] > 1_000_000 do return -1 }
	for i := 0; i < n; i += 1 { if vec[i] < -1_000_000 || vec[i] > 1_000_000 do return -1 }
	if output == nil || capacity < c.size_t(4+4*n) do return -2
	y: [8]f32 = {}; stage: [36]u8 = {}
	for i := 0; i < n; i += 1 { acc: f32 = 0; for k := 0; k < int(row[i]); k += 1 { j := int(ptr[k])+i; product := decode(data[j])*decode(vec[int(col[j])]); acc = acc+product }; y[int(perm[i])] = acc }
	put32(&stage[0], 0, u32(n)); for i := 0; i < n; i += 1 { put32(&stage[0], 4+4*i, transmute(u32)y[i]) }
	for i := 0; i < 4+4*n; i += 1 { output[i] = stage[i] }
	return i64(4+4*n)
}
