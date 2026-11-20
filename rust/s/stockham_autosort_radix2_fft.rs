const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_N + 1;
const MAX_SCALARS: usize = 2 * MAX_N;
const TAU: f64 = 6.283185307179586476925286766559;

fn stockham_stage(source: &[f64; MAX_SCALARS], destination: &mut [f64; MAX_SCALARS],
                  n: usize, stride: usize) {
    for j in 0..n / 2 {
        let column = j % stride;
        let group = j / stride;
        let base = group * 2 * stride + column;
        let angle = -TAU * column as f64 / (2 * stride) as f64;
        let (sine, cosine) = angle.sin_cos();
        let left = 2 * j;
        let right = 2 * (j + n / 2);
        let product_real = cosine * source[right] - sine * source[right + 1];
        let product_imag = cosine * source[right + 1] + sine * source[right];
        let first_real = source[left];
        let first_imag = source[left + 1];
        let out_left = 2 * base;
        let out_right = 2 * (base + stride);
        destination[out_left] = first_real + product_real;
        destination[out_left + 1] = first_imag + product_imag;
        destination[out_right] = first_real - product_real;
        destination[out_right + 1] = first_imag - product_imag;
    }
}

#[no_mangle]
pub unsafe extern "C" fn stockham_autosort_radix2_fft(
    input: *const f64, input_length: usize,
    output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || !(3..=MAX_INPUT_LENGTH).contains(&input_length) {
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
    if !n.is_power_of_two() || input_length != 1 + 2 * n
        || values[1..].iter().any(|value| !(-8.0..=8.0).contains(value)) {
        return -1;
    }

    let mut first = [0.0; MAX_SCALARS];
    let mut second = [0.0; MAX_SCALARS];
    first[..2 * n].copy_from_slice(&values[1..]);
    let mut source_is_first = true;
    let mut stride = 1;
    while stride < n {
        if source_is_first {
            stockham_stage(&first, &mut second, n, stride);
        } else {
            stockham_stage(&second, &mut first, n, stride);
        }
        source_is_first = !source_is_first;
        stride *= 2;
    }

    let needed = 2 * n;
    if output.is_null() || output_capacity < needed {
        return -2;
    }
    let result = if source_is_first { &first } else { &second };
    for index in 0..needed {
        unsafe { *output.add(index) = result[index] };
    }
    needed as i64
}
