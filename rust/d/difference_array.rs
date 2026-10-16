fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn difference_array(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let (raw_n, raw_q) = (values[0], values[1]);
    if !(1..=64).contains(&raw_n) || !(0..=64).contains(&raw_q) { return -1; }
    let (n, q) = (raw_n as usize, raw_q as usize);
    if length != 2 + n + 3 * q { return -1; }
    if values[2..2+n].iter().any(|&x| !(-1_000_000..=1_000_000).contains(&x)) { return -1; }
    for u in 0..q {
        let base = 2 + n + 3 * u;
        if values[base] < 0 || values[base] >= raw_n || values[base + 1] < values[base] || values[base + 1] >= raw_n ||
            !(-1_000_000..=1_000_000).contains(&values[base + 2]) { return -1; }
    }
    let bytes = n * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let mut diff = [0i64; 65];
    diff[0] = values[2];
    for i in 1..n { diff[i] = values[2+i] - values[2+i-1]; }
    for u in 0..q {
        let base = 2 + n + 3 * u;
        let left = values[base] as usize;
        let right = values[base + 1] as usize;
        let delta = values[base + 2];
        diff[left] += delta;
        diff[right + 1] -= delta;
    }
    let result = std::slice::from_raw_parts_mut(output, bytes);
    let mut current = diff[0];
    put_i64_le(result, 0, current);
    for i in 1..n { current += diff[i]; put_i64_le(result, i*8, current); }
    bytes as i64
}
