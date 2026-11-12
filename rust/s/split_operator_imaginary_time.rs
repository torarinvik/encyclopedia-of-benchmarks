const MAX_N: usize = 64;
const MAX_STEPS: usize = 8;
const MAX_INPUT_LENGTH: usize = 2 + 4 * MAX_N;
const TAU: f64 = 6.28318530717958647692528676655900577;

fn bounded_integer(value: f64, minimum: f64, maximum: f64) -> bool {
    value.is_finite() && value.fract() == 0.0 && value >= minimum && value <= maximum
}

fn fft(real: &mut [f64; MAX_N], imag: &mut [f64; MAX_N], n: usize, inverse: bool) {
    let mut reverse = 0;
    for position in 1..n {
        let mut bit = n >> 1;
        while bit != 0 && reverse & bit != 0 {
            reverse ^= bit;
            bit >>= 1;
        }
        reverse ^= bit;
        if position < reverse {
            real.swap(position, reverse);
            imag.swap(position, reverse);
        }
    }
    let mut block = 2;
    while block <= n {
        let direction = if inverse { 1.0 } else { -1.0 };
        let angle = direction * TAU / block as f64;
        let (step_real, step_imag) = (angle.cos(), angle.sin());
        for start in (0..n).step_by(block) {
            let (mut weight_real, mut weight_imag) = (1.0, 0.0);
            for offset in 0..block / 2 {
                let first = start + offset;
                let second = first + block / 2;
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
        }
        block *= 2;
    }
    if inverse {
        for index in 0..n {
            real[index] /= n as f64;
            imag[index] /= n as f64;
        }
    }
}

fn normalize(real: &mut [f64; MAX_N], imag: &mut [f64; MAX_N], n: usize) {
    let norm_squared: f64 = (0..n).map(|i| real[i] * real[i] + imag[i] * imag[i]).sum();
    let norm = norm_squared.sqrt();
    for i in 0..n {
        real[i] /= norm;
        imag[i] /= norm;
    }
}

#[no_mangle]
pub unsafe extern "C" fn split_operator_imaginary_time(
    input: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_LENGTH { return -1; }
    let n_value = *input;
    let steps_value = *input.add(1);
    if !bounded_integer(n_value, 2.0, MAX_N as f64)
        || !bounded_integer(steps_value, 0.0, MAX_STEPS as f64) { return -1; }
    let n = n_value as usize;
    let steps = steps_value as usize;
    if n & (n - 1) != 0 || length != 2 + 4 * n { return -1; }
    let momentum_start = 2 + n;
    let state_start = 2 + 2 * n;
    let mut norm_squared = 0.0;
    for i in 0..n {
        let position = *input.add(2 + i);
        let momentum = *input.add(momentum_start + i);
        let real_value = *input.add(state_start + 2 * i);
        let imag_value = *input.add(state_start + 2 * i + 1);
        if !position.is_finite() || !(0.25..=1.0).contains(&position)
            || !momentum.is_finite() || !(0.25..=1.0).contains(&momentum)
            || !real_value.is_finite() || real_value.abs() > 1.0
            || !imag_value.is_finite() || imag_value.abs() > 1.0 { return -1; }
        norm_squared += real_value * real_value + imag_value * imag_value;
    }
    if !(norm_squared > 0.0) { return -1; }
    let output_count = 2 * n;
    if output.is_null() || capacity < output_count { return -2; }

    let mut real = [0.0; MAX_N];
    let mut imag = [0.0; MAX_N];
    for i in 0..n {
        real[i] = *input.add(state_start + 2 * i);
        imag[i] = *input.add(state_start + 2 * i + 1);
    }
    normalize(&mut real, &mut imag, n);
    for _ in 0..steps {
        for i in 0..n {
            let factor = *input.add(2 + i);
            real[i] *= factor;
            imag[i] *= factor;
        }
        fft(&mut real, &mut imag, n, false);
        for i in 0..n {
            let factor = *input.add(momentum_start + i);
            real[i] *= factor;
            imag[i] *= factor;
        }
        fft(&mut real, &mut imag, n, true);
        for i in 0..n {
            let factor = *input.add(2 + i);
            real[i] *= factor;
            imag[i] *= factor;
        }
        normalize(&mut real, &mut imag, n);
    }
    for i in 0..n {
        *output.add(2 * i) = real[i];
        *output.add(2 * i + 1) = imag[i];
    }
    output_count as i64
}
