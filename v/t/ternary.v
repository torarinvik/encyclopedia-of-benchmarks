module ternary

import math

const max_input_length = usize(6)
const invalid_result = -1.0e300

fn objective(operation i64, x f64) f64 {
	delta := if operation == 0 { x - 1.0 } else { x + 1.0 }
	square := delta * delta
	return if operation == 0 { -square } else { square }
}

fn ternary_search(operation i64, a f64, b f64, epsilon f64, frame i64, max_calls i64) f64 {
	if math.abs(a - b) <= epsilon { return objective(operation, (a + b) / 2.0) }
	left := (2.0 * a + b) / 3.0
	right := (a + 2.0 * b) / 3.0
	left_value := objective(operation, left)
	right_value := objective(operation, right)
	take_left := if operation == 0 { left_value < right_value } else { left_value > right_value }
	if frame >= max_calls { return invalid_result }
	if take_left { return ternary_search(operation, left, b, epsilon, frame + 1, max_calls) }
	return ternary_search(operation, a, right, epsilon, frame + 1, max_calls)
}

@[export: 'ternary']
pub fn ternary(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 5 || length > max_input_length { return invalid_result }
	unsafe {
		operation := input[0]
		a_milli := input[1]
		b_milli := input[2]
		epsilon_micro := input[3]
		max_calls := input[4]
		if length != 5 || (operation != 0 && operation != 1) ||
			a_milli < -1_000_000 || a_milli > b_milli || b_milli > 1_000_000 ||
			epsilon_micro < 1 || epsilon_micro > 1_000_000 || max_calls < 1 || max_calls > 64 { return invalid_result }

		return ternary_search(operation, f64(a_milli) / 1000.0, f64(b_milli) / 1000.0,
			f64(epsilon_micro) / 1_000_000.0, 1, max_calls)
	}
}
