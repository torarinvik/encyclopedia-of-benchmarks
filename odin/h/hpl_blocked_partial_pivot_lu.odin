package hpl_blocked_partial_pivot_lu

import "core:c"

MAX_N :: 8
MAX_INPUT_LENGTH :: 66
MAX_OUTPUT_ELEMENTS :: 72

exact_integer :: proc(x: f64, lo, hi: i64) -> (i64, bool) {
	if x != x || x < f64(lo) || x > f64(hi) do return 0, false
	value := i64(x)
	if f64(value) != x do return 0, false
	return value, true
}

finite_value :: proc(x: f64) -> bool {
	return x == x && x >= -1e308 && x <= 1e308
}

@(export)
hpl_blocked_partial_pivot_lu :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	n_value, valid_n := exact_integer(input[0], 2, MAX_N)
	if !valid_n do return -1
	n := int(n_value)
	if int(input_length) != 1+n*n do return -1
	mut a: [64]f64
	for i := 0; i < n*n; i += 1 {
		value, valid := exact_integer(input[i+1], -16, 16)
		if !valid do return -1
		a[i] = f64(value)
	}
	mut pivots: [MAX_N]int
	mut panel := 0
	for panel < n {
		panel_end := panel+2
		if panel_end > n { panel_end = n }
		for col := panel; col < panel_end; col += 1 {
			mut pivot_row := col
			mut pivot_magnitude := a[col*n+col]
			if pivot_magnitude < 0 { pivot_magnitude = -pivot_magnitude }
			for row := col+1; row < n; row += 1 {
				mut magnitude := a[row*n+col]
				if magnitude < 0 { magnitude = -magnitude }
				if magnitude > pivot_magnitude { pivot_magnitude = magnitude; pivot_row = row }
			}
			if !finite_value(pivot_magnitude) || pivot_magnitude == 0 do return -1
			pivots[col] = pivot_row
			if pivot_row != col {
				for j := 0; j < n; j += 1 {
					temporary := a[col*n+j]; a[col*n+j] = a[pivot_row*n+j]; a[pivot_row*n+j] = temporary
				}
			}
			diagonal := a[col*n+col]
			if !finite_value(diagonal) || diagonal == 0 do return -1
			for row := col+1; row < n; row += 1 {
				a[row*n+col] /= diagonal
				if !finite_value(a[row*n+col]) do return -1
				multiplier := a[row*n+col]
				for j := col+1; j < panel_end; j += 1 {
					a[row*n+j] -= multiplier*a[col*n+j]
					if !finite_value(a[row*n+j]) do return -1
				}
			}
		}
		for row := panel; row < panel_end; row += 1 {
			for col := panel_end; col < n; col += 1 {
				mut value := a[row*n+col]
				for inner := panel; inner < row; inner += 1 { value -= a[row*n+inner]*a[inner*n+col] }
				if !finite_value(value) do return -1
				a[row*n+col] = value
			}
		}
		for row := panel_end; row < n; row += 1 {
			for col := panel_end; col < n; col += 1 {
				mut update: f64 = 0
				for inner := panel; inner < panel_end; inner += 1 { update += a[row*n+inner]*a[inner*n+col] }
				a[row*n+col] -= update
				if !finite_value(a[row*n+col]) do return -1
			}
		}
		panel = panel_end
	}
	mut staged: [MAX_OUTPUT_ELEMENTS]f64
	for i := 0; i < n; i += 1 { staged[i] = f64(pivots[i]) }
	for i := 0; i < n*n; i += 1 {
		if !finite_value(a[i]) do return -1
		staged[n+i] = a[i]
	}
	output_length := n+n*n
	if output == nil || capacity < c.size_t(output_length) do return -2
	for i := 0; i < output_length; i += 1 { output[i] = staged[i] }
	return i64(output_length)
}
