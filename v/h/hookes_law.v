module hookes_law

@[export: 'hookes_law']
pub fn hookes_law(values &i64, length usize) f64 {
	if length != 2 { return -1.0e300 }
	spring_constant := unsafe { values[0] }
	displacement := unsafe { values[1] }
	if spring_constant < 1 || spring_constant > 1000 || displacement < -1000 || displacement > 1000 {
		return -1.0e300
	}
	return (-f64(spring_constant)) * f64(displacement)
}
