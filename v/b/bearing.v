module bearing

import math

// Return a spherical initial bearing in integer microdegrees.
@[export: 'bearing']
pub fn bearing(values &i64, length usize) i64 {
	if values == nil || length != 4 { return -1 }
	latitude1_value := unsafe { values[0] }
	longitude1_value := unsafe { values[1] }
	latitude2_value := unsafe { values[2] }
	longitude2_value := unsafe { values[3] }
	if latitude1_value < -90000000 || latitude1_value > 90000000 ||
		latitude2_value < -90000000 || latitude2_value > 90000000 ||
		longitude1_value < -180000000 || longitude1_value > 180000000 ||
		longitude2_value < -180000000 || longitude2_value > 180000000 ||
		(latitude1_value == latitude2_value && longitude1_value == longitude2_value) {
		return -1
	}

	radians_per_microdegree := 0.000001 * (3.14159265358979323846 / 180.0)
	latitude1 := f64(latitude1_value) * radians_per_microdegree
	longitude1 := f64(longitude1_value) * radians_per_microdegree
	latitude2 := f64(latitude2_value) * radians_per_microdegree
	longitude2 := f64(longitude2_value) * radians_per_microdegree
	delta_longitude := longitude2 - longitude1
	east := math.sin(delta_longitude) * math.cos(latitude2)
	north := math.cos(latitude1) * math.sin(latitude2) -
		math.sin(latitude1) * math.cos(latitude2) * math.cos(delta_longitude)
	mut degrees := math.atan2(east, north) * 57.2957795130823208768
	if degrees < 0.0 { degrees += 360.0 }
	result := i64(degrees * 1000000.0 + 0.5)
	if result >= 360000000 { return 0 }
	return result
}
