module relativity

import math

const speed_of_light = 299_792_458.0
const speed_of_light_milli = i64(299_792_458_000)
const max_length_time_milli = i64(1_000_000)
const max_input_length = usize(4)
const invalid_result = -1.0e300

fn lorentz_gamma(velocity f64) f64 {
	return 1.0 / math.sqrt(1.0 - velocity * velocity / (speed_of_light * speed_of_light))
}

@[export: 'relativity']
pub fn relativity(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 3 || length > max_input_length { return invalid_result }
	unsafe {
		operation := input[0]
		arg1_milli := input[1]
		arg2_milli := input[2]
		if length != 3 { return invalid_result }

		if operation == 0 {
			if arg2_milli != 0 || arg1_milli <= -speed_of_light_milli || arg1_milli >= speed_of_light_milli { return invalid_result }
			return lorentz_gamma(f64(arg1_milli) / 1000.0)
		}
		if operation == 1 || operation == 2 {
			if arg1_milli < 0 || arg1_milli > max_length_time_milli ||
				arg2_milli <= -speed_of_light_milli || arg2_milli >= speed_of_light_milli { return invalid_result }
			quantity := f64(arg1_milli) / 1000.0
			velocity := f64(arg2_milli) / 1000.0
			gamma := lorentz_gamma(velocity)
			if operation == 1 { return quantity / gamma }
			return quantity * gamma
		}
		if operation == 3 {
			if arg1_milli < -speed_of_light_milli || arg1_milli > speed_of_light_milli ||
				arg2_milli <= -speed_of_light_milli || arg2_milli >= speed_of_light_milli { return invalid_result }
			velocity_one := f64(arg1_milli) / 1000.0
			frame_velocity := f64(arg2_milli) / 1000.0
			return (velocity_one - frame_velocity) /
				(1.0 - velocity_one * frame_velocity / (speed_of_light * speed_of_light))
		}
		return invalid_result
	}
}
