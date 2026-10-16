module radar_target_calculation

import math

const pi_value = 3.14159265358979323846
const wgs84_a = 6378137.0
const wgs84_b = 6356752.314245

@[export: 'radar_target_calculation']
pub fn radar_target_calculation(values &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(values) || length != 6 { return -1 }
		for i in 0 .. 6 {
			if values[i] != values[i] { return -1 }
		}
		radar_lat, radar_lon, radar_alt := values[0], values[1], values[2]
		azimuth_deg, range_m, elevation_deg := values[3], values[4], values[5]
		if radar_lat < -80.0 || radar_lat > 80.0 || radar_lon < -180.0 || radar_lon > 180.0 ||
			radar_alt < -1000.0 || radar_alt > 10000.0 || azimuth_deg < -360.0 || azimuth_deg > 360.0 ||
			range_m < 0.0 || range_m > 200000.0 || elevation_deg < -30.0 || elevation_deg > 30.0 { return -1 }

		a_squared := wgs84_a * wgs84_a
		b_squared := wgs84_b * wgs84_b
		e_squared := 1.0 - (b_squared / a_squared)
		ep_squared := (a_squared - b_squared) / b_squared
		az_rad := azimuth_deg * pi_value / 180.0
		el_rad := elevation_deg * pi_value / 180.0
		east := range_m * math.cos(el_rad) * math.sin(az_rad)
		north := range_m * math.cos(el_rad) * math.cos(az_rad)
		up := range_m * math.sin(el_rad)

		lat_rad := radar_lat * pi_value / 180.0
		lon_rad := radar_lon * pi_value / 180.0
		sin_lat := math.sin(lat_rad)
		cos_lat := math.cos(lat_rad)
		n_radius := wgs84_a / math.sqrt(1.0 - e_squared * sin_lat * sin_lat)
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
		mut target_lat := f64(0)
		mut target_lon := f64(0)
		mut target_alt := f64(0)
		if p == 0.0 {
			target_lon = 0.0
			target_lat = if target_z > 0.0 { 90.0 } else { -90.0 }
			target_alt = math.abs(target_z) - wgs84_b
		} else {
			theta := math.atan2(target_z * wgs84_a, p * wgs84_b)
			sin_theta := math.sin(theta)
			cos_theta := math.cos(theta)
			target_lon_rad := math.atan2(target_y, target_x)
			sin_theta_cubed := sin_theta * sin_theta * sin_theta
			cos_theta_cubed := cos_theta * cos_theta * cos_theta
			target_lat_rad := math.atan2(target_z + ep_squared * wgs84_b * sin_theta_cubed,
				p - e_squared * wgs84_a * cos_theta_cubed)
			target_sin_lat := math.sin(target_lat_rad)
			target_n_radius := wgs84_a / math.sqrt(1.0 - e_squared * target_sin_lat * target_sin_lat)
			target_alt = (p / math.cos(target_lat_rad)) - target_n_radius
			target_lat = target_lat_rad * 180.0 / pi_value
			target_lon = target_lon_rad * 180.0 / pi_value
		}

		if isnil(output) || capacity < 3 { return -2 }
		output[0], output[1], output[2] = target_lat, target_lon, target_alt
		return 3
	}
}
