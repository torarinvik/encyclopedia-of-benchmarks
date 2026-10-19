package mibench_automotive_basicmath_cubic

import "core:c"
import "core:math"

INPUT_COUNT :: 4
MAX_ROOTS :: 3

solve_cubic :: proc "contextless" (input: [^]f64, roots: [^]f64) -> i64 {
	a, b, cval, d := input[0], input[1], input[2], input[3]
	a1, a2, a3 := b/a, cval/a, d/a
	q := (a1*a1 - 3.0*a2)/9.0
	r := (2.0*a1*a1*a1 - 9.0*a1*a2 + 27.0*a3)/54.0
	discriminant := r*r - q*q*q
	if discriminant == 0.0 do return -1
	if discriminant <= 0.0 {
		pi := math.acos(-1.0)
		theta := math.acos(r / math.sqrt(q*q*q))
		roots[0] = -2.0*math.sqrt(q)*math.cos(theta/3.0) - a1/3.0
		roots[1] = -2.0*math.sqrt(q)*math.cos((theta+2.0*pi)/3.0) - a1/3.0
		roots[2] = -2.0*math.sqrt(q)*math.cos((theta+4.0*pi)/3.0) - a1/3.0
		return 3
	}
	abs_r := r
	if abs_r < 0.0 do abs_r = -abs_r
	root := math.pow_f64(math.sqrt(discriminant) + abs_r, 1.0/3.0)
	root += q/root
	if r < 0.0 { root *= 1.0 } else { root *= -1.0 }
	roots[0] = root - a1/3.0
	return 1
}

@(export)
mibench_automotive_basicmath_cubic :: proc "c" (input: [^]f64,
	input_length: c.size_t, output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length != c.size_t(INPUT_COUNT) do return -1
	for index := 0; index < INPUT_COUNT; index += 1 {
		if !(input[index] >= -100.0 && input[index] <= 100.0) do return -1
	}
	if input[0] > -1.0 && input[0] < 1.0 do return -1
	mut roots: [MAX_ROOTS]f64
	count := solve_cubic(input, &roots[0])
	if count < 0 do return -1
	if output == nil || output_capacity < c.size_t(count) do return -2
	for index := 0; index < int(count); index += 1 { output[index] = roots[index] }
	return count
}
