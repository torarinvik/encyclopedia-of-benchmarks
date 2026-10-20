package rader_fft

import "core:c"
import "core:math"

MAX_COMPONENT :: 100.0
PI_VALUE :: 3.14159265358979323846264338327950288

fft8 :: proc "contextless" (real, imag: [^]f64, inverse: bool) {
	reversed := [8]int{0, 4, 2, 6, 1, 5, 3, 7}
	for i := 0; i < 8; i += 1 {
		j := reversed[i]
		if i < j {
			t := real[i]; real[i] = real[j]; real[j] = t
			t = imag[i]; imag[i] = imag[j]; imag[j] = t
		}
	}
	for stage := 1; stage <= 3; stage += 1 {
		block := 1 << stage
		half := block / 2
		for start := 0; start < 8; start += block {
			for j := 0; j < half; j += 1 {
				sign := -1.0
				if inverse { sign = 1.0 }
				angle := sign * 2.0 * PI_VALUE * f64(j) / f64(block)
				wr, wi := math.cos_f64(angle), math.sin_f64(angle)
				even, odd := start+j, start+j+half
				ur, ui := real[even], imag[even]
				vr := real[odd]*wr - imag[odd]*wi
				vi := real[odd]*wi + imag[odd]*wr
				real[even], imag[even] = ur+vr, ui+vi
				real[odd], imag[odd] = ur-vr, ui-vi
			}
		}
	}
	if inverse {
		for i := 0; i < 8; i += 1 { real[i] /= 8.0; imag[i] /= 8.0 }
	}
}

@(export)
rader_fft :: proc "c" (input: [^]f64, input_length: c.size_t,
		output: [^]f64, output_capacity: c.size_t) -> i64 {
	permutation := [4]int{1, 2, 4, 3}
	kernel_power := [4]int{1, 3, 4, 2}
	if input == nil || input_length != 10 do return -1
	for i := 0; i < 10; i += 1 {
		value := input[i]
		if value != value || value < -MAX_COMPONENT || value > MAX_COMPONENT do return -1
	}
	if output == nil || output_capacity < 10 do return -2

	ar, ai := [8]f64{}, [8]f64{}
	br, bi := [8]f64{}, [8]f64{}
	for i := 0; i < 4; i += 1 {
		ar[i], ai[i] = input[2*permutation[i]], input[2*permutation[i]+1]
		angle := -2.0 * PI_VALUE * f64(kernel_power[i]) / 5.0
		br[i], bi[i] = math.cos_f64(angle), math.sin_f64(angle)
	}
	fft8(&ar[0], &ai[0], false)
	fft8(&br[0], &bi[0], false)
	for i := 0; i < 8; i += 1 {
		product_real := ar[i]*br[i] - ai[i]*bi[i]
		product_imag := ar[i]*bi[i] + ai[i]*br[i]
		ar[i], ai[i] = product_real, product_imag
	}
	fft8(&ar[0], &ai[0], true)

	result := [10]f64{}
	for n := 0; n < 5; n += 1 {
		result[0] += input[2*n]
		result[1] += input[2*n+1]
	}
	for k := 1; k < 5; k += 1 { result[2*k], result[2*k+1] = input[0], input[1] }
	for i := 0; i < 4; i += 1 {
		target := kernel_power[i]
		result[2*target] += ar[i] + ar[i+4]
		result[2*target+1] += ai[i] + ai[i+4]
	}
	for i := 0; i < 10; i += 1 { output[i] = result[i] }
	return 10
}
