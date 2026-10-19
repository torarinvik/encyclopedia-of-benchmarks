module polybench_ludcmp

const max_dimension = 64
const max_cells = max_dimension * max_dimension
const invalid_result = -1.0e300

@[export: 'polybench_ludcmp']
pub fn polybench_ludcmp(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 1 { return invalid_result }
	unsafe {
		if values[0] < 1 || values[0] > max_dimension { return invalid_result }
		n := int(values[0])
		mut a := []f64{len: max_cells, init: 0.0}
		mut product := []f64{len: max_cells, init: 0.0}
		mut b := []f64{len: max_dimension, init: 0.0}
		mut x := []f64{len: max_dimension, init: 0.0}
		mut y := []f64{len: max_dimension, init: 0.0}
		for i in 0 .. n {
			x[i] = 0.0
			y[i] = 0.0
			b[i] = (f64(i + 1) / f64(n)) / 2.0 + 4.0
		}
		for i in 0 .. n {
			for j in 0 .. i + 1 { a[i * n + j] = f64(-(j % n)) / f64(n) + 1.0 }
			for j in i + 1 .. n { a[i * n + j] = 0.0 }
			a[i * n + i] = 1.0
		}
		for r in 0 .. n { for s in 0 .. n { product[r * n + s] = 0.0 } }
		for t in 0 .. n { for r in 0 .. n { for s in 0 .. n {
			product[r * n + s] = product[r * n + s] + a[r * n + t] * a[s * n + t]
		} } }
		for r in 0 .. n { for s in 0 .. n { a[r * n + s] = product[r * n + s] } }
		for i in 0 .. n {
			for j in 0 .. i {
				mut w := a[i * n + j]
				for k in 0 .. j { w = w - a[i * n + k] * a[k * n + j] }
				a[i * n + j] = w / a[j * n + j]
			}
			for j in i .. n {
				mut w := a[i * n + j]
				for k in 0 .. i { w = w - a[i * n + k] * a[k * n + j] }
				a[i * n + j] = w
			}
		}
		for i in 0 .. n {
			mut w := b[i]
			for j in 0 .. i { w = w - a[i * n + j] * y[j] }
			y[i] = w
		}
		mut reverse := n
		for reverse > 0 {
			reverse--
			i := reverse
			mut w := y[i]
			for j in i + 1 .. n { w = w - a[i * n + j] * x[j] }
			x[i] = w / a[i * n + i]
		}
		mut result := 0.0
		for i in 0 .. n { result += x[i] }
		return result
	}
}
