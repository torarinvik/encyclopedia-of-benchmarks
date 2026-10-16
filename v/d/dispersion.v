module dispersion

import math

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'dispersion']
pub fn dispersion(values &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { values == nil } || length == 0 || length > 128 { return -1 }
	unsafe {
		for i in 0 .. int(length) {
			if values[i] < -10000 || values[i] > 10000 { return -1 }
		}
		if output == nil || capacity < 16 { return -2 }
		mut sum := f64(0)
		for i in 0 .. int(length) { sum += f64(values[i]) }
		mean := sum / f64(length)
		mut squared_deviations := f64(0)
		for i in 0 .. int(length) {
			deviation := f64(values[i]) - mean
			squared_deviations += deviation * deviation
		}
		variance := squared_deviations / f64(length)
		put_f64_le(mut output, 0, variance)
		put_f64_le(mut output, 8, math.sqrt(variance))
		return 16
	}
}
