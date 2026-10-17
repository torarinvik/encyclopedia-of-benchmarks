#[no_mangle]
pub unsafe extern "C" fn median_search2(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=129).contains(&length) { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    if !(0..=128).contains(&words[0]) { return -1; }
    let count = words[0] as usize;
    if length != count + 1 { return -1; }
    for &value in &words[1..] {
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
    }

    let mut next = [-1i32; 128];
    for i in 0..count {
        next[i] = if i + 1 < count { (i + 1) as i32 } else { -1 };
    }
    let mut found = 0i32;
    let mut median_index = -1i32;
    if count > 0 {
        let mut slow = 0i32;
        let mut fast = 0i32;
        while next[fast as usize] >= 0 && next[next[fast as usize] as usize] >= 0 {
            slow = next[slow as usize];
            fast = next[next[fast as usize] as usize];
        }
        median_index = if next[fast as usize] >= 0 { next[slow as usize] } else { slow };
        found = 1;
    }
    if output.is_null() || capacity < 8 { return -2; }
    let mut buffer = [0u8; 8];
    buffer[0..4].copy_from_slice(&found.to_le_bytes());
    buffer[4..8].copy_from_slice(&median_index.to_le_bytes());
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, 8);
    8
}
