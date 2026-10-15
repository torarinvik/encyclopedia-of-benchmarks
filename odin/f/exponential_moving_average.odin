package exponential_moving_average

import "core:c"

put_f64_le :: proc(value: f64, output: [^]u8, offset: usize) {
	bits := transmute(u64)value
	for byte: usize = 0; byte < 8; byte += 1 { output[offset + byte] = u8(bits >> u64(8 * byte)) }
}

@(export)
exponential_moving_average :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 do return -1
	wv, nv := input[0], input[1]
	if wv < 2 || wv > 32 || nv < 1 || nv > 256 do return -1
	w, n := usize(wv), usize(nv)
	if length != n + 2 do return -1
	for i: usize = 0; i < n; i += 1 { if input[2 + i] < -1_000_000 || input[2 + i] > 1_000_000 do return -1 }
	if output == nil || capacity < n * 8 do return -2
	alpha := 2.0 / (1.0 + f64(w))
	average: f64 = 0
	for i: usize = 0; i < n; i += 1 {
		price := f64(input[2 + i])
		if i == 0 { average = price }
		else if i <= w { average = (average + price) * 0.5 }
		else { average = (alpha * price) + ((1.0 - alpha) * average) }
		put_f64_le(average, output, i * 8)
	}
	return i64(n * 8)
}
