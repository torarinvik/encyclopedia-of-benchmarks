package min_plus_convolution_convex_convex
import "core:c"

MAX_INPUT :: 259
MAX_OUTPUT :: 2040
MAX_N :: 128
MAX_M :: 128

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits&255)
		bits >>= 8
	}
}

min_plus_convolution_convex_convex :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 #export {
	if input == nil || length < 4 || length > c.size_t(MAX_INPUT) do return -1
	n0, m0 := input[0], input[1]
	if n0 < 1 || n0 > MAX_N || m0 < 1 || m0 > MAX_M do return -1
	n, m := int(n0), int(m0)
	if length != c.size_t(2+n+m) do return -1
	a: [MAX_N]i64
	b: [MAX_M]i64
	for i := 0; i < n+m; i += 1 {
		value := input[2+i]
		if value < 0 || value > 1_000_000_000 do return -1
		if i < n { a[i] = value } else { b[i-n] = value }
	}
	for i := 0; i+2 < n; i += 1 {
		if a[i+1]-a[i] > a[i+2]-a[i+1] do return -1
	}
	for i := 0; i+2 < m; i += 1 {
		if b[i+1]-b[i] > b[i+2]-b[i+1] do return -1
	}
	count := n+m-1
	bytes := 8*count
	if bytes > MAX_OUTPUT do return -1
	if output == nil || capacity < c.size_t(bytes) do return -2

	result: [MAX_N+MAX_M-1]i64
	result[0] = a[0]+b[0]
	ai, bi, out := 0, 0, 1
	for ai+1 < n || bi+1 < m {
		slope: i64
		if bi+1 == m || (ai+1 < n && a[ai+1]-a[ai] <= b[bi+1]-b[bi]) {
			slope = a[ai+1]-a[ai]
			ai += 1
		} else {
			slope = b[bi+1]-b[bi]
			bi += 1
		}
		result[out] = result[out-1]+slope
		out += 1
	}
	for i := 0; i < count; i += 1 { store_i64_le(output, 8*i, result[i]) }
	return i64(bytes)
}
