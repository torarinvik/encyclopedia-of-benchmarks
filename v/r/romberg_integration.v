import math

fn romberg_exact_integer(value f64, low i64, high i64) bool {
	return value.is_finite() && value >= f64(low) && value <= f64(high) && f64(i64(value)) == value
}

fn romberg_integrand(id i64, x f64) f64 {
	if id == 0 { return math.exp(x) }
	if id == 1 { return x*x*x*x*x }
	if id == 2 { return 1.0/(1.0+x*x) }
	return math.cos(x)
}

fn romberg_compute(id i64, a f64, b f64, levels int) f64 {
	if a == b { return 0.0 }
	mut previous := [9]f64{}
	previous[0] = (b-a)*(romberg_integrand(id,a)+romberg_integrand(id,b))*0.5
	for level in 1 .. levels+1 {
		interval_count := 1 << level
		spacing := (b-a)/f64(interval_count)
		mut added := 0.0
		for index in 1 .. interval_count {
			if index % 2 == 1 { added += romberg_integrand(id,a+f64(index)*spacing) }
		}
		mut current := [9]f64{}
		current[0] = previous[0]*0.5+spacing*added
		mut factor := 4.0
		for order in 1 .. level+1 {
			current[order] = current[order-1]+(current[order-1]-previous[order-1])/(factor-1.0)
			factor *= 4.0
		}
		previous = current
	}
	return previous[levels]
}

@[export: 'romberg_integration']
pub fn romberg_integration(input &f64, input_length usize,
	mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length != 4 || input_length > 5 { return -1 }
		if !romberg_exact_integer(input[0],0,3) || !romberg_exact_integer(input[1],-1000000,1000000) ||
			!romberg_exact_integer(input[2],-1000000,1000000) || !romberg_exact_integer(input[3],3,8) { return -1 }
		id := i64(input[0]); a_micro := i64(input[1]); b_micro := i64(input[2]); levels := int(input[3])
		if a_micro > b_micro { return -1 }
		if output == nil || output_capacity < 1 { return -2 }
		result := romberg_compute(id,f64(a_micro)/1000000.0,f64(b_micro)/1000000.0,levels)
		if !result.is_finite() { return -1 }
		output[0] = result
		return 1
	}
}
