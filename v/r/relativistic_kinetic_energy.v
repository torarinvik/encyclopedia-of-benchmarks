module relativistic_kinetic_energy

import math

const speed_of_light = i64(299792458)
const invalid_result = -1.0e300

@[export: 'relativistic_kinetic_energy']
pub fn relativistic_kinetic_energy(values &i64, length usize) f64 {
	if length != 2 { return invalid_result }
	mass := unsafe { values[0] }
	velocity := unsafe { values[1] }
	if mass < 0 || mass > 1_000_000 || velocity < -(speed_of_light - 1) || velocity > speed_of_light - 1 {
		return invalid_result
	}
	c_squared := speed_of_light * speed_of_light
	gamma := 1.0 / math.sqrt(1.0 - f64(velocity * velocity) / f64(c_squared))
	return (gamma - 1.0) * f64(mass) * f64(c_squared)
}
