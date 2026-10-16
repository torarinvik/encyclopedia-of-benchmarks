module problem190

import math

const max_n = i64(15)

@[export: 'problem190']
pub fn problem190(n i64) i64 {
	if n < 0 || n > max_n { return -1 }
	mut total := i64(0)
	mut m := i64(2)
	for m <= n {
		x1 := 2.0 / f64(m + 1)
		mut product := 1.0
		mut i := i64(1)
		for i <= m {
			xi := f64(i) * x1
			product *= math.pow(xi, f64(i))
			i++
		}
		total += i64(product)
		m++
	}
	return total
}
