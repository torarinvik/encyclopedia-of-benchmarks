/// Pack a bounded prefix of OEIS A086747 using a zero-run parity automaton.
fn baum_sweet_term(number: i64) -> i64 {
    if number == 0 { return 0; }
    let mut mask = 1i64;
    while mask <= number / 2 { mask *= 2; }
    let mut odd_zero_run = false;
    while mask > 0 {
        if number & mask != 0 {
            if odd_zero_run { return 0; }
            odd_zero_run = false;
        } else {
            odd_zero_run = !odd_zero_run;
        }
        mask /= 2;
    }
    if odd_zero_run { 0 } else { 1 }
}

#[no_mangle]
pub extern "C" fn baum_sweet_sequence(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let count = values[0];
    if !(0..=63).contains(&count) { return -1; }
    let mut packed = 0i64;
    let mut bit = 1i64;
    for index in 0..count {
        if baum_sweet_term(index) != 0 { packed += bit; }
        if index + 1 < count { bit *= 2; }
    }
    packed
}
