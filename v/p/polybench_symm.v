module polybench_symm

const max_dimension = 64
const max_cells = max_dimension * max_dimension
const invalid_result = -1.0e300

@[export: 'polybench_symm']
pub fn polybench_symm(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 2 { return invalid_result }
	unsafe {
		if values[0] < 1 || values[0] > max_dimension || values[1] < 1 || values[1] > max_dimension { return invalid_result }
		m, n := int(values[0]), int(values[1])
		mut a := []f64{len: max_cells, init: 0.0}
		mut b := []f64{len: max_cells, init: 0.0}
		mut c := []f64{len: max_cells, init: 0.0}
		alpha, beta := 1.5, 1.2
		for i in 0 .. m { for j in 0 .. n {
			c[i * n + j] = f64((i + j) % 100) / f64(m)
			b[i * n + j] = f64((n + i - j) % 100) / f64(m)
		} }
		for i in 0 .. m { for j in 0 .. m {
			if j <= i { a[i * m + j] = f64((i + j) % 100) / f64(m) } else { a[i * m + j] = -999.0 }
		} }
		for i in 0 .. m { for j in 0 .. n {
			mut temp2 := 0.0
			for k in 0 .. i {
				c[k * n + j] = c[k * n + j] + alpha * b[i * n + j] * a[i * m + k]
				temp2 = temp2 + b[k * n + j] * a[i * m + k]
			}
			c[i * n + j] = beta * c[i * n + j] + alpha * b[i * n + j] * a[i * m + i] + alpha * temp2
		} }
		mut result := 0.0
		for i in 0 .. m { for j in 0 .. n { result += c[i * n + j] } }
		return result
	}
}
