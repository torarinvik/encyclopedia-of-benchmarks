const MAX_N: usize = 8;
const MAX_D: usize = 3;
const MAX_INPUT: usize = 37;
const TOLERANCE: f64 = 0.001;
const EPSILON: f64 = 0.001;

fn field(value: f64, low: i64, high: i64) -> Option<i64> {
    if !value.is_finite() || value < low as f64 || value > high as f64 || value.trunc() != value {
        None
    } else { Some(value as i64) }
}

fn kernel(points: &[[f64; MAX_D]; MAX_N], i: usize, j: usize, d: usize) -> f64 {
    (0..d).map(|k| points[i][k] * points[j][k]).sum()
}

fn decision(i: usize, alpha: &[f64; MAX_N], bias: f64,
            labels: &[i64; MAX_N], points: &[[f64; MAX_D]; MAX_N],
            n: usize, d: usize) -> f64 {
    bias + (0..n).map(|k| alpha[k] * labels[k] as f64 * kernel(points, k, i, d)).sum::<f64>()
}

fn dual(alpha: &[f64; MAX_N], labels: &[i64; MAX_N],
         points: &[[f64; MAX_D]; MAX_N], n: usize, d: usize) -> f64 {
    let mut value: f64 = alpha[..n].iter().sum();
    for i in 0..n {
        for j in 0..n {
            value -= 0.5 * alpha[i] * alpha[j] * (labels[i] * labels[j]) as f64 * kernel(points, i, j, d);
        }
    }
    value
}

fn take_step(i: usize, j: usize, alpha: &mut [f64; MAX_N], bias: &mut f64, c: f64,
             labels: &[i64; MAX_N], points: &[[f64; MAX_D]; MAX_N], n: usize, d: usize) -> bool {
    if i == j { return false; }
    let yi = labels[i];
    let yj = labels[j];
    let sign = yi * yj;
    let old_i = alpha[i];
    let old_j = alpha[j];
    let error_i = decision(i, alpha, *bias, labels, points, n, d) - yi as f64;
    let error_j = decision(j, alpha, *bias, labels, points, n, d) - yj as f64;
    let (low, high) = if yi != yj {
        (0.0_f64.max(old_j - old_i), c.min(c + old_j - old_i))
    } else {
        (0.0_f64.max(old_i + old_j - c), c.min(old_i + old_j))
    };
    if low == high { return false; }
    let kii = kernel(points, i, i, d);
    let kjj = kernel(points, j, j, d);
    let kij = kernel(points, i, j, d);
    let curvature = kii + kjj - 2.0 * kij;
    let new_j;
    if curvature > 0.0 {
        new_j = (old_j + yj as f64 * (error_i - error_j) / curvature).clamp(low, high);
    } else {
        let mut trial = *alpha;
        trial[i] = old_i + sign as f64 * (old_j - low);
        trial[j] = low;
        let low_value = dual(&trial, labels, points, n, d);
        trial[i] = old_i + sign as f64 * (old_j - high);
        trial[j] = high;
        let high_value = dual(&trial, labels, points, n, d);
        new_j = if low_value > high_value + EPSILON { low }
            else if high_value > low_value + EPSILON { high }
            else { old_j };
    }
    if (new_j - old_j).abs() < EPSILON * (new_j + old_j + EPSILON) { return false; }
    let new_i = old_i + sign as f64 * (old_j - new_j);
    let delta_i = new_i - old_i;
    let delta_j = new_j - old_j;
    let bias_i = *bias - error_i - yi as f64 * delta_i * kii - yj as f64 * delta_j * kij;
    let bias_j = *bias - error_j - yi as f64 * delta_i * kij - yj as f64 * delta_j * kjj;
    *bias = if new_i > 0.0 && new_i < c { bias_i }
        else if new_j > 0.0 && new_j < c { bias_j }
        else { 0.5 * (bias_i + bias_j) };
    alpha[i] = new_i;
    alpha[j] = new_j;
    true
}

fn examine(j: usize, alpha: &mut [f64; MAX_N], bias: &mut f64, c: f64,
           labels: &[i64; MAX_N], points: &[[f64; MAX_D]; MAX_N], n: usize, d: usize) -> bool {
    let error_j = decision(j, alpha, *bias, labels, points, n, d) - labels[j] as f64;
    let residual = error_j * labels[j] as f64;
    if !((residual < -TOLERANCE && alpha[j] < c) || (residual > TOLERANCE && alpha[j] > 0.0)) {
        return false;
    }
    let mut free_count = 0;
    let mut preferred = 0;
    let mut greatest_gap = -1.0;
    for i in 0..n {
        if alpha[i] > 0.0 && alpha[i] < c {
            free_count += 1;
            let error_i = decision(i, alpha, *bias, labels, points, n, d) - labels[i] as f64;
            let gap = (error_i - error_j).abs();
            if gap > greatest_gap { greatest_gap = gap; preferred = i; }
        }
    }
    if free_count > 1 && take_step(preferred, j, alpha, bias, c, labels, points, n, d) { return true; }
    for i in 0..n {
        if alpha[i] > 0.0 && alpha[i] < c && take_step(i, j, alpha, bias, c, labels, points, n, d) {
            return true;
        }
    }
    for i in 0..n {
        if take_step(i, j, alpha, bias, c, labels, points, n, d) { return true; }
    }
    false
}

#[no_mangle]
pub unsafe extern "C" fn smo_deterministic_training(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 4 || input_length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let Some(n_raw) = field(values[0], 2, MAX_N as i64) else { return -1; };
    let Some(d_raw) = field(values[1], 1, MAX_D as i64) else { return -1; };
    let Some(c_raw) = field(values[2], 1, 5000) else { return -1; };
    let Some(cap_raw) = field(values[3], 1, 16) else { return -1; };
    let (n, d, c_milli, pass_cap) = (n_raw as usize, d_raw as usize, c_raw, cap_raw as usize);
    if input_length != 4 + n + n * d { return -1; }
    let mut labels = [0_i64; MAX_N];
    let mut points = [[0.0_f64; MAX_D]; MAX_N];
    let mut alpha = [0.0_f64; MAX_N];
    let mut positive = false;
    let mut negative = false;
    let mut at = 4;
    for i in 0..n {
        let Some(label) = field(values[at], -1, 1) else { return -1; };
        if label == 0 { return -1; }
        labels[i] = label;
        positive |= label > 0;
        negative |= label < 0;
        at += 1;
    }
    if !positive || !negative { return -1; }
    for i in 0..n {
        for k in 0..d {
            let Some(value) = field(values[at], -32, 32) else { return -1; };
            points[i][k] = value as f64;
            at += 1;
        }
    }
    if output.is_null() || output_capacity < n + 4 { return -2; }

    let c = c_milli as f64 / 1000.0;
    let mut bias = 0.0;
    let mut changed = 0;
    let mut examine_all = true;
    let mut passes = 0;
    while passes < pass_cap && (changed > 0 || examine_all) {
        changed = 0;
        for j in 0..n {
            if (examine_all || (alpha[j] > 0.0 && alpha[j] < c)) &&
                examine(j, &mut alpha, &mut bias, c, &labels, &points, n, d) { changed += 1; }
        }
        passes += 1;
        if examine_all { examine_all = false; }
        else if changed == 0 { examine_all = true; }
    }
    let mut staged = [0.0_f64; MAX_N + 4];
    staged[0] = passes as f64;
    staged[1] = changed as f64;
    staged[2] = if passes < pass_cap && changed == 0 && !examine_all { 1.0 } else { 0.0 };
    staged[3..3 + n].copy_from_slice(&alpha[..n]);
    staged[3 + n] = bias;
    let out = std::slice::from_raw_parts_mut(output, n + 4);
    out.copy_from_slice(&staged[..n + 4]);
    (n + 4) as i64
}
