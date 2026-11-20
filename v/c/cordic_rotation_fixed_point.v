module main

import math

const cordic_scale = i64(1_000_000_000)
const cordic_half_pi = i64(1_570_796_327)
const cordic_angles = [
	i64(785_398_163), i64(463_647_609), i64(244_978_663), i64(124_354_995),
	i64(62_418_810), i64(31_239_833), i64(15_623_729), i64(7_812_341),
	i64(3_906_230), i64(1_953_123), i64(976_562), i64(488_281),
	i64(244_141), i64(122_070), i64(61_035),
]

fn cordic_shift_floor(value i64, shift int) i64 {
	if shift == 0 { return value }
	divisor := i64(1) << shift
	if value >= 0 { return value / divisor }
	return -((-value + divisor - 1) / divisor)
}

fn cordic_put_f64(mut output &u8, offset int, value f64) {
	mut bits := math.f64_bits(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((bits >> (byte * 8)) & 255) }
	}
}

@[export: 'cordic_rotation_fixed_point']
pub fn cordic_rotation_fixed_point(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 3 { return -1 }
		if length != 2 { return -1 }
		angle, stages := input[0], input[1]
		if angle < -3_141_592_653 || angle > 3_141_592_653 || stages < 1 || stages > 16 { return -1 }
		if output == nil || capacity < 24 { return -2 }

		mut x := cordic_scale
		mut y := i64(0)
		mut z := angle
		mut direction := if z >= 0 { i64(1) } else { i64(-1) }
		if direction > 0 {
			old_x := x
			x, y = -y, old_x
		} else {
			old_x := x
			x, y = y, -old_x
		}
		z -= direction * cordic_half_pi
		for shift in 0 .. int(stages - 1) {
			direction = if z >= 0 { i64(1) } else { i64(-1) }
			old_x, old_y := x, y
			x = old_x - direction * cordic_shift_floor(old_y, shift)
			y = old_y + direction * cordic_shift_floor(old_x, shift)
			z -= direction * cordic_angles[shift]
		}

		scale := 1_000_000_000.0
		cordic_put_f64(mut output, 0, f64(x) / scale)
		cordic_put_f64(mut output, 8, f64(y) / scale)
		cordic_put_f64(mut output, 16, f64(z) / scale)
		return 24
	}
}
