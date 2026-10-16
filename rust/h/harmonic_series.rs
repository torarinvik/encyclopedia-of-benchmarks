fn append_decimal(out: &mut [u8], mut position: usize, mut value: usize) -> usize {
    let mut digits = [0u8; 4]; let mut count = 0;
    loop { digits[count] = (value % 10) as u8; count += 1; value /= 10; if value == 0 { break; } }
    while count > 0 { count -= 1; out[position] = b'0' + digits[count]; position += 1; }
    position
}

#[no_mangle]
pub unsafe extern "C" fn harmonic_series(n: i64, output: *mut u8, capacity: usize) -> i64 {
    if !(-512..=512).contains(&n) { return -1; }
    if n <= 0 { return 0; }
    let mut needed = 2usize;
    for term in 2..=n as usize {
        let mut value = term; let mut digits = 0;
        loop { digits += 1; value /= 10; if value == 0 { break; } }
        needed += digits + 3;
    }
    if output.is_null() || capacity < needed { return -2; }
    let out = std::slice::from_raw_parts_mut(output, capacity);
    let mut position = 0;
    out[position] = b'1'; position += 1; out[position] = b'\n'; position += 1;
    for term in 2..=n as usize {
        out[position] = b'1'; position += 1; out[position] = b'/'; position += 1;
        position = append_decimal(out, position, term);
        out[position] = b'\n'; position += 1;
    }
    position as i64
}
