const MAX_VALUE: i64 = 1_000_000;

#[no_mangle]
pub extern "C" fn lucas_carmichael_number_predicate(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let value = unsafe { *input };
    if !(1..=MAX_VALUE).contains(&value) { return -1; }

    let mut remaining = value;
    let mut divisor = 2_i64;
    let mut composite = false;
    while divisor <= remaining / divisor {
        if remaining % divisor == 0 {
            composite = true;
            let mut exponent = 0;
            while remaining % divisor == 0 {
                remaining /= divisor;
                exponent += 1;
            }
            if exponent != 1 || (value + 1) % (divisor + 1) != 0 { return 0; }
        }
        divisor += 1;
    }
    if remaining > 1 {
        if !composite || (value + 1) % (remaining + 1) != 0 { return 0; }
    }
    if composite { 1 } else { 0 }
}
