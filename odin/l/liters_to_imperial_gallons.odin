package liters_to_imperial_gallons

import "core:math"

@(export)
liters_to_imperial_gallons :: proc "c" (liters: f64) -> f64 {
	if math.isnan_f64(liters) || liters < -1e100 || liters > 1e100 do return -1e300
	return liters / 4.54609
}
