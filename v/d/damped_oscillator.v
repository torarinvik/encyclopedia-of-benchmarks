module damped_oscillator

import math

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'damped_oscillator']
pub fn damped_oscillator(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 5 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 1024 || input[1] < 0 || input[1] > 1024 || input[2] < -1024 || input[2] > 1024 || input[3] < -1024 || input[3] > 1024 || input[4] < 1 || input[4] > 1024 { return -1 }
		if unsafe { output == nil } || capacity < 16 { return -2 }
		omega0 := f64(input[0]) / 1024.0
		gamma := f64(input[1]) / 1024.0
		x := f64(input[2]) / 1024.0
		v := f64(input[3]) / 1024.0
		dt := f64(input[4]) / 1024.0
		acceleration := -2.0 * gamma * v - omega0 * omega0 * x
		x_next := x + dt * v
		v_next := v + dt * acceleration
		put_f64_le(mut output, 0, x_next)
		put_f64_le(mut output, 8, v_next)
		return 16
	}
}
