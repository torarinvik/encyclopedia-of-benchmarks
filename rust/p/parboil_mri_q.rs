const MAX_INPUT_LENGTH: usize = 24;
const PI_X_2: f32 = 6.2831853071795864769252867665590058_f32;

/* Clean-room Parboil MRI-Q profile; Illinois Open Source License in package docs. */
fn decode_component(raw: i64) -> f32 { raw as f32 / 1_000_000.0_f32 }

fn quantize_q(value: f32) -> i32 {
    let scaled = value * 1_000.0_f32;
    let magnitude = scaled.abs();
    let mut whole = magnitude as i32;
    let fraction = magnitude - whole as f32;
    if fraction >= 0.5_f32 { whole += 1; }
    if scaled < 0.0 { -whole } else { whole }
}

fn write_i32_le(output: &mut [u8], offset: usize, value: i32) {
    let bytes = value.to_le_bytes();
    output[offset..offset + 4].copy_from_slice(&bytes);
}

#[no_mangle]
pub unsafe extern "C" fn parboil_mri_q(
    input: *const i64, input_length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 9 || input_length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values[0] < 1 || values[0] > 4 { return -1; }
    let count = values[0] as usize;
    if input_length != 4 + 5 * count { return -1; }
    if values[1..].iter().any(|v| *v < -1_000_000 || *v > 1_000_000) { return -1; }
    if output.is_null() || output_capacity < 8 { return -2; }

    let x = decode_component(values[1]);
    let y = decode_component(values[2]);
    let z = decode_component(values[3]);
    let mut phi_magnitudes = [0.0_f32; 4];
    for k in 0..count {
        let offset = 4 + 5 * k;
        let phi_real = decode_component(values[offset + 3]);
        let phi_imag = decode_component(values[offset + 4]);
        let real_square = phi_real * phi_real;
        let imag_square = phi_imag * phi_imag;
        phi_magnitudes[k] = real_square + imag_square;
    }
    let mut qr = 0.0_f32;
    let mut qi = 0.0_f32;
    for k in 0..count {
        let offset = 4 + 5 * k;
        let kx = decode_component(values[offset]);
        let ky = decode_component(values[offset + 1]);
        let kz = decode_component(values[offset + 2]);
        let kx_x = kx * x;
        let ky_y = ky * y;
        let kz_z = kz * z;
        let xy = kx_x + ky_y;
        let xyz = xy + kz_z;
        let phase = PI_X_2 * xyz;
        let cos_phase = phase.cos();
        let sin_phase = phase.sin();
        let qr_term = phi_magnitudes[k] * cos_phase;
        let qi_term = phi_magnitudes[k] * sin_phase;
        qr = qr + qr_term;
        qi = qi + qi_term;
    }
    let result = std::slice::from_raw_parts_mut(output, 8);
    write_i32_le(result, 0, quantize_q(qr));
    write_i32_le(result, 4, quantize_q(qi));
    8
}
