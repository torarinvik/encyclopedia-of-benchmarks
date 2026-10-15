module mass_energy_equivalence

const speed_of_light = 299792458.0
const speed_of_light_squared = speed_of_light * speed_of_light

@[export: 'mass_energy_equivalence']
pub fn mass_energy_equivalence(values &i64, length usize) f64 {
	if length != 2 { return -1.0e300 }
	operation := unsafe { values[0] }
	value := unsafe { values[1] }
	if (operation != 0 && operation != 1) || value < 0 || value > 1000000000 { return -1.0e300 }
	if operation == 0 { return f64(value) * speed_of_light_squared }
	return f64(value) / speed_of_light_squared
}
