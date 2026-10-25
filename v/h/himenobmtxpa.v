module himenobmtxpa

import math

@[export: 'himenobmtxpa']
pub fn himenobmtxpa(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || length != 4 { return -1 }
		mut dims := [4]int{}
		for q in 0 .. 4 {
			value := input[q]
			if !value.is_finite() || math.trunc(value) != value { return -1 }
			if q < 3 {
				if value < 2.0 || value > 6.0 { return -1 }
			} else if value < 1.0 || value > 4.0 { return -1 }
			dims[q] = int(value)
		}
		nx, ny, nz, iterations := dims[0], dims[1], dims[2], dims[3]
		if output == nil || capacity < 1 { return -2 }

		mut p := [216]f32{}
		mut work := [216]f32{}
		a3 := f32(1) / f32(6)
		omega := f32(0.8)
		denominator := f32((nx - 1) * (nx - 1))
		for i in 0 .. nx {
			for j in 0 .. ny {
				for k in 0 .. nz {
					q := i * ny * nz + j * nz + k
					p[q] = f32(i * i) / denominator
				}
			}
		}
		mut gosa := f32(0)
		for _ in 0 .. iterations {
			gosa = f32(0)
			for i in 1 .. nx - 1 {
				for j in 1 .. ny - 1 {
					for k in 1 .. nz - 1 {
						q := i * ny * nz + j * nz + k
						mut s0 := p[q + ny * nz] + p[q + nz] + p[q + 1]
						s0 = s0 + p[q - ny * nz] + p[q - nz] + p[q - 1]
						ss := s0 * a3 - p[q]
						gosa = gosa + ss * ss
						work[q] = p[q] + omega * ss
					}
				}
			}
			for i in 1 .. nx - 1 {
				for j in 1 .. ny - 1 {
					for k in 1 .. nz - 1 {
						q := i * ny * nz + j * nz + k
						p[q] = work[q]
					}
				}
			}
		}
		output[0] = f64(gosa)
		return 1
	}
}
