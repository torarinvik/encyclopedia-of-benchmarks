module rhumb_bearing

import math

const pi_value = 3.14159265358979323846264338327950288

@[export: 'rhumb_bearing']
pub fn rhumb_bearing(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length != 4 { return -1 }
	unsafe {
		lat1, long1, lat2, long2 := input[0], input[1], input[2], input[3]
		if !lat1.is_finite() || !long1.is_finite() || !lat2.is_finite() || !long2.is_finite() ||
			lat1 < -85.0 || lat1 > 85.0 || lat2 < -85.0 || lat2 > 85.0 ||
			long1 < -180.0 || long1 > 180.0 || long2 < -180.0 || long2 > 180.0 { return -1 }
		phi1 := lat1 * pi_value / 180.0
		phi2 := lat2 * pi_value / 180.0
		mut del_lambda := (long2 - long1) * pi_value / 180.0
		if del_lambda > pi_value { del_lambda -= 2.0 * pi_value }
		else if del_lambda < -pi_value { del_lambda += 2.0 * pi_value }
		del_psi := math.log(math.tan(phi2 / 2.0 + pi_value / 4.0) / math.tan(phi1 / 2.0 + pi_value / 4.0))
		bearing := math.atan2(del_lambda, del_psi) * 180.0 / pi_value
		bearing_plus_360 := bearing + 360.0
		normalized := bearing_plus_360 - math.floor(bearing_plus_360 / 360.0) * 360.0
		if unsafe { output == nil } || output_capacity < 1 { return -2 }
		output[0] = normalized
		return 1
	}
}
