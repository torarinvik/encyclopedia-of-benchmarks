/// Recursive Sylvester recurrence on the signed 64-bit benchmark domain.
fn sylvester_term(n: i64) -> i64 {
    if n == 1 {
        return 2;
    }
    let previous = sylvester_term(n - 1);
    previous * (previous - 1) + 1
}

#[no_mangle]
pub extern "C" fn sylvester_sequence(n: i64) -> i64 {
    if !(1..=7).contains(&n) {
        return -1;
    }
    sylvester_term(n)
}
