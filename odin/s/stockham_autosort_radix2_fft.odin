package stockham_autosort_radix2_fft

import "core:c"
import "core:math"

MAX_SCALARS :: 128
TAU :: 6.283185307179586476925286766559

stockham_stage :: proc(source, destination: [^]f64, n, stride: int) {
	for j in 0..<n/2 {
		column := j % stride
		group := j / stride
		base := group * 2 * stride + column
		angle := -TAU * f64(column) / f64(2*stride)
		cosine, sine := math.cos_f64(angle), math.sin_f64(angle)
		left, right := 2*j, 2*(j+n/2)
		product_real := cosine*source[right] - sine*source[right+1]
		product_imag := cosine*source[right+1] + sine*source[right]
		first_real, first_imag := source[left], source[left+1]
		out_left, out_right := 2*base, 2*(base+stride)
		destination[out_left] = first_real + product_real
		destination[out_left+1] = first_imag + product_imag
		destination[out_right] = first_real - product_real
		destination[out_right+1] = first_imag - product_imag
	}
}

@(export)
stockham_autosort_radix2_fft :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 3 || input_length > 130 do return -1
	for i in 0..<int(input_length) { if !math.is_finite(input[i]) do return -1 }
	n_value := input[0]
	if n_value < 1 || n_value > 64 || math.trunc(n_value) != n_value do return -1
	n := int(n_value)
	if (n & (n-1)) != 0 || input_length != c.size_t(1+2*n) do return -1
	for i in 0..<2*n { if input[i+1] < -8 || input[i+1] > 8 do return -1 }

	first: [MAX_SCALARS]f64
	second: [MAX_SCALARS]f64
	for i in 0..<2*n { first[i] = input[i+1] }
	source_is_first := true
	stride := 1
	for stride < n {
		if source_is_first {
			stockham_stage(&first[0], &second[0], n, stride)
		} else {
			stockham_stage(&second[0], &first[0], n, stride)
		}
		source_is_first = !source_is_first
		stride *= 2
	}

	needed := 2*n
	if output == nil || output_capacity < c.size_t(needed) do return -2
	for i in 0..<needed {
		if source_is_first { output[i] = first[i] } else { output[i] = second[i] }
	}
	return i64(needed)
}
