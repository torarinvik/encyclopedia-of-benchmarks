#[no_mangle]
pub unsafe extern "C" fn hamming_numbers(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length != 1 { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    if !(1..=32).contains(&input[0]) { return -1; }
    let count = input[0] as usize;
    let output_bytes = count * 8;
    if output_capacity < output_bytes || output.is_null() { return -2; }

    let mut values = [0u64; 32];
    values[0] = 1;
    let (mut i2, mut i3, mut i5) = (0usize, 0usize, 0usize);
    for index in 1..count {
        let c2 = values[i2] * 2;
        let c3 = values[i3] * 3;
        let c5 = values[i5] * 5;
        let next = c2.min(c3).min(c5);
        values[index] = next;
        if c2 == next { i2 += 1; }
        if c3 == next { i3 += 1; }
        if c5 == next { i5 += 1; }
    }
    for index in 0..count {
        for byte in 0..8 {
            *output.add(index * 8 + byte) = (values[index] >> (byte * 8)) as u8;
        }
    }
    count as i64
}
