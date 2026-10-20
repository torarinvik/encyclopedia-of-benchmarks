module rader_fft

import math

const max_component = 100.0
const pi_value = 3.14159265358979323846264338327950288

fn fft8(mut real &f64, mut imag &f64, inverse bool) {
	unsafe {
		reversed := [8]int{0, 4, 2, 6, 1, 5, 3, 7}
		for i in 0 .. 8 {
			j := reversed[i]
			if i < j {
				t := real[i]; real[i] = real[j]; real[j] = t
				t = imag[i]; imag[i] = imag[j]; imag[j] = t
			}
		}
		for stage in 1 .. 4 {
			block := 1 << stage
			half := block / 2
			for start := 0; start < 8; start += block {
				for j := 0; j < half; j++ {
					sign := -1.0
					if inverse { sign = 1.0 }
					angle := sign * 2.0 * pi_value * f64(j) / f64(block)
					wr, wi := math.cos(angle), math.sin(angle)
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
			for i in 0 .. 8 { real[i] /= 8.0; imag[i] /= 8.0 }
		}
	}
}

@[export: 'rader_fft']
pub fn rader_fft(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		permutation := [4]int{1, 2, 4, 3}
		kernel_power := [4]int{1, 3, 4, 2}
		if input == nil || input_length != 10 { return -1 }
		for i in 0 .. 10 {
			value := input[i]
			if value != value || value < -max_component || value > max_component { return -1 }
		}
		if output == nil || output_capacity < 10 { return -2 }

		mut ar := [8]f64{}
		mut ai := [8]f64{}
		mut br := [8]f64{}
		mut bi := [8]f64{}
		for i in 0 .. 4 {
			ar[i], ai[i] = input[2*permutation[i]], input[2*permutation[i]+1]
			angle := -2.0 * pi_value * f64(kernel_power[i]) / 5.0
			br[i], bi[i] = math.cos(angle), math.sin(angle)
		}
		fft8(mut &ar[0], mut &ai[0], false)
		fft8(mut &br[0], mut &bi[0], false)
		for i in 0 .. 8 {
			product_real := ar[i]*br[i] - ai[i]*bi[i]
			product_imag := ar[i]*bi[i] + ai[i]*br[i]
			ar[i], ai[i] = product_real, product_imag
		}
		fft8(mut &ar[0], mut &ai[0], true)

		mut result := [10]f64{}
		for n in 0 .. 5 { result[0] += input[2*n]; result[1] += input[2*n+1] }
		for k in 1 .. 5 { result[2*k] = input[0]; result[2*k+1] = input[1] }
		for i in 0 .. 4 {
			target := kernel_power[i]
			result[2*target] += ar[i] + ar[i+4]
			result[2*target+1] += ai[i] + ai[i+4]
		}
		for i in 0 .. 10 { output[i] = result[i] }
		return 10
	}
}
