module reynolds_number

@[export: 'reynolds_number']
pub fn reynolds_number(values &i64, length usize) f64 {
	if length != 4 { return -1.0e300 }
	density := unsafe { values[0] }
	velocity := unsafe { values[1] }
	diameter := unsafe { values[2] }
	viscosity := unsafe { values[3] }
	if density < 1 || density > 1000 || velocity < -1000 || velocity > 1000 || diameter < 1 || diameter > 1000 || viscosity < 1 || viscosity > 1000 {
		return -1.0e300
	}
	speed := if velocity < 0 { -velocity } else { velocity }
	return (((f64(density) * f64(speed)) * f64(diameter)) / f64(viscosity))
}
