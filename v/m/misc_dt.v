module misc_dt

import math

const max_iterations = i64(128)
const max_vector_size = 64

@[export: 'misc_dt']
pub fn misc_dt(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if isnil(input) || input_length != 2 {
			return -1
		}
		requested_iterations := input[0]
		requested_size := input[1]
		if requested_iterations != requested_iterations || requested_iterations < 1.0 ||
			requested_iterations > f64(max_iterations) || f64(i64(requested_iterations)) != requested_iterations {
			return -1
		}
		if requested_size != requested_size || requested_size < 1.0 ||
			requested_size > f64(max_vector_size) || f64(i64(requested_size)) != requested_size {
			return -1
		}
		iterations := i64(requested_iterations)
		size := int(requested_size)
		if isnil(output) || output_capacity < usize(size) {
			return -2
		}
		mut numerator := [max_vector_size]f64{}
		mut denominator := [max_vector_size]f64{}
		for index in 0 .. size {
			cosine := f32(math.cos(f64(size - index)))
			sine := f32(math.sin(f64(index)))
			numerator[index] = 1.0000001 * f64(cosine)
			denominator[index] = 1.0 + 1e-10 * f64(sine)
		}
		for _ in 0 .. int(iterations) {
			for index in 0 .. size {
				numerator[index] = numerator[index] / denominator[index]
			}
		}
		for index in 0 .. size {
			output[index] = numerator[index]
		}
		return i64(size)
	}
}
