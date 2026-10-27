package min_plus_distance_product
import "core:c"

MAX_INPUT :: 130
MAX_OUTPUT :: 512
MAX_DIM :: 8
INF :: i64(1000000)

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits&255); bits >>= 8 }
}

@(export)
min_plus_distance_product :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > MAX_INPUT do return -1
	n0, m0 := input[0], input[1]
	if n0 < 1 || n0 > MAX_DIM || m0 < 1 || m0 > MAX_DIM do return -1
	n, m := int(n0), int(m0)
	if length != c.size_t(2+2*n*m) do return -1
	for i := 2; i < int(length); i += 1 {
		if input[i] < 0 || (input[i] > 1000 && input[i] != INF) do return -1
	}
	bytes := 8*n*n
	if bytes > MAX_OUTPUT do return -1
	if output == nil || capacity < c.size_t(bytes) do return -2
	result: [MAX_DIM*MAX_DIM]i64
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 {
			best := INF
			for k := 0; k < m; k += 1 {
				x, y := input[2+i*m+k], input[2+n*m+k*n+j]
				if x != INF && y != INF && x+y < best { best = x+y }
			}
			result[i*n+j] = best
		}
	}
	for i := 0; i < n*n; i += 1 { store_i64_le(output,8*i,result[i]) }
	return i64(bytes)
}
