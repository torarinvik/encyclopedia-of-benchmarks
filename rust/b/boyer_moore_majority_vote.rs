/// Return a strict majority element, or -1 if none exists.
#[no_mangle]
pub unsafe extern "C" fn boyer_moore_majority_vote(values: *const i64, length: usize) -> i64 {
    if length == 0 || length > 256 || values.is_null() { return -1; }
    let mut candidate = 0i64;
    let mut balance = 0usize;
    for index in 0..length {
        let value = *values.add(index);
        if balance == 0 { candidate = value; }
        if value == candidate { balance += 1; } else { balance -= 1; }
    }
    let mut occurrences = 0usize;
    for index in 0..length {
        if *values.add(index) == candidate { occurrences += 1; }
    }
    if occurrences > length / 2 { candidate } else { -1 }
}
