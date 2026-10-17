module pid

const max_input_length = 64
const max_errors = 60

@[export: 'pid']
pub fn pid(input &f64, length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_input_length { return -1 }
		error_count := int(length) - 4
		kp64 := input[0]
		ki64 := input[1]
		kd64 := input[2]
		dt64 := input[3]
		if kp64 != kp64 || kp64 < -1.0 || kp64 > 1.0 ||
			ki64 != ki64 || ki64 < -1.0 || ki64 > 1.0 ||
			kd64 != kd64 || kd64 < -1.0 || kd64 > 1.0 ||
			dt64 != dt64 || (dt64 != 0.0 && (dt64 < 0.01 || dt64 > 1.0)) ||
			error_count < 1 || error_count > max_errors { return -1 }
		mut errors := [max_errors]f32{}
		for index in 0 .. error_count {
			value := input[index + 4]
			if value != value || value < -1.0 || value > 1.0 { return -1 }
			errors[index] = f32(value)
		}
		if output == nil || output_capacity < usize(error_count) { return -2 }

		kp := f32(kp64)
		ki := f32(ki64)
		kd := f32(kd64)
		dt := f32(dt64)
		mut integral := f32(0.0)
		mut last_error := f32(0.0)
		for index in 0 .. error_count {
			error := errors[index]
			proportional := error * kp
			mut integral_step := error * dt
			integral_step = integral_step * ki
			integral = integral + integral_step
			mut derivative := f32(0.0)
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
}
