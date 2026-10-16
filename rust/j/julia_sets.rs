fn put_f32(output: &mut [u8], offset: usize, value: f32) {
    output[offset..offset + 4].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn julia_sets(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > 68 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let (iterations, cr_units, ci_units, count_value) = (values[0], values[1], values[2], values[3]);
    if !(0..=8).contains(&iterations) || !(0..=32).contains(&count_value) ||
        !(-128..=128).contains(&cr_units) || !(-128..=128).contains(&ci_units) {
        return -1;
    }
    let count = count_value as usize;
    if length != 4 + 2 * count || values[4..].iter().any(|&v| !(-128..=128).contains(&v)) {
        return -1;
    }
    let needed = 8 * count;
    if output.is_null() || capacity < needed {
        return -2;
    }
    let out = unsafe { std::slice::from_raw_parts_mut(output, needed) };
    let cr = cr_units as f32 / 16.0_f32;
    let ci = ci_units as f32 / 16.0_f32;
    let mut computed = [0.0f32; 64];
    for point in 0..count {
        let mut real = values[4 + 2 * point] as f32 / 16.0_f32;
        let mut imag = values[5 + 2 * point] as f32 / 16.0_f32;
        for _ in 0..iterations {
            let real_square = real * real;
            let imag_square = imag * imag;
            let real_imag = real * imag;
            let imag_real = imag * real;
            let next_real = (real_square - imag_square) + cr;
            let next_imag = (real_imag + imag_real) + ci;
            if !next_real.is_finite() || !next_imag.is_finite() {
                return -1;
            }
            real = next_real;
            imag = next_imag;
        }
        computed[2 * point] = real;
        computed[2 * point + 1] = imag;
    }
    for component in 0..2 * count {
        put_f32(out, component * 4, computed[component]);
    }
    needed as i64
}
