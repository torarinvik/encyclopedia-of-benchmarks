#[no_mangle]
pub unsafe extern "C" fn first_fit_cardinality_bin_packing(input: *const i64, length: usize,
                                                            output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 4 || length > 35 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (n0, limit, cap) = (values[0], values[1], values[2]);
    if !(1..=32).contains(&n0) || !(1..=32).contains(&limit) || !(1..=10000).contains(&cap) || length != n0 as usize + 3 { return -1; }
    let n = n0 as usize;
    let sizes = &values[3..];
    if sizes.iter().any(|&x| x < 1 || x > cap) { return -1; }
    let mut loads = [0i64; 32]; let mut used = [0i64; 32]; let mut owners = [0i64; 32];
    let mut bins = 0usize;
    for (i, &size) in sizes.iter().enumerate() {
        let mut b = 0usize;
        while b < bins && (used[b] >= limit || loads[b] > cap - size) { b += 1; }
        if b == bins { bins += 1; }
        loads[b] += size; used[b] += 1; owners[i] = b as i64;
    }
    let bytes = 8 * (n + 1);
    if output.is_null() || capacity < bytes { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, bytes);
    dst[..8].copy_from_slice(&(bins as i64).to_le_bytes());
    for i in 0..n { dst[(i+1)*8..(i+2)*8].copy_from_slice(&owners[i].to_le_bytes()); }
    bytes as i64
}
