const FFT_SIZE: usize = 8;
const BASE: i64 = 1000;
const SCALE: i64 = 1_000_000;

fn fft_transform(real: &mut [f64; FFT_SIZE], imag: &mut [f64; FFT_SIZE], inverse: bool) {
    let mut j = 0usize;
    for i in 1..FFT_SIZE {
        let mut bit = FFT_SIZE >> 1;
        while j & bit != 0 {
            j ^= bit;
            bit >>= 1;
        }
        j ^= bit;
        if i < j {
            real.swap(i, j);
            imag.swap(i, j);
        }
    }
    let mut length = 2usize;
    while length <= FFT_SIZE {
        let (root_real, root_imag) = if length == 2 {
            (-1.0, 0.0)
        } else if length == 4 {
            (0.0, if inverse { 1.0 } else { -1.0 })
        } else {
            (0.7071067811865476, if inverse { 0.7071067811865476 } else { -0.7071067811865476 })
        };
        let half = length >> 1;
        for start in (0..FFT_SIZE).step_by(length) {
            let mut twiddle_real = 1.0;
            let mut twiddle_imag = 0.0;
            for offset in 0..half {
                let even = start + offset;
                let odd = even + half;
                let odd_real = real[odd] * twiddle_real - imag[odd] * twiddle_imag;
                let odd_imag = real[odd] * twiddle_imag + imag[odd] * twiddle_real;
                let even_real = real[even];
                let even_imag = imag[even];
                real[even] = even_real + odd_real;
                imag[even] = even_imag + odd_imag;
                real[odd] = even_real - odd_real;
                imag[odd] = even_imag - odd_imag;
                let next_real = twiddle_real * root_real - twiddle_imag * root_imag;
                twiddle_imag = twiddle_real * root_imag + twiddle_imag * root_real;
                twiddle_real = next_real;
            }
        }
        length <<= 1;
    }
    if inverse {
        for i in 0..FFT_SIZE {
            real[i] /= FFT_SIZE as f64;
            imag[i] /= FFT_SIZE as f64;
        }
    }
}

fn fft_multiply_fixed(left_value: i64, right_value: i64) -> i64 {
    let mut left = left_value;
    let mut right = right_value;
    let mut sign = 1i64;
    if left < 0 { sign = -sign; left = -left; }
    if right < 0 { sign = -sign; right = -right; }
    let mut left_real = [0.0; FFT_SIZE];
    let mut left_imag = [0.0; FFT_SIZE];
    let mut right_real = [0.0; FFT_SIZE];
    let mut right_imag = [0.0; FFT_SIZE];
    for i in 0..3 {
        left_real[i] = (left % BASE) as f64;
        right_real[i] = (right % BASE) as f64;
        left /= BASE;
        right /= BASE;
    }
    fft_transform(&mut left_real, &mut left_imag, false);
    fft_transform(&mut right_real, &mut right_imag, false);
    for i in 0..FFT_SIZE {
        let product_real = left_real[i] * right_real[i] - left_imag[i] * right_imag[i];
        let product_imag = left_real[i] * right_imag[i] + left_imag[i] * right_real[i];
        left_real[i] = product_real;
        left_imag[i] = product_imag;
    }
    fft_transform(&mut left_real, &mut left_imag, true);
    let mut product = 0i64;
    let mut place = 1i64;
    for i in 0..5 {
        let coefficient = (left_real[i] + 0.5) as i64;
        product += coefficient * place;
        place *= BASE;
    }
    sign * ((product + SCALE / 2) / SCALE)
}

fn fixed_sqrt(value: i64) -> i64 {
    if value <= 0 { return 0; }
    let radicand = value * SCALE;
    let mut root = radicand;
    loop {
        let next = (root + radicand / root) / 2;
        if next >= root { break; }
        root = next;
    }
    let lower_error = radicand - root * root;
    let upper_error = (root + 1) * (root + 1) - radicand;
    if upper_error < lower_error { root + 1 } else { root }
}

fn fixed_half(value: i64) -> i64 {
    if value < 0 { -((-value) / 2) } else { value / 2 }
}

fn fixed_divide(numerator: i64, denominator: i64) -> i64 {
    if denominator <= 0 { return 0; }
    let scaled = numerator * SCALE;
    if scaled < 0 { -((-scaled + denominator / 2) / denominator) }
    else { (scaled + denominator / 2) / denominator }
}

#[no_mangle]
pub extern "C" fn freebench_pifft(nfft: i64) -> i64 {
    if nfft != FFT_SIZE as i64 { return -1; }
    let mut c = fixed_sqrt(125_000);
    let mut a = SCALE + 3 * c;
    let mut b = fixed_sqrt(a);
    let mut e = b - 625_000;
    b *= 2;
    c = e - c;
    a += e;
    let mut npow = 4i64;
    for _ in 0..8 {
        npow *= 2;
        e = fixed_half(a + b);
        b = fixed_sqrt(fft_multiply_fixed(a, b));
        e -= b;
        b *= 2;
        c -= e;
        a = e + b;
        if (-1..=1).contains(&e) { break; }
    }
    e = fixed_half(e);
    e = fft_multiply_fixed(e, e);
    a += b;
    let numerator = fft_multiply_fixed(a, a) - e - fixed_half(e);
    let denominator = fft_multiply_fixed(a, c) - e;
    let pi = fixed_divide(numerator, denominator);
    let pi = (pi + npow / 2) / npow;
    (pi + 500) / 1000
}
