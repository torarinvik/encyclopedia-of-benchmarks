package trig_functions

import "core:c"
import "core:math"

PI :: 3.14159265358979323846

finite_value :: proc(value: f64) -> bool {
	return value == value && !math.is_inf_f64(value)
}

nan_value :: proc() -> f64 {
	zero: f64 = 0.0
	return zero / zero
}

rounded_six :: proc(value: f64) -> f64 {
	magnitude := math.floor_f64(math.abs(value) * 1_000_000.0 + 0.5) / 1_000_000.0
	return if value < 0.0 { -magnitude } else { magnitude }
}

integer_power :: proc(value: f64, exponent: int) -> f64 {
	result: f64 = 1.0
	for _ in 0..<exponent do result *= value
	return result
}

factorial_double :: proc(n: int) -> f64 {
	result: f64 = 1.0
	for factor := 2; factor <= n; factor += 1 do result *= f64(factor)
	return result
}

trig_series :: proc(input_value, tolerance: f64, kind: int) -> f64 {
	value := input_value
	period := 2.0 * PI
	for value >= period do value -= period
	for value <= -period do value += period
	result: f64 = 0.0
	previous: f64 = 1.0
	step := 0
	for math.abs(previous-result) > tolerance {
		previous = result
		power := 2*step + kind
		term := integer_power(value, power) / factorial_double(power)
		if step % 2 == 0 do result += term else do result -= term
		step += 1
	}
	return rounded_six(result)
}

@(export)
trig_functions :: proc "c" (input: [^]f64, length: c.size_t,
						 output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length != c.size_t(3) do return -1
	selector_value := input[0]
	x := input[1]
	tolerance := input[2]
	if !finite_value(selector_value) || selector_value < 0.0 || selector_value > 7.0 do return -1
	selector := int(selector_value)
	if selector_value != f64(selector) do return -1
	if !finite_value(tolerance) || tolerance < 1e-9 || tolerance > 1e-2 do return -1
	if finite_value(x) && (x < -10000.0 || x > 10000.0) do return -1
	if output == nil || capacity < c.size_t(1) do return -2
	if !finite_value(x) { output[0] = nan_value(); return 1 }
	mut value := x
	if selector == 2 || selector == 3 || selector == 6 || selector == 7 do value = value * PI / 180.0
	result: f64 = 0.0
	if selector == 0 || selector == 2 do result = trig_series(value, tolerance, 1)
	else if selector == 1 || selector == 3 do result = trig_series(value, tolerance, 0)
	else if selector == 4 || selector == 6 {
		denominator := trig_series(value, tolerance, 0)
		result = if denominator == 0.0 { nan_value() } else { trig_series(value, tolerance, 1) / denominator }
	} else {
		denominator := trig_series(value, tolerance, 1)
		result = if denominator == 0.0 { nan_value() } else { trig_series(value, tolerance, 0) / denominator }
	}
	output[0] = result
	return 1
}
