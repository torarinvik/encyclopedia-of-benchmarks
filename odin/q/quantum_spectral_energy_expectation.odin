package quantum_spectral_energy_expectation

import "core:c"
import "core:math"

MAX_N :: 32
SCALE :: i64(256)
INVALID_RESULT :: -1.0e300
TAU :: 6.283185307179586476925286766559005768

fft :: proc(real, imag: [^]f64, n: int, inverse: bool) {
	j := 0
	for i in 1..<n {
		bit := n >> 1
		for (j & bit) != 0 { j ^= bit; bit >>= 1 }
		j ^= bit
		if i < j {
			temporary := real[i]; real[i] = real[j]; real[j] = temporary
			temporary = imag[i]; imag[i] = imag[j]; imag[j] = temporary
		}
	}
	width := 2
	for width <= n {
		direction := f64(-1)
		if inverse { direction = 1 }
		angle := direction * TAU / f64(width)
		step_real, step_imag := math.cos(angle), math.sin(angle)
		half := width >> 1
		start := 0
		for start < n {
			twiddle_real, twiddle_imag := f64(1), f64(0)
			for offset in 0..<half {
				even, odd := start + offset, start + offset + half
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
			start += width
		}
		width <<= 1
	}
	if inverse {
		for i in 0..<n { real[i] /= f64(n); imag[i] /= f64(n) }
	}
}

@(export)
quantum_spectral_energy_expectation :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
	if values == nil || length < 1 || length > 98 do return INVALID_RESULT
	n_value := values[0]
	if n_value < 2 || n_value > MAX_N || (n_value & (n_value - 1)) != 0 do return INVALID_RESULT
	n := int(n_value)
	if length != c.size_t(1 + 3*n) do return INVALID_RESULT
	norm := i64(0)
	for i in 0..<n {
		potential, real_q, imag_q := values[1+i], values[1+n+i], values[1+2*n+i]
		if potential < -2048 || potential > 2048 || real_q < -2048 || real_q > 2048 ||
		   imag_q < -2048 || imag_q > 2048 do return INVALID_RESULT
		norm += real_q*real_q + imag_q*imag_q
	}
	if norm != SCALE*SCALE*n_value do return INVALID_RESULT
	var real: [MAX_N]f64
	var imag: [MAX_N]f64
	for i in 0..<n { real[i] = f64(values[1+n+i])/f64(SCALE); imag[i] = f64(values[1+2*n+i])/f64(SCALE) }
	fft(&real[0], &imag[0], n, false)
	for i in 0..<n {
		frequency := i64(i)
		if i > n/2 { frequency -= n_value }
		wave_number := TAU*f64(frequency)
		multiplier := 0.5*wave_number*wave_number
		real[i] *= multiplier
		imag[i] *= multiplier
	}
	fft(&real[0], &imag[0], n, true)
	total := f64(0)
	for i in 0..<n {
		psi_real, psi_imag := f64(values[1+n+i])/f64(SCALE), f64(values[1+2*n+i])/f64(SCALE)
		potential := f64(values[1+i])/f64(SCALE)
		total += psi_real*(real[i]+potential*psi_real) + psi_imag*(imag[i]+potential*psi_imag)
	}
	return total/f64(n)
}
