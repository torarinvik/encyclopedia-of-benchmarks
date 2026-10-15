/// Case-insensitive ASCII pattern search using the Z algorithm.
#[no_mangle]
pub unsafe extern "C" fn z_algorithm_search(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    const MAX: usize = 2047;
    const TOTAL_MAX: usize = 2 * MAX + 1;
    if values.is_null() || length < 2 { return -1; }
    let tv = *values;
    let pv = *values.add(1);
    if !(0..=MAX as i64).contains(&tv) || !(0..=MAX as i64).contains(&pv) { return -1; }
    let (text_len, pattern_len) = (tv as usize, pv as usize);
    if length != 2 + text_len + pattern_len { return -1; }
    for i in 2..length { if !(0..=127).contains(&*values.add(i)) { return -1; } }
    if pattern_len == 0 {
        let count = text_len + 1;
        if output_capacity < 4 * count || output.is_null() { return -2; }
        for i in 0..count { let p = (i + 1) as u32; for b in 0..4 { *output.add(4 * i + b) = (p >> (8 * b)) as u8; } }
        return count as i64;
    }
    let mut sequence = [0u32; TOTAL_MAX];
    let mut z = [0usize; TOTAL_MAX];
    let total = pattern_len + 1 + text_len;
    for i in 0..pattern_len {
        let v = *values.add(2 + text_len + i) as u32;
        sequence[i] = if (b'A' as u32..=b'Z' as u32).contains(&v) { v + 32 } else { v };
    }
    sequence[pattern_len] = 256;
    for i in 0..text_len {
        let v = *values.add(2 + i) as u32;
        sequence[pattern_len + 1 + i] = if (b'A' as u32..=b'Z' as u32).contains(&v) { v + 32 } else { v };
    }
    let (mut left, mut right) = (0usize, 0usize);
    for i in 1..total {
        if i < right { z[i] = z[i - left].min(right - i); }
        while i + z[i] < total && sequence[z[i]] == sequence[i + z[i]] { z[i] += 1; }
        if i + z[i] > right { left = i; right = i + z[i]; }
    }
    let count = (pattern_len + 1..total).filter(|&i| z[i] >= pattern_len).count();
    if output_capacity < 4 * count || (count != 0 && output.is_null()) { return -2; }
    let mut write = 0;
    for i in pattern_len + 1..total { if z[i] >= pattern_len {
        let p = (i - pattern_len) as u32;
        for b in 0..4 { *output.add(4 * write + b) = (p >> (8 * b)) as u8; }
        write += 1;
    }}
    count as i64
}
