package relativistic_velocity_summation

import "core:c"

SPEED_OF_LIGHT :: i64(299792458)
INVALID_RESULT :: -1.0e300

@(export)
relativistic_velocity_summation :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 2 do return INVALID_RESULT
	object_velocity := values[0]
	frame_velocity := values[1]
	if object_velocity < -SPEED_OF_LIGHT || object_velocity > SPEED_OF_LIGHT ||
		frame_velocity < -(SPEED_OF_LIGHT-1) || frame_velocity > SPEED_OF_LIGHT-1 do return INVALID_RESULT
	numerator := object_velocity + frame_velocity
	c_squared := SPEED_OF_LIGHT * SPEED_OF_LIGHT
	denominator := 1.0 + f64(object_velocity*frame_velocity)/f64(c_squared)
	return f64(numerator) / denominator
}
