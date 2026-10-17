module schur_complement

const invalid_result = -1.0e300

@[export: 'schur_complement']
pub fn schur_complement(input &i64, length usize) f64 {
	if unsafe { input == nil } || length != 6 { return invalid_result }
	unsafe {
		a00 := input[0]
		a01 := input[1]
		a11 := input[2]
		b0 := input[3]
		b1 := input[4]
		c00 := input[5]
		if a00 < -8 || a00 > 8 || a01 < -8 || a01 > 8 || a11 < -8 || a11 > 8 ||
			b0 < -100 || b0 > 100 || b1 < -100 || b1 > 100 || c00 < -100 || c00 > 100 { return invalid_result }
		determinant := a00 * a11 - a01 * a01
		if determinant == 0 { return invalid_result }
		inv00 := f64(a11) / f64(determinant)
		inv01 := -f64(a01) / f64(determinant)
		inv10 := -f64(a01) / f64(determinant)
		inv11 := f64(a00) / f64(determinant)
		left0 := f64(b0) * inv00 + f64(b1) * inv10
		left1 := f64(b0) * inv01 + f64(b1) * inv11
		quadratic := left0 * f64(b0) + left1 * f64(b1)
		return f64(c00) - quadratic
	}
}
