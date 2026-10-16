module liters_to_imperial_gallons

import math

@[export: 'liters_to_imperial_gallons']
pub fn liters_to_imperial_gallons(liters f64) f64 {
	if math.is_nan(liters) || liters < -1e100 || liters > 1e100 { return -1e300 }
	return liters / 4.54609
}
