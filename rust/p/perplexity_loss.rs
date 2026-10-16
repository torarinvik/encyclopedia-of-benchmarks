const MAX_INPUT_LENGTH: usize = 3 + 8 * 16 * 17;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn perplexity_loss(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(values, length);
    let (batch_value, time_value, vocab_value) = (values[0], values[1], values[2]);
    if !(1..=8).contains(&batch_value) || !(1..=16).contains(&time_value) || !(2..=16).contains(&vocab_value) { return INVALID_RESULT; }
    let (batch, time, vocab) = (batch_value as usize, time_value as usize, vocab_value as usize);
    let tokens = batch * time;
    let probability_base = 3 + tokens;
    if length != probability_base + tokens * vocab { return INVALID_RESULT; }
    for row in 0..tokens {
        let label = values[3 + row];
        if label < 0 || label as usize >= vocab { return INVALID_RESULT; }
        let mut row_sum = 0i64;
        for c in 0..vocab {
            let p = values[probability_base + row * vocab + c];
            if !(0..=1_000_000).contains(&p) { return INVALID_RESULT; }
            row_sum += p;
        }
        if row_sum != 1_000_000 { return INVALID_RESULT; }
    }
    let mut batch_total = 0.0;
    for sentence in 0..batch {
        let mut log_total = 0.0;
        for step in 0..time {
            let row = sentence * time + step;
            let label = values[3 + row] as usize;
            let p = values[probability_base + row * vocab + label] as f64 / 1_000_000.0;
            log_total += p.clamp(1e-7, 1.0).ln();
        }
        batch_total += (-(log_total / time as f64)).exp();
    }
    batch_total / batch as f64
}
