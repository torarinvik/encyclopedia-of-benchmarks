package blocked_lu_factorization

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 66

exact_integer :: proc(x: f64, lo, hi: i64) -> bool {
	if math.is_nan(x) || math.is_inf(x) || x < f64(lo) || x > f64(hi) do return false
	return f64(i64(x)) == x
}

@(export)
blocked_lu_factorization :: proc "c" (input: [^]f64, input_length: c.size_t, output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
	if !exact_integer(input[0], 2, 8) do return -1
	n := int(input[0])
	if n % 2 != 0 || int(input_length) != 1+n*n do return -1
	mut schur: [64]f64
	for row := 0; row < n; row += 1 {
		off_sum := i64(0)
		for col := 0; col < n; col += 1 {
			p := row*n+col
			lo := i64(-2)
		hi := i64(2)
			if row == col { lo = 1; hi = 16 }
			if !exact_integer(input[p+1], lo, hi) do return -1
			value := i64(input[p+1])
			schur[p] = f64(value)
			if row != col {
				if value < 0 { off_sum += -value } else { off_sum += value }
			}
		}
		if schur[row*n+row] <= f64(off_sum) do return -1
	}
	mut lower, upper: [64]f64
	for k := 0; k < n; k += 2 {
		u00 := schur[k*n+k]
		u01 := schur[k*n+k+1]
		if u00 == 0 || math.is_nan(u00) || math.is_inf(u00) do return -1
		l10 := schur[(k+1)*n+k] / u00
		u11 := schur[(k+1)*n+k+1] - l10*u01
		if math.is_nan(l10) || math.is_inf(l10) || u11 == 0 || math.is_nan(u11) || math.is_inf(u11) do return -1
		lower[k*n+k] = 1
		lower[(k+1)*n+k] = l10
		lower[(k+1)*n+k+1] = 1
		upper[k*n+k] = u00
		upper[k*n+k+1] = u01
		upper[(k+1)*n+k+1] = u11
		for j := k+2; j < n; j += 2 {
			for col := j; col < j+2; col += 1 {
				s0 := schur[k*n+col]
				s1 := schur[(k+1)*n+col]
				upper[k*n+col] = s0
				upper[(k+1)*n+col] = s1-l10*s0
			}
		}
		for i := k+2; i < n; i += 2 {
			for row := i; row < i+2; row += 1 {
				s0 := schur[row*n+k]
				s1 := schur[row*n+k+1]
				l0 := s0/u00
				l1 := (s1-l0*u01)/u11
				lower[row*n+k] = l0
				lower[row*n+k+1] = l1
			}
		}
		for i := k+2; i < n; i += 2 {
			for j := k+2; j < n; j += 2 {
				for row := i; row < i+2; row += 1 {
					for col := j; col < j+2; col += 1 {
						update := lower[row*n+k]*upper[k*n+col] + lower[row*n+k+1]*upper[(k+1)*n+col]
						schur[row*n+col] -= update
					}
				}
			}
		}
	}
	mut staged: [128]f64
	m := n*n
	for row := 0; row < n; row += 1 {
		lower[row*n+row] = 1
		for col := row; col < n; col += 1 { upper[row*n+col] = schur[row*n+col] }
	}
	for i := 0; i < m; i += 1 {
		if math.is_nan(lower[i]) || math.is_inf(lower[i]) || math.is_nan(upper[i]) || math.is_inf(upper[i]) do return -1
		staged[i] = lower[i]
		staged[m+i] = upper[i]
	}
	length := 2*m
	if output == nil || capacity < c.size_t(length) do return -2
	for i := 0; i < length; i += 1 { output[i] = staged[i] }
	return i64(length)
}
