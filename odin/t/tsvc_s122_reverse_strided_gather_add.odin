package tsvc_s122_reverse_strided_gather_add

import "core:c"

// Clean-room port of TSVC s122; see package README for provenance and rights.
MAX_N :: 32

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s122_reverse_strided_gather_add :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 67 do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	if input[1] < 1 || input[1] > i64(n) || input[2] < 1 || input[2] > i64(n) do return -1
	if length != c.size_t(3 + 2 * n) do return -1
	start := int(input[1])
	stride := int(input[2])
	var a, b: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		a[i] = input[3 + i]
		b[i] = input[3 + n + i]
		if a[i] < -100 || a[i] > 100 || b[i] < -100 || b[i] > 100 do return -1
	}
	if output == nil || capacity < c.size_t(8 * n) do return -2
	j := 1
	k := 0
	for i := start - 1; i < n; i += stride {
		k += j
		a[i] += b[n - k]
	}
	for i := 0; i < n; i += 1 { store_i64_le(output, 8 * i, a[i]) }
	return i64(n)
}
