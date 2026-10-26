package harmonic_4_bin_packing

import "core:c"

MAX_N :: 32
MAX_INPUT :: 33
CAPACITY :: i64(10000)

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits & 255); bits >>= 8 }
}

@(export)
harmonic_4_bin_packing :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n64 := input[0]
	if n64 < 1 || n64 > MAX_N || length != c.size_t(1+n64) do return -1
	n := int(n64)
	for i := 0; i < n; i += 1 do if input[1+i] < 1 || input[1+i] > CAPACITY do return -1
	output_bytes := 8*(n+1)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	current: [4]i64 = {-1, -1, -1, -1}
	remaining: [4]i64
	assignment: [MAX_N]i64
	bins: i64 = 0
	for i := 0; i < n; i += 1 {
		size := input[1+i]
		kind := 3
		if size*2 > CAPACITY { kind = 0 } else if size*3 > CAPACITY { kind = 1 } else if size*4 > CAPACITY { kind = 2 }
		if current[kind] < 0 || size > remaining[kind] {
			current[kind] = bins
			bins += 1
			remaining[kind] = CAPACITY
		}
		assignment[i] = current[kind]
		remaining[kind] -= size
	}
	store_i64_le(output, 0, bins)
	for i := 0; i < n; i += 1 do store_i64_le(output, 8*(i+1), assignment[i])
	return i64(output_bytes)
}
