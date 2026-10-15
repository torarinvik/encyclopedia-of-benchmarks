module bisection_method

const max_coord_milli = i64(100000)
const max_tolerance_micro = i64(1000000)
const root_scale = 1_000_000.0
const max_iterations = 64

fn evaluate(equation i64, x f64) f64 {
	if equation == 0 { return x * x * x + 2.0 * x - 10.0 }
	return x * x * x - 4.0 * x - 9.0
}

// Return the rounded micro-unit root, -1 for invalid input, or -2 when not bracketed.
@[export: 'bisection_method']
pub fn bisection_method(input &i64, length usize) i64 {
	if length != 4 { return -1 }
	unsafe {
		equation := input[0]
		left_milli := input[1]
		right_milli := input[2]
		tolerance_micro := input[3]
		if equation < 0 || equation > 1 || left_milli < -max_coord_milli || left_milli > max_coord_milli ||
			right_milli < -max_coord_milli || right_milli > max_coord_milli || left_milli >= right_milli ||
			tolerance_micro < 1 || tolerance_micro > max_tolerance_micro { return -1 }
		mut left := f64(left_milli) / 1000.0
		mut right := f64(right_milli) / 1000.0
		mut f_left := evaluate(equation, left)
		f_right := evaluate(equation, right)
		if f_left == 0.0 { return i64(left * root_scale + 0.5) }
		if f_right == 0.0 { return i64(right * root_scale + 0.5) }
		if (f_left < 0.0) == (f_right < 0.0) { return -2 }
		tolerance := f64(tolerance_micro) / root_scale
		for _ in 0 .. max_iterations {
			middle := left + (right - left) * 0.5
			f_middle := evaluate(equation, middle)
			if f_middle == 0.0 { return i64(middle * root_scale + 0.5) }
			if (f_left < 0.0) != (f_middle < 0.0) { right = middle } else { left = middle; f_left = f_middle }
			if right - left <= tolerance { return i64((left + (right - left) * 0.5) * root_scale + 0.5) }
		}
		return -2
	}
}
