module electrical_impedance

import math

@[export: 'electrical_impedance']
pub fn electrical_impedance(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	resistance := unsafe { values[0] }
	reactance := unsafe { values[1] }
	impedance := unsafe { values[2] }
	if resistance < 0 || resistance > 1000 || reactance < 0 || reactance > 1000 || impedance < 0 || impedance > 1000 { return -1.0e300 }
	mut zeros := 0
	if resistance == 0 { zeros++ }
	if reactance == 0 { zeros++ }
	if impedance == 0 { zeros++ }
	if zeros != 1 { return -1.0e300 }
	r := f64(resistance)
	x := f64(reactance)
	z := f64(impedance)
	mut radicand := f64(0)
	if resistance == 0 { radicand = z * z - x * x }
	else if reactance == 0 { radicand = z * z - r * r }
	else { radicand = r * r + x * x }
	if radicand < 0 { return -1.0e300 }
	return math.sqrt(radicand)
}
