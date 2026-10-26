#[no_mangle]
pub unsafe extern "C" fn approximate_tandem_squares(input: *const i64, length: usize,
                                                     output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 34 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let n0 = values[0];
    let budget = values[1];
    if !(2..=32).contains(&n0) || !(0..=8).contains(&budget) || length != n0 as usize + 2 { return -1; }
    let n = n0 as usize;
    let word = &values[2..];
    if word.iter().any(|&x| !(0..=3).contains(&x)) { return -1; }
    let mut records = [[0i64; 3]; 256];
    let mut count = 0usize;
    for start in 0..n {
        let mut period = 1usize;
        while 2 * period <= n - start {
            let mut mismatches = 0i64;
            for i in 0..period {
                if word[start + i] != word[start + period + i] { mismatches += 1; }
            }
            if mismatches <= budget {
                records[count] = [start as i64, period as i64, mismatches];
                count += 1;
            }
            period += 1;
        }
    }
    let bytes = 8 * (1 + 3 * count);
    if output.is_null() || capacity < bytes { return -2; }
    let dst = std::slice::from_raw_parts_mut(output, bytes);
    let mut flat = Vec::with_capacity(1 + 3 * count);
    flat.push(count as i64);
    for record in records.iter().take(count) { flat.extend_from_slice(record); }
    for (i, value) in flat.iter().enumerate() { dst[i * 8..i * 8 + 8].copy_from_slice(&value.to_le_bytes()); }
    bytes as i64
}
