// Based on Don Cross <dcross@intersrv.com>'s public-domain fft_float (intersrv.com/~dcross/fft.html).
// Modified for the bounded float64-slice ABI; binary32 work-array semantics retained.
use std::ffi::c_double;

fn transform(real: &mut [f32; 16], imag: &mut [f32; 16], n: usize, inverse: bool) {
    let bits = n.trailing_zeros();
    for i in 0..n {
        let mut source = i;
        let mut reverse = 0usize;
        for _ in 0..bits { reverse = (reverse << 1) | (source & 1); source >>= 1; }
        if i < reverse { real.swap(i, reverse); imag.swap(i, reverse); }
    }
    let angle_num = if inverse { -2.0_f64 } else { 2.0_f64 } * std::f64::consts::PI;
    let mut block_end = 1usize;
    let mut block = 2usize;
    while block <= n {
        let delta = angle_num / block as f64;
        let (sm2, sm1) = ((-2.0 * delta).sin(), (-delta).sin());
        let (cm2, cm1) = ((-2.0 * delta).cos(), (-delta).cos());
        let w = 2.0 * cm1;
        let mut start = 0usize;
        while start < n {
            let (mut ar2, mut ar1, mut ai2, mut ai1) = (cm2, cm1, sm2, sm1);
            for offset in 0..block_end {
                let ar0 = w * ar1 - ar2; ar2 = ar1; ar1 = ar0;
                let ai0 = w * ai1 - ai2; ai2 = ai1; ai1 = ai0;
                let first = start + offset;
                let second = first + block_end;
                let tr = ar0 * real[second] as f64 - ai0 * imag[second] as f64;
                let ti = ar0 * imag[second] as f64 + ai0 * real[second] as f64;
                real[second] = (real[first] as f64 - tr) as f32;
                imag[second] = (imag[first] as f64 - ti) as f32;
                real[first] = (real[first] as f64 + tr) as f32;
                imag[first] = (imag[first] as f64 + ti) as f32;
            }
            start += block;
        }
        block_end = block;
        block <<= 1;
    }
    if inverse { for i in 0..n { real[i] = (real[i] as f64 / n as f64) as f32; imag[i] = (imag[i] as f64 / n as f64) as f32; } }
}

#[no_mangle]
pub unsafe extern "C" fn mibench_telecomm_fft(input: *const c_double, length: usize,
                                                 output: *mut c_double, capacity: usize) -> i64 {
    if input.is_null() || !(6..=34).contains(&length) { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let nd = values[0]; let inverse = values[1];
    if !nd.is_finite() || nd.fract() != 0.0 || !(2.0..=16.0).contains(&nd)
        || !inverse.is_finite() || inverse.fract() != 0.0 || (inverse != 0.0 && inverse != 1.0) { return -1; }
    let n = nd as usize;
    if !n.is_power_of_two() || length != 2 + 2 * n { return -1; }
    if values[2..].iter().any(|x| !x.is_finite() || x.abs() > 8.0) { return -1; }
    let required = 2 * n;
    if output.is_null() || capacity < required { return -2; }
    let mut real = [0.0_f32; 16]; let mut imag = [0.0_f32; 16];
    for i in 0..n { real[i] = values[2 + i] as f32; imag[i] = values[2 + n + i] as f32; }
    transform(&mut real, &mut imag, n, inverse != 0.0);
    let mut staged = [0.0_f64; 32];
    for i in 0..n { staged[2 * i] = real[i] as f64; staged[2 * i + 1] = imag[i] as f64; }
    let out = std::slice::from_raw_parts_mut(output, required);
    out.copy_from_slice(&staged[..required]);
    required as i64
}
