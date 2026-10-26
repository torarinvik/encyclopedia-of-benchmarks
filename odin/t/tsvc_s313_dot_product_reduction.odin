package tsvc_s313_dot_product_reduction

import "core:c"
import "core:math"

MAX_N :: 64

@(export)
tsvc_s313_dot_product_reduction :: proc "c" (input: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 129 do return -1
	raw_n := input[0]
	if raw_n != raw_n || math.trunc(raw_n) != raw_n || raw_n < 1 || raw_n > f64(MAX_N) do return -1
	n := int(raw_n)
	if length != c.size_t(1 + 2*n) do return -1
	for i := 1; i < int(length); i += 1 {
		if input[i] != input[i] || math.trunc(input[i]) != input[i] || math.abs(input[i]) > 1000 do return -1
	}
	if output == nil || capacity < 1 do return -2
	sum: f64 = 0
	for i := 0; i < n; i += 1 { sum += input[1+i] * input[1+n+i] }
	output[0] = sum
	return 1
}
