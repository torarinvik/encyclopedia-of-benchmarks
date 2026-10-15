module centripetal_force

// Centripetal force: (mass * velocity^2) / radius.
@[export: 'centripetal_force']
pub fn centripetal_force(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	mass := unsafe { values[0] }
	velocity := unsafe { values[1] }
	radius := unsafe { values[2] }
	if mass < 0 || mass > 1000 || velocity < -1000 || velocity > 1000 || radius < 1 || radius > 1000 {
		return -1.0e300
	}
	velocity_squared := f64(velocity) * f64(velocity)
	return (f64(mass) * velocity_squared) / f64(radius)
}
