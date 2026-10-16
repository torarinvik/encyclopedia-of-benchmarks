const INVALID_RESULT: f64 = -1.0e300;
#[no_mangle]
pub unsafe extern "C" fn categorical_focal_cross_entropy(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length < 2 || length > 2050 { return INVALID_RESULT; }
    let batch_value = unsafe { *values };
    let classes_value = unsafe { *values.add(1) };
    if !(1..=64).contains(&batch_value) || !(2..=16).contains(&classes_value) { return INVALID_RESULT; }
    let batch = batch_value as usize;
    let classes = classes_value as usize;
    let cells = batch * classes;
    if length != 2 + 2 * cells { return INVALID_RESULT; }
    for row in 0..batch {
        let mut label_sum = 0i64;
        let mut probability_sum = 0i64;
        for column in 0..classes {
            let index = row * classes + column;
            let label = unsafe { *values.add(2 + index) };
            let probability = unsafe { *values.add(2 + cells + index) };
            if label != 0 && label != 1 { return INVALID_RESULT; }
            if probability < 0 || probability > 1_000_000 { return INVALID_RESULT; }
            label_sum += label;
            probability_sum += probability;
        }
        if label_sum != 1 || probability_sum != 1_000_000 { return INVALID_RESULT; }
    }
    let mut total = 0.0;
    for row in 0..batch {
        let mut row_loss = 0.0;
        for column in 0..classes {
            let index = row * classes + column;
            let label = unsafe { *values.add(2 + index) } as f64;
            let mut probability = unsafe { *values.add(2 + cells + index) } as f64 / 1_000_000.0;
            if probability < 1e-15 { probability = 1e-15; }
            if probability > 1.0 - 1e-15 { probability = 1.0 - 1e-15; }
            let negative_probability = 1.0 - probability;
            row_loss -= negative_probability * negative_probability * label * probability.ln();
        }
        total += row_loss;
    }
    total / batch as f64
}
