module mvt

const max_dimension = 64
const max_cells = max_dimension * max_dimension
const invalid_result = -1.0e300

@[export: 'mvt']
pub fn mvt(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 1 { return invalid_result }
	unsafe {
		if values[0] < 1 || values[0] > max_dimension { return invalid_result }
		n := int(values[0])
		mut x1 := []f64{len: max_dimension, init: 0.0}
		mut x2 := []f64{len: max_dimension, init: 0.0}
		mut y1 := []f64{len: max_dimension, init: 0.0}
		mut y2 := []f64{len: max_dimension, init: 0.0}
		mut matrix := []f64{len: max_cells, init: 0.0}
		for i in 0 .. n {
			x1[i] = f64(i % n) / f64(n)
			x2[i] = f64((i + 1) % n) / f64(n)
			y1[i] = f64((i + 3) % n) / f64(n)
			y2[i] = f64((i + 4) % n) / f64(n)
			for j in 0 .. n { matrix[i * n + j] = f64((i * j) % n) / f64(n) }
		}
		for i in 0 .. n { for j in 0 .. n { x1[i] = x1[i] + matrix[i * n + j] * y1[j] } }
		for i in 0 .. n { for j in 0 .. n { x2[i] = x2[i] + matrix[j * n + i] * y2[j] } }
		mut checksum := 0.0
		for i in 0 .. n { checksum += x1[i] }
		for i in 0 .. n { checksum += x2[i] }
		return checksum
	}
}
