const MAX_N: usize = 8;
const MAX_D: usize = 3;
const MAX_INPUT: usize = 47;

fn field(x: f64, low: i64, high: i64) -> Option<i64> {
    if !x.is_finite() || x < low as f64 || x > high as f64 || x.trunc() != x {
        None
    } else {
        Some(x as i64)
    }
}

fn dot(x: &[[f64; MAX_D]; MAX_N], a: usize, b: usize, d: usize) -> f64 {
    (0..d).map(|r| x[a][r] * x[b][r]).sum()
}

fn objective(alpha: &[f64; MAX_N], y: &[i64; MAX_N],
             x: &[[f64; MAX_D]; MAX_N], n: usize, d: usize) -> f64 {
    let mut value: f64 = alpha[..n].iter().sum();
    for p in 0..n {
        for q in 0..n {
            value -= 0.5 * alpha[p] * alpha[q] * (y[p] * y[q]) as f64 * dot(x, p, q, d);
        }
    }
    value
}

#[no_mangle]
pub unsafe extern "C" fn smo_dual_pair_update(
    input: *const f64,
    input_length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 6 || input_length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    let Some(n_raw) = field(values[0], 2, MAX_N as i64) else { return -1; };
    let Some(d_raw) = field(values[1], 1, MAX_D as i64) else { return -1; };
    let Some(c_milli_raw) = field(values[2], 1, 5000) else { return -1; };
    let Some(b_milli_raw) = field(values[3], -1_000_000, 1_000_000) else { return -1; };
    let n = n_raw as usize;
    let d = d_raw as usize;
    let c_milli = c_milli_raw as i32;
    let b_milli = b_milli_raw as i32;
    if input_length != 6 + 2 * n + n * d { return -1; }

    let mut labels = [0_i64; MAX_N];
    let mut alpha = [0.0_f64; MAX_N];
    let mut x = [[0.0_f64; MAX_D]; MAX_N];
    let mut negative = false;
    let mut positive = false;
    let mut equality = 0_i64;
    let mut at = 4;
    for k in 0..n {
        let Some(label) = field(values[at], -1, 1) else { return -1; };
        if label == 0 { return -1; }
        labels[k] = label;
        negative |= label < 0;
        positive |= label > 0;
        at += 1;
    }
    for k in 0..n {
        let Some(value) = field(values[at], 0, c_milli as i64) else { return -1; };
        alpha[k] = value as f64 / 1000.0;
        equality += labels[k] * value;
        at += 1;
    }
    if !negative || !positive || equality != 0 { return -1; }
    for row in 0..n {
        for col in 0..d {
            let Some(value) = field(values[at], -32, 32) else { return -1; };
            x[row][col] = value as f64;
            at += 1;
        }
    }
    let Some(i_raw) = field(values[at], 0, n as i64 - 1) else { return -1; };
    let Some(j_raw) = field(values[at + 1], 0, n as i64 - 1) else { return -1; };
    let (i, j) = (i_raw as usize, j_raw as usize);
    if i == j { return -1; }
    if output.is_null() || output_capacity < n + 1 { return -2; }

    let c_value = c_milli as f64 / 1000.0;
    let bias = b_milli as f64 / 1000.0;
    let yi = labels[i];
    let yj = labels[j];
    let sign = yi * yj;
    let (old_i, old_j) = (alpha[i], alpha[j]);
    let kii = dot(&x, i, i, d);
    let kjj = dot(&x, j, j, d);
    let kij = dot(&x, i, j, d);
    let mut error_i = bias - yi as f64;
    let mut error_j = bias - yj as f64;
    for k in 0..n {
        error_i += alpha[k] * labels[k] as f64 * dot(&x, k, i, d);
        error_j += alpha[k] * labels[k] as f64 * dot(&x, k, j, d);
    }
    let (low, high) = if yi != yj {
        (0.0_f64.max(old_j - old_i), c_value.min(c_value + old_j - old_i))
    } else {
        (0.0_f64.max(old_i + old_j - c_value), c_value.min(old_i + old_j))
    };
    let eta = 2.0 * kij - kii - kjj;
    let new_j = if eta < 0.0 {
        (old_j - yj as f64 * (error_i - error_j) / eta).clamp(low, high)
    } else {
        let mut candidate = alpha;
        candidate[i] = old_i + sign as f64 * (old_j - low);
        candidate[j] = low;
        let low_score = objective(&candidate, &labels, &x, n, d);
        candidate[i] = old_i + sign as f64 * (old_j - high);
        candidate[j] = high;
        let high_score = objective(&candidate, &labels, &x, n, d);
        if high_score > low_score { high } else { low }
    };
    let new_i = old_i + sign as f64 * (old_j - new_j);
    let delta_i = new_i - old_i;
    let delta_j = new_j - old_j;
    let bias_i = bias - error_i - yi as f64 * delta_i * kii - yj as f64 * delta_j * kij;
    let bias_j = bias - error_j - yi as f64 * delta_i * kij - yj as f64 * delta_j * kjj;
    let new_bias = if 0.0 < new_i && new_i < c_value { bias_i }
        else if 0.0 < new_j && new_j < c_value { bias_j }
        else { 0.5 * (bias_i + bias_j) };
    alpha[i] = new_i;
    alpha[j] = new_j;
    let out = std::slice::from_raw_parts_mut(output, n + 1);
    out[..n].copy_from_slice(&alpha[..n]);
    out[n] = new_bias;
    (n + 1) as i64
}
