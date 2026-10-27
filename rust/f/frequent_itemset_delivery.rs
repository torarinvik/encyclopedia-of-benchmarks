const MAX_ITEMS: usize = 8;
const MAX_ROWS: usize = 64;
const MAX_INPUT: usize = 69;
const MAX_OUTPUT: usize = 200;

fn put_u64(output: &mut [u8], word: usize, value: u64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn frequent_itemset_delivery(input: *const i64, length: usize,
                                                       output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 6 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n0, m0, minimum, tail0, prefix0) = (values[0], values[1], values[2], values[3], values[4]);
    if !(1..=MAX_ITEMS as i64).contains(&n0) || !(1..=MAX_ROWS as i64).contains(&m0) ||
       minimum < 1 || minimum > m0 || length != 5 + m0 as usize { return -1; }
    let n = n0 as usize; let rows = m0 as usize;
    if tail0 < -1 || tail0 >= n0 || prefix0 < 0 { return -1; }
    let limit = 1u64 << n; let prefix = prefix0 as u64;
    if prefix >= limit || (tail0 == -1 && prefix != 0) ||
       (tail0 >= 0 && ((prefix >> tail0 as u32) & 1 == 0 || prefix >> (tail0 as u32 + 1) != 0)) { return -1; }
    let mut occurrences = [0u64; MAX_ITEMS];
    let mut supports = [0u64; MAX_ITEMS];
    for row in 0..rows {
        let row0 = values[5 + row];
        if row0 < 0 || row0 as u64 >= limit { return -1; }
        let mask = row0 as u64;
        if mask & prefix != prefix { continue; }
        for item in (tail0 + 1) as usize..n {
            if mask & (1u64 << item) != 0 { occurrences[item] |= 1u64 << row; supports[item] += 1; }
        }
    }
    let mut words = [0u64; 1 + 3 * MAX_ITEMS];
    let mut records = 0usize;
    for item in (tail0 + 1) as usize..n {
        if supports[item] < minimum as u64 { continue; }
        let at = 1 + 3 * records; records += 1;
        words[at] = item as u64; words[at + 1] = occurrences[item]; words[at + 2] = supports[item];
    }
    words[0] = records as u64;
    let word_count = 1 + 3 * records; let bytes = 8 * word_count;
    if bytes > MAX_OUTPUT { return -1; }
    if output.is_null() || capacity < bytes { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, bytes);
    for word in 0..word_count { put_u64(dst, word, words[word]); }
    bytes as i64
}
