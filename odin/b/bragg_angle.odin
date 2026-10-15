package bragg_angle

import "core:c"
import "core:math"

PI :: 3.141592653589793238462643383279502884

round_one_even :: proc(value: f64) -> f64 {
	scaled := value * 10.0
	lower := math.floor(scaled)
	fraction := scaled - lower
	rounded := i64(lower)
	if fraction > 0.5 || (fraction == 0.5 && rounded % 2 != 0) do rounded += 1
	return f64(rounded) / 10.0
}

@(export)
bragg_angle :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	distance, order, wavelength := values[0], values[1], values[2]
	if distance < 1 || distance > 1000000 || order < -1000 || order > 1000 || wavelength < 0 || wavelength > 1000000 do return -1.0e300
	sine := (f64(order) * f64(wavelength)) / (2.0 * f64(distance))
	if sine < -1.0 || sine > 1.0 do return -1.0e300
	degrees := math.asin(sine) * (180.0 / PI)
	return round_one_even(degrees)
}
