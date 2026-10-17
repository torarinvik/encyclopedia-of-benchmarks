module shreedharacharya

import math

const max_coefficient = 1_000_000.0
const min_abs_leading_coefficient = 0.000001

pub fn shreedharacharya(input &f64, input_len usize, mut output &f64, output_capacity usize) i64 {
	if unsafe { input == nil } || input_len != 3 { return -1 }
	unsafe {
		a := input[0]
		b := input[1]
		c := input[2]
		if !a.is_finite() || !b.is_finite() || !c.is_finite() ||
			a.abs() < min_abs_leading_coefficient || a.abs() > max_coefficient ||
			b.abs() > max_coefficient || c.abs() > max_coefficient { return -1 }

		discriminant := b * b - 4.0 * a * c
		mut roots := [2]f64{}
		mut count := 0
		if discriminant == 0.0 {
			roots[count] = -b / (2.0 * a)
			count++
		} else if discriminant > 0.0 {
			square_root := math.sqrt(discriminant)
			denominator := 2.0 * a
			roots[count] = (-b + square_root) / denominator
			count++
			roots[count] = (-b - square_root) / denominator
			count++
		}
		for index in 0 .. count { if !roots[index].is_finite() { return -1 } }
		if output == nil || output_capacity < usize(count) { return -2 }
		for index in 0 .. count { output[index] = roots[index] }
		return i64(count)
	}
}
