module rhumb_destination

import math

const pi_value = 3.14159265358979323846264338327950288
const earth_radius = 6371000.0

@[export: 'rhumb_destination']
pub fn rhumb_destination(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length != 4 { return -1 }
	unsafe {
		latitude, longitude, distance, bearing := input[0], input[1], input[2], input[3]
		if !latitude.is_finite() || !longitude.is_finite() || !distance.is_finite() || !bearing.is_finite() ||
			latitude < -80.0 || latitude > 80.0 || longitude < -180.0 || longitude > 180.0 ||
			distance < 0.0 || distance > 300000.0 || bearing < 0.0 || bearing > 360.0 { return -1 }
		del := distance / earth_radius
		phi1 := latitude * pi_value / 180.0
		lambda1 := longitude * pi_value / 180.0
		theta := bearing * pi_value / 180.0
		del_phi := del * math.cos(theta)
		mut phi2 := phi1 + del_phi
		if phi2 > pi_value / 2.0 { phi2 = pi_value / 2.0 }
		else if phi2 < -pi_value / 2.0 { phi2 = -pi_value / 2.0 }
		del_psi := math.log(math.tan(phi2 / 2.0 + pi_value / 4.0) / math.tan(phi1 / 2.0 + pi_value / 4.0))
		q := if math.abs(del_psi) > 1e-12 { del_phi / del_psi } else { math.cos(phi1) }
		del_lambda := del * math.sin(theta) / q
		result_latitude := phi2 * 180.0 / pi_value
		result_longitude := (lambda1 + del_lambda) * 180.0 / pi_value
		if unsafe { output == nil } || output_capacity < 2 { return -2 }
		output[0] = result_latitude
		output[1] = result_longitude
		return 2
	}
}
