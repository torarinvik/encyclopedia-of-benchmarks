#[no_mangle]
pub extern "C" fn common_characters_frequency_quotient(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    const MAX_INPUT: usize = 1 + 16 * (1 + 64);
    if input.is_null() || length == 0 || length > MAX_INPUT { return -1; }
    let values = unsafe { std::slice::from_raw_parts(input, length) };
    let string_count = values[0];
    if !(0..=16).contains(&string_count) { return -1; }
    let mut counts = [0i64; 26];
    let mut offset = 1usize;
    let mut total = 0usize;
    for _ in 0..string_count {
        if offset >= length { return -1; }
        let string_length = values[offset];
        offset += 1;
        if !(0..=64).contains(&string_length) || string_length as usize > length - offset {
            return -1;
        }
        for value in &values[offset..offset + string_length as usize] {
            if !(97..=122).contains(value) { return -1; }
            counts[(value - 97) as usize] += 1;
        }
        offset += string_length as usize;
        total += string_length as usize;
        if total > 512 { return -1; }
    }
    if offset != length { return -1; }
    let mut used = 0usize;
    if string_count > 0 {
        for count in counts.iter() { used += (count / string_count) as usize; }
    }
    if used > capacity || (used > 0 && output.is_null()) { return -2; }
    let mut output_offset = 0usize;
    if string_count > 0 {
        for (letter, count) in counts.iter().enumerate() {
            for _ in 0..(count / string_count) {
                unsafe { *output.add(output_offset) = b'a' + letter as u8; }
                output_offset += 1;
            }
        }
    }
    used as i64
}
