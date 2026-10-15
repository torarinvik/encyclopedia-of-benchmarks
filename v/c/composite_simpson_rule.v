module composite_simpson_rule

import math

const invalid_result = -1.0
const max_intervals = 128

fn sample(function_id int, x f64) f64 {
	match function_id {
		0 { return math.sqrt(x) + math.log(x) }
		1 { return math.exp(-x) * (4.0 - math.pow(x, 2.0)) }
		2 { return math.sqrt(2.0 * math.pow(x, 3.0) + 3.0) }
		else { return x + math.log(2.0 * x + 1.0) }
	}
}

@[export: 'composite_simpson_rule']
pub fn composite_simpson_rule(intervals_input f64, function_id_input f64) f64 {
	if math.is_nan(intervals_input) || math.is_nan(function_id_input) ||
		intervals_input < 2.0 || intervals_input > max_intervals ||
		function_id_input < 0.0 || function_id_input > 3.0 ||
		math.floor(intervals_input) != intervals_input || math.floor(function_id_input) != function_id_input {
		return invalid_result
	}
	intervals := int(intervals_input)
	if intervals % 2 != 0 { return invalid_result }
	function_id := int(function_id_input)
	h := 2.0 / f64(intervals)
	mut x := 1.0
	mut sum := 0.0
	for i := 0; i <= intervals; i++ {
		y := sample(function_id, x)
		weight := if i == 0 || i == intervals { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }
		sum += weight * y
		x += h
	}
	return sum * (h / 3.0)
}
