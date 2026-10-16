package ground_to_ground_projectile_motion

import "core:c"
import "core:math"

INPUT_SCALE :: i64(1_000_000)
MAX_SPEED :: i64(1_000_000_000)
MAX_ANGLE :: i64(360_000_000)
MIN_GRAVITY :: i64(1_000)
MAX_GRAVITY :: i64(100_000_000)
MAX_TIME :: i64(1_000_000_000)
INVALID_RESULT :: f64(-1.0e300)
PI_VALUE :: f64(3.14159265358979323846264338327950288)

@(export)
ground_to_ground_projectile_motion :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length != 4 do return INVALID_RESULT
	operation, speed_value, angle_value, auxiliary_value := values[0], values[1], values[2], values[3]
	if operation < 0 || operation > 2 || speed_value < 0 || speed_value > MAX_SPEED ||
		angle_value < -MAX_ANGLE || angle_value > MAX_ANGLE do return INVALID_RESULT
	if operation == 1 {
		if auxiliary_value < 0 || auxiliary_value > MAX_TIME do return INVALID_RESULT
	} else if auxiliary_value < MIN_GRAVITY || auxiliary_value > MAX_GRAVITY do return INVALID_RESULT

	speed := f64(speed_value) / f64(INPUT_SCALE)
	angle := f64(angle_value) / f64(INPUT_SCALE)
	radians := angle * (PI_VALUE / 180.0)
	vertical_velocity := speed * math.sin(radians)
	if operation == 0 {
		gravity := f64(auxiliary_value) / f64(INPUT_SCALE)
		return 2.0 * vertical_velocity / gravity
	}
	if operation == 1 {
		time := f64(auxiliary_value) / f64(INPUT_SCALE)
		return (speed * math.cos(radians)) * time
	}
	gravity := f64(auxiliary_value) / f64(INPUT_SCALE)
	return math.pow_f64(vertical_velocity, 2.0) / (2.0 * gravity)
}
