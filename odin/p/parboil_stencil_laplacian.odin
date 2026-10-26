package parboil_stencil_laplacian

import "core:c"
import "core:math"

@(export)
parboil_stencil_laplacian :: proc "c" (input: [^]f64, length: c.size_t,
    output: [^]f64, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 129 do return -1
	nxv, nyv, nzv, stepsv := input[0], input[1], input[2], input[3]
	if nxv != nxv || nyv != nyv || nzv != nzv || stepsv != stepsv do return -1
	if math.trunc(nxv) != nxv || math.trunc(nyv) != nyv || math.trunc(nzv) != nzv || math.trunc(stepsv) != stepsv do return -1
	if nxv < 3 || nxv > 5 || nyv < 3 || nyv > 5 || nzv < 3 || nzv > 5 || stepsv < 1 || stepsv > 4 do return -1
	nx, ny, nz, steps := int(nxv), int(nyv), int(nzv), int(stepsv)
	cells := nx * ny * nz
	if length != c.size_t(4 + cells) do return -1
	for q := 0; q < cells; q += 1 {
		value := input[4 + q]
		if value != value || value < -8 || value > 8 do return -1
	}
	if output == nil || capacity < c.size_t(cells) do return -2
	var a: [125]f32
	var b: [125]f32
	var staged: [125]f64
	for q := 0; q < cells; q += 1 { a[q] = f32(input[4 + q]); b[q] = a[q] }
	c0 := f32(1.0) / f32(6.0)
	c1 := (f32(1.0) / f32(6.0)) / f32(6.0)
	for step := 0; step < steps; step += 1 {
		for i := 1; i < nx-1; i += 1 { for j := 1; j < ny-1; j += 1 { for k := 1; k < nz-1; k += 1 {
			q := i + nx*(j + ny*k)
			sum := a[q + nx*ny] + a[q - nx*ny]
			sum = sum + a[q + nx]
			sum = sum + a[q - nx]
			sum = sum + a[q + 1]
			sum = sum + a[q - 1]
			neighbor_term := sum * c1
			center_term := a[q] * c0
			b[q] = neighbor_term - center_term
		} } }
		for q := 0; q < cells; q += 1 { temp := a[q]; a[q] = b[q]; b[q] = temp }
	}
	for q := 0; q < cells; q += 1 { staged[q] = f64(a[q]) }
	for q := 0; q < cells; q += 1 { output[q] = staged[q] }
	return i64(cells)
}
