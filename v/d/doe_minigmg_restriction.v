module doe_minigmg_restriction

@[export: 'doe_minigmg_restriction']
pub fn doe_minigmg_restriction(values &i64, length usize) f64 {
	if length < 11 || length > 515 { return -1.0e300 }
	unsafe {
		nx_raw := values[0]
		ny_raw := values[1]
		nz_raw := values[2]
		if nx_raw < 2 || nx_raw > 8 || nx_raw % 2 != 0 { return -1.0e300 }
		if ny_raw < 2 || ny_raw > 8 || ny_raw % 2 != 0 { return -1.0e300 }
		if nz_raw < 2 || nz_raw > 8 || nz_raw % 2 != 0 { return -1.0e300 }
		nx, ny, nz := int(nx_raw), int(ny_raw), int(nz_raw)
		cells := nx * ny * nz
		if length != usize(3 + cells) { return -1.0e300 }
		for q in 0 .. cells {
			if values[3 + q] < -32768 || values[3 + q] > 32767 { return -1.0e300 }
		}

		coarse_nx, coarse_ny, coarse_nz := nx / 2, ny / 2, nz / 2
		plane := nx * ny
		mut checksum := f64(0)
		mut coarse_index := 0
		for k in 0 .. coarse_nz {
			for j in 0 .. coarse_ny {
				for i in 0 .. coarse_nx {
					base := 3 + 2 * i + 2 * j * nx + 2 * k * plane
					sum := f64(values[base]) + f64(values[base + 1]) +
						f64(values[base + nx]) + f64(values[base + nx + 1]) +
						f64(values[base + plane]) + f64(values[base + plane + 1]) +
						f64(values[base + plane + nx]) + f64(values[base + plane + nx + 1])
					restricted := sum * 0.125
					weight := f64(coarse_index + 1)
					checksum += weight * restricted * restricted
					coarse_index++
				}
			}
		}
		return checksum
	}
}
