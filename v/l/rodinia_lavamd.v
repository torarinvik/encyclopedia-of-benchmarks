module rodinia_lavamd

import math

const scale = 1_000_000.0
const bias = i64(1_000_000_000_000)

fn round_micro(value f64) i64 {
	scaled := value * scale
	if scaled < 0.0 { return -i64(math.floor(-scaled + 0.5)) }
	return i64(math.floor(scaled + 0.5))
}

// Rodinia source-order screened pair interactions over a home and one neighbor box.
@[export: 'rodinia_lavamd']
pub fn rodinia_lavamd(input &i64, length usize) i64 {
	if length < 12 || length > 42 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > 4 || input[1] < 1 || input[1] > 4 { return -1 }
		home_n := int(input[0]); neighbor_n := int(input[1])
		if length != usize(2 + 5*(home_n+neighbor_n)) { return -1 }
		mut particles := [2][4][5]f64{}
		counts := [home_n, neighbor_n]
		mut cursor := 2
		for box := 0; box < 2; box++ {
			for p := 0; p < counts[box]; p++ {
				for c := 0; c < 5; c++ {
					raw := input[cursor]; cursor++
					if raw < 0 || raw > 1000000 { return -1 }
					particles[box][p][c] = f64(raw) / scale
				}
			}
		}
		mut total := 0.0
		for i := 0; i < home_n; i++ {
			mut fv := 0.0; mut fx := 0.0; mut fy := 0.0; mut fz := 0.0
			for box := 0; box < 2; box++ {
				for j := 0; j < counts[box]; j++ {
					a := particles[0][i]; b := particles[box][j]
					dot := a[1]*b[1] + a[2]*b[2] + a[3]*b[3]
					r2 := a[0] + b[0] - dot
					vij := math.exp(-(0.5*r2)); fs := 2.0*vij
					dx := a[1]-b[1]; dy := a[2]-b[2]; dz := a[3]-b[3]
					fv += b[4]*vij; fx += b[4]*(fs*dx); fy += b[4]*(fs*dy); fz += b[4]*(fs*dz)
				}
			}
			total += f64(i+1)*((fv+fx)+fy+fz)
		}
		return bias + round_micro(total)
	}
}
