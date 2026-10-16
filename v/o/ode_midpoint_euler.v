module ode_midpoint_euler

import math

const max_steps = 8
const output_bytes = 16

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'ode_midpoint_euler']
pub fn ode_midpoint_euler(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length != 4 { return -1 }
	unsafe {
		steps := input[0]
		dt_quarters := input[1]
		u0 := input[2]
		v0 := input[3]
		if steps < 1 || steps > max_steps || dt_quarters < 1 || dt_quarters > 4 ||
			u0 < -10 || u0 > 10 || v0 < -10 || v0 > 10 { return -1 }
		if output == nil || capacity < output_bytes { return -2 }

		dt := f64(dt_quarters) / 4.0
		half_dt := 0.5 * dt
		mut u := f64(u0)
		mut v := f64(v0)
		for mut step := i64(0); step < steps; step++ {
			midpoint_u := u + half_dt * v
			midpoint_v := v - half_dt * u
			next_u := u + dt * midpoint_v
			next_v := v - dt * midpoint_u
			u = next_u
			v = next_v
		}
		put_f64_le(mut output, 0, u)
		put_f64_le(mut output, 8, v)
		return output_bytes
	}
}
