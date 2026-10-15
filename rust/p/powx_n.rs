fn pow_positive(base: f64, exponent: i64) -> f64 {
    if exponent == 0 { return 1.0; }
    let mut mask = 1i64;
    while mask <= exponent / 2 { mask <<= 1; }
    let mut result = base;
    mask >>= 1;
    while mask != 0 {
        result *= result;
        if exponent & mask != 0 { result *= base; }
        mask >>= 1;
    }
    result
}

#[no_mangle]
pub extern "C" fn powx_n(base: f64, exponent: i32) -> f64 {
    if exponent == 0 { return 1.0; }
    if exponent == i32::MIN { return 1.0 / (pow_positive(base, i32::MAX as i64) * base); }
    if exponent < 0 { return 1.0 / pow_positive(base, -(exponent as i64)); }
    pow_positive(base, exponent as i64)
}
