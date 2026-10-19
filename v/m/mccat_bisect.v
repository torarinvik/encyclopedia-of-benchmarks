module mccat_bisect

import math

const max_n = 32
const max_output_bytes = (max_n + 1) * 8
const epsilon = 2.2204460492503131e-16

fn abs_value(value f64) f64 {
	return if value < 0.0 { -value } else { value }
}

fn sturm(diagonal []f64, off_diagonal []f64, beta []f64, n int, x f64) int {
	mut negative_count := 0
	mut q := 1.0
	for i in 0 .. n {
		if q != 0.0 { q = (diagonal[i] - x) - beta[i] / q }
		else { q = (diagonal[i] - x) - abs_value(off_diagonal[i]) / epsilon }
		if q < 0.0 { negative_count++ }
	}
	return negative_count
}

fn put_f64_le(mut output []u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for i in 0 .. 8 {
		output[offset + i] = u8(bits & 255)
		bits >>= 8
	}
}

fn solve(n int, mut staged []u8) int {
	mut diagonal := []f64{len: max_n, init: 0.0}
	mut off_diagonal := []f64{len: max_n, init: 0.0}
	mut beta := []f64{len: max_n, init: 0.0}
	mut eigenvalues := []f64{len: max_n + 1, init: 0.0}
	mut lower_bounds := []f64{len: max_n + 1, init: 0.0}
	for i in 0 .. n {
		value := f64(i + 1)
		diagonal[i] = value * value
		diagonal[i] = diagonal[i] * diagonal[i]
		off_diagonal[i] = f64(i)
		beta[i] = off_diagonal[i] * off_diagonal[i]
	}
	beta[0] = 0.0
	off_diagonal[0] = 0.0

	fudge := 1.01
	mut xmin := diagonal[n - 1] - fudge * abs_value(off_diagonal[n - 1])
	mut xmax := diagonal[n - 1] + fudge * abs_value(off_diagonal[n - 1])
	for i := n - 2; i >= 0; i-- {
		h := fudge * (abs_value(off_diagonal[i]) + abs_value(off_diagonal[i + 1]))
		if diagonal[i] + h > xmax { xmax = diagonal[i] + h }
		if diagonal[i] - h < xmin { xmin = diagonal[i] - h }
	}
	mut eps2 := epsilon * (if xmin + xmax > 0.0 { xmax } else { -xmin })
	mut eps1 := epsilon
	if eps1 <= 0.0 { eps1 = eps2 }
	eps2 = 0.5 * eps1 + 7.0 * eps2

	mut x0 := xmax
	for i := n; i >= 1; i-- {
		eigenvalues[i] = xmax
		lower_bounds[i] = xmin
	}
	mut iterations := 0
	for k := n; k >= 1; k-- {
		mut xu := xmin
		for i := k; i >= 1; i-- {
			if xu < lower_bounds[i] { xu = lower_bounds[i]; break }
		}
		if x0 > eigenvalues[k] { x0 = eigenvalues[k] }
		mut x1 := (xu + x0) / 2.0
		for x0 - xu > 2.0 * epsilon * (abs_value(xu) + abs_value(x0)) + eps1 {
			iterations++
			count := sturm(diagonal, off_diagonal, beta, n, x1)
			if count < k {
				if count < 1 { xu = x1; lower_bounds[1] = x1 }
				else {
					xu = x1
					lower_bounds[count + 1] = x1
					if eigenvalues[count] > x1 { eigenvalues[count] = x1 }
				}
			} else { x0 = x1 }
			x1 = (xu + x0) / 2.0
		}
		eigenvalues[k] = (xu + x0) / 2.0
	}

	mut used := 0
	for i in 2 .. n + 1 {
		put_f64_le(mut staged, used, eigenvalues[i])
		used += 8
	}
	put_f64_le(mut staged, used, eps2)
	used += 8
	put_f64_le(mut staged, used, f64(iterations))
	used + 8
}

@[export: 'mccat_bisect']
pub fn mccat_bisect(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length != 1 || values[0] < 2 || values[0] > max_n { return -1 }
		 n := int(values[0])
		required := (n + 1) * 8
		if output == nil || output_capacity < usize(required) { return -2 }
		mut staged := []u8{len: max_output_bytes, init: 0}
		used := solve(n, mut staged)
		for i in 0 .. used { output[i] = staged[i] }
		return i64(used)
	}
}
