const MAX_N: i64 = 100_000;

/// Emit distinct values of floor(n / x) in increasing x order.
#[no_mangle]
pub extern "C" fn enumerate_quotients(value: i64, output: *mut u8, output_capacity: usize) -> i64 {
    if !(1..=MAX_N).contains(&value) { return -1; }
    let n = value as u64;
    let mut count = 0usize;
    let mut left = 1u64;
    while left <= n {
        let quotient = n / left;
        count += 1;
        left = n / quotient + 1;
    }
    let byte_count = (count + 1) * 8;
    if output.is_null() || output_capacity < byte_count { return -2; }
    let count_word = count as u64;
    for byte in 0..8 {
        unsafe { *output.add(byte) = (count_word >> (byte * 8)) as u8; }
    }
    let mut index = 0usize;
    left = 1;
    while left <= n {
        let quotient = n / left;
        for byte in 0..8 {
            unsafe { *output.add((index + 1) * 8 + byte) = (quotient >> (byte * 8)) as u8; }
        }
        index += 1;
        left = n / quotient + 1;
    }
    byte_count as i64
}
