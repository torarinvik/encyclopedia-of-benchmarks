module streaming_moving_average

import math

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'streaming_moving_average']
pub fn streaming_moving_average(input &i64, length usize, mut output &u8, capacity usize) i64 {
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
			start := if i + 1 > w { i + 1 - w } else { 0 }
			mut sum := i64(0)
			for j := start; j <= i; j++ { sum += input[2 + j] }
			average := f64(sum) / f64(i + 1 - start)
			put_f64_le(mut output, i * 8, average)
		}
	}
	return i64(n * 8)
}
