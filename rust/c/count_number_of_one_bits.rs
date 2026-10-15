/// Compare Kernighan, modulo-shift, and byte-lookup set-bit counters.
#[no_mangle]
pub extern "C" fn count_number_of_one_bits(number: i64, method: i64) -> i64 {
    if !(0..=4_294_967_295).contains(&number) || !(0..=2).contains(&method) { return -1; }
    let mut remaining = number as u32;
    let mut count = 0i64;
    if method == 0 {
        while remaining != 0 {
            remaining &= remaining - 1;
            count += 1;
        }
        return count;
    }
    if method == 1 {
        while remaining != 0 {
            if remaining % 2 == 1 { count += 1; }
            remaining >>= 1;
        }
        return count;
    }
    let mut lookup = [0i64; 256];
    for index in 1..256 { lookup[index] = lookup[index >> 1] + (index & 1) as i64; }
    lookup[(remaining & 0xff) as usize] + lookup[((remaining >> 8) & 0xff) as usize]
        + lookup[((remaining >> 16) & 0xff) as usize] + lookup[(remaining >> 24) as usize]
}
