module cone

import math

@[export: 'cone']
pub fn cone(values &i64, length usize) f64 {
	if length != 3 { return -1.0e300 }
	operation := unsafe { values[0] }
	radius := unsafe { values[1] }
	height := unsafe { values[2] }
	if (operation != 0 && operation != 1) || radius < 0 || radius > 1000 ||
		height < 0 || height > 1000 { return -1.0e300 }
	pi := 3.14159265358979323846
	radius_value := f64(radius)
	radius_squared := radius_value * radius_value
	base_area := radius_squared * pi
	if operation == 0 { return (base_area * f64(height) * 1.0) / 3.0 }
	height_value := f64(height)
	return base_area + pi * radius_value * math.sqrt(radius_squared + height_value * height_value)
}
