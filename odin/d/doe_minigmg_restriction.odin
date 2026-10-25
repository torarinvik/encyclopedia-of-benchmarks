package doe_minigmg_restriction

import "core:c"

@(export)
doe_minigmg_restriction :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < c.size_t(11) || length > c.size_t(515) do return -1.0e300
	nx_raw, ny_raw, nz_raw := values[0], values[1], values[2]
	if nx_raw < 2 || nx_raw > 8 || nx_raw % 2 != 0 do return -1.0e300
	if ny_raw < 2 || ny_raw > 8 || ny_raw % 2 != 0 do return -1.0e300
	if nz_raw < 2 || nz_raw > 8 || nz_raw % 2 != 0 do return -1.0e300

	nx, ny, nz := int(nx_raw), int(ny_raw), int(nz_raw)
	cells := nx * ny * nz
	if length != c.size_t(3 + cells) do return -1.0e300
	for q := 0; q < cells; q += 1 {
		if values[3 + q] < -32768 || values[3 + q] > 32767 do return -1.0e300
	}

	coarse_nx, coarse_ny, coarse_nz := nx / 2, ny / 2, nz / 2
	plane := nx * ny
	checksum: f64 = 0.0
	coarse_index := 0
	for k := 0; k < coarse_nz; k += 1 {
		for j := 0; j < coarse_ny; j += 1 {
			for i := 0; i < coarse_nx; i += 1 {
				base := 3 + 2 * i + 2 * j * nx + 2 * k * plane
				sum := f64(values[base]) + f64(values[base + 1]) +
					f64(values[base + nx]) + f64(values[base + nx + 1]) +
					f64(values[base + plane]) + f64(values[base + plane + 1]) +
					f64(values[base + plane + nx]) + f64(values[base + plane + nx + 1])
				restricted := sum * 0.125
				weight := f64(coarse_index + 1)
				checksum += weight * restricted * restricted
				coarse_index += 1
			}
		}
	}
	return checksum
}
