module npb_ep

import math

const max_pairs = 4096
const modulus_mask = u64(70_368_744_177_663)
const word_mask = u64(8_388_607)
const multiplier = u64(1_220_703_125)
const modulus_scale = 70_368_744_177_664.0

fn is_bounded_integer(value f64, minimum f64, maximum f64) bool {
	return value.is_finite() && math.trunc(value) == value && value >= minimum && value <= maximum
}

fn advance_state(state u64) u64 {
	low := state & word_mask
	high := state >> 23
	multiplier_low := multiplier & word_mask
	multiplier_high := multiplier >> 23
	low_product := low * multiplier_low
	cross := (low * multiplier_high + high * multiplier_low) & word_mask
	return (low_product + (cross << 23)) & modulus_mask
}

@[export: 'npb_ep']
pub fn npb_ep(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		if !is_bounded_integer(input[0], 1.0, f64(max_pairs)) ||
			!is_bounded_integer(input[1], 1.0, 70_368_744_177_663.0) { return -1 }
		pair_count := int(input[0])
		if output == nil || capacity < 12 { return -2 }

		mut state := u64(input[1])
		mut histogram := [10]u64{}
		mut sum_x := f64(0.0)
		mut sum_y := f64(0.0)
		for _ in 0 .. pair_count {
			state = advance_state(state)
			x := 2.0 * (f64(state) / modulus_scale) - 1.0
			state = advance_state(state)
			y := 2.0 * (f64(state) / modulus_scale) - 1.0
			radius_squared := x * x + y * y
			if radius_squared <= 0.0 || radius_squared > 1.0 { continue }
			scale := math.sqrt(-2.0 * math.log(radius_squared) / radius_squared)
			normal_x := x * scale
			normal_y := y * scale
			abs_x := if normal_x < 0.0 { -normal_x } else { normal_x }
			abs_y := if normal_y < 0.0 { -normal_y } else { normal_y }
			extent := if abs_x > abs_y { abs_x } else { abs_y }
			if extent < 10.0 { histogram[int(extent)]++ }
			sum_x += normal_x
			sum_y += normal_y
		}
		for bin in 0 .. 10 { output[bin] = f64(histogram[bin]) }
		output[10] = sum_x
		output[11] = sum_y
		return 12
	}
}
