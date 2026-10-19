const max_dimension = 16
const max_cells = max_dimension * max_dimension
const invalid_result = -1.0e300

@[export: 'two_mm']
pub fn two_mm(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 4 { return invalid_result }
	unsafe {
		for i in 0 .. 4 {
			if values[i] < 1 || values[i] > max_dimension { return invalid_result }
		}
		ni, nj, nk, nl := int(values[0]), int(values[1]), int(values[2]), int(values[3])
		alpha, beta := 1.5, 1.2
		mut a := []f64{len: max_cells, init: 0.0}
		mut b := []f64{len: max_cells, init: 0.0}
		mut c := []f64{len: max_cells, init: 0.0}
		mut d := []f64{len: max_cells, init: 0.0}
		mut tmp := []f64{len: max_cells, init: 0.0}
		for i in 0 .. ni {
			for k in 0 .. nk { a[i * nk + k] = f64((i * k + 1) % ni) / f64(ni) }
		}
		for k in 0 .. nk {
			for j in 0 .. nj { b[k * nj + j] = f64((k * (j + 1)) % nj) / f64(nj) }
		}
		for j in 0 .. nj {
			for l in 0 .. nl { c[j * nl + l] = f64((j * (l + 3) + 1) % nl) / f64(nl) }
		}
		for i in 0 .. ni {
			for l in 0 .. nl { d[i * nl + l] = f64((i * (l + 2)) % nk) / f64(nk) }
		}
		for i in 0 .. ni {
			for j in 0 .. nj {
				tmp[i * nj + j] = 0.0
				for k in 0 .. nk { tmp[i * nj + j] += alpha * a[i * nk + k] * b[k * nj + j] }
			}
		}
		for i in 0 .. ni {
			for l in 0 .. nl {
				d[i * nl + l] *= beta
				for j in 0 .. nj { d[i * nl + l] += tmp[i * nj + j] * c[j * nl + l] }
			}
		}
		mut checksum := 0.0
		for i in 0 .. ni {
			for l in 0 .. nl { checksum += d[i * nl + l] }
		}
		return checksum
	}
}
