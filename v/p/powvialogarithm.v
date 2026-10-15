module powvialogarithm

import math

const invalid_result = -1.0e300

@[export: 'powvialogarithm']
pub fn powvialogarithm(base f64, exponent f64) f64 {
	if math.is_nan(base) || math.is_nan(exponent) || base < -4.0 || base > 4.0 ||
		exponent < -8.0 || exponent > 8.0 || math.floor(base) != base || math.floor(exponent) != exponent ||
		(base == 0.0 && exponent <= 0.0) || ((base == 2.0 || base == -2.0) && exponent == -1.0) {
		return invalid_result
	}

	mut sign := 1.0
	power := i64(exponent)
	if base < 0.0 && power % 2 != 0 { sign = -1.0 }
	logarithm := math.log(math.abs(base))
	exponential := math.exp(exponent * logarithm)
	result := exponential * sign
	return math.round(result)
}
