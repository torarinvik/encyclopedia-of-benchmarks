module full_wave_rectifier

import math

fn store_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

// Evaluate the six pinned full-wave rectifier helper formulas.
@[export: 'full_wave_rectifier']
pub fn full_wave_rectifier(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length != 5 { return -1 }
	rf_i := unsafe { values[0] }
	rs_i := unsafe { values[1] }
	rl_i := unsafe { values[2] }
	vm_i := unsafe { values[3] }
	im_i := unsafe { values[4] }
	if rf_i < 0 || rf_i > 1000000 || rs_i < 0 || rs_i > 1000000 ||
		rl_i < 1 || rl_i > 1000000 || vm_i < -1000000 || vm_i > 1000000 ||
		im_i < -1000000 || im_i > 1000000 { return -1 }
	if unsafe { output == nil } || output_capacity < 48 { return -2 }

	rf, rs, rl := f64(rf_i), f64(rs_i), f64(rl_i)
	vm, im := f64(vm_i), f64(im_i)
	store_f64_le(mut output, 0, vm / (rf + rs + rl))
	store_f64_le(mut output, 8, 2.0 * im * 0.318)
	store_f64_le(mut output, 16, 2.0 * 0.318 * vm)
	store_f64_le(mut output, 24, vm / rl)
	store_f64_le(mut output, 32, im * 0.707)
	store_f64_le(mut output, 40, vm * 0.707)
	return 48
}
