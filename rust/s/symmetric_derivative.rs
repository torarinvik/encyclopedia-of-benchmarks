const MIN_X_NANOUNITS: i64 = -6_300_000_000;
const MAX_X_NANOUNITS: i64 = 6_300_000_000;
const DEFAULT_STEP: f64 = 1.0e-10;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn symmetric_derivative(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 {
        return INVALID_RESULT;
    }
    let function_id = *values;
    let x_nanounits = *values.add(1);
    if (function_id != 0 && function_id != 1)
        || x_nanounits < MIN_X_NANOUNITS
        || x_nanounits > MAX_X_NANOUNITS
    {
        return INVALID_RESULT;
    }

    let x = x_nanounits as f64 / 1_000_000_000.0;
    let (upper, lower) = if function_id == 0 {
        ((x + DEFAULT_STEP).sin(), (x - DEFAULT_STEP).sin())
    } else {
        ((x + DEFAULT_STEP).exp(), (x - DEFAULT_STEP).exp())
    };
    (upper - lower) / (2.0 * DEFAULT_STEP)
}
