package tsvc_s111_odd_index_neighbor_update

import "core:c"
import "core:math"

MAX_N :: 64

@(export)
tsvc_s111_odd_index_neighbor_update :: proc "c" (input: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 129 do return -1
	rn := input[0]
	if rn != rn || math.trunc(rn) != rn || rn < 1 || rn > f64(MAX_N) do return -1
	n := int(rn)
	if length != c.size_t(1 + 2*n) do return -1
	for i := 1; i < int(length); i += 1 {
		if input[i] != input[i] || math.trunc(input[i]) != input[i] || math.abs(input[i]) > 1000 do return -1
	}
	if output == nil || capacity < c.size_t(n) do return -2
	for i := 0; i < n; i += 1 { output[i] = input[1+i] }
	for i := 1; i < n; i += 2 { output[i] = input[1+i-1] + input[1+n+i] }
	return i64(n)
}
