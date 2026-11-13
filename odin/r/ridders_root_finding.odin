package ridders_root_finding

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 6

exact_integer :: proc(value: f64, low, high: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(low) || value > f64(high) do return false
	return f64(i64(value)) == value
}

polynomial :: proc(id: i64, x: f64) -> f64 {
	if id == 0 do return x*x-2.0
	if id == 1 do return x*x*x-2.0
	if id == 2 do return x*x*x+x-1.0
	return x
}

opposite :: proc(a, b: f64) -> bool { return (a < 0.0) != (b < 0.0) }

@(export)
ridders_root_finding :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length != 5 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 0, 3) || !exact_integer(input[1], -3000, 3000) ||
		!exact_integer(input[2], -3000, 3000) || !exact_integer(input[3], 1, 1000) ||
		!exact_integer(input[4], 24, 32) do return -1
	id := i64(input[0])
	left_milli := i64(input[1])
	right_milli := i64(input[2])
	tolerance_micro := i64(input[3])
	iterations := i64(input[4])
	if left_milli >= right_milli do return -1
	left := f64(left_milli)/1000.0
	right := f64(right_milli)/1000.0
	mut f_left := polynomial(id, left)
	mut f_right := polynomial(id, right)
	if f_left != 0.0 && f_right != 0.0 && !opposite(f_left, f_right) do return -1
	if output == nil || output_capacity < 1 do return -2
	if f_left == 0.0 { output[0] = left; return 1 }
	if f_right == 0.0 { output[0] = right; return 1 }
	tolerance := f64(tolerance_micro)/1_000_000.0
	for step in 0..<iterations {
		if right-left <= tolerance { output[0] = (left+right)*0.5; return 1 }
		middle := (left+right)*0.5
		f_middle := polynomial(id, middle)
		if f_middle == 0.0 { output[0] = middle; return 1 }
		radicand := f_middle*f_middle-f_left*f_right
		if math.is_nan(radicand) || math.is_inf(radicand) || radicand <= 0.0 do return -3
		denominator := math.sqrt(radicand)
		if math.is_nan(denominator) || math.is_inf(denominator) || denominator == 0.0 do return -3
		direction := f64(1.0)
		if f_left < f_right do direction = -1.0
		candidate := middle+(middle-left)*direction*f_middle/denominator
		if math.is_nan(candidate) || math.is_inf(candidate) || candidate <= left || candidate >= right do return -3
		f_candidate := polynomial(id, candidate)
		if f_candidate == 0.0 { output[0] = candidate; return 1 }
		if opposite(f_left, f_candidate) { right = candidate; f_right = f_candidate }
		else { left = candidate; f_left = f_candidate }
		if right-left <= tolerance { output[0] = (left+right)*0.5; return 1 }
	}
	return -3
}
