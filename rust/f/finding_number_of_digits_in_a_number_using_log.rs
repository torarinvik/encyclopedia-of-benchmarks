const MAX_ABS_VALUE: i64 = 1_000_000;

#[no_mangle]
pub extern "C" fn finding_number_of_digits_in_a_number_using_log(value: i64) -> i64 {
    if !(-MAX_ABS_VALUE..=MAX_ABS_VALUE).contains(&value) {
        return -1;
    }
    if value == 0 {
        return 0;
    }
    ((value as f64).abs().log10() + 1.0).floor() as i64
}
