package vectors_3d

import "core:c"
import "core:math"

COMPONENT_LIMIT :: 1_000_000.0
EPSILON :: 1.0e-9

dot_product :: proc "contextless" (ax, ay, az, bx, by, bz: f32) -> f32 {
	dot := ax * bx
	dot += ay * by
	dot += az * bz
	return dot
}

vector_norm :: proc "contextless" (x, y, z: f32) -> f32 {
	return f32(math.sqrt_f64(f64(dot_product(x, y, z, x, y, z))))
}

@(export)
vectors_3d :: proc "c" (input: [^]f64, input_len: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_len == 0 do return -1
	operation_value := input[0]
	if operation_value != operation_value || operation_value < 0.0 || operation_value > 7.0 ||
		operation_value != f64(int(operation_value)) do return -1
	operation := int(operation_value)
	required_length := if operation <= 3 || operation == 7 do 7 else 4
	if input_len != c.size_t(required_length) do return -1

	components: [6]f32
	for index in 0..<required_length - 1 {
		value := input[index + 1]
		if value != value || value < -COMPONENT_LIMIT || value > COMPONENT_LIMIT do return -1
		components[index] = f32(value)
	}
	ax, ay, az := components[0], components[1], components[2]
	bx, by, bz := components[3], components[4], components[5]
	result := [9]f64{}
	result_length: int
	switch operation {
	case 0:
		result_length = 3
		result[0], result[1], result[2] = f64(ax + bx), f64(ay + by), f64(az + bz)
	case 1:
		result_length = 3
		result[0], result[1], result[2] = f64(ax - bx), f64(ay - by), f64(az - bz)
	case 2:
		result_length = 1
		result[0] = f64(dot_product(ax, ay, az, bx, by, bz))
	case 3:
		result_length = 3
		result[0] = f64(ay*bz - az*by)
		result[1] = f64(-ax*bz + az*bx)
		result[2] = f64(ax*by - ay*bx)
	case 4:
		result_length = 1
		result[0] = f64(vector_norm(ax, ay, az))
	case 5:
		result_length = 3
		norm := vector_norm(ax, ay, az)
		if f64(norm) >= EPSILON && norm != 1.0 do {
			result[0], result[1], result[2] = f64(ax/norm), f64(ay/norm), f64(az/norm)
		}
	case 6:
		result_length = 9
		result = [9]f64{0.0, -f64(az), f64(ay), f64(az), 0.0, -f64(ax), -f64(ay), f64(ax), 0.0}
	case 7:
		result_length = 1
		norm_a, norm_b := vector_norm(ax, ay, az), vector_norm(bx, by, bz)
		if f64(norm_a) < EPSILON || f64(norm_b) < EPSILON {
			result[0] = math.acos(2.0)
		} else {
			cosine := dot_product(ax, ay, az, bx, by, bz) / (norm_a * norm_b)
			result[0] = math.acos(f64(cosine))
		}
	}

	if output == nil || output_capacity < c.size_t(result_length) do return -2
	for index in 0..<result_length { output[index] = result[index] }
	return i64(result_length)
}
