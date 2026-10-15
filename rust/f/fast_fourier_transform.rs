fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}
fn quantize(value: f64) -> i64 {
    let scaled = value * 1_000_000.0;
    if scaled >= 0.0 { (scaled + 0.5) as i64 } else { (scaled - 0.5) as i64 }
}
fn transform(real: &mut [f64; 64], imag: &mut [f64; 64], n: usize) {
    let mut reverse = 0usize;
    for position in 1..n {
        let mut bit = n >> 1;
        while reverse & bit != 0 { reverse ^= bit; bit >>= 1; }
        reverse ^= bit;
        if position < reverse { real.swap(position, reverse); imag.swap(position, reverse); }
    }
    let mut block = 2usize;
    while block <= n {
        let angle = 6.283185307179586476925286766559 / block as f64;
        let (step_real, step_imag) = (angle.cos(), angle.sin());
        let mut start = 0usize;
        while start < n {
            let (mut weight_real, mut weight_imag) = (1.0, 0.0);
            for offset in 0..block / 2 {
                let (first, second) = (start + offset, start + offset + block / 2);
                let product_real = weight_real * real[second] - weight_imag * imag[second];
                let product_imag = weight_real * imag[second] + weight_imag * real[second];
                let (first_real, first_imag) = (real[first], imag[first]);
                real[first] = first_real + product_real; imag[first] = first_imag + product_imag;
                real[second] = first_real - product_real; imag[second] = first_imag - product_imag;
                let next_real = weight_real * step_real - weight_imag * step_imag;
                weight_imag = weight_real * step_imag + weight_imag * step_real; weight_real = next_real;
            }
            start += block;
        }
        block *= 2;
    }
}

#[no_mangle]
pub unsafe extern "C" fn fast_fourier_transform(values: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if values.is_null() || !(2..=65).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    let raw_n = input[0];
    if !(1..=64).contains(&raw_n) || raw_n & (raw_n - 1) != 0 { return -1; }
    let n = raw_n as usize;
    if length != n + 1 || input[1..].iter().any(|&value| !(-1000..=1000).contains(&value)) { return -1; }
    let byte_count = 16 * n;
    if output.is_null() || capacity < byte_count { return -2; }
    let mut real = [0.0; 64]; let mut imag = [0.0; 64];
    for index in 0..n { real[index] = input[index + 1] as f64; }
    transform(&mut real, &mut imag, n);
    let result = std::slice::from_raw_parts_mut(output, capacity);
    for index in 0..n { store_i64_le(result, 16 * index, quantize(real[index])); store_i64_le(result, 16 * index + 8, quantize(imag[index])); }
    byte_count as i64
}
