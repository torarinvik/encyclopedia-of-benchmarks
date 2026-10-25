package parboil_mri_q

import "core:c"
import "core:math"

MAX_INPUT_LENGTH :: 24
PI_X_2 :: f32(6.2831853071795864769252867665590058)

/* Clean-room Parboil MRI-Q profile; Illinois Open Source License in package docs. */
decode_component :: proc(raw: i64) -> f32 { return f32(raw) / 1_000_000.0 }

quantize_q :: proc(value: f32) -> i32 {
    scaled := value * 1_000.0
    magnitude := if scaled < 0.0 then -scaled else scaled
    whole := i32(magnitude)
    fraction := magnitude - f32(whole)
    if fraction >= 0.5 do whole += 1
    if scaled < 0.0 do return -whole
    return whole
}

write_i32_le :: proc(output: [^]u8, offset: int, value: i32) {
    bits := u32(value)
    output[offset] = u8(bits)
    output[offset + 1] = u8(bits >> 8)
    output[offset + 2] = u8(bits >> 16)
    output[offset + 3] = u8(bits >> 24)
}

@(export)
parboil_mri_q :: proc "c" (input: [^]i64, input_length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 9 || input_length > MAX_INPUT_LENGTH do return -1
    if input[0] < 1 || input[0] > 4 do return -1
    count := int(input[0])
    if input_length != c.size_t(4 + 5 * count) do return -1
    for i := 1; i < int(input_length); i += 1 {
        if input[i] < -1_000_000 || input[i] > 1_000_000 do return -1
    }
    if output == nil || output_capacity < 8 do return -2

    x, y, z := decode_component(input[1]), decode_component(input[2]), decode_component(input[3])
    phi_magnitudes: [4]f32 = {}
    for k := 0; k < count; k += 1 {
        offset := 4 + 5*k
        phi_real := decode_component(input[offset+3])
        phi_imag := decode_component(input[offset+4])
        real_square := phi_real * phi_real
        imag_square := phi_imag * phi_imag
        phi_magnitudes[k] = real_square + imag_square
    }
    qr, qi: f32 = 0.0, 0.0
    for k := 0; k < count; k += 1 {
        offset := 4 + 5*k
        kx, ky, kz := decode_component(input[offset]), decode_component(input[offset+1]), decode_component(input[offset+2])
        kx_x, ky_y, kz_z := kx*x, ky*y, kz*z
        xy := kx_x + ky_y
        xyz := xy + kz_z
        phase := PI_X_2 * xyz
        cos_phase, sin_phase := f32(math.cos(f64(phase))), f32(math.sin(f64(phase)))
        qr_term := phi_magnitudes[k] * cos_phase
        qi_term := phi_magnitudes[k] * sin_phase
        qr = qr + qr_term
        qi = qi + qi_term
    }
    write_i32_le(output, 0, quantize_q(qr))
    write_i32_le(output, 4, quantize_q(qi))
    return 8
}
