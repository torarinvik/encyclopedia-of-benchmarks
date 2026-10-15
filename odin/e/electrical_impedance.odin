package electrical_impedance

import "core:c"
import "core:math"

@(export)
electrical_impedance :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 3 do return -1.0e300
	resistance := values[0]
	reactance := values[1]
	impedance := values[2]
	if resistance < 0 || resistance > 1000 || reactance < 0 || reactance > 1000 || impedance < 0 || impedance > 1000 do return -1.0e300
	zeros := 0
	if resistance == 0 do zeros += 1
	if reactance == 0 do zeros += 1
	if impedance == 0 do zeros += 1
	if zeros != 1 do return -1.0e300
	r := f64(resistance)
	x := f64(reactance)
	z := f64(impedance)
	radicand := f64(0)
	if resistance == 0 {
		radicand = z * z - x * x
	} else if reactance == 0 {
		radicand = z * z - r * r
	} else {
		radicand = r * r + x * x
	}
	if radicand < 0 do return -1.0e300
	return math.sqrt(radicand)
}
