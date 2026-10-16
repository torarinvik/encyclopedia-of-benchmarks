const MAX_ITEMS: usize = 12;
const MAX_SAFE: i64 = 9_007_199_254_740_991;

fn put32(out: &mut [u8], pos: &mut usize, value: u32) {
    out[*pos..*pos + 4].copy_from_slice(&value.to_le_bytes());
    *pos += 4;
}
fn put64(out: &mut [u8], pos: &mut usize, value: i64) {
    out[*pos..*pos + 8].copy_from_slice(&value.to_le_bytes());
    *pos += 8;
}

#[no_mangle]
pub unsafe extern "C" fn generate_sub_sets(input: *const i64, length: usize,
                                              output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 || length > MAX_ITEMS + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > MAX_ITEMS as i64 { return -1; }
    let n = values[0] as usize;
    if length != n + 1 || values[1..].iter().any(|v| *v < -MAX_SAFE || *v > MAX_SAFE) { return -1; }
    let subsets = 1usize << n;
    let total_items = if n == 0 { 0 } else { n * (subsets / 2) };
    let needed = 4 + 4 * subsets + 8 * total_items;
    if output.is_null() || capacity < needed { return -2; }
    let out = std::slice::from_raw_parts_mut(output, needed);
    let mut pos = 0;
    put32(out, &mut pos, subsets as u32);
    for mask in 0..subsets {
        let count = mask.count_ones();
        put32(out, &mut pos, count);
        for j in 0..n { if mask & (1usize << j) != 0 { put64(out, &mut pos, values[j + 1]); } }
    }
    needed as i64
}
