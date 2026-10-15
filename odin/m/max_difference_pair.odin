package max_difference_pair

import "core:c"

Pair :: struct { small, big: i64 }

solve :: proc "contextless" (values: [^]i64, start, n: usize) -> Pair {
	if n == 1 do return Pair{values[start], values[start]}
	left_n := n / 2
	left := solve(values, start, left_n)
	right := solve(values, start + left_n, n - left_n)
	min_left, max_right := values[start], values[start + left_n]
	for i := start + 1; i < start + left_n; i += 1 { if values[i] < min_left do min_left = values[i] }
	for i := start + left_n + 1; i < start + n; i += 1 { if values[i] > max_right do max_right = values[i] }
	cross := max_right - min_left
	right_diff, left_diff := right.big - right.small, left.big - left.small
	if right_diff > cross && right_diff > left_diff do return right
	if left_diff > cross do return left
	return Pair{min_left, max_right}
}

put_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
	bits := transmute(u64)value
	for b: usize = 0; b < 8; b += 1 { output[offset+b] = u8(bits >> u64(8*b)) }
}

@(export)
max_difference_pair :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	if input[0] < 1 || input[0] > 128 do return -1
	n := usize(input[0]); if length != n + 1 do return -1
	for i: usize = 0; i < n; i += 1 { if input[i+1] < -1000000 || input[i+1] > 1000000 do return -1 }
	if output == nil || capacity < 16 do return -2
	result := solve(input, 1, n)
	put_le(output, 0, result.small); put_le(output, 8, result.big)
	return 16
}
