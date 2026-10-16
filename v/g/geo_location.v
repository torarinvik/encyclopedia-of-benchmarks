module geo_location
import math

const pi_value = 3.14159265358979323846264338327950288

@[export: 'geo_location']
pub fn geo_location(values &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(values) || length != 4 { return -1 }
		for i in 0 .. 4 { if values[i] != values[i] || values[i] > 1.0e100 || values[i] < -1.0e100 { return -1 } }
		lat1d, lon1d, lat2d, lon2d := values[0], values[1], values[2], values[3]
		if lat1d < -90.0 || lat1d > 90.0 || lat2d < -90.0 || lat2d > 90.0 || lon1d < -180.0 || lon1d > 180.0 || lon2d < -180.0 || lon2d > 180.0 { return -1 }
		factor := pi_value / 180.0
		lat1, lon1, lat2, lon2 := lat1d*factor, lon1d*factor, lat2d*factor, lon2d*factor
		diff_lat, diff_lon := lat2-lat1, lon2-lon1
		sin_lat, sin_lon := math.sin(diff_lat/2.0), math.sin(diff_lon/2.0)
		haversine := sin_lat*sin_lat + math.cos(lat1)*math.cos(lat2)*sin_lon*sin_lon
		if haversine < 0.0 || haversine > 1.0 { return -1 }
		if isnil(output) || capacity < 1 { return -2 }
		output[0] = 6371010.0 * (2.0 * math.atan2(math.sqrt(haversine), math.sqrt(1.0-haversine)))
		return 1
	}
}
