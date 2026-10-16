module main

import math

const coordinate_limit = 1_000_000.0
const angle_limit = 1_000_000.0
const output_limit = 2_000_000.0
const pi_value = 3.14159265358979323846

@[export: 'vector3_axis_rotation']
pub fn vector3_axis_rotation(input &f64, input_len usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_len != 5 { return -1 }
		for i in 0 .. 3 {
			value := input[i]
			if value != value || value < -coordinate_limit || value > coordinate_limit { return -1 }
		}
		axis := input[3]
		mut angle := input[4]
		if (axis != 0.0 && axis != 1.0 && axis != 2.0) || angle != angle || angle < -angle_limit || angle > angle_limit { return -1 }
		angle -= math.floor(angle / 360.0) * 360.0
		if angle == 0.0 { angle = 0.0 }
		angle = angle / 450.0 * 180.0 / pi_value
		x := input[0]
		y := input[1]
		z := input[2]
		cosine := math.cos(angle)
		sine := math.sin(angle)
		mut result := [3]f64{}
		if axis == 0.0 {
			result[0] = x
			result[1] = y * cosine - z * sine
			result[2] = z * cosine + y * sine
		} else if axis == 1.0 {
			result[0] = x * cosine - z * sine
			result[1] = y
			result[2] = z * cosine + x * sine
		} else {
			result[0] = x * cosine - y * sine
			result[1] = y * cosine + x * sine
			result[2] = z
		}
		for value in result {
			if value != value || value < -output_limit || value > output_limit { return -1 }
		}
		if output == nil || output_capacity < 3 { return -2 }
		for i in 0 .. 3 { output[i] = result[i] }
		return 3
	}
}
