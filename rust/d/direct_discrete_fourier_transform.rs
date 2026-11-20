const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_N + 1;
const TAU: f64 = 6.283185307179586476925286766559;

#[no_mangle]
pub unsafe extern "C" fn direct_discrete_fourier_transform(
    input: *const f64, input_length: usize,
    output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=MAX_INPUT_LENGTH).contains(&input_length) {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }
    let n_value = values[0];
    if n_value < 1.0 || n_value > MAX_N as f64 || n_value.fract() != 0.0 {
        return -1;
    }
    let n = n_value as usize;
    if input_length != 1 + 2 * n
        || values[1..].iter().any(|value| !(-8.0..=8.0).contains(value)) {
        return -1;
    }

    let needed = 2 * n;
    if output.is_null() || output_capacity < needed {
        return -2;
    }
    for k in 0..n {
        let mut real_sum = 0.0;
        let mut imag_sum = 0.0;
        for j in 0..n {
            let angle = -TAU * j as f64 * k as f64 / n as f64;
            let (sine, cosine) = angle.sin_cos();
            let sample_real = values[1 + 2 * j];
            let sample_imag = values[2 + 2 * j];
            real_sum += sample_real * cosine + sample_imag * sine;
            imag_sum += sample_imag * cosine - sample_real * sine;
        }
        unsafe {
            *output.add(2 * k) = real_sum;
            *output.add(2 * k + 1) = imag_sum;
        }
    }
    needed as i64
}

