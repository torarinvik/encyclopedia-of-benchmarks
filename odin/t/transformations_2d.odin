package transformations_2d

import "core:c"
import "core:math"

INVALID_RESULT :: f64(-1.0e300)

@(export)
transformations_2d :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return INVALID_RESULT
	operation, parameter_micro, component := values[0], values[1], values[2]
	if operation < 0 || operation > 3 || component < 0 || component > 3 do return INVALID_RESULT

	m0, m1, m2, m3 := f64(0.0), f64(0.0), f64(0.0), f64(0.0)
	if operation == 0 {
		if parameter_micro < -1000000 || parameter_micro > 1000000 do return INVALID_RESULT
		factor := f64(parameter_micro) / 1000000.0
		m0, m1, m2, m3 = factor * 1.0, factor * 0.0, factor * 0.0, factor * 1.0
	} else {
		if parameter_micro < -6283185 || parameter_micro > 6283185 do return INVALID_RESULT
		angle := f64(parameter_micro) / 1000000.0
		cosine, sine := math.cos_f64(angle), math.sin_f64(angle)
		if operation == 1 {
			m0, m1, m2, m3 = cosine, -sine, sine, cosine
		} else {
			cs := cosine * sine
			if operation == 2 {
				m0, m1, m2, m3 = cosine * cosine, cs, cs, sine * sine
			} else {
				m0, m1, m2, m3 = 2.0 * cosine - 1.0, 2.0 * cs, 2.0 * cs, 2.0 * sine - 1.0
			}
		}
	}

	if component == 0 do return m0
	if component == 1 do return m1
	if component == 2 do return m2
	return m3
}
