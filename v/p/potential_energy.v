module potential_energy

// Gravitational potential energy: mass * standard gravity * height.
@[export: 'potential_energy']
pub fn potential_energy(values &i64, length usize) f64 {
	if length != 2 { return -1.0e300 }
	mass := unsafe { values[0] }
	height := unsafe { values[1] }
	if mass < 0 || mass > 1000 || height < 0 || height > 1000 {
		return -1.0e300
	}
	return (f64(mass) * 9.80665) * f64(height)
}
