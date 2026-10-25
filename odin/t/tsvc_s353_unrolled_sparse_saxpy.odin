package tsvc_s353_unrolled_sparse_saxpy

import "core:c"

// Clean-room port of TSVC s353; see package README for provenance and rights.
MAX_N :: 20

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s353_unrolled_sparse_saxpy :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 17 || length > c.size_t(2 + 3 * MAX_N) do return -1
	if input[0] < 5 || input[0] > MAX_N || input[0] % 5 != 0 do return -1
	n := int(input[0])
	if length != c.size_t(2 + 3 * n) do return -1
	alpha := input[1]
	if alpha < -8 || alpha > 8 do return -1
	var a, b, indices: [MAX_N]i64
	for i in 0 ..< n {
		a[i] = input[2 + i]
		b[i] = input[2 + n + i]
		indices[i] = input[2 + 2 * n + i]
		if a[i] < -1_000_000 || a[i] > 1_000_000 || b[i] < -1_000_000 || b[i] > 1_000_000 ||
			indices[i] < 0 || indices[i] >= i64(n) do return -1
	}
	if output == nil || capacity < c.size_t(8 * n) do return -2
	for i := 0; i < n; i += 5 {
		a[i] += alpha * b[int(indices[i])]
		a[i + 1] += alpha * b[int(indices[i + 1])]
		a[i + 2] += alpha * b[int(indices[i + 2])]
		a[i + 3] += alpha * b[int(indices[i + 3])]
		a[i + 4] += alpha * b[int(indices[i + 4])]
	}
	for i in 0 ..< n do store_i64_le(output, 8 * i, a[i])
	return i64(n)
}
