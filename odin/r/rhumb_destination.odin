package rhumb_destination

import "core:c"
import "core:math"

PI_VALUE :: 3.14159265358979323846264338327950288
EARTH_RADIUS :: 6371000.0

@(export)
rhumb_destination :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length != 4 do return -1
	latitude, longitude, distance, bearing := input[0], input[1], input[2], input[3]
	if latitude != latitude || longitude != longitude || distance != distance || bearing != bearing ||
		math.abs(latitude) > 1e308 || math.abs(longitude) > 1e308 || math.abs(distance) > 1e308 || math.abs(bearing) > 1e308 ||
		latitude < -80.0 || latitude > 80.0 || longitude < -180.0 || longitude > 180.0 ||
		distance < 0.0 || distance > 300000.0 || bearing < 0.0 || bearing > 360.0 do return -1
	del := distance / EARTH_RADIUS
	phi1 := latitude * PI_VALUE / 180.0
	lambda1 := longitude * PI_VALUE / 180.0
	theta := bearing * PI_VALUE / 180.0
	del_phi := del * math.cos(theta)
	phi2 := phi1 + del_phi
	if phi2 > PI_VALUE / 2.0 do phi2 = PI_VALUE / 2.0
	else if phi2 < -PI_VALUE / 2.0 do phi2 = -PI_VALUE / 2.0
	del_psi := math.ln(math.tan(phi2/2.0 + PI_VALUE/4.0) / math.tan(phi1/2.0 + PI_VALUE/4.0))
	q := if math.abs(del_psi) > 1e-12 do del_phi / del_psi else math.cos(phi1)
	del_lambda := del * math.sin(theta) / q
	result_latitude := phi2 * 180.0 / PI_VALUE
	result_longitude := (lambda1 + del_lambda) * 180.0 / PI_VALUE
	if output == nil || output_capacity < c.size_t(2) do return -2
	output[0] = result_latitude
	output[1] = result_longitude
	return 2
}
