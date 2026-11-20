module quantum_spectral_energy_expectation

import math

const max_n = 32
const scale = i64(256)
const invalid_result = -1.0e300
const tau = 6.283185307179586476925286766559005768

fn fft(mut real []f64, mut imag []f64, n int, inverse bool) {
	mut j := 0
	for i in 1 .. n {
		mut bit := n >> 1
		for (j & bit) != 0 { j ^= bit; bit >>= 1 }
		j ^= bit
		if i < j {
			temporary := real[i]; real[i] = real[j]; real[j] = temporary
			temporary = imag[i]; imag[i] = imag[j]; imag[j] = temporary
		}
	}
	mut width := 2
	for width <= n {
		angle := (if inverse { f64(1) } else { f64(-1) }) * tau / f64(width)
		step_real, step_imag := math.cos(angle), math.sin(angle)
		half := width >> 1
		for start in 0 .. n / width {
			mut twiddle_real := f64(1)
			mut twiddle_imag := f64(0)
			for offset in 0 .. half {
				even := start * width + offset
				odd := even + half
				odd_real := real[odd] * twiddle_real - imag[odd] * twiddle_imag
				odd_imag := real[odd] * twiddle_imag + imag[odd] * twiddle_real
				real[odd] = real[even] - odd_real
				imag[odd] = imag[even] - odd_imag
				real[even] += odd_real
				imag[even] += odd_imag
				next_real := twiddle_real * step_real - twiddle_imag * step_imag
				twiddle_imag = twiddle_real * step_imag + twiddle_imag * step_real
				twiddle_real = next_real
			}
		}
		width <<= 1
	}
	if inverse {
		for i in 0 .. n { real[i] /= f64(n); imag[i] /= f64(n) }
	}
}

@[export: 'quantum_spectral_energy_expectation']
pub fn quantum_spectral_energy_expectation(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 1 || length > 98 { return invalid_result }
	unsafe {
		n_value := values[0]
		if n_value < 2 || n_value > max_n || (n_value & (n_value - 1)) != 0 { return invalid_result }
		n := int(n_value)
		if length != usize(1 + 3*n) { return invalid_result }
		mut norm := i64(0)
		for i in 0 .. n {
			potential, real_q, imag_q := values[1+i], values[1+n+i], values[1+2*n+i]
			if potential < -2048 || potential > 2048 || real_q < -2048 || real_q > 2048 || imag_q < -2048 || imag_q > 2048 { return invalid_result }
			norm += real_q*real_q + imag_q*imag_q
		}
		if norm != scale*scale*n_value { return invalid_result }
		mut real := [32]f64{}
		mut imag := [32]f64{}
		for i in 0 .. n { real[i] = f64(values[1+n+i])/f64(scale); imag[i] = f64(values[1+2*n+i])/f64(scale) }
		fft(mut real[..], mut imag[..], n, false)
		for i in 0 .. n {
			mut frequency := i64(i)
			if i > n/2 { frequency -= n_value }
			wave_number := tau*f64(frequency)
			multiplier := 0.5*wave_number*wave_number
			real[i] *= multiplier
			imag[i] *= multiplier
		}
		fft(mut real[..], mut imag[..], n, true)
		mut total := f64(0)
		for i in 0 .. n {
			psi_real, psi_imag := f64(values[1+n+i])/f64(scale), f64(values[1+2*n+i])/f64(scale)
			potential := f64(values[1+i])/f64(scale)
			total += psi_real*(real[i]+potential*psi_real) + psi_imag*(imag[i]+potential*psi_imag)
		}
		return total/f64(n)
	}
}
