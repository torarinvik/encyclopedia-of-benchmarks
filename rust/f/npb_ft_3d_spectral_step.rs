const MAX_POINTS: usize = 64;
const MAX_STEPS: usize = 6;
const CHECKSUM_TERMS: usize = 64;
const TAU: f64 = 6.28318530717958647692528676655900577;
const ALPHA: f64 = 0.000001;

fn fft_line(real: &mut [f64; 4], imag: &mut [f64; 4], n: usize, inverse: bool) {
    let mut reverse = 0usize;
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
    let mut block = 2usize;
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
        for i in 0..n {
            real[i] /= n as f64;
            imag[i] /= n as f64;
        }
    }
}

fn line_index(axis: usize, a: usize, b: usize, p: usize, n: usize) -> usize {
    match axis {
        0 => (p * n + a) * n + b,
        1 => (a * n + p) * n + b,
        _ => (a * n + b) * n + p,
    }
}

fn axis_transform(real: &mut [f64; MAX_POINTS], imag: &mut [f64; MAX_POINTS],
                   n: usize, axis: usize, inverse: bool) {
    for a in 0..n {
        for b in 0..n {
            let mut line_real = [0.0; 4];
            let mut line_imag = [0.0; 4];
            for p in 0..n {
                let index = line_index(axis, a, b, p, n);
                line_real[p] = real[index];
                line_imag[p] = imag[index];
            }
            fft_line(&mut line_real, &mut line_imag, n, inverse);
            for p in 0..n {
                let index = line_index(axis, a, b, p, n);
                real[index] = line_real[p];
                imag[index] = line_imag[p];
            }
        }
    }
}

fn transform3d(real: &mut [f64; MAX_POINTS], imag: &mut [f64; MAX_POINTS],
               n: usize, inverse: bool) {
    axis_transform(real, imag, n, 2, inverse);
    axis_transform(real, imag, n, 1, inverse);
    axis_transform(real, imag, n, 0, inverse);
}

fn signed_frequency(index: usize, n: usize) -> isize {
    if index <= n / 2 { index as isize } else { index as isize - n as isize }
}

#[no_mangle]
pub unsafe extern "C" fn npb_ft_3d_spectral_step(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(2..=130).contains(&input_length) { return -1; }
    let side_value = unsafe { *input };
    let steps_value = unsafe { *input.add(1) };
    if side_value != 2.0 && side_value != 4.0 { return -1; }
    if !steps_value.is_finite() || steps_value < 1.0 || steps_value > MAX_STEPS as f64
        || steps_value.fract() != 0.0 { return -1; }
    let n = side_value as usize;
    let steps = steps_value as usize;
    let volume = n * n * n;
    if input_length != 2 + 2 * volume { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, input_length) };
    if values[2..].iter().any(|value| !value.is_finite() || !(-1.0..=1.0).contains(value)) {
        return -1;
    }
    let needed = 2 * steps;
    if output.is_null() || output_capacity < needed { return -2; }

    let mut spectrum_real = [0.0; MAX_POINTS];
    let mut spectrum_imag = [0.0; MAX_POINTS];
    let mut work_real = [0.0; MAX_POINTS];
    let mut work_imag = [0.0; MAX_POINTS];
    for i in 0..volume {
        spectrum_real[i] = values[2 + 2 * i];
        spectrum_imag[i] = values[2 + 2 * i + 1];
    }
    transform3d(&mut spectrum_real, &mut spectrum_imag, n, false);
    for step in 1..=steps {
        for x in 0..n {
            for y in 0..n {
                for z in 0..n {
                    let index = (x * n + y) * n + z;
                    let kx = signed_frequency(x, n);
                    let ky = signed_frequency(y, n);
                    let kz = signed_frequency(z, n);
                    let radius_squared = (kx * kx + ky * ky + kz * kz) as f64;
                    let factor = (-39.47841760435743447533796399950460 * ALPHA
                        * step as f64 * radius_squared).exp();
                    work_real[index] = spectrum_real[index] * factor;
                    work_imag[index] = spectrum_imag[index] * factor;
                }
            }
        }
        transform3d(&mut work_real, &mut work_imag, n, true);
        let (mut sum_real, mut sum_imag) = (0.0, 0.0);
        for j in 1..=CHECKSUM_TERMS {
            let x = (j - 1) % n;
            let y = (3 * j - 1) % n;
            let z = (5 * j - 1) % n;
            let index = (x * n + y) * n + z;
            sum_real += work_real[index];
            sum_imag += work_imag[index];
        }
        unsafe {
            *output.add(2 * (step - 1)) = sum_real / volume as f64;
            *output.add(2 * (step - 1) + 1) = sum_imag / volume as f64;
        }
    }
    needed as i64
}
