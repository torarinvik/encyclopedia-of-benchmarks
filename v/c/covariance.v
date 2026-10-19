const max_dimension = 64
const max_cells = max_dimension * max_dimension
const invalid_result = -1.0e300

@[export: 'covariance']
pub fn covariance(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 2 { return invalid_result }
	unsafe {
		if values[0] < 2 || values[0] > max_dimension || values[1] < 1 || values[1] > max_dimension { return invalid_result }
		n, m := int(values[0]), int(values[1])
		float_n := f64(n)
		mut data := []f64{len: max_cells, init: 0.0}
		mut cov := []f64{len: max_cells, init: 0.0}
		mut mean := []f64{len: max_dimension, init: 0.0}
		for i in 0 .. n {
			for j in 0 .. m { data[i * m + j] = (f64(i) * f64(j)) / f64(m) }
		}
		for j in 0 .. m {
			mean[j] = 0.0
			for i in 0 .. n { mean[j] += data[i * m + j] }
			mean[j] /= float_n
		}
		for i in 0 .. n {
			for j in 0 .. m { data[i * m + j] -= mean[j] }
		}
		for i in 0 .. m {
			for j in i .. m {
				cov[i * m + j] = 0.0
				for k in 0 .. n { cov[i * m + j] += data[k * m + i] * data[k * m + j] }
				cov[i * m + j] /= float_n - 1.0
				cov[j * m + i] = cov[i * m + j]
			}
		}
		mut checksum := 0.0
		for i in 0 .. m {
			for j in 0 .. m { checksum += cov[i * m + j] }
		}
		return checksum
	}
}
