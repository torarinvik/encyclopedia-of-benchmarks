/// Preserve the source's factor-of-two reduction for Proth membership.
#[no_mangle]
pub extern "C" fn is_proth_number(input: i64) -> i64 {
    if input <= 0 { return -1; }
    if input == 1 { return 0; }

    let mut remainder = input - 1;
    let mut exponent = 0u32;
    while remainder % 2 == 0 {
        exponent += 1;
        remainder /= 2;
    }
    if remainder < (1_i64 << exponent) { 1 } else { 0 }
}
