const MAX_COMPONENT: f64 = 100.0;
const PI_VALUE: f64 = 3.14159265358979323846264338327950288;

fn fft8(real: &mut [f64; 8], imag: &mut [f64; 8], inverse: bool) {
    const REVERSED: [usize; 8] = [0, 4, 2, 6, 1, 5, 3, 7];
    for i in 0..8 {
        let j = REVERSED[i];
        if i < j {
            real.swap(i, j);
            imag.swap(i, j);
        }
    }
    for stage in 1..=3 {
        let block = 1usize << stage;
        let half = block / 2;
        for start in (0..8).step_by(block) {
            for j in 0..half {
                let sign = if inverse { 1.0 } else { -1.0 };
                let angle = sign * 2.0 * PI_VALUE * j as f64 / block as f64;
                let (wr, wi) = (angle.cos(), angle.sin());
                let even = start + j;
                let odd = even + half;
                let (ur, ui) = (real[even], imag[even]);
                let (vr, vi) = (
                    real[odd] * wr - imag[odd] * wi,
                    real[odd] * wi + imag[odd] * wr,
                );
                real[even] = ur + vr;
                imag[even] = ui + vi;
                real[odd] = ur - vr;
                imag[odd] = ui - vi;
            }
        }
    }
    if inverse {
        for i in 0..8 {
            real[i] /= 8.0;
            imag[i] /= 8.0;
        }
    }
}

#[no_mangle]
pub unsafe extern "C" fn rader_fft(
    input: *const f64,
    input_len: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    const PERMUTATION: [usize; 4] = [1, 2, 4, 3];
    const KERNEL_POWER: [usize; 4] = [1, 3, 4, 2];
    if input.is_null() || input_len != 10 { return -1; }
    for i in 0..10 {
        let value = *input.add(i);
        if !value.is_finite() || value < -MAX_COMPONENT || value > MAX_COMPONENT { return -1; }
    }
    if output.is_null() || output_capacity < 10 { return -2; }

    let mut ar = [0.0; 8];
    let mut ai = [0.0; 8];
    let mut br = [0.0; 8];
    let mut bi = [0.0; 8];
    for i in 0..4 {
        ar[i] = *input.add(2 * PERMUTATION[i]);
        ai[i] = *input.add(2 * PERMUTATION[i] + 1);
        let angle = -2.0 * PI_VALUE * KERNEL_POWER[i] as f64 / 5.0;
        br[i] = angle.cos();
        bi[i] = angle.sin();
    }
    fft8(&mut ar, &mut ai, false);
    fft8(&mut br, &mut bi, false);
    for i in 0..8 {
        let product_real = ar[i] * br[i] - ai[i] * bi[i];
        let product_imag = ar[i] * bi[i] + ai[i] * br[i];
        ar[i] = product_real;
        ai[i] = product_imag;
    }
    fft8(&mut ar, &mut ai, true);

    let mut result = [0.0; 10];
    for n in 0..5 {
        result[0] += *input.add(2 * n);
        result[1] += *input.add(2 * n + 1);
    }
    for k in 1..5 {
        result[2 * k] = *input;
        result[2 * k + 1] = *input.add(1);
    }
    for i in 0..4 {
        let target = KERNEL_POWER[i];
        result[2 * target] += ar[i] + ar[i + 4];
        result[2 * target + 1] += ai[i] + ai[i + 4];
    }
    for i in 0..10 { *output.add(i) = result[i]; }
    10
}
