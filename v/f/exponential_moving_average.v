module exponential_moving_average

import math

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'exponential_moving_average']
pub fn exponential_moving_average(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 { return -1 }
	wv := unsafe { input[0] }
	nv := unsafe { input[1] }
	if wv < 2 || wv > 32 || nv < 1 || nv > 256 { return -1 }
	w := int(wv)
	n := int(nv)
	if length != usize(n + 2) { return -1 }
	unsafe {
		for i in 0 .. n { if input[2 + i] < -1_000_000 || input[2 + i] > 1_000_000 { return -1 } }
		if output == nil || capacity < n * 8 { return -2 }
		alpha := 2.0 / (1.0 + f64(w))
		mut average := f64(0)
		for i in 0 .. n {
			price := f64(input[2 + i])
			if i == 0 { average = price }
			else if i <= w { average = (average + price) * 0.5 }
			else { average = (alpha * price) + ((1.0 - alpha) * average) }
			put_f64_le(mut output, i * 8, average)
		}
	}
	return i64(n * 8)
}
