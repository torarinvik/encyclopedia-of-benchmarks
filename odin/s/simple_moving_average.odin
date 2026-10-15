package simple_moving_average

import "core:c"

put_u64_le :: proc(bits_value: u64, output: [^]u8, offset: usize) {
	bits := bits_value
	for byte: usize = 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
simple_moving_average :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
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
		if i + 1 < w {
			put_u64_le(0x7ff8000000000000, output, i * 8)
		} else {
			sum: i64 = 0
			for j := i + 1 - w; j <= i; j += 1 { sum += input[2 + j] }
			average := f64(sum) / f64(w)
			put_u64_le(transmute(u64)average, output, i * 8)
		}
	}
	return i64(n * 8)
}
