const INVALID_RESULT: f64 = -1.0e300;

fn gamma_recursive_impl(num: f64) -> f64 {
    if num == 0.5 { return 3.141592653589793_f64.sqrt(); }
    if num == 1.0 { return 1.0; }
    (num - 1.0) * gamma_recursive_impl(num - 1.0)
}

/// Evaluate the source's recursive gamma recurrence on positive half-integers.
#[no_mangle]
pub extern "C" fn gamma_recursive(num: f64) -> f64 {
    if !(0.5..=20.0).contains(&num) || (num * 2.0).fract() != 0.0 { return INVALID_RESULT; }
    gamma_recursive_impl(num)
}
