#[no_mangle]
pub unsafe extern "C" fn z_algorithm(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || !(1..=2048).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(input, length);
    if !(0..=2047).contains(&input[0]) { return -1; }
    let count = input[0] as usize;
    if length != count + 1 { return -1; }
    let output_bytes = count * 4;
    if output_capacity < output_bytes || (count > 0 && output.is_null()) { return -2; }

    let mut z = [0usize; 2047];
    let (mut left, mut right) = (0usize, 0usize);
    for index in 1..count {
        if index < right { z[index] = z[index - left].min(right - index); }
        while index + z[index] < count && input[1 + z[index]] == input[1 + index + z[index]] {
            z[index] += 1;
        }
        if index + z[index] > right {
            left = index;
            right = index + z[index];
        }
    }
    for index in 0..count {
        let bytes = (z[index] as u32).to_le_bytes();
        for (byte, value) in bytes.iter().enumerate() { *output.add(index * 4 + byte) = *value; }
    }
    count as i64
}
