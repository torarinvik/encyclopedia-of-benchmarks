package de_boor_bspline_curve_evaluation

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 24

exact_integer :: proc(value: f64, low, high: i64) -> bool {
	if math.is_nan(value) || math.is_inf(value) || value < f64(low) || value > f64(high) do return false
	return f64(i64(value)) == value
}

evaluate :: proc(p, n: i64, u: f64, knots, controls: [^]f64) -> f64 {
	span := p
	if u == knots[n] {
		span = n-1
	} else {
		for span < n-1 && u >= knots[span+1] { span += 1 }
	}
	mut local: [4]f64 = {}
	for j: i64 = 0; j <= p; j += 1 { local[j] = controls[span-p+j] }
	for level: i64 = 1; level <= p; level += 1 {
		for slot: i64 = p; slot >= level; slot -= 1 {
			left := span-p+slot
			right := span+slot-level+1
			denominator := knots[right]-knots[left]
			alpha := f64(0)
			if denominator != 0 do alpha = (u-knots[left])/denominator
			local[slot] = (1-alpha)*local[slot-1]+alpha*local[slot]
		}
	}
	return local[p]
}

@(export)
de_boor_bspline_curve_evaluation :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0],1,3) do return -1
	p := i64(input[0])
	if !exact_integer(input[1],p+1,8) || math.is_nan(input[2]) || math.is_inf(input[2]) do return -1
	n := i64(input[1])
	knot_count := n+p+1
	if input_length != c.size_t(3+knot_count+n) do return -1
	knots := input+3
	controls := knots+knot_count
	mut run: i64 = 1
	for i: i64 = 0; i < knot_count; i += 1 {
		if math.is_nan(knots[i]) || math.is_inf(knots[i]) || knots[i] < -1000 || knots[i] > 1000 do return -1
		if i > 0 {
			if knots[i] < knots[i-1] do return -1
			if knots[i] == knots[i-1] do run += 1 else run = 1
			if run > p+1 do return -1
		}
	}
	for i: i64 = 0; i < n; i += 1 {
		if math.is_nan(controls[i]) || math.is_inf(controls[i]) || controls[i] < -1000 || controls[i] > 1000 do return -1
	}
	if !(knots[p] < knots[n] && input[2] >= knots[p] && input[2] <= knots[n]) do return -1
	if output == nil || output_capacity < 1 do return -2
	result := evaluate(p,n,input[2],knots,controls)
	if math.is_nan(result) || math.is_inf(result) do return -1
	output[0] = result
	return 1
}
