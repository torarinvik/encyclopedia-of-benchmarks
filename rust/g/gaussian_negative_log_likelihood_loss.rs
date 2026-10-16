const MAX_COUNT: usize = 256;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_COUNT;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn gaussian_negative_log_likelihood_loss(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 4 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(values, length);
    let count_value = values[0];
    if !(1..=MAX_COUNT as i64).contains(&count_value) { return INVALID_RESULT; }
    let count = count_value as usize;
    if length != 1 + 3 * count { return INVALID_RESULT; }
    let mut total = 0.0;
    for i in 0..count {
        let y_scaled = values[1 + i];
        let mu_scaled = values[1 + count + i];
        let variance_nano = values[1 + 2 * count + i];
        if !(-1_000_000..=1_000_000).contains(&y_scaled) || !(-1_000_000..=1_000_000).contains(&mu_scaled)
            || !(1..=1_000_000_000).contains(&variance_nano) { return INVALID_RESULT; }
        let y = y_scaled as f64 / 1_000_000.0;
        let mu = mu_scaled as f64 / 1_000_000.0;
        let variance = (variance_nano as f64 / 1_000_000_000.0).max(1e-6);
        let residual = y - mu;
        let loss_var = 0.5 * variance.ln();
        let loss_exp = 0.5 * ((residual * residual) / variance);
        total += loss_var + loss_exp;
    }
    total / count as f64
}
