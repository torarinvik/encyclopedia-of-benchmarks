module rms_speed_of_molecule

import math

@[export: 'rms_speed_of_molecule']
pub fn rms_speed_of_molecule(values &i64, length usize) f64 {
	if length != 2 { return -1.0e300 }
	temperature := unsafe { values[0] }
	molar_mass := unsafe { values[1] }
	if temperature < 0 || temperature > 1000 || molar_mass < 1 || molar_mass > 1000 {
		return -1.0e300
	}
	numerator := (3.0 * 8.3144598) * f64(temperature)
	return math.pow(numerator / f64(molar_mass), 0.5)
}
