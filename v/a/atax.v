module atax

const max_dimension = 64
const max_cells = max_dimension * max_dimension
const invalid_result = -1.0e300

@[export: 'atax']
pub fn atax(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 2 { return invalid_result }
	unsafe {
		if values[0] < 1 || values[0] > max_dimension || values[1] < 1 || values[1] > max_dimension { return invalid_result }
		m, n := int(values[0]), int(values[1])
		mut matrix := []f64{len: max_cells, init: 0.0}
		mut x := []f64{len: max_dimension, init: 0.0}
		mut y := []f64{len: max_dimension, init: 0.0}
		mut temporary := []f64{len: max_dimension, init: 0.0}
		fn_value := f64(n)
		for i in 0 .. n { x[i] = 1.0 + f64(i) / fn_value }
		for i in 0 .. m { for j in 0 .. n { matrix[i * n + j] = f64((i + j) % n) / f64(5 * m) } }
		for i in 0 .. n { y[i] = 0.0 }
		for i in 0 .. m {
			temporary[i] = 0.0
			for j in 0 .. n { temporary[i] = temporary[i] + matrix[i * n + j] * x[j] }
			for j in 0 .. n { y[j] = y[j] + matrix[i * n + j] * temporary[i] }
		}
		mut checksum := 0.0
		for j in 0 .. n { checksum += y[j] }
		return checksum
	}
}
