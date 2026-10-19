const max_dimension = 64
const max_cells = max_dimension * max_dimension
const invalid_result = -1.0e300

@[export: 'gemver']
pub fn gemver(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 1 { return invalid_result }
	unsafe {
		if values[0] < 1 || values[0] > max_dimension { return invalid_result }
		n := int(values[0])
		alpha, beta := 1.5, 1.2
		mut a := []f64{len: max_cells, init: 0.0}
		mut u1 := []f64{len: max_dimension, init: 0.0}
		mut v1 := []f64{len: max_dimension, init: 0.0}
		mut u2 := []f64{len: max_dimension, init: 0.0}
		mut v2 := []f64{len: max_dimension, init: 0.0}
		mut w := []f64{len: max_dimension, init: 0.0}
		mut x := []f64{len: max_dimension, init: 0.0}
		mut y := []f64{len: max_dimension, init: 0.0}
		mut z := []f64{len: max_dimension, init: 0.0}
		for i in 0 .. n {
			u1[i] = f64(i)
			u2[i] = (f64(i + 1) / f64(n)) / 2.0
			v1[i] = (f64(i + 1) / f64(n)) / 4.0
			v2[i] = (f64(i + 1) / f64(n)) / 6.0
			y[i] = (f64(i + 1) / f64(n)) / 8.0
			z[i] = (f64(i + 1) / f64(n)) / 9.0
			for j in 0 .. n { a[i * n + j] = f64((i * j) % n) / f64(n) }
		}
		for i in 0 .. n {
			for j in 0 .. n { a[i * n + j] = a[i * n + j] + u1[i] * v1[j] + u2[i] * v2[j] }
		}
		for i in 0 .. n {
			for j in 0 .. n { x[i] = x[i] + beta * a[j * n + i] * y[j] }
		}
		for i in 0 .. n { x[i] = x[i] + z[i] }
		for i in 0 .. n {
			for j in 0 .. n { w[i] = w[i] + alpha * a[i * n + j] * x[j] }
		}
		mut checksum := 0.0
		for i in 0 .. n { checksum += w[i] }
		return checksum
	}
}
