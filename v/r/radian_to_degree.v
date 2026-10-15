module radian_to_degree

@[export: 'radian_to_degree']
pub fn radian_to_degree(radian f64) f64 {
	if !(radian >= -1_000_000.0 && radian <= 1_000_000.0) { return -1.0e300 }
	return radian * (180.0 / 3.141592653589793)
}
