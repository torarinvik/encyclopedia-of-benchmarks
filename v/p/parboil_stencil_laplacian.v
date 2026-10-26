import math

@[export: 'parboil_stencil_laplacian']
pub fn parboil_stencil_laplacian(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > 129 { return -1 }
		nxv, nyv, nzv, stepsv := input[0], input[1], input[2], input[3]
		if !nxv.is_finite() || !nyv.is_finite() || !nzv.is_finite() || !stepsv.is_finite() ||
			math.trunc(nxv) != nxv || math.trunc(nyv) != nyv || math.trunc(nzv) != nzv || math.trunc(stepsv) != stepsv { return -1 }
		if nxv < 3 || nxv > 5 || nyv < 3 || nyv > 5 || nzv < 3 || nzv > 5 || stepsv < 1 || stepsv > 4 { return -1 }
		nx, ny, nz, steps := int(nxv), int(nyv), int(nzv), int(stepsv)
		cells := nx * ny * nz
		if length != usize(4 + cells) { return -1 }
		for q in 0 .. cells {
			value := input[4 + q]
			if !value.is_finite() || value < -8 || value > 8 { return -1 }
		}
		if output == nil || capacity < usize(cells) { return -2 }
		mut a := [125]f32{}
		mut b := [125]f32{}
		mut staged := [125]f64{}
		for q in 0 .. cells { a[q] = f32(input[4 + q]); b[q] = a[q] }
		c0 := f32(1.0) / f32(6.0)
		c1 := (f32(1.0) / f32(6.0)) / f32(6.0)
		for _ in 0 .. steps {
			for i in 1 .. nx-1 { for j in 1 .. ny-1 { for k in 1 .. nz-1 {
				q := i + nx * (j + ny * k)
				mut sum := f32(a[q + nx * ny] + a[q - nx * ny])
				sum = f32(sum + a[q + nx])
				sum = f32(sum + a[q - nx])
				sum = f32(sum + a[q + 1])
				sum = f32(sum + a[q - 1])
				neighbor_term := f32(sum * c1)
				center_term := f32(a[q] * c0)
				b[q] = f32(neighbor_term - center_term)
			} } }
			for q in 0 .. cells { temp := a[q]; a[q] = b[q]; b[q] = temp }
		}
		for q in 0 .. cells { staged[q] = f64(a[q]) }
		for q in 0 .. cells { output[q] = staged[q] }
		return i64(cells)
	}
}
