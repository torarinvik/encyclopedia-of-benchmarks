module liters_to_usgallons

import math

@[export: 'liters_to_usgallons']
pub fn liters_to_usgallons(liters f64) f64 {
	if math.is_nan(liters) || liters < -1e100 || liters > 1e100 { return -1e300 }
	return liters / 3.785411784
}
