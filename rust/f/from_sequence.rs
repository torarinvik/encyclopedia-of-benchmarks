const MAX_NODES: usize = 128;
const MAX_OUTPUT: usize = 3589;

fn append_i64(buffer: &mut [u8; MAX_OUTPUT], mut position: usize, value: i64) -> usize {
    let mut reversed = [0u8; 20];
    let mut length = 0usize;
    let mut magnitude = value.unsigned_abs();
    loop {
        reversed[length] = b'0' + (magnitude % 10) as u8;
        length += 1;
        magnitude /= 10;
        if magnitude == 0 { break; }
    }
    buffer[position] = b'<'; position += 1;
    if value < 0 { buffer[position] = b'-'; position += 1; }
    while length > 0 { length -= 1; buffer[position] = reversed[length]; position += 1; }
    buffer[position] = b'>'; position += 1;
    buffer[position..position + 6].copy_from_slice(b" ---> ");
    position + 6
}

#[no_mangle]
pub unsafe extern "C" fn from_sequence(input: *const i64, length: usize,
                                        output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > MAX_NODES + 1 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let count = values[0];
    if !(1..=MAX_NODES as i64).contains(&count) || length != count as usize + 1 { return -1; }
    let mut buffer = [0u8; MAX_OUTPUT];
    let mut position = 0usize;
    for &value in &values[1..] { position = append_i64(&mut buffer, position, value); }
    buffer[position..position + 5].copy_from_slice(b"<END>");
    position += 5;
    if output.is_null() || capacity < position { return -2; }
    std::ptr::copy_nonoverlapping(buffer.as_ptr(), output, position);
    position as i64
}
