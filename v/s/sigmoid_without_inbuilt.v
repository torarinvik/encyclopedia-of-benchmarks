module sigmoid_without_inbuilt

import math

const invalid_result = -1.0e300

@[export: 'sigmoid_without_inbuilt']
pub fn sigmoid_without_inbuilt(x f64, slope f64) f64 {
	if math.is_nan(x) || math.is_nan(slope) || x < -10.0 || x > 10.0 || slope < -10.0 || slope > 10.0 {
		return invalid_result
	}
	return 1.0 / (1.0 + math.exp(-slope * x))
}

