module rhumb_distance

import math

const pi_value = 3.14159265358979323846264338327950288
const earth_radius = 6371000.0

@[export: 'rhumb_distance']
pub fn rhumb_distance(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length != 4 { return -1 }
	unsafe {
		lat1, long1, lat2, long2 := input[0], input[1], input[2], input[3]
		if !lat1.is_finite() || !long1.is_finite() || !lat2.is_finite() || !long2.is_finite() ||
			lat1 < -85.0 || lat1 > 85.0 || lat2 < -85.0 || lat2 > 85.0 ||
			long1 < -180.0 || long1 > 180.0 || long2 < -180.0 || long2 > 180.0 { return -1 }
		phi1 := lat1 * pi_value / 180.0
		phi2 := lat2 * pi_value / 180.0
		del_phi := phi2 - phi1
		mut del_lambda := (long2 - long1) * pi_value / 180.0
		if del_lambda > pi_value { del_lambda -= 2.0 * pi_value }
		else if del_lambda < -pi_value { del_lambda += 2.0 * pi_value }
		del_psi := math.log(math.tan(phi2 / 2.0 + pi_value / 4.0) / math.tan(phi1 / 2.0 + pi_value / 4.0))
		q := if math.abs(del_psi) > 1e-12 { del_phi / del_psi } else { math.cos(phi1) }
		distance := math.sqrt(math.pow(del_phi, 2.0) + math.pow(q * del_lambda, 2.0)) * earth_radius
		if unsafe { output == nil } || output_capacity < 1 { return -2 }
		output[0] = distance
		return 1
	}
}
