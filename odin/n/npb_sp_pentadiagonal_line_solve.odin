package npb_sp_pentadiagonal_line_solve

import "core:c"
import "core:math"

MIN_N :: 5
MAX_N :: 16

@(export)
npb_sp_pentadiagonal_line_solve :: proc "c" (input: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 31 || length > 97 do return -1
	n_value := input[0]
	if n_value != n_value || math.trunc(n_value) != n_value || n_value < 5 || n_value > 16 do return -1
	n := int(n_value)
	if length != c.size_t(1 + 6*n) do return -1
	if input[1] != 0 || input[2] != 0 || input[1+n] != 0 ||
		input[4*n] != 0 || input[5*n-1] != 0 || input[5*n] != 0 do return -1
	for row := 0; row < n; row += 1 {
		lower2 := input[1+row]
		lower1 := input[1+n+row]
		diagonal := input[1+2*n+row]
		upper1 := input[1+3*n+row]
		upper2 := input[1+4*n+row]
		rhs := input[1+5*n+row]
		bands := [4]f64{lower2, lower1, upper1, upper2}
		radius: f64 = 0
		for band in bands {
			if band != band || math.abs(band) > 2 do return -1
			radius += math.abs(band)
		}
		if diagonal != diagonal || diagonal < 5 || diagonal > 16 ||
			rhs != rhs || rhs < -64 || rhs > 64 || diagonal-radius < 0.25 do return -1
	}
	if output == nil || capacity < c.size_t(n) do return -2
	lo1: [MAX_N]f64
	diag: [MAX_N]f64
	up1: [MAX_N]f64
	up2: [MAX_N]f64
	work_rhs: [MAX_N]f64
	solution: [MAX_N]f64
	for row := 0; row < n; row += 1 {
		lo1[row] = input[1+n+row]; diag[row] = input[1+2*n+row]
		up1[row] = input[1+3*n+row]; up2[row] = input[1+4*n+row]; work_rhs[row] = input[1+5*n+row]
	}
	for pivot_row := 0; pivot_row < n; pivot_row += 1 {
		pivot := diag[pivot_row]
		if pivot_row+1 < n {
			row := pivot_row+1
			factor := lo1[row]/pivot
			diag[row] -= factor*up1[pivot_row]
			up1[row] -= factor*up2[pivot_row]
			work_rhs[row] -= factor*work_rhs[pivot_row]
		}
		if pivot_row+2 < n {
			row := pivot_row+2
			factor := input[1+row]/pivot
			lo1[row] -= factor*up1[pivot_row]
			diag[row] -= factor*up2[pivot_row]
			work_rhs[row] -= factor*work_rhs[pivot_row]
		}
	}
	back := n
	for back > 0 {
		back -= 1
		value := work_rhs[back]
		if back+1 < n do value -= up1[back]*solution[back+1]
		if back+2 < n do value -= up2[back]*solution[back+2]
		solution[back] = value/diag[back]
	}
	for row := 0; row < n; row += 1 do output[row] = solution[row]
	return i64(n)
}
