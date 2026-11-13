package romberg_integration

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 5

exact_integer :: proc(value: f64, low, high: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(low) || value > f64(high) do return false
	return f64(i64(value)) == value
}

integrand :: proc(id: i64, x: f64) -> f64 {
	if id == 0 do return math.exp_f64(x)
	if id == 1 do return x*x*x*x*x
	if id == 2 do return 1.0/(1.0+x*x)
	return math.cos_f64(x)
}

romberg :: proc(id: i64, a, b: f64, levels: i64) -> f64 {
	if a == b do return 0.0
	mut previous: [9]f64 = {}
	previous[0] = (b-a)*(integrand(id,a)+integrand(id,b))*0.5
	for level: i64 = 1; level <= levels; level += 1 {
		interval_count := i64(1) << u32(level)
		spacing := (b-a)/f64(interval_count)
		mut added := 0.0
		for index: i64 = 1; index < interval_count; index += 2 {
			added += integrand(id,a+f64(index)*spacing)
		}
		mut current: [9]f64 = {}
		current[0] = previous[0]*0.5+spacing*added
		mut factor := 4.0
		for order: i64 = 1; order <= level; order += 1 {
			current[order] = current[order-1]+(current[order-1]-previous[order-1])/(factor-1.0)
			factor *= 4.0
		}
		previous = current
	}
	return previous[levels]
}

@(export)
romberg_integration :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length != 4 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0],0,3) || !exact_integer(input[1],-1_000_000,1_000_000) ||
		!exact_integer(input[2],-1_000_000,1_000_000) || !exact_integer(input[3],3,8) do return -1
	id := i64(input[0])
	a_micro := i64(input[1])
	b_micro := i64(input[2])
	levels := i64(input[3])
	if a_micro > b_micro do return -1
	if output == nil || output_capacity < 1 do return -2
	result := romberg(id,f64(a_micro)/1_000_000.0,f64(b_micro)/1_000_000.0,levels)
	if math.is_nan(result) || math.is_inf(result) do return -1
	output[0] = result
	return 1
}
