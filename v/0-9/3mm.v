const max_dimension = 16
const max_cells = max_dimension * max_dimension
const invalid_result = -1.0e300

@[export: 'three_mm']
pub fn three_mm(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 5 { return invalid_result }
	unsafe {
		for i in 0 .. 5 {
			if values[i] < 1 || values[i] > max_dimension { return invalid_result }
		}
		ni, nj, nk, nl, nm := int(values[0]), int(values[1]), int(values[2]), int(values[3]), int(values[4])
		mut a := []f64{len: max_cells, init: 0.0}
		mut b := []f64{len: max_cells, init: 0.0}
		mut c := []f64{len: max_cells, init: 0.0}
		mut d := []f64{len: max_cells, init: 0.0}
		mut e := []f64{len: max_cells, init: 0.0}
		mut f := []f64{len: max_cells, init: 0.0}
		mut g := []f64{len: max_cells, init: 0.0}
		for i in 0 .. ni {
			for k in 0 .. nk { a[i * nk + k] = f64((i * k + 1) % ni) / f64(5 * ni) }
		}
		for k in 0 .. nk {
			for j in 0 .. nj { b[k * nj + j] = f64((k * (j + 1) + 2) % nj) / f64(5 * nj) }
		}
		for i in 0 .. nj {
			for j in 0 .. nm { c[i * nm + j] = f64((i * (j + 3)) % nl) / f64(5 * nl) }
		}
		for i in 0 .. nm {
			for j in 0 .. nl { d[i * nl + j] = f64((i * (j + 2) + 2) % nk) / f64(5 * nk) }
		}
		for i in 0 .. ni {
			for j in 0 .. nj {
				e[i * nj + j] = 0.0
				for k in 0 .. nk { e[i * nj + j] += a[i * nk + k] * b[k * nj + j] }
			}
		}
		for i in 0 .. nj {
			for j in 0 .. nl {
				f[i * nl + j] = 0.0
				for k in 0 .. nm { f[i * nl + j] += c[i * nm + k] * d[k * nl + j] }
			}
		}
		for i in 0 .. ni {
			for j in 0 .. nl {
				g[i * nl + j] = 0.0
				for k in 0 .. nj { g[i * nl + j] += e[i * nj + k] * f[k * nl + j] }
			}
		}
		mut checksum := 0.0
		for i in 0 .. ni {
			for j in 0 .. nl { checksum += g[i * nl + j] }
		}
		return checksum
	}
}
