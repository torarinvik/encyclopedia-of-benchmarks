#[no_mangle]
pub unsafe extern "C" fn reverse_letters(input: *const i64, length: usize, output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let data = std::slice::from_raw_parts(input, length);
    if !(0..=256).contains(&data[0]) || length != data[0] as usize + 1 { return -1; }
    let n = data[0] as usize;
    for i in 0..n {
        if data[i + 1] == 32 {
            if i == 0 || i + 1 == n || data[i] == 32 { return -1; }
        } else if !(33..=126).contains(&data[i + 1]) { return -1; }
    }
    if output.is_null() || capacity < n + 1 { return -2; }
    let result = std::slice::from_raw_parts_mut(output, capacity);
    let mut start = 0;
    while start < n {
        let mut ending = start;
        while ending < n && data[ending + 1] != 32 { ending += 1; }
        for i in 0..ending - start + 1 { result[start + i] = data[ending - i] as u8; }
        if ending < n { result[ending] = 32; }
        start = ending + 1;
    }
    result[n] = 0;
    n as i64
}
