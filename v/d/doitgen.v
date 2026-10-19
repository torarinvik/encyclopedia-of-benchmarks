const max_dimension = 16
const max_a_cells = max_dimension * max_dimension * max_dimension
const max_c4_cells = max_dimension * max_dimension
const invalid_result = -1.0e300

@[export: 'doitgen']
pub fn doitgen(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 3 { return invalid_result }
	unsafe {
		if values[0] < 1 || values[0] > max_dimension || values[1] < 1 || values[1] > max_dimension || values[2] < 1 || values[2] > max_dimension { return invalid_result }
		nr, nq, np := int(values[0]), int(values[1]), int(values[2])
		mut a := []f64{len: max_a_cells, init: 0.0}
		mut c4 := []f64{len: max_c4_cells, init: 0.0}
		mut sums := []f64{len: max_dimension, init: 0.0}
		for r in 0 .. nr {
			for q in 0 .. nq {
				for p in 0 .. np { a[(r * nq + q) * np + p] = f64((r * q + p) % np) / f64(np) }
			}
		}
		for i in 0 .. np {
			for j in 0 .. np { c4[i * np + j] = f64((i * j) % np) / f64(np) }
		}
		for r in 0 .. nr {
			for q in 0 .. nq {
				for p in 0 .. np {
					sums[p] = 0.0
					for s in 0 .. np { sums[p] += a[(r * nq + q) * np + s] * c4[s * np + p] }
				}
				for p in 0 .. np { a[(r * nq + q) * np + p] = sums[p] }
			}
		}
		mut checksum := 0.0
		for r in 0 .. nr {
			for q in 0 .. nq {
				for p in 0 .. np { checksum += a[(r * nq + q) * np + p] }
			}
		}
		return checksum
	}
}
