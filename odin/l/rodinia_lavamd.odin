package rodinia_lavamd

import "core:c"
import "core:math"

SCALE :: 1_000_000.0
BIAS :: i64(1_000_000_000_000)

round_micro :: proc(value: f64) -> i64 {
	scaled := value * SCALE
	if scaled < 0.0 do return -i64(math.floor(-scaled + 0.5))
	return i64(math.floor(scaled + 0.5))
}

// Rodinia source-order screened pair interactions over a home and one neighbor box.
@(export)
rodinia_lavamd :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 12 || length > 42 do return -1
	if input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 4 do return -1
	home_n := int(input[0]); neighbor_n := int(input[1])
	if length != c.size_t(2 + 5*(home_n+neighbor_n)) do return -1
	particles: [2][4][5]f64
	counts := [2]int{home_n, neighbor_n}
	cursor := 2
	for box in 0 ..< 2 {
		for p in 0 ..< counts[box] {
			for component in 0 ..< 5 {
				raw := input[cursor]; cursor += 1
				if raw < 0 || raw > 1_000_000 do return -1
				particles[box][p][component] = f64(raw) / SCALE
			}
		}
	}
	total := 0.0
	for i in 0 ..< home_n {
		fv := 0.0; fx := 0.0; fy := 0.0; fz := 0.0
		for box in 0 ..< 2 {
			for j in 0 ..< counts[box] {
				a := particles[0][i]; b := particles[box][j]
				dot := a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
				r2 := a[0] + b[0] - dot
				vij := math.exp_f64(-(0.5*r2)); fs := 2.0*vij
				dx := a[1]-b[1]; dy := a[2]-b[2]; dz := a[3]-b[3]
				fv += b[4]*vij; fx += b[4]*(fs*dx); fy += b[4]*(fs*dy); fz += b[4]*(fs*dz)
			}
		}
		total += f64(i+1)*((fv+fx)+fy+fz)
	}
	return BIAS + round_micro(total)
}
