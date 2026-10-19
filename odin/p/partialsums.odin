package partialsums

import "core:c"
import "core:math"

MAX_N :: 10000
OUTPUT_COUNT :: 9

@(export)
partialsums :: proc "c" (input: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	n_value := input[0]
	if n_value != n_value || math.trunc(n_value) != n_value || n_value < 1.0 || n_value > f64(MAX_N) do return -1
	n := int(n_value)
	geometric, inverse_sqrt, flint, cookson: f64 = 0, 0, 0, 0
	telescoping, harmonic, zeta, alternating, gregory: [2]f64
	term := 1.0
	vector_limit := n + (n & 1)
	for k := 1; k <= vector_limit; k += 1 {
		kd := f64(k)
		lane := (k - 1) & 1
		if k <= n {
			k3 := kd * kd * kd
			s, co := math.sin(kd), math.cos(kd)
			geometric += term
			term *= 2.0 / 3.0
			inverse_sqrt += 1.0 / math.sqrt_f64(kd)
			flint += 1.0 / (k3 * s * s)
			cookson += 1.0 / (k3 * co * co)
		}
		telescoping[lane] += 1.0 / (kd * (kd + 1.0))
		harmonic[lane] += 1.0 / kd
		zeta[lane] += 1.0 / (kd * kd)
		sign := 1.0
		if lane != 0 do sign = -1.0
		alternating[lane] += sign / kd
		gregory[lane] += sign / (2.0 * kd - 1.0)
	}
	if output == nil || capacity < OUTPUT_COUNT do return -2
	output[0] = geometric
	output[1] = inverse_sqrt
	output[2] = telescoping[0] + telescoping[1]
	output[3] = flint
	output[4] = cookson
	output[5] = harmonic[0] + harmonic[1]
	output[6] = zeta[0] + zeta[1]
	output[7] = alternating[0] + alternating[1]
	output[8] = gregory[0] + gregory[1]
	return OUTPUT_COUNT
}
