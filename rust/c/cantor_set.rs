const MAX_LEVEL: usize = 6;
const MAX_INTERVALS: usize = 64;
const SCALE: u64 = 1_000_000;

fn put_byte(output: &mut [u8], length: &mut usize, byte: u8) -> bool {
    if *length >= output.len() { return false; }
    output[*length] = byte;
    *length += 1;
    true
}
fn put_text(output: &mut [u8], length: &mut usize, text: &[u8]) -> bool {
    for &byte in text { if !put_byte(output, length, byte) { return false; } }
    true
}
fn put_uint(output: &mut [u8], length: &mut usize, mut value: u64) -> bool {
    let mut digits = [0u8; 20];
    let mut count = 0;
    loop {
        digits[count] = b'0' + (value % 10) as u8;
        count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while count > 0 { count -= 1; if !put_byte(output, length, digits[count]) { return false; } }
    true
}
fn put_fixed(output: &mut [u8], length: &mut usize, ticks: u64) -> bool {
    let mut fraction = ticks % SCALE;
    if !put_uint(output, length, ticks / SCALE) || !put_byte(output, length, b'.') { return false; }
    let mut divisor = 100_000;
    while divisor > 0 {
        if !put_byte(output, length, b'0' + (fraction / divisor % 10) as u8) { return false; }
        fraction %= divisor;
        divisor /= 10;
    }
    true
}

#[no_mangle]
pub unsafe extern "C" fn cantor_set(input: *const i64, length: usize,
                                     output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length != 3 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 0 || values[0] > values[1] || values[1] > 100_000 || values[2] < 0 || values[2] > MAX_LEVEL as i64 { return -1; }
    if output.is_null() { return -2; }
    let output = std::slice::from_raw_parts_mut(output, capacity);
    let start = values[0] as u64;
    let span = (values[1] - values[0]) as u64;
    let levels = values[2] as usize;
    let mut positions = [0u64; MAX_INTERVALS];
    let mut next = [0u64; MAX_INTERVALS];
    let mut count = 1usize;
    let mut denominator = 1u64;
    let mut output_length = 0usize;
    for level in 0..=levels {
        if !put_text(output, &mut output_length, b"Level ") || !put_uint(output, &mut output_length, level as u64) || !put_byte(output, &mut output_length, b'\t') { return -2; }
        for index in 0..count {
            let left_num = start * denominator + span * positions[index];
            let right_num = start * denominator + span * (positions[index] + 1);
            let left = (left_num * SCALE + denominator / 2) / denominator;
            let right = (right_num * SCALE + denominator / 2) / denominator;
            if !put_text(output, &mut output_length, b"\t[") || !put_fixed(output, &mut output_length, left) ||
                !put_text(output, &mut output_length, b"] -- [") || !put_fixed(output, &mut output_length, right) ||
                !put_byte(output, &mut output_length, b']') { return -2; }
        }
        if !put_byte(output, &mut output_length, b'\n') { return -2; }
        if level < levels {
            if !put_byte(output, &mut output_length, b'\n') { return -2; }
            for index in 0..count { next[2 * index] = positions[index] * 3; next[2 * index + 1] = positions[index] * 3 + 2; }
            count *= 2;
            positions[..count].copy_from_slice(&next[..count]);
            denominator *= 3;
        }
    }
    if output_length >= capacity { return -2; }
    output[output_length] = 0;
    (output_length + 1) as i64
}
