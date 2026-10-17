package rhumb_bearing

import "core:c"
import "core:math"

PI_VALUE :: 3.14159265358979323846264338327950288

@(export)
rhumb_bearing :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length != 4 do return -1
	lat1, long1, lat2, long2 := input[0], input[1], input[2], input[3]
	if lat1 != lat1 || long1 != long1 || lat2 != lat2 || long2 != long2 ||
		math.abs(lat1) > 1e308 || math.abs(long1) > 1e308 || math.abs(lat2) > 1e308 || math.abs(long2) > 1e308 ||
		lat1 < -85.0 || lat1 > 85.0 || lat2 < -85.0 || lat2 > 85.0 ||
		long1 < -180.0 || long1 > 180.0 || long2 < -180.0 || long2 > 180.0 do return -1
	phi1 := lat1 * PI_VALUE / 180.0
	phi2 := lat2 * PI_VALUE / 180.0
	del_lambda := (long2 - long1) * PI_VALUE / 180.0
	if del_lambda > PI_VALUE do del_lambda -= 2.0 * PI_VALUE
	else if del_lambda < -PI_VALUE do del_lambda += 2.0 * PI_VALUE
	del_psi := math.ln(math.tan(phi2/2.0 + PI_VALUE/4.0) / math.tan(phi1/2.0 + PI_VALUE/4.0))
	bearing := math.atan2(del_lambda, del_psi) * 180.0 / PI_VALUE
	bearing_plus_360 := bearing + 360.0
	normalized := bearing_plus_360 - math.floor_f64(bearing_plus_360/360.0) * 360.0
	if output == nil || output_capacity < c.size_t(1) do return -2
	output[0] = normalized
	return 1
}
