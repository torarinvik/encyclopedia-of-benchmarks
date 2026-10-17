package pid

import "core:c"

MAX_INPUT_LENGTH :: 64
MAX_ERRORS :: 60

@(export, link_name="pid")
pid :: proc "c" (input: [^]f64, length: c.size_t,
                 output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	error_count := int(length) - 4
	kp64, ki64, kd64, dt64 := input[0], input[1], input[2], input[3]
	if kp64 != kp64 || kp64 < -1.0 || kp64 > 1.0 ||
	   ki64 != ki64 || ki64 < -1.0 || ki64 > 1.0 ||
	   kd64 != kd64 || kd64 < -1.0 || kd64 > 1.0 ||
	   dt64 != dt64 || (dt64 != 0.0 && (dt64 < 0.01 || dt64 > 1.0)) ||
	   error_count < 1 || error_count > MAX_ERRORS do return -1
	errors: [MAX_ERRORS]f32
	for index := 0; index < error_count; index += 1 {
		value := input[index + 4]
		if value != value || value < -1.0 || value > 1.0 do return -1
		errors[index] = f32(value)
	}
	if output == nil || output_capacity < c.size_t(error_count) do return -2

	kp, ki, kd, dt := f32(kp64), f32(ki64), f32(kd64), f32(dt64)
	integral: f32 = 0.0
	last_error: f32 = 0.0
	for index := 0; index < error_count; index += 1 {
		error := errors[index]
		proportional := error * kp
		integral_step := error * dt
		integral_step = integral_step * ki
		integral = integral + integral_step
		derivative: f32 = 0.0
		if dt != 0.0 {
			difference := error - last_error
			rate := difference / dt
			derivative = rate * kd
		}
		last_error = error
		partial := proportional + integral
		result := partial + derivative
		output[index] = f64(result)
	}
	return i64(error_count)
}
