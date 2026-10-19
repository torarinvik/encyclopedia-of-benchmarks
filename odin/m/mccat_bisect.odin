package mccat_bisect

import "core:c"

MAX_N :: 32
MAX_OUTPUT_BYTES :: (MAX_N + 1) * 8
EPSILON :: 2.2204460492503131e-16

abs_value :: proc "contextless" (value: f64) -> f64 {
	if value < 0.0 do return -value
	return value
}

sturm :: proc "contextless" (n: int, diagonal, off_diagonal, beta: [^]f64, x: f64) -> int {
	negative_count := 0
	q := 1.0
	for i := 0; i < n; i += 1 {
		if q != 0.0 do q = (diagonal[i] - x) - beta[i] / q
		else do q = (diagonal[i] - x) - abs_value(off_diagonal[i]) / EPSILON
		if q < 0.0 do negative_count += 1
	}
	return negative_count
}

store_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for i := 0; i < 8; i += 1 {
		output[offset+i] = u8(bits >> u64(8*i))
	}
}

solve :: proc "contextless" (n: int, staged: [^]u8) -> int {
	diagonal: [MAX_N]f64
	off_diagonal: [MAX_N]f64
	beta: [MAX_N]f64
	eigenvalues: [MAX_N+1]f64
	lower_bounds: [MAX_N+1]f64
	for i := 0; i < n; i += 1 {
		value := f64(i + 1)
		diagonal[i] = value * value
		diagonal[i] = diagonal[i] * diagonal[i]
		off_diagonal[i] = f64(i)
		beta[i] = off_diagonal[i] * off_diagonal[i]
	}
	beta[0] = 0.0
	off_diagonal[0] = 0.0

	fudge := 1.01
	xmin := diagonal[n-1] - fudge * abs_value(off_diagonal[n-1])
	xmax := diagonal[n-1] + fudge * abs_value(off_diagonal[n-1])
	for i := n-2; i >= 0; i -= 1 {
		h := fudge * (abs_value(off_diagonal[i]) + abs_value(off_diagonal[i+1]))
		if diagonal[i]+h > xmax do xmax = diagonal[i]+h
		if diagonal[i]-h < xmin do xmin = diagonal[i]-h
	}
	eps2 := EPSILON * (if xmin+xmax > 0.0 then xmax else -xmin)
	eps1 := EPSILON
	if eps1 <= 0.0 do eps1 = eps2
	eps2 = 0.5*eps1 + 7.0*eps2

	x0 := xmax
	for i := n; i >= 1; i -= 1 {
		eigenvalues[i] = xmax
		lower_bounds[i] = xmin
	}
	iterations := 0
	for k := n; k >= 1; k -= 1 {
		xu := xmin
		for i := k; i >= 1; i -= 1 {
			if xu < lower_bounds[i] { xu = lower_bounds[i]; break }
		}
		if x0 > eigenvalues[k] do x0 = eigenvalues[k]
		x1 := (xu + x0) / 2.0
		for x0-xu > 2.0*EPSILON*(abs_value(xu)+abs_value(x0))+eps1 {
			iterations += 1
			count := sturm(n, &diagonal[0], &off_diagonal[0], &beta[0], x1)
			if count < k {
				if count < 1 { xu = x1; lower_bounds[1] = x1 }
				else {
					xu = x1
					lower_bounds[count+1] = x1
					if eigenvalues[count] > x1 do eigenvalues[count] = x1
				}
			} else do x0 = x1
			x1 = (xu + x0) / 2.0
		}
		eigenvalues[k] = (xu + x0) / 2.0
	}

	used := 0
	for i := 2; i <= n; i += 1 { store_f64_le(staged, used, eigenvalues[i]); used += 8 }
	store_f64_le(staged, used, eps2); used += 8
	store_f64_le(staged, used, f64(iterations)); used += 8
	return used
}

@(export)
mccat_bisect :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length != 1 do return -1
	if values[0] < 2 || values[0] > MAX_N do return -1
	n := int(values[0])
	required := c.size_t((n + 1) * 8)
	if output == nil || capacity < required do return -2
	staged: [MAX_OUTPUT_BYTES]u8
	used := solve(n, &staged[0])
	for i := 0; i < used; i += 1 { output[i] = staged[i] }
	return i64(used)
}
