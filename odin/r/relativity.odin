package relativity

import "core:c"
import "core:math"

SPEED_OF_LIGHT :: 299_792_458.0
SPEED_OF_LIGHT_MILLI :: i64(299_792_458_000)
MAX_LENGTH_TIME_MILLI :: i64(1_000_000)
MAX_INPUT_LENGTH :: 4
INVALID_RESULT :: -1.0e300

lorentz_gamma :: proc(velocity: f64) -> f64 {
	return 1.0 / math.sqrt_f64(1.0 - velocity * velocity / (SPEED_OF_LIGHT * SPEED_OF_LIGHT))
}

@(export)
relativity :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 3 || length > MAX_INPUT_LENGTH do return INVALID_RESULT
	operation, arg1_milli, arg2_milli := input[0], input[1], input[2]
	if length != 3 do return INVALID_RESULT

	if operation == 0 {
		if arg2_milli != 0 || arg1_milli <= -SPEED_OF_LIGHT_MILLI || arg1_milli >= SPEED_OF_LIGHT_MILLI do return INVALID_RESULT
		return lorentz_gamma(f64(arg1_milli) / 1000.0)
	}
	if operation == 1 || operation == 2 {
		if arg1_milli < 0 || arg1_milli > MAX_LENGTH_TIME_MILLI ||
			arg2_milli <= -SPEED_OF_LIGHT_MILLI || arg2_milli >= SPEED_OF_LIGHT_MILLI do return INVALID_RESULT
		quantity := f64(arg1_milli) / 1000.0
		velocity := f64(arg2_milli) / 1000.0
		gamma := lorentz_gamma(velocity)
		if operation == 1 do return quantity / gamma
		return quantity * gamma
	}
	if operation == 3 {
		if arg1_milli < -SPEED_OF_LIGHT_MILLI || arg1_milli > SPEED_OF_LIGHT_MILLI ||
			arg2_milli <= -SPEED_OF_LIGHT_MILLI || arg2_milli >= SPEED_OF_LIGHT_MILLI do return INVALID_RESULT
		velocity_one := f64(arg1_milli) / 1000.0
		frame_velocity := f64(arg2_milli) / 1000.0
		return (velocity_one - frame_velocity) /
			(1.0 - velocity_one * frame_velocity / (SPEED_OF_LIGHT * SPEED_OF_LIGHT))
	}
	return INVALID_RESULT
}
