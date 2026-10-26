package tsvc_s275_column_conditional_axpy_recurrence

import "core:c"
import "core:math"

MAX_N :: 8

@(export)
tsvc_s275_column_conditional_axpy_recurrence :: proc "c" (input: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 193 do return -1
	rn := input[0]
	if rn != rn || math.trunc(rn) != rn || rn < 1 || rn > f64(MAX_N) do return -1
	n := int(rn)
	cells := n * n
	if length != c.size_t(1 + 3*cells) do return -1
	for i := 1; i < int(length); i += 1 {
		if input[i] != input[i] || math.trunc(input[i]) != input[i] || math.abs(input[i]) > 16 do return -1
	}
	if output == nil || capacity < c.size_t(cells) do return -2
	var a: [MAX_N*MAX_N]f64
	for i := 0; i < cells; i += 1 { a[i] = input[1+i] }
	bs := 1 + cells
	cs := 1 + 2*cells
	for col := 0; col < n; col += 1 {
		if a[col] > 0 {
			for row := 1; row < n; row += 1 {
				index := row*n + col
				a[index] = a[index-n] + input[bs+index] * input[cs+index]
			}
		}
	}
	for i := 0; i < cells; i += 1 { output[i] = a[i] }
	return i64(cells)
}
