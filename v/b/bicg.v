module bicg

const max_dimension = 64
const max_cells = max_dimension * max_dimension
const invalid_result = -1.0e300

@[export: 'bicg']
pub fn bicg(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 2 { return invalid_result }
	unsafe {
		if values[0] < 1 || values[0] > max_dimension || values[1] < 1 || values[1] > max_dimension { return invalid_result }
		m, n := int(values[0]), int(values[1])
		mut matrix := []f64{len: max_cells, init: 0.0}
		mut p := []f64{len: max_dimension, init: 0.0}
		mut r := []f64{len: max_dimension, init: 0.0}
		mut s := []f64{len: max_dimension, init: 0.0}
		mut q := []f64{len: max_dimension, init: 0.0}
		for i in 0 .. m { p[i] = f64(i % m) / f64(m) }
		for i in 0 .. n {
			r[i] = f64(i % n) / f64(n)
			for j in 0 .. m { matrix[i * m + j] = f64((i * (j + 1)) % n) / f64(n) }
		}
		for i in 0 .. m { s[i] = 0.0 }
		for i in 0 .. n {
			q[i] = 0.0
			for j in 0 .. m {
				s[j] = s[j] + r[i] * matrix[i * m + j]
				q[i] = q[i] + matrix[i * m + j] * p[j]
			}
		}
		mut checksum := 0.0
		for j in 0 .. m { checksum += s[j] }
		for i in 0 .. n { checksum += q[i] }
		return checksum
	}
}
