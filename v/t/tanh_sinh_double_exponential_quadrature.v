import math

const ts_max_parseable_input_length = 3
const ts_pi = 3.14159265358979323846264338327950288

fn ts_exact_integer(value f64, low i64, high i64) bool {
	return value.is_finite() && value >= f64(low) && value <= f64(high) && f64(i64(value)) == value
}

fn ts_integrate(function_id int, p int) f64 {
	h := 1.0 / f64(1 << p)
	half_pi := ts_pi / 2.0
	limit := 3 * (1 << p)
	mut total := 0.0
	for j in -limit .. limit + 1 {
		t := f64(j) * h
		exp_t := math.exp(t)
		exp_minus_t := math.exp(-t)
		sinh_t := (exp_t-exp_minus_t)*0.5
		cosh_t := (exp_t+exp_minus_t)*0.5
		u := half_pi*sinh_t
		abs_u := if u < 0.0 { -u } else { u }
		q := math.exp(-2.0*abs_u)
		one_plus_q := 1.0+q
		sech_squared := (4.0*q)/(one_plus_q*one_plus_q)
		magnitude_x := (1.0-q)/one_plus_q
		x := if u >= 0.0 { magnitude_x } else { -magnitude_x }
		jacobian := (half_pi*cosh_t)*sech_squared
		mut sample := 0.0
		if function_id == 0 { sample = 1.0 }
		else if function_id == 1 { sample = x*x }
		else if function_id == 2 { sample = 1.0/math.sqrt(sech_squared) }
		else if u >= 0.0 { sample = 1.0/math.sqrt((2.0*q)/one_plus_q) }
		else { sample = 1.0/math.sqrt(2.0/one_plus_q) }
		transformed := sample*jacobian
		total += h*transformed
	}
	return total
}

@[export: 'tanh_sinh_double_exponential_quadrature']
pub fn tanh_sinh_double_exponential_quadrature(input &f64, input_length usize, mut output &f64,
	output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > ts_max_parseable_input_length { return -1 }
		if input_length != 2 || !ts_exact_integer(input[0],0,3) || !ts_exact_integer(input[1],2,4) { return -1 }
		if output == nil || output_capacity < 1 { return -2 }
		value := ts_integrate(int(input[0]),int(input[1]))
		if !value.is_finite() { return -1 }
		output[0] = value
		return 1
	}
}
