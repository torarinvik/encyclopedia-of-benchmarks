module ground_to_ground_projectile_motion

import math

const input_scale = i64(1_000_000)
const max_speed = i64(1_000_000_000)
const max_angle = i64(360_000_000)
const min_gravity = i64(1_000)
const max_gravity = i64(100_000_000)
const max_time = i64(1_000_000_000)
const invalid_result = -1.0e300
const pi_value = 3.14159265358979323846264338327950288

@[export: 'ground_to_ground_projectile_motion']
pub fn ground_to_ground_projectile_motion(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 4 { return invalid_result }
	operation, speed_value, angle_value, auxiliary_value := unsafe { values[0] }, unsafe { values[1] }, unsafe { values[2] }, unsafe { values[3] }
	if operation < 0 || operation > 2 || speed_value < 0 || speed_value > max_speed ||
		angle_value < -max_angle || angle_value > max_angle { return invalid_result }
	if operation == 1 {
		if auxiliary_value < 0 || auxiliary_value > max_time { return invalid_result }
	} else if auxiliary_value < min_gravity || auxiliary_value > max_gravity { return invalid_result }

	speed := f64(speed_value) / f64(input_scale)
	angle := f64(angle_value) / f64(input_scale)
	radians := angle * (pi_value / 180.0)
	vertical_velocity := speed * math.sin(radians)
	if operation == 0 {
		gravity := f64(auxiliary_value) / f64(input_scale)
		return 2.0 * vertical_velocity / gravity
	}
	if operation == 1 {
		time := f64(auxiliary_value) / f64(input_scale)
		return (speed * math.cos(radians)) * time
	}
	gravity := f64(auxiliary_value) / f64(input_scale)
	return math.pow(vertical_velocity, 2.0) / (2.0 * gravity)
}
