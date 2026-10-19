module polybench_cholesky

import math

const max_dimension = 64
const max_cells = max_dimension * max_dimension
const invalid_result = -1.0e300

@[export: 'polybench_cholesky']
pub fn polybench_cholesky(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 1 { return invalid_result }
	unsafe {
		if values[0] < 1 || values[0] > max_dimension { return invalid_result }
		n := int(values[0])
		mut a := []f64{len: max_cells, init: 0.0}
		mut product := []f64{len: max_cells, init: 0.0}
		for i in 0 .. n {
			for j in 0 .. i + 1 { a[i * n + j] = f64(-(j % n)) / f64(n) + 1.0 }
			for j in i + 1 .. n { a[i * n + j] = 0.0 }
			a[i * n + i] = 1.0
		}
		for t in 0 .. n { for r in 0 .. n { for s in 0 .. n {
			product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t]
		} } }
		for r in 0 .. n { for s in 0 .. n { a[r * n + s] = product[r * n + s] } }
		for i in 0 .. n {
			for j in 0 .. i {
				for k in 0 .. j { a[i * n + j] = a[i * n + j] - a[i * n + k] * a[j * n + k] }
				a[i * n + j] = a[i * n + j] / a[j * n + j]
			}
			for k in 0 .. i { a[i * n + i] = a[i * n + i] - a[i * n + k] * a[i * n + k] }
			a[i * n + i] = math.sqrt(a[i * n + i])
		}
		mut result := 0.0
		for i in 0 .. n { for j in 0 .. i + 1 { result += a[i * n + j] } }
		return result
	}
}
