module simple_moving_average

import math

fn put_u64_le(mut output &u8, offset int, bits_value u64) {
	mut bits := bits_value
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'simple_moving_average']
pub fn simple_moving_average(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 3 { return -1 }
	wv := unsafe { input[0] }
	nv := unsafe { input[1] }
	if wv < 1 || wv > 256 || nv < 1 || nv > 256 { return -1 }
	w := int(wv)
	n := int(nv)
	if length != usize(n + 2) { return -1 }
	unsafe {
		for i in 0 .. n {
			if input[2 + i] < -2147483648 || input[2 + i] > 2147483647 { return -1 }
		}
		if capacity < n * 8 || output == nil { return -2 }
		for i in 0 .. n {
			if i + 1 < w {
				put_u64_le(mut output, i * 8, u64(0x7ff8000000000000))
			} else {
				mut sum := i64(0)
				for j := i + 1 - w; j <= i; j++ { sum += input[2 + j] }
				average := f64(sum) / f64(w)
				put_u64_le(mut output, i * 8, math.bits_from_f64(average))
			}
		}
	}
	return i64(n * 8)
}
