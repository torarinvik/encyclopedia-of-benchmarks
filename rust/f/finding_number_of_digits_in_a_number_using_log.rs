const MAX_ABS_VALUE: f64 = 1_000_000.0;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn finding_number_of_digits_in_a_number_using_log(value: f64) -> f64 {
    if !(value >= -MAX_ABS_VALUE && value <= MAX_ABS_VALUE) {
        return INVALID_RESULT;
    }
    if value == 0.0 {
        return 0.0;
    }
    (value.abs().log10() + 1.0).floor()
}
