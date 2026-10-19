const max_dimension = 64
const max_cells = max_dimension * max_dimension
const invalid_result = -1.0e300

@[export: 'gemm']
pub fn gemm(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 3 { return invalid_result }
	unsafe {
		if values[0] < 1 || values[0] > max_dimension || values[1] < 1 || values[1] > max_dimension || values[2] < 1 || values[2] > max_dimension { return invalid_result }
		ni, nj, nk := int(values[0]), int(values[1]), int(values[2])
		alpha, beta := 1.5, 1.2
		mut c := []f64{len: max_cells, init: 0.0}
		mut a := []f64{len: max_cells, init: 0.0}
		mut b := []f64{len: max_cells, init: 0.0}
		for i in 0 .. ni {
			for j in 0 .. nj { c[i * nj + j] = f64((i * j + 1) % ni) / f64(ni) }
		}
		for i in 0 .. ni {
			for k in 0 .. nk { a[i * nk + k] = f64((i * (k + 1)) % nk) / f64(nk) }
		}
		for k in 0 .. nk {
			for j in 0 .. nj { b[k * nj + j] = f64((k * (j + 2)) % nj) / f64(nj) }
		}
		for i in 0 .. ni {
			for j in 0 .. nj { c[i * nj + j] *= beta }
			for k in 0 .. nk {
				for j in 0 .. nj { c[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j] }
			}
		}
		mut checksum := 0.0
		for i in 0 .. ni {
			for j in 0 .. nj { checksum += c[i * nj + j] }
		}
		return checksum
	}
}
