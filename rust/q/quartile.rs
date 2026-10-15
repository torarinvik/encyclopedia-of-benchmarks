/// Sort up to ten bounded values and encode quartile statistics.
fn store_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub extern "C" fn quartile(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 11 { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    let count = packed[0];
    if !(1..=10).contains(&count) || length != count as usize + 1 { return -1; }
    let mut values = [0i64; 10];
    for index in 0..count as usize {
        let value = packed[index + 1];
        if !(0..=99).contains(&value) { return -1; }
        values[index] = value;
    }
    for i in 0..count as usize {
        for j in 0..count as usize {
            if values[i] < values[j] { values.swap(i, j); }
        }
    }
    let q1 = values[count as usize / 4];
    let q3 = values[(3 * count as usize) / 4];
    let required = (count as usize + 4) * 8;
    if output.is_null() || output_capacity < required { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(output, required) };
    store_i64_le(output, 0, count);
    for index in 0..count as usize { store_i64_le(output, 8 * (index + 1), values[index]); }
    store_i64_le(output, 8 * (count as usize + 1), q1);
    store_i64_le(output, 8 * (count as usize + 2), q3);
    store_i64_le(output, 8 * (count as usize + 3), q3 - q1);
    required as i64
}
