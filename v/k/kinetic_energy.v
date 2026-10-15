module kinetic_energy

// Classical kinetic energy: 0.5 * mass * abs(velocity)^2.
@[export: 'kinetic_energy']
pub fn kinetic_energy(values &i64, length usize) f64 {
	if length != 2 { return -1.0e300 }
	mass := unsafe { values[0] }
	velocity := unsafe { values[1] }
	if mass < 0 || mass > 1000 || velocity < -1000 || velocity > 1000 {
		return -1.0e300
	}
	speed := if velocity < 0 { -velocity } else { velocity }
	return ((0.5 * f64(mass)) * f64(speed)) * f64(speed)
}
