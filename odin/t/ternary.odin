package ternary

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 6
INVALID_RESULT :: -1.0e300

objective :: proc(operation: i64, x: f64) -> f64 {
	delta := x - 1.0
	if operation != 0 do delta = x + 1.0
	square := delta * delta
	if operation == 0 do return -square
	return square
}

ternary_search :: proc(operation: i64, a: f64, b: f64, epsilon: f64,
		frame: i64, max_calls: i64) -> f64 {
	if math.abs(a - b) <= epsilon do return objective(operation, (a + b) / 2.0)

	left := (2.0 * a + b) / 3.0
	right := (a + 2.0 * b) / 3.0
	left_value := objective(operation, left)
	right_value := objective(operation, right)
	take_left := left_value < right_value
	if operation == 1 do take_left = left_value > right_value
	if frame >= max_calls do return INVALID_RESULT
	if take_left do return ternary_search(operation, left, b, epsilon, frame + 1, max_calls)
	return ternary_search(operation, a, right, epsilon, frame + 1, max_calls)
}

@(export)
ternary :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 5 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	operation, a_milli, b_milli := input[0], input[1], input[2]
	epsilon_micro, max_calls := input[3], input[4]
	if length != 5 || (operation != 0 && operation != 1) ||
		a_milli < -1_000_000 || a_milli > b_milli || b_milli > 1_000_000 ||
		epsilon_micro < 1 || epsilon_micro > 1_000_000 || max_calls < 1 || max_calls > 64 do return INVALID_RESULT

	a := f64(a_milli) / 1000.0
	b := f64(b_milli) / 1000.0
	epsilon := f64(epsilon_micro) / 1_000_000.0
	return ternary_search(operation, a, b, epsilon, 1, max_calls)
}
