const MAX_N: usize = 32;
const SCALE: i64 = 256;
const INVALID_RESULT: f64 = -1.0e300;
const TAU: f64 = std::f64::consts::TAU;

fn fft(real: &mut [f64; MAX_N], imag: &mut [f64; MAX_N], n: usize, inverse: bool) {
    let mut j = 0usize;
    for i in 1..n {
        let mut bit = n >> 1;
        while j & bit != 0 { j ^= bit; bit >>= 1; }
        j ^= bit;
        if i < j { real.swap(i, j); imag.swap(i, j); }
    }
    let mut width = 2;
    while width <= n {
        let angle = (if inverse { 1.0 } else { -1.0 }) * TAU / width as f64;
        let (step_imag, step_real) = angle.sin_cos();
        let half = width >> 1;
        for start in (0..n).step_by(width) {
            let (mut twiddle_imag, mut twiddle_real) = (0.0, 1.0);
            for offset in 0..half {
                let even = start + offset;
                let odd = even + half;
                let odd_real = real[odd] * twiddle_real - imag[odd] * twiddle_imag;
                let odd_imag = real[odd] * twiddle_imag + imag[odd] * twiddle_real;
                real[odd] = real[even] - odd_real;
                imag[odd] = imag[even] - odd_imag;
                real[even] += odd_real;
                imag[even] += odd_imag;
                let next_real = twiddle_real * step_real - twiddle_imag * step_imag;
                twiddle_imag = twiddle_real * step_imag + twiddle_imag * step_real;
                twiddle_real = next_real;
            }
        }
        width <<= 1;
    }
    if inverse {
        for i in 0..n { real[i] /= n as f64; imag[i] /= n as f64; }
    }
}

fn calculate(values: &[i64]) -> f64 {
    if values.is_empty() || values.len() > 98 { return INVALID_RESULT; }
    let n_value = values[0];
    if !(2..=MAX_N as i64).contains(&n_value) || !(n_value as usize).is_power_of_two() {
        return INVALID_RESULT;
    }
    let n = n_value as usize;
    if values.len() != 1 + 3 * n { return INVALID_RESULT; }
    let mut norm = 0i64;
    for i in 0..n {
        let potential = values[1 + i];
        let real_q = values[1 + n + i];
        let imag_q = values[1 + 2 * n + i];
        if !(-2048..=2048).contains(&potential)
            || !(-2048..=2048).contains(&real_q)
            || !(-2048..=2048).contains(&imag_q) { return INVALID_RESULT; }
        norm += real_q * real_q + imag_q * imag_q;
    }
    if norm != SCALE * SCALE * n as i64 { return INVALID_RESULT; }

    let mut real = [0.0; MAX_N];
    let mut imag = [0.0; MAX_N];
    for i in 0..n {
        real[i] = values[1 + n + i] as f64 / SCALE as f64;
        imag[i] = values[1 + 2 * n + i] as f64 / SCALE as f64;
    }
    fft(&mut real, &mut imag, n, false);
    for i in 0..n {
        let frequency = if i <= n / 2 { i as i64 } else { i as i64 - n as i64 };
        let wave_number = TAU * frequency as f64;
        let multiplier = 0.5 * wave_number * wave_number;
        real[i] *= multiplier;
        imag[i] *= multiplier;
    }
    fft(&mut real, &mut imag, n, true);

    let mut total = 0.0;
    for i in 0..n {
        let psi_real = values[1 + n + i] as f64 / SCALE as f64;
        let psi_imag = values[1 + 2 * n + i] as f64 / SCALE as f64;
        let potential = values[1 + i] as f64 / SCALE as f64;
        total += psi_real * (real[i] + potential * psi_real)
            + psi_imag * (imag[i] + potential * psi_imag);
    }
    total / n as f64
}

#[no_mangle]
pub unsafe extern "C" fn quantum_spectral_energy_expectation(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length > 98 { return INVALID_RESULT; }
    calculate(std::slice::from_raw_parts(input, length))
}
