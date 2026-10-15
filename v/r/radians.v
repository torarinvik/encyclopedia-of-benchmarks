module radians

@[export: 'radians']
pub fn radians(degree f64) f64 {
	if !(degree >= -1_000_000.0 && degree <= 1_000_000.0) { return -1.0e300 }
	return degree / (180.0 / 3.141592653589793)
}
