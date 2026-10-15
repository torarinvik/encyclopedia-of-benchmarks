module newtons_second_law_of_motion

@[export: 'newtons_second_law_of_motion']
pub fn newtons_second_law_of_motion(values &i64, length usize) f64 {
	if length != 2 { return -1.0e300 }
	mass := unsafe { values[0] }
	acceleration := unsafe { values[1] }
	if mass < -1000 || mass > 1000 || acceleration < -1000 || acceleration > 1000 {
		return -1.0e300
	}
	return f64(mass) * f64(acceleration)
}
