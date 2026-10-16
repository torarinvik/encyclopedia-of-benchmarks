package gauss_seidel_method

import "core:c"
import "core:math"

put_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for b: int = 0; b < 8; b += 1 { output[offset+b] = u8(bits >> u64(8*b)) }
}

@(export)
gauss_seidel_method :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || input[0] < 1 || input[0] > 8 do return -1
	n := int(input[0])
	if length != c.size_t(1+n*n+n) do return -1
	rhs := 1+n*n
	for k := 1; k < int(length); k += 1 do if input[k] < -1_000_000_000 || input[k] > 1_000_000_000 do return -1
	for row := 0; row < n; row += 1 {
		diagonal := input[1+row*n+row]
		if diagonal <= 0 do return -1
		off_sum: i64 = 0
		for col := 0; col < n; col += 1 {
			value := input[1+row*n+col]
			if value != input[1+col*n+row] do return -1
			if row != col {
				if value < 0 { off_sum += -value } else { off_sum += value }
			}
		}
		if diagonal <= off_sum do return -1
	}
	if output == nil || capacity < c.size_t(n*8) do return -2
	a: [64]f64
	b: [8]f64
	x: [8]f64
	old: [8]f64
	for i := 0; i < n*n; i += 1 do a[i] = f64(input[i+1])/1_000_000.0
	for i := 0; i < n; i += 1 do b[i] = f64(input[rhs+i])/1_000_000.0
	for iteration := 0; iteration < 1000; iteration += 1 {
		for i := 0; i < n; i += 1 do old[i] = x[i]
		for i := 0; i < n; i += 1 {
			before: f64 = 0
			for j := 0; j < i; j += 1 do before += a[i*n+j]*x[j]
			after: f64 = 0
			for j := i+1; j < n; j += 1 do after += a[i*n+j]*old[j]
			x[i] = (b[i]-before-after)/a[i*n+i]
		}
		done := true
		for i := 0; i < n; i += 1 do if math.abs(x[i]-old[i]) >= 1.0e-10 do done = false
		if done do break
	}
	for i := 0; i < n; i += 1 do put_f64_le(output, i*8, math.round(x[i]*1.0e10)/1.0e10)
	return i64(n*8)
}
