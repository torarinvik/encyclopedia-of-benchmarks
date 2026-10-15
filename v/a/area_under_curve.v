module area_under_curve

const max_steps = i64(10000)
const max_coord_milli = i64(100000)
const output_scale = 1_000_000.0

fn sample_value(function_id i64, x f64) f64 {
	if function_id == 0 { return 5.0 }
	if function_id == 1 { return x }
	return x * x
}

// Composite trapezoidal integration for constant, linear, and quadratic samples.
@[export: 'area_under_curve']
pub fn area_under_curve(input &i64, length usize) i64 {
	if length != 4 { return -1 }
	unsafe {
		function_id := input[0]
		start_milli := input[1]
		end_milli := input[2]
		steps := input[3]
		if function_id < 0 || function_id > 2 || start_milli < 0 || start_milli > max_coord_milli ||
			end_milli < 0 || end_milli > max_coord_milli || steps < 1 || steps > max_steps { return -1 }
		low_milli := if start_milli < end_milli { start_milli } else { end_milli }
		high_milli := if start_milli < end_milli { end_milli } else { start_milli }
		start := f64(low_milli) / 1000.0
		ending := f64(high_milli) / 1000.0
		width := (ending - start) / f64(steps)
		mut x1 := start
		mut y1 := sample_value(function_id, x1)
		mut area := f64(0)
		for _ in 0 .. int(steps) {
			x2 := x1 + width
			y2 := sample_value(function_id, x2)
			area += (y1 + y2) * width * 0.5
			x1 = x2
			y1 = y2
		}
		return i64(area * output_scale + 0.5)
	}
}
