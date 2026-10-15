const INVALID_RESULT: i64 = -1;

fn reverse_factorial_recursive_impl(value: i64, divisor: i64) -> i64 {
    if value == 1 {
        return if divisor == 1 { 1 } else { divisor - 1 };
    }
    if value % divisor != 0 {
        return INVALID_RESULT;
    }
    reverse_factorial_recursive_impl(value / divisor, divisor + 1)
}

#[no_mangle]
pub extern "C" fn reverse_factorial_recursive(value: i64) -> i64 {
    if value < 1 {
        return INVALID_RESULT;
    }
    reverse_factorial_recursive_impl(value, 1)
}
