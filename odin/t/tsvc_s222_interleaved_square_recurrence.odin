package tsvc_s222_interleaved_square_recurrence

import "core:c"
import "core:math"

seed_ok :: proc(x: f64) -> bool { return x == -1 || x == -0.5 || x == 0 || x == 0.5 || x == 1 }

@(export)
tsvc_s222_interleaved_square_recurrence :: proc "c" (input: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 257 do return -1
	rn := input[0]
	if rn != rn || math.trunc(rn) != rn || rn < 1 || rn > 64 do return -1
	n := int(rn)
	if length != c.size_t(1+4*n) do return -1
	for i := 1; i < 1+3*n; i += 1 {
		if input[i] != input[i] || math.trunc(input[i]) != input[i] || math.abs(input[i]) > 2 do return -1
	}
	for i := 1+3*n; i < int(length); i += 1 {
		if input[i] != input[i] || !seed_ok(input[i]) do return -1
	}
	required := 2*n
	if output == nil || capacity < c.size_t(required) do return -2
	 a: [64]f64
	 e: [64]f64
	for i := 0; i < n; i += 1 { a[i]=input[1+i]; e[i]=input[1+3*n+i] }
	for i := 1; i < n; i += 1 {
		product := input[1+n+i]*input[1+2*n+i]
		a[i]=a[i]+product
		e[i]=e[i-1]*e[i-1]
		a[i]=a[i]-product
	}
	for i := 0; i < n; i += 1 { output[i]=a[i]; output[n+i]=e[i] }
	return i64(required)
}
