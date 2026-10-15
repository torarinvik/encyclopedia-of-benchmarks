module correlation

import math

const invalid_result = -1.0e300
const delta = 1.0e-9

@[export: 'correlation']
pub fn correlation(values &i64, length usize) f64 {
	if length < 3 { return invalid_result }
	n_value := unsafe { values[0] }
	if n_value < 1 || n_value > 128 || length != 1 + 2 * usize(n_value) { return invalid_result }
	n := int(n_value)
	mut exy := 0.0
	mut ex := 0.0
	mut exx := 0.0
	mut ey := 0.0
	mut eyy := 0.0
	for i in 0 .. n {
		xi := unsafe { values[1+i] }
		yi := unsafe { values[1+n+i] }
		if xi < -1000 || xi > 1000 || yi < -1000 || yi > 1000 { return invalid_result }
		x := f64(xi)
		y := f64(yi)
		exy += x * y
		ex += x
		exx += x * x
		ey += y
		eyy += y * y
	}
	exy /= f64(n)
	ex /= f64(n)
	exx /= f64(n)
	ey /= f64(n)
	eyy /= f64(n)
	cov := exy - ex * ey
	varx := math.sqrt(exx - ex * ex)
	vary := math.sqrt(eyy - ey * ey)
	if varx * vary < delta { return 0.0 }
	return cov / math.sqrt(varx * vary)
}
