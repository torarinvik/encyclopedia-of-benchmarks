/// Portable byte counting sort for printable non-space ASCII characters.
#[no_mangle]
pub unsafe extern "C" fn counting_sort_string(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    const MAX_TEXT_LENGTH: i64 = 4095;
    if values.is_null() || length < 1 || length > MAX_TEXT_LENGTH as usize + 1 { return -1; }
    let count = *values;
    if !(0..=MAX_TEXT_LENGTH).contains(&count) || length != count as usize + 1 { return -1; }

    let mut frequencies = [0usize; 256];
    for index in 0..count as usize {
        let value = *values.add(index + 1);
        if !(33..=126).contains(&value) { return -1; }
        frequencies[value as usize] += 1;
    }
    if output.is_null() || output_capacity < count as usize { return -2; }

    for value in 1..256 { frequencies[value] += frequencies[value - 1]; }
    for index in (1..=count as usize).rev() {
        let value = *values.add(index) as usize;
        frequencies[value] -= 1;
        *output.add(frequencies[value]) = value as u8;
    }
    count
}
