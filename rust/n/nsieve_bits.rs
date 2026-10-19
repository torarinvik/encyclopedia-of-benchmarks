const MAX_LIMIT: i64 = 1_000_000;
const MAX_WORDS: usize = 15_626;

fn count_primes(limit: i64) -> i64 {
    let mut bits = [u64::MAX; MAX_WORDS];
    let mut count = 0;
    for value in 2..=limit {
        let word = (value >> 6) as usize;
        let mask = 1u64 << (value & 63);
        if bits[word] & mask != 0 {
            count += 1;
            let mut multiple = value + value;
            while multiple <= limit {
                let multiple_word = (multiple >> 6) as usize;
                let multiple_mask = 1u64 << (multiple & 63);
                if bits[multiple_word] & multiple_mask != 0 { bits[multiple_word] ^= multiple_mask; }
                multiple += value;
            }
        }
    }
    count
}

fn put_u64_le(output: *mut u8, offset: usize, value: u64) {
    let bytes = value.to_le_bytes();
    unsafe { std::ptr::copy_nonoverlapping(bytes.as_ptr(), output.add(offset), bytes.len()); }
}

#[no_mangle]
pub unsafe extern "C" fn benchmarkgame_nsieve_bits(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let limit = unsafe { *input };
    if !(0..=MAX_LIMIT).contains(&limit) { return -1; }
    if output.is_null() || capacity < 24 { return -2; }
    for pass in 0..3 { put_u64_le(output, pass * 8, count_primes(limit >> pass) as u64); }
    24
}
