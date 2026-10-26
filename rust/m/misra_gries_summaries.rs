const MAX_K: usize = 8;
const MAX_ITEMS: usize = 64;
const MAX_INPUT: usize = 66;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = (bits >> (8 * byte)) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn misra_gries_summaries(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT { return -1; }
    let k64 = *input;
    let count64 = *input.add(1);
    if !(1..=MAX_K as i64).contains(&k64) || !(0..=MAX_ITEMS as i64).contains(&count64)
        || length != 2 + count64 as usize { return -1; }
    let k = k64 as usize;
    let count = count64 as usize;
    let mut items = [-1i64; MAX_K];
    let mut counts = [0i64; MAX_K];
    for index in 0..count {
        let item = *input.add(index + 2);
        if !(0..=15).contains(&item) { return -1; }
        let mut slot = 0;
        while slot < k && items[slot] != item { slot += 1; }
        if slot < k { counts[slot] += 1; continue; }
        slot = 0;
        while slot < k && counts[slot] != 0 { slot += 1; }
        if slot < k { items[slot] = item; counts[slot] = 1; continue; }
        for slot in 0..k {
            counts[slot] -= 1;
            if counts[slot] == 0 { items[slot] = -1; }
        }
    }
    let used = counts[..k].iter().filter(|&&count| count > 0).count();
    let output_bytes = 8 * (1 + 2 * used);
    if output.is_null() || capacity < output_bytes { return -2; }
    let mut ordered = [(0i64, 0i64); MAX_K];
    let mut at = 0;
    for slot in 0..k {
        if counts[slot] > 0 { ordered[at] = (items[slot], counts[slot]); at += 1; }
    }
    ordered[..used].sort_by_key(|pair| pair.0);
    store_i64_le(output, 0, used as i64);
    for index in 0..used {
        store_i64_le(output, 8 * (1 + 2 * index), ordered[index].0);
        store_i64_le(output, 8 * (2 + 2 * index), ordered[index].1);
    }
    output_bytes as i64
}
