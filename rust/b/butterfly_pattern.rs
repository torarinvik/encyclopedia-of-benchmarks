fn write_run(output: &mut [u8], mut position: usize, byte: u8, count: usize) -> usize {
    for _ in 0..count {
        output[position] = byte;
        position += 1;
    }
    position
}

#[no_mangle]
pub unsafe extern "C" fn butterfly_pattern(n: i64, output: *mut u8, capacity: usize) -> i64 {
    if !(1..=45).contains(&n) { return -1; }
    let side = n as usize;
    let width = 2 * side - 1;
    let required = width * width + 2 * side - 2;
    if output.is_null() || capacity < required { return -2; }
    let output = std::slice::from_raw_parts_mut(output, required);

    let mut position = 0;
    for count in 1..side {
        if position != 0 { output[position] = b'\n'; position += 1; }
        position = write_run(output, position, b'*', count);
        position = write_run(output, position, b' ', 2 * (side - count) - 1);
        position = write_run(output, position, b'*', count);
    }
    if position != 0 { output[position] = b'\n'; position += 1; }
    position = write_run(output, position, b'*', width);
    for count in (1..side).rev() {
        output[position] = b'\n'; position += 1;
        position = write_run(output, position, b'*', count);
        position = write_run(output, position, b' ', 2 * (side - count) - 1);
        position = write_run(output, position, b'*', count);
    }
    position as i64
}
