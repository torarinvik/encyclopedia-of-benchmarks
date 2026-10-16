package radar_target_calculation

import "core:c"
import "core:math"

PI :: 3.14159265358979323846
WGS84_A :: 6378137.0
WGS84_B :: 6356752.314245

@(export)
radar_target_calculation :: proc "c" (values: [^]f64, length: c.size_t,
	output: [^]f64, capacity: c.size_t) -> i64 {
	if values == nil || length != c.size_t(6) do return -1
	for i := 0; i < 6; i += 1 {
		if values[i] != values[i] do return -1
	}

	radar_lat, radar_lon, radar_alt := values[0], values[1], values[2]
	azimuth_deg, range_m, elevation_deg := values[3], values[4], values[5]
	if radar_lat < -80 || radar_lat > 80 || radar_lon < -180 || radar_lon > 180 ||
		radar_alt < -1000 || radar_alt > 10000 || azimuth_deg < -360 || azimuth_deg > 360 ||
		range_m < 0 || range_m > 200000 || elevation_deg < -30 || elevation_deg > 30 do return -1

	a_squared := WGS84_A * WGS84_A
	b_squared := WGS84_B * WGS84_B
	e_squared := 1.0 - (b_squared / a_squared)
	ep_squared := (a_squared - b_squared) / b_squared
	az_rad := azimuth_deg * PI / 180.0
	el_rad := elevation_deg * PI / 180.0
	east := range_m * math.cos(el_rad) * math.sin(az_rad)
	north := range_m * math.cos(el_rad) * math.cos(az_rad)
	up := range_m * math.sin(el_rad)

	lat_rad := radar_lat * PI / 180.0
	lon_rad := radar_lon * PI / 180.0
	sin_lat := math.sin(lat_rad)
	cos_lat := math.cos(lat_rad)
	n_radius := WGS84_A / math.sqrt(1.0 - e_squared * sin_lat * sin_lat)
	radar_x := (n_radius + radar_alt) * cos_lat * math.cos(lon_rad)
	radar_y := (n_radius + radar_alt) * cos_lat * math.sin(lon_rad)
	radar_z := (n_radius * (1.0 - e_squared) + radar_alt) * sin_lat

	sin_lon := math.sin(lon_rad)
	cos_lon := math.cos(lon_rad)
	dx := -sin_lon * east - sin_lat * cos_lon * north + cos_lat * cos_lon * up
	dy := cos_lon * east - sin_lat * sin_lon * north + cos_lat * sin_lon * up
	dz := cos_lat * north + sin_lat * up
	target_x, target_y, target_z := radar_x + dx, radar_y + dy, radar_z + dz

	p := math.sqrt(target_x * target_x + target_y * target_y)
	target_lat, target_lon, target_alt: f64
	if p == 0 {
		target_lon = 0
		if target_z > 0 {
			target_lat = 90
		} else {
			target_lat = -90
		}
		target_alt = math.abs(target_z) - WGS84_B
	} else {
		theta := math.atan2(target_z * WGS84_A, p * WGS84_B)
		sin_theta := math.sin(theta)
		cos_theta := math.cos(theta)
		target_lon_rad := math.atan2(target_y, target_x)
		sin_theta_cubed := sin_theta * sin_theta * sin_theta
		cos_theta_cubed := cos_theta * cos_theta * cos_theta
		target_lat_rad := math.atan2(target_z + ep_squared * WGS84_B * sin_theta_cubed,
			p - e_squared * WGS84_A * cos_theta_cubed)
		target_sin_lat := math.sin(target_lat_rad)
		target_n_radius := WGS84_A / math.sqrt(1.0 - e_squared * target_sin_lat * target_sin_lat)
		target_alt = (p / math.cos(target_lat_rad)) - target_n_radius
		target_lat = target_lat_rad * 180.0 / PI
		target_lon = target_lon_rad * 180.0 / PI
	}

	if output == nil || capacity < c.size_t(3) do return -2
	output[0], output[1], output[2] = target_lat, target_lon, target_alt
	return 3
}
