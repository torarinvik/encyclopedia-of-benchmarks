const MAX_INPUT_LENGTH: usize = 131;
const PI: f64 = 3.14159265358979323846264338327950288;

fn write_f64_le(output: &mut [u8], offset: usize, value: f64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

fn transform(real: &mut [f64; 128], imag: &mut [f64; 128], n: usize, inverse: bool) {
    let mut reverse = 0usize;
    for position in 1..n {
        let mut bit = n >> 1;
        while reverse & bit != 0 { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if position < reverse { real.swap(position, reverse); imag.swap(position, reverse); }
    }
    let mut block = 2usize;
    while block <= n {
        let direction = if inverse { -1.0 } else { 1.0 };
        let angle = -2.0 * PI / block as f64 * direction;
        let (step_real, step_imag) = (angle.cos(), angle.sin());
        let mut start = 0usize;
        while start < n {
            let (mut weight_real, mut weight_imag) = (1.0, 0.0);
            for offset in 0..block / 2 {
                let (first, second) = (start + offset, start + offset + block / 2);
                let product_real = weight_real * real[second] - weight_imag * imag[second];
                let product_imag = weight_real * imag[second] + weight_imag * real[second];
                let (first_real, first_imag) = (real[first], imag[first]);
                real[first] = first_real + product_real;
                imag[first] = first_imag + product_imag;
                real[second] = first_real - product_real;
                imag[second] = first_imag - product_imag;
                let next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real;
                weight_real = next_real;
            }
            start += block;
        }
        block *= 2;
    }
    if inverse {
        for index in 0..n { real[index] /= n as f64; imag[index] /= n as f64; }
    }
}

#[no_mangle]
pub unsafe extern "C" fn convolution_fft(input: *const i64, length: usize,
    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || !(4..=MAX_INPUT_LENGTH).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (raw_a, raw_b) = (values[0], values[1]);
    if !(1..=64).contains(&raw_a) || !(1..=64).contains(&raw_b) { return -1; }
    let (a_count, b_count) = (raw_a as usize, raw_b as usize);
    if length != 2 + a_count + b_count || values[2..].iter().any(|&x| !(-64..=64).contains(&x)) { return -1; }
    let result_count = a_count + b_count - 1;
    let byte_count = result_count * 16;
    if output.is_null() || capacity < byte_count { return -2; }
    let mut fft_length = 1usize;
    while fft_length < result_count { fft_length *= 2; }
    let mut a_real = [0.0; 128]; let mut a_imag = [0.0; 128];
    let mut b_real = [0.0; 128]; let mut b_imag = [0.0; 128];
    let mut product_real = [0.0; 128]; let mut product_imag = [0.0; 128];
    for index in 0..a_count { a_real[index] = values[index + 2] as f64 / 16.0; }
    for index in 0..b_count { b_real[index] = values[a_count + index + 2] as f64 / 16.0; }
    transform(&mut a_real, &mut a_imag, fft_length, false);
    transform(&mut b_real, &mut b_imag, fft_length, false);
    for index in 0..fft_length {
        product_real[index] = a_real[index] * b_real[index] - a_imag[index] * b_imag[index];
        product_imag[index] = a_real[index] * b_imag[index] + a_imag[index] * b_real[index];
    }
    transform(&mut product_real, &mut product_imag, fft_length, true);
    let result = std::slice::from_raw_parts_mut(output, byte_count);
    for index in 0..result_count {
        write_f64_le(result, index * 16, product_real[index]);
        write_f64_le(result, index * 16 + 8, product_imag[index]);
    }
    byte_count as i64
}
