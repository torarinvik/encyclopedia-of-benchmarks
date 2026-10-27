package apsp_min_plus_repeated_squaring

import "core:c"

MAX_N :: 8
MAX_INPUT :: 65
INF :: i64(1_000_000)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset+byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
apsp_min_plus_repeated_squaring :: proc "c" (input: [^]i64,
	length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n64 := input[0]
	if n64 < 1 || n64 > MAX_N do return -1
	n := int(n64)
	if length != c.size_t(1+n*n) do return -1
	var current, next: [MAX_N*MAX_N]i64
	for i := 0; i < n; i += 1 {
		for j := 0; j < n; j += 1 {
			value := input[1+i*n+j]
			if (i == j && value != 0) || (i != j && value != INF && (value < 1 || value > 1000)) do return -1
			current[i*n+j] = value
		}
	}
	edge_bound := 1
	for edge_bound < n-1 {
		for i := 0; i < n; i += 1 {
			for j := 0; j < n; j += 1 {
				best := INF
				for k := 0; k < n; k += 1 {
					left, right := current[i*n+k], current[k*n+j]
					if left != INF && right != INF && left+right < best { best = left+right }
				}
				next[i*n+j] = best
			}
		}
		for index := 0; index < n*n; index += 1 { current[index] = next[index] }
		edge_bound *= 2
	}
	bytes := 8*n*n
	if output == nil || capacity < c.size_t(bytes) do return -2
	for index := 0; index < n*n; index += 1 { store_i64_le(output, 8*index, current[index]) }
	return i64(bytes)
}
