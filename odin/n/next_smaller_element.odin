package next_smaller_element

import "core:c"

put_i64_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
	bits := transmute(u64)value
	for b: usize = 0; b < 8; b += 1 { output[offset+b] = u8(bits >> u64(8*b)) }
}

@(export)
next_smaller_element :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 do return -1
	if input[0] < 0 || input[0] > 1024 do return -1
	n := usize(input[0]); if length != n + 1 do return -1
	for i: usize = 0; i < n; i += 1 { if input[i+1] < -2147483648 || input[i+1] > 2147483647 do return -1 }
	if capacity < n*8 || (n > 0 && output == nil) do return -2
	stack: [1024]i64
	top: usize = 0
	for i: usize = 0; i < n; i += 1 {
		value := input[i+1]
		for top > 0 && stack[top-1] >= value { top -= 1 }
		previous: i64 = -1; if top > 0 do previous = stack[top-1]
		put_i64_le(output, i*8, previous)
		stack[top] = value; top += 1
	}
	return i64(n*8)
}
