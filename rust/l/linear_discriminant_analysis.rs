const MAX_CLASSES: usize = 4;
const MAX_SAMPLES: usize = 16;
const MAX_INPUT: usize = 22;
const MIN_MARGIN: f64 = 1e-8;

#[no_mangle]
pub unsafe extern "C" fn linear_discriminant_analysis(input: *const f64, input_length: usize,
    output: *mut f64, capacity: usize) -> i64 {
    if input.is_null() || input_length == 0 || input_length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, input_length);
    if !values[0].is_finite() || values[0] < 2.0 || values[0] > 4.0 || values[0].trunc() != values[0] { return -1; }
    let class_count = values[0] as usize;
    if input_length < 1 + class_count { return -1; }
    let mut counts = [0usize; MAX_CLASSES];
    let mut total_count = 0usize;
    for k in 0..class_count {
        let count = values[1 + k];
        if !count.is_finite() || count < 2.0 || count > 6.0 || count.trunc() != count { return -1; }
        counts[k] = count as usize;
        total_count += counts[k];
    }
    if total_count > MAX_SAMPLES || input_length != 1 + class_count + total_count { return -1; }
    let mut groups = [[0.0f64; 6]; MAX_CLASSES];
    let mut means = [0.0f64; MAX_CLASSES];
    let mut offset = 1 + class_count;
    for k in 0..class_count {
        let mut sum = 0.0;
        for j in 0..counts[k] {
            let x = values[offset]; offset += 1;
            if !x.is_finite() || x < -32.0 || x > 32.0 || x.trunc() != x { return -1; }
            groups[k][j] = x;
            sum += x;
        }
        means[k] = sum / counts[k] as f64;
        if means[k].trunc() != means[k] { return -1; }
    }
    let mut squared_sum = 0.0;
    for k in 0..class_count { for j in 0..counts[k] { let delta = groups[k][j] - means[k]; squared_sum += delta * delta; } }
    let variance = (1.0 / (total_count - class_count) as f64) * squared_sum;
    if !variance.is_finite() || variance <= 0.0 { return -1; }
    let mut priors = [0.0f64; MAX_CLASSES];
    for k in 0..class_count { priors[k] = counts[k] as f64 / total_count as f64; }
    let mut staged = [0.0f64; MAX_SAMPLES];
    let mut n = 0;
    for group in 0..class_count { for j in 0..counts[group] {
        let x = groups[group][j];
        let mut best = f64::NEG_INFINITY; let mut second = f64::NEG_INFINITY; let mut winner = 0usize;
        for k in 0..class_count {
            let score = x * (means[k] / variance) - (means[k] * means[k] / (2.0 * variance)) + priors[k].ln();
            if score > best { second = best; best = score; winner = k; }
            else if score > second { second = score; }
        }
        if !best.is_finite() || best - second < MIN_MARGIN { return -1; }
        staged[n] = winner as f64; n += 1;
    } }
    if output.is_null() || capacity < n { return -2; }
    std::ptr::copy_nonoverlapping(staged.as_ptr(), output, n);
    n as i64
}
