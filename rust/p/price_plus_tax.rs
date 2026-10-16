const SCALE: i64 = 1_000_000;
const MAX_PRICE_MICRO: i64 = 1_000_000_000_000;
const MAX_TAX_RATE_MICRO: i64 = 1_000_000;
const MAX_INPUT_LENGTH: usize = 3;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub unsafe extern "C" fn price_plus_tax(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 || length > MAX_INPUT_LENGTH {
        return INVALID_RESULT;
    }
    let price_micro = *values;
    let tax_rate_micro = *values.add(1);
    if price_micro < 0 || price_micro > MAX_PRICE_MICRO
            || tax_rate_micro < 0 || tax_rate_micro > MAX_TAX_RATE_MICRO {
        return INVALID_RESULT;
    }
    let price = price_micro as f64 / SCALE as f64;
    let tax_rate = tax_rate_micro as f64 / SCALE as f64;
    price * (1.0 + tax_rate)
}
