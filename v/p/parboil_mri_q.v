module main

import math

const max_input_length = 24
const pi_x_2 = f32(6.2831853071795864769252867665590058)

fn decode_component(raw i64) f32 { return f32(raw) / f32(1_000_000) }

fn quantize_q(value f32) i32 {

	scaled := value * f32(1_000)
	magnitude := if scaled < 0 { -scaled } else { scaled }
	mut whole := i32(magnitude)
	fraction := magnitude - f32(whole)
	if fraction >= f32(0.5) { whole++ }
	if scaled < 0 { return -whole }
	return whole
}

fn write_i32_le(output &u8, offset int, value i32) {
	bits := u32(value)
	unsafe {
		output[offset] = u8(bits)
		output[offset + 1] = u8(bits >> 8)
		output[offset + 2] = u8(bits >> 16)
		output[offset + 3] = u8(bits >> 24)
	}
}

// Clean-room Parboil MRI-Q profile; Illinois Open Source License in package docs.
@[export: 'parboil_mri_q']
pub fn parboil_mri_q(input &i64, input_length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || input_length < 9 || input_length > max_input_length { return -1 }
	count_value := unsafe { input[0] }
	if count_value < 1 || count_value > 4 { return -1 }
	count := int(count_value)
	if input_length != usize(4 + 5 * count) { return -1 }
	for i in 1 .. int(input_length) {
		value := unsafe { input[i] }
		if value < -1_000_000 || value > 1_000_000 { return -1 }
	}
	if unsafe { output == nil } || output_capacity < 8 { return -2 }

	x := decode_component(unsafe { input[1] })
	y := decode_component(unsafe { input[2] })
	z := decode_component(unsafe { input[3] })
	mut phi_magnitudes := [4]f32{}
	for k in 0 .. count {
		offset := 4 + 5 * k
		phi_real := decode_component(unsafe { input[offset + 3] })
		phi_imag := decode_component(unsafe { input[offset + 4] })
		real_square := phi_real * phi_real
		imag_square := phi_imag * phi_imag
		phi_magnitudes[k] = real_square + imag_square
	}
	mut qr := f32(0)
	mut qi := f32(0)
	for k in 0 .. count {
		offset := 4 + 5 * k
		kx := decode_component(unsafe { input[offset] })
		ky := decode_component(unsafe { input[offset + 1] })
		kz := decode_component(unsafe { input[offset + 2] })
		kx_x := kx * x
		ky_y := ky * y
		kz_z := kz * z
		xy := kx_x + ky_y
		xyz := xy + kz_z
		phase := pi_x_2 * xyz
		cos_phase := f32(math.cos(f64(phase)))
		sin_phase := f32(math.sin(f64(phase)))
		qr_term := phi_magnitudes[k] * cos_phase
		qi_term := phi_magnitudes[k] * sin_phase
		qr = qr + qr_term
		qi = qi + qi_term
	}
	write_i32_le(output, 0, quantize_q(qr))
	write_i32_le(output, 4, quantize_q(qi))
	return 8
}
