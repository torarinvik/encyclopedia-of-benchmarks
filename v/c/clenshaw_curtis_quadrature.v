import math

const cc_max_parseable_input_length = 19
const cc_pi = 3.14159265358979323846264338327950288

fn cc_exact_integer(value f64, low i64, high i64) bool {
	return value.is_finite() && value >= f64(low) && value <= f64(high) && f64(i64(value)) == value
}

fn cc_compute(n int, samples &f64) f64 {
	mut result := 0.0
	for k in 0 .. n + 1 {
		mut inner := 0.0
		for j in 1 .. n / 2 + 1 {
			bj := if j == n / 2 { 1.0 } else { 2.0 }
			denominator := f64(4 * j * j - 1)
			angle := (((2.0 * f64(j)) * f64(k)) * cc_pi) / f64(n)
			term := (bj / denominator) * math.cos(angle)
			inner += term
		}
		gk := if k == 0 || k == n { 1.0 } else { 2.0 }
		weight := (gk / f64(n)) * (1.0 - inner)
		result += weight * unsafe { samples[k + 1] }
	}
	return result
}

@[export: 'clenshaw_curtis_quadrature']
pub fn clenshaw_curtis_quadrature(input &f64, input_length usize, mut output &f64,
	output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 4 || input_length > cc_max_parseable_input_length { return -1 }
		if !cc_exact_integer(input[0], 2, 16) { return -1 }
		n := int(input[0])
		if n % 2 != 0 || input_length != usize(n + 2) { return -1 }
		for i in 1 .. input_length {
			if !input[i].is_finite() || math.abs(input[i]) > 1000.0 { return -1 }
		}
		if output == nil || output_capacity < 1 { return -2 }
		value := cc_compute(n, input)
		if !value.is_finite() { return -1 }
		output[0] = value
		return 1
	}
}
