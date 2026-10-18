const MAX_SAMPLES: usize = 8;
const MAX_OUTPUT: usize = 12;

#[no_mangle]
pub unsafe extern "C" fn pca(input: *const f64, input_length: usize,
    output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || input_length < 9 || input_length > 19 { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if values[1] != 2.0 || values[2] != 1.0 || !(3.0..=8.0).contains(&values[0]) || values[0] != values[0].trunc() { return -1; }
    let n = values[0] as usize;
    if input_length != 3 + 2 * n { return -1; }
    let mut x = [0.0f64; MAX_SAMPLES];
    let mut y = [0.0f64; MAX_SAMPLES];
    let mut z0 = [0.0f64; MAX_SAMPLES];
    let mut z1 = [0.0f64; MAX_SAMPLES];
    let (mut mean0, mut mean1) = (0.0, 0.0);
    for i in 0..n {
        x[i] = values[3 + 2 * i]; y[i] = values[4 + 2 * i];
        if x[i].is_nan() || y[i].is_nan() || x[i].abs() > 1000.0 || y[i].abs() > 1000.0 { return -1; }
        mean0 += x[i]; mean1 += y[i];
    }
    mean0 /= n as f64; mean1 /= n as f64;
    let (mut sum0, mut sum1) = (0.0, 0.0);
    for i in 0..n { let a = x[i] - mean0; let b = y[i] - mean1; sum0 += a * a; sum1 += b * b; }
    let denom = (n - 1) as f64;
    if sum0 <= 0.0 || sum1 <= 0.0 { return -1; }
    let scale0 = (sum0 / denom).sqrt(); let scale1 = (sum1 / denom).sqrt();
    let (mut a, mut b, mut d) = (0.0, 0.0, 0.0);
    for i in 0..n { z0[i] = (x[i] - mean0) / scale0; z1[i] = (y[i] - mean1) / scale1; a += z0[i] * z0[i]; b += z0[i] * z1[i]; d += z1[i] * z1[i]; }
    a /= denom; b /= denom; d /= denom;
    let root = ((a - d) * (a - d) + 4.0 * b * b).sqrt();
    let lambda0 = 0.5 * (a + d + root); let lambda1 = 0.5 * (a + d - root);
    if lambda0 - lambda1 <= 1e-8 { return -1; }
    let (mut vx, mut vy);
    if b == 0.0 { vx = if a >= d { 1.0 } else { 0.0 }; vy = if a >= d { 0.0 } else { 1.0 }; }
    else { vx = b; vy = lambda0 - a; let norm = (vx * vx + vy * vy).sqrt(); if norm == 0.0 { return -1; } vx /= norm; vy /= norm; }
    if (vx.abs() >= vy.abs() && vx < 0.0) || (vy.abs() > vx.abs() && vy < 0.0) { vx = -vx; vy = -vy; }
    let mut staged = [0.0f64; MAX_OUTPUT];
    for i in 0..n { staged[i] = z0[i] * vx + z1[i] * vy; }
    staged[n] = vx; staged[n + 1] = vy; staged[n + 2] = lambda0; staged[n + 3] = lambda1;
    let output_size = n + 4;
    if output.is_null() || capacity < output_size { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, output_size);
    output_size as i64
}
