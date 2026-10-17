package schur_complement

import "core:c"

INVALID_RESULT :: -1.0e300

schur_complement :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length != 6 do return INVALID_RESULT
	a00, a01, a11 := input[0], input[1], input[2]
	b0, b1, c00 := input[3], input[4], input[5]
	if a00 < -8 || a00 > 8 || a01 < -8 || a01 > 8 || a11 < -8 || a11 > 8 ||
		b0 < -100 || b0 > 100 || b1 < -100 || b1 > 100 || c00 < -100 || c00 > 100 do return INVALID_RESULT
	determinant := a00 * a11 - a01 * a01
	if determinant == 0 do return INVALID_RESULT
	inv00 := f64(a11) / f64(determinant)
	inv01 := -f64(a01) / f64(determinant)
	inv10 := -f64(a01) / f64(determinant)
	inv11 := f64(a00) / f64(determinant)
	left0 := f64(b0) * inv00 + f64(b1) * inv10
	left1 := f64(b0) * inv01 + f64(b1) * inv11
	quadratic := left0 * f64(b0) + left1 * f64(b1)
	return f64(c00) - quadratic
}
