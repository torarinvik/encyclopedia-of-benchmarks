module relativistic_velocity_summation

const speed_of_light = i64(299792458)
const invalid_result = -1.0e300

@[export: 'relativistic_velocity_summation']
pub fn relativistic_velocity_summation(values &i64, length usize) f64 {
	if length != 2 { return invalid_result }
	object_velocity := unsafe { values[0] }
	frame_velocity := unsafe { values[1] }
	if object_velocity < -speed_of_light || object_velocity > speed_of_light ||
		frame_velocity < -(speed_of_light - 1) || frame_velocity > speed_of_light - 1 {
		return invalid_result
	}
	numerator := object_velocity + frame_velocity
	c_squared := speed_of_light * speed_of_light
	denominator := 1.0 + f64(object_velocity * frame_velocity) / f64(c_squared)
	return f64(numerator) / denominator
}
