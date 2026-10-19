module partialsums

import math

const max_n = 10000
const output_count = 9

@[export: 'partialsums']
pub fn partialsums(input &f64, length usize, mut output &f64, capacity usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	unsafe {
		n_value := input[0]
		if !n_value.is_finite() || math.trunc(n_value) != n_value || n_value < 1.0 || n_value > f64(max_n) { return -1 }
		n := int(n_value)
		mut geometric := 0.0
		mut inverse_sqrt := 0.0
		mut flint := 0.0
		mut cookson := 0.0
		mut telescoping := [2]f64{}
		mut harmonic := [2]f64{}
		mut zeta := [2]f64{}
		mut alternating := [2]f64{}
		mut gregory := [2]f64{}
		mut term := 1.0
		vector_limit := n + (n & 1)
		for k in 1 .. vector_limit + 1 {
			kd := f64(k)
			lane := (k - 1) & 1
			if k <= n {
				k3 := kd * kd * kd
				s := math.sin(kd)
				c := math.cos(kd)
				geometric += term
				term *= 2.0 / 3.0
				inverse_sqrt += 1.0 / math.sqrt(kd)
				flint += 1.0 / (k3 * s * s)
				cookson += 1.0 / (k3 * c * c)
			}
			telescoping[lane] += 1.0 / (kd * (kd + 1.0))
			harmonic[lane] += 1.0 / kd
			zeta[lane] += 1.0 / (kd * kd)
			sign := if lane == 0 { 1.0 } else { -1.0 }
			alternating[lane] += sign / kd
			gregory[lane] += sign / (2.0 * kd - 1.0)
		}
		if output == nil || capacity < output_count { return -2 }
		output[0] = geometric
		output[1] = inverse_sqrt
		output[2] = telescoping[0] + telescoping[1]
		output[3] = flint
		output[4] = cookson
		output[5] = harmonic[0] + harmonic[1]
		output[6] = zeta[0] + zeta[1]
		output[7] = alternating[0] + alternating[1]
		output[8] = gregory[0] + gregory[1]
		return output_count
	}
}
