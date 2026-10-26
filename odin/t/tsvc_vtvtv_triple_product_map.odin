package tsvc_vtvtv_triple_product_map

import "core:c"
import "core:math"

@(export)
tsvc_vtvtv_triple_product_map :: proc "c" (input: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 193 do return -1
	rn := input[0]
	if rn != rn || math.trunc(rn) != rn || rn < 1 || rn > 64 do return -1
	n := int(rn)
	if length != c.size_t(1 + 3*n) do return -1
	for i := 1; i < int(length); i += 1 {
		if input[i] != input[i] || math.trunc(input[i]) != input[i] || math.abs(input[i]) > 2 do return -1
	}
	if output == nil || capacity < c.size_t(n) do return -2
	for i := 0; i < n; i += 1 { output[i] = (input[1+i] * input[1+n+i]) * input[1+2*n+i] }
	return i64(n)
}
