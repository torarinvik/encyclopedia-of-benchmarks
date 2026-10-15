/// Return the length of the strict longest alternating subsequence.
#[no_mangle]
pub extern "C" fn longest_alternating_subsequence(values: *const i64, length: usize) -> i64 {
    if length > 512 || (length != 0 && values.is_null()) { return -1; }
    let mut result = 1i64;
    let mut rising = [0i64; 512];
    let mut falling = [0i64; 512];
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
        rising[index] = 1;
        falling[index] = 1;
        for previous in 0..index {
            let prior = unsafe { *values.add(previous) };
            if prior < value && rising[index] < falling[previous] + 1 {
                rising[index] = falling[previous] + 1;
            }
            if prior > value && falling[index] < rising[previous] + 1 {
                falling[index] = rising[previous] + 1;
            }
        }
        result = result.max(rising[index]).max(falling[index]);
    }
    result
}
