module mibench_automotive_basicmath_cubic

import math

const input_count = 4
const max_roots = 3

fn solve_cubic(input &f64, mut roots &f64) i64 {
	a := unsafe { input[0] }
	b := unsafe { input[1] }
	cval := unsafe { input[2] }
	d := unsafe { input[3] }
	a1 := b / a
	a2 := cval / a
	a3 := d / a
	q := (a1 * a1 - 3.0 * a2) / 9.0
	r := (2.0 * a1 * a1 * a1 - 9.0 * a1 * a2 + 27.0 * a3) / 54.0
	discriminant := r * r - q * q * q
	if discriminant == 0.0 { return -1 }
	if discriminant <= 0.0 {
		pi := math.acos(-1.0)
		theta := math.acos(r / math.sqrt(q * q * q))
		unsafe {
			roots[0] = -2.0 * math.sqrt(q) * math.cos(theta / 3.0) - a1 / 3.0
			roots[1] = -2.0 * math.sqrt(q) * math.cos((theta + 2.0 * pi) / 3.0) - a1 / 3.0
			roots[2] = -2.0 * math.sqrt(q) * math.cos((theta + 4.0 * pi) / 3.0) - a1 / 3.0
		}
		return 3
	}
	mut root := math.pow(math.sqrt(discriminant) + math.abs(r), 1.0 / 3.0)
	root += q / root
	root *= if r < 0.0 { 1.0 } else { -1.0 }
	unsafe { roots[0] = root - a1 / 3.0 }
	return 1
}

@[export: 'mibench_automotive_basicmath_cubic']
pub fn mibench_automotive_basicmath_cubic(input &f64, input_length usize,
	mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length != input_count { return -1 }
		for index in 0 .. input_count {
			if !input[index].is_finite() || input[index] < -100.0 || input[index] > 100.0 { return -1 }
		}
		if input[0] > -1.0 && input[0] < 1.0 { return -1 }
		mut roots := [max_roots]f64{}
		count := solve_cubic(input, &roots[0])
		if count < 0 { return -1 }
		if output == nil || output_capacity < usize(count) { return -2 }
		for index in 0 .. int(count) { output[index] = roots[index] }
		return count
	}
}
