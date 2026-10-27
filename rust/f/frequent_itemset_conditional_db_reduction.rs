const MAX_ROWS: usize = 64;
const MAX_INPUT: usize = 69;
const MAX_OUTPUT: usize = 1032;

fn put_u64(output: &mut [u8], word: usize, value: u64) {
    output[word * 8..word * 8 + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn frequent_itemset_conditional_db_reduction(
    input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 6 || length > MAX_INPUT { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n0, rows0, minimum, tail, prefix0) = (values[0], values[1], values[2], values[3], values[4]);
    if !(1..=8).contains(&n0) || !(1..=MAX_ROWS as i64).contains(&rows0) ||
       minimum < 1 || minimum > rows0 || length != 5 + rows0 as usize { return -1; }
    if tail < -1 || tail >= n0 || prefix0 < 0 { return -1; }
    let n = n0 as usize; let rows = rows0 as usize;
    let limit = 1u64 << n; let prefix = prefix0 as u64;
    if prefix >= limit || (tail == -1 && prefix != 0) ||
       (tail >= 0 && ((prefix >> tail as u32) & 1 == 0 || prefix >> (tail as u32 + 1) != 0)) { return -1; }
    let mut selected = [0u64; MAX_ROWS];
    let mut support = [0u64; 8];
    let mut selected_count = 0usize;
    for row in 0..rows {
        let row0 = values[5 + row];
        if row0 < 0 || row0 as u64 >= limit { return -1; }
        let mask = row0 as u64;
        if mask & prefix != prefix { continue; }
        selected[selected_count] = mask; selected_count += 1;
        for item in (tail + 1) as usize..n {
            if mask & (1u64 << item) != 0 { support[item] += 1; }
        }
    }
    if selected_count < minimum as usize { return -1; }
    let mut keep = if tail >= 0 { 1u64 << tail as u32 } else { 0 };
    for item in (tail + 1) as usize..n {
        if support[item] >= minimum as u64 { keep |= 1u64 << item; }
    }
    let below = if tail > 0 { (1u64 << tail as u32) - 1 } else { 0 };
    let mut masks = [0u64; MAX_ROWS]; let mut counts = [0u64; MAX_ROWS];
    let mut distinct = 0usize;
    for row in 0..selected_count {
        let reduced = selected[row] & !below & keep;
        let mut at = 0usize;
        while at < distinct && masks[at] != reduced { at += 1; }
        if at == distinct { masks[distinct] = reduced; distinct += 1; }
        counts[at] += 1;
    }
    for i in 1..distinct {
        let (saved_mask, saved_count) = (masks[i], counts[i]);
        let mut j = i;
        while j > 0 && masks[j - 1] > saved_mask {
            masks[j] = masks[j - 1]; counts[j] = counts[j - 1]; j -= 1;
        }
        masks[j] = saved_mask; counts[j] = saved_count;
    }
    let word_count = 1 + 2 * distinct; let bytes = 8 * word_count;
    if bytes > MAX_OUTPUT { return -1; }
    if output.is_null() || capacity < bytes { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, bytes);
    put_u64(dst, 0, distinct as u64);
    for i in 0..distinct { put_u64(dst, 1 + 2 * i, masks[i]); put_u64(dst, 2 + 2 * i, counts[i]); }
    bytes as i64
}
