import math

const max_scalars = 128
const tau = 6.283185307179586476925286766559

fn stockham_stage(source [max_scalars]f64, mut destination [max_scalars]f64, n int, stride int) {
	for j in 0 .. n / 2 {
		column := j % stride
		group := j / stride
		base := group * 2 * stride + column
		angle := -tau * f64(column) / f64(2 * stride)
		cosine := math.cos(angle)
		sine := math.sin(angle)
		left := 2 * j
		right := 2 * (j + n / 2)
		product_real := cosine * source[right] - sine * source[right + 1]
		product_imag := cosine * source[right + 1] + sine * source[right]
		first_real := source[left]
		first_imag := source[left + 1]
		out_left := 2 * base
		out_right := 2 * (base + stride)
		destination[out_left] = first_real + product_real
		destination[out_left + 1] = first_imag + product_imag
		destination[out_right] = first_real - product_real
		destination[out_right + 1] = first_imag - product_imag
	}
}

@[export: 'stockham_autosort_radix2_fft']
pub fn stockham_autosort_radix2_fft(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 3 || input_length > 130 { return -1 }
		for i in 0 .. input_length { if !math.is_finite(input[i]) { return -1 } }
		n_value := input[0]
		if n_value < 1.0 || n_value > 64.0 || math.trunc(n_value) != n_value { return -1 }
		n := int(n_value)
		if (n & (n - 1)) != 0 || input_length != usize(1 + 2 * n) { return -1 }
		for i in 0 .. 2 * n {
			if input[i + 1] < -8.0 || input[i + 1] > 8.0 { return -1 }
		}

		mut first := [max_scalars]f64{}
		mut second := [max_scalars]f64{}
		for i in 0 .. 2 * n { first[i] = input[i + 1] }
		mut source_is_first := true
		mut stride := 1
		for stride < n {
			if source_is_first {
				stockham_stage(first, mut second, n, stride)
			} else {
				stockham_stage(second, mut first, n, stride)
			}
			source_is_first = !source_is_first
			stride *= 2
		}

		needed := 2 * n
		if output == nil || output_capacity < usize(needed) { return -2 }
		for i in 0 .. needed {
			if source_is_first { output[i] = first[i] } else { output[i] = second[i] }
		}
		return i64(needed)
	}
}
