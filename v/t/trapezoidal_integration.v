module trapezoidal_integration

const scale = i64(1_000_000)
const max_endpoint_micro = i64(1_000_000)
const max_steps = i64(10_000)
const invalid_result = -1.0e300

fn sample_value(function_id i64, x f64) f64 {
	if function_id == 0 { return x * x }
	return x * x * x
}

@[export: 'trapezoidal_integration']
pub fn trapezoidal_integration(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 4 { return invalid_result }
	start_micro, end_micro := unsafe { values[0] }, unsafe { values[1] }
	steps, function_id := unsafe { values[2] }, unsafe { values[3] }
	if start_micro < -max_endpoint_micro || start_micro > max_endpoint_micro ||
		end_micro < -max_endpoint_micro || end_micro > max_endpoint_micro ||
		steps < 1 || steps > max_steps || function_id < 0 || function_id > 1 { return invalid_result }
	start := f64(start_micro) / f64(scale)
	end := f64(end_micro) / f64(scale)
	delta := (end - start) / f64(steps)
	total := f64(0)
	for index := i64(0); index < steps; index++ {
		left := start + delta * f64(index)
		right := left + delta
		midpoint := (sample_value(function_id, left) + sample_value(function_id, right)) * 0.5
		total += midpoint * delta
	}
	return total
}
