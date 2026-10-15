package streaming_moving_average

import "core:c"

put_f64_le :: proc(value: f64, output: [^]u8, offset: usize) {
	bits := transmute(u64)value
	for byte: usize = 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}

@(export)
streaming_moving_average :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 do return -1
	wv, nv := input[0], input[1]
	if wv < 1 || wv > 256 || nv < 1 || nv > 256 do return -1
	w, n := usize(wv), usize(nv)
	if length != n + 2 do return -1
	for i: usize = 0; i < n; i += 1 {
		if input[2 + i] < -2147483648 || input[2 + i] > 2147483647 do return -1
	}
	if capacity < n * 8 || output == nil do return -2
	for i: usize = 0; i < n; i += 1 {
		start: usize = 0
		if i + 1 > w { start = i + 1 - w }
		sum: i64 = 0
		for j := start; j <= i; j += 1 { sum += input[2 + j] }
		put_f64_le(f64(sum) / f64(i + 1 - start), output, i * 8)
	}
	return i64(n * 8)
}
