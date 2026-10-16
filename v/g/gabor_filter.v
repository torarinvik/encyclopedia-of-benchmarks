module main

import math

const pi = 3.14159265358979323846264338327950288

fn put_f32_le(output &u8, offset int, value f64) {
	bits := math.f32_bits(f32(value))
	for byte in 0 .. 4 {
		unsafe { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'gabor_filter']
pub fn gabor_filter(values &i64, length usize, output &u8, capacity usize) i64 {
	if isnil(values) || length < 1 || length > 7 { return -1 }
	if length != 6 { return -1 }
	requested := unsafe { values[0] }
	sigma := unsafe { values[1] }
	theta := unsafe { values[2] }
	wavelength := unsafe { values[3] }
	gamma := unsafe { values[4] }
	phase := unsafe { values[5] }
	if requested < 1 || requested > 7 || sigma < 1 || sigma > 8 { return -1 }
	if theta < 0 || theta > 359 || wavelength < 1 || wavelength > 8 { return -1 }
	if gamma < 0 || gamma > 4 || phase < -6 || phase > 6 { return -1 }

	mut side := int(requested)
	if side % 2 == 0 { side++ }
	output_bytes := side * side * 4
	if isnil(output) || capacity < usize(output_bytes) { return -2 }

	angle := (f64(theta) / 180.0) * pi
	cosine := math.cos(angle)
	sine := math.sin(angle)
	center := side / 2
	mut offset := 0
	for y in 0 .. side {
		py := f64(y - center)
		for x in 0 .. side {
			px := f64(x - center)
			kernel_x := cosine * px + sine * py
			kernel_y := -sine * px + cosine * py
			exponent := -(kernel_x * kernel_x + f64(gamma * gamma) * kernel_y * kernel_y) /
				(2.0 * f64(sigma) * f64(sigma))
			phase_angle := 2.0 * pi * kernel_x / f64(wavelength) + f64(phase)
			put_f32_le(output, offset, math.exp(exponent) * math.cos(phase_angle))
			offset += 4
		}
	}
	return i64(output_bytes)
}
