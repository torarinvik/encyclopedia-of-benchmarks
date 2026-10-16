module main

import math

const component_limit = 1_000_000.0
const epsilon = 1.0e-9

fn dot_product(ax, ay, az, bx, by, bz f32) f32 {
	mut dot := ax * bx
	dot += ay * by
	dot += az * bz
	return dot
}

fn vector_norm(x, y, z f32) f32 {
	return f32(math.sqrt(f64(dot_product(x, y, z, x, y, z))))
}

@[export: 'vectors_3d']
pub fn vectors_3d(input &f64, input_len usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_len == 0 { return -1 }
		operation_value := input[0]
		if operation_value != operation_value || operation_value < 0.0 || operation_value > 7.0 { return -1 }
		operation := int(operation_value)
		if f64(operation) != operation_value { return -1 }
		required_length := if operation <= 3 || operation == 7 { 7 } else { 4 }
		if input_len != usize(required_length) { return -1 }

		mut components := [6]f32{}
		component_count := required_length - 1
		for index in 0 .. component_count {
			value := input[index + 1]
			if value != value || math.abs(value) > component_limit { return -1 }
			components[index] = f32(value)
		}
		ax, ay, az := components[0], components[1], components[2]
		bx, by, bz := components[3], components[4], components[5]
		mut result := [9]f64{}
		mut result_length := 0
		if operation == 0 {
			result_length = 3
			result[0], result[1], result[2] = f64(ax + bx), f64(ay + by), f64(az + bz)
		} else if operation == 1 {
			result_length = 3
			result[0], result[1], result[2] = f64(ax - bx), f64(ay - by), f64(az - bz)
		} else if operation == 2 {
			result_length = 1
			result[0] = f64(dot_product(ax, ay, az, bx, by, bz))
		} else if operation == 3 {
			result_length = 3
			result[0] = f64(ay*bz - az*by)
			result[1] = f64(-ax*bz + az*bx)
			result[2] = f64(ax*by - ay*bx)
		} else if operation == 4 {
			result_length = 1
			result[0] = f64(vector_norm(ax, ay, az))
		} else if operation == 5 {
			result_length = 3
			norm := vector_norm(ax, ay, az)
			if f64(norm) >= epsilon && norm != f32(1.0) {
				result[0], result[1], result[2] = f64(ax/norm), f64(ay/norm), f64(az/norm)
			}
		} else if operation == 6 {
			result_length = 9
			result = [9]f64{0.0, -f64(az), f64(ay), f64(az), 0.0, -f64(ax), -f64(ay), f64(ax), 0.0}
		} else {
			result_length = 1
			norm_a, norm_b := vector_norm(ax, ay, az), vector_norm(bx, by, bz)
			if f64(norm_a) < epsilon || f64(norm_b) < epsilon {
				result[0] = math.acos(2.0)
			} else {
				cosine := dot_product(ax, ay, az, bx, by, bz) / (norm_a * norm_b)
				result[0] = math.acos(f64(cosine))
			}
		}
		if output == nil || output_capacity < usize(result_length) { return -2 }
		for index in 0 .. result_length { output[index] = result[index] }
		return i64(result_length)
	}
}
