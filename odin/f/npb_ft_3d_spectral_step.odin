package npb_ft_3d_spectral_step

import "core:c"
import "core:math"

MAX_POINTS :: 64
MAX_STEPS :: 6
CHECKSUM_TERMS :: 64
TAU :: 6.28318530717958647692528676655900577
ALPHA :: 0.000001

fft_line :: proc(real, imag: [^]f64, n: int, inverse: bool) {
	reverse := 0
	for position in 1..<n {
		bit := n >> 1
		for (reverse & bit) != 0 { reverse ^= bit; bit >>= 1 }
		reverse ^= bit
		if position < reverse {
			temporary := real[position]; real[position] = real[reverse]; real[reverse] = temporary
			temporary = imag[position]; imag[position] = imag[reverse]; imag[reverse] = temporary
		}
	}
	block := 2
	for block <= n {
		direction := -1.0
		if inverse { direction = 1.0 }
		angle := direction * TAU / f64(block)
		step_real, step_imag := math.cos_f64(angle), math.sin_f64(angle)
		for start := 0; start < n; start += block {
			weight_real, weight_imag := 1.0, 0.0
			for offset in 0..<block/2 {
				first, second := start+offset, start+offset+block/2
				product_real := weight_real*real[second] - weight_imag*imag[second]
				product_imag := weight_real*imag[second] + weight_imag*real[second]
				first_real, first_imag := real[first], imag[first]
				real[first], imag[first] = first_real+product_real, first_imag+product_imag
				real[second], imag[second] = first_real-product_real, first_imag-product_imag
				next_real := weight_real*step_real - weight_imag*step_imag
				weight_imag = weight_real*step_imag + weight_imag*step_real
				weight_real = next_real
			}
		}
		block *= 2
	}
	if inverse {
		for i in 0..<n { real[i] /= f64(n); imag[i] /= f64(n) }
	}
}

axis_transform :: proc(real, imag: [^]f64, n, axis: int, inverse: bool) {
	line_real: [4]f64
	line_imag: [4]f64
	for a in 0..<n {
		for b in 0..<n {
			for p in 0..<n {
				x, y, z := a, b, p
				if axis == 0 { x, y, z = p, a, b } else if axis == 1 { x, y, z = a, p, b }
				index := (x*n+y)*n+z
				line_real[p], line_imag[p] = real[index], imag[index]
			}
			fft_line(&line_real[0], &line_imag[0], n, inverse)
			for p in 0..<n {
				x, y, z := a, b, p
				if axis == 0 { x, y, z = p, a, b } else if axis == 1 { x, y, z = a, p, b }
				index := (x*n+y)*n+z
				real[index], imag[index] = line_real[p], line_imag[p]
			}
		}
	}
}

transform3d :: proc(real, imag: [^]f64, n: int, inverse: bool) {
	axis_transform(real, imag, n, 2, inverse)
	axis_transform(real, imag, n, 1, inverse)
	axis_transform(real, imag, n, 0, inverse)
}

signed_frequency :: proc(index, n: int) -> int {
	if index <= n/2 { return index }
	return index-n
}

@(export)
npb_ft_3d_spectral_step :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 2 || input_length > 130 do return -1
	if input[0] != 2.0 && input[0] != 4.0 do return -1
	if !math.is_finite(input[1]) || input[1] < 1.0 || input[1] > f64(MAX_STEPS) do return -1
	steps := int(input[1])
	if f64(steps) != input[1] do return -1
	n := int(input[0])
	volume := n*n*n
	if input_length != c.size_t(2+2*volume) do return -1
	for i in 2..<int(input_length) {
		if !math.is_finite(input[i]) || input[i] < -1.0 || input[i] > 1.0 do return -1
	}
	needed := 2*steps
	if output == nil || output_capacity < c.size_t(needed) do return -2

	spectrum_real: [MAX_POINTS]f64
	spectrum_imag: [MAX_POINTS]f64
	work_real: [MAX_POINTS]f64
	work_imag: [MAX_POINTS]f64
	for i in 0..<volume {
		spectrum_real[i], spectrum_imag[i] = input[2+2*i], input[2+2*i+1]
	}
	transform3d(&spectrum_real[0], &spectrum_imag[0], n, false)
	for step in 1..=steps {
		for x in 0..<n {
			for y in 0..<n {
				for z in 0..<n {
					index := (x*n+y)*n+z
					kx, ky, kz := signed_frequency(x,n), signed_frequency(y,n), signed_frequency(z,n)
					radius_squared := f64(kx*kx+ky*ky+kz*kz)
					factor := math.exp_f64(-39.47841760435743447533796399950460*ALPHA*f64(step)*radius_squared)
					work_real[index] = spectrum_real[index]*factor
					work_imag[index] = spectrum_imag[index]*factor
				}
			}
		}
		transform3d(&work_real[0], &work_imag[0], n, true)
		sum_real, sum_imag := 0.0, 0.0
		for j in 1..=CHECKSUM_TERMS {
			x, y, z := (j-1)%n, (3*j-1)%n, (5*j-1)%n
			index := (x*n+y)*n+z
			sum_real += work_real[index]
			sum_imag += work_imag[index]
		}
		output[2*(step-1)] = sum_real/f64(volume)
		output[2*(step-1)+1] = sum_imag/f64(volume)
	}
	return i64(needed)
}
