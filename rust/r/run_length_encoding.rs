/// Encode runs as an unambiguous decimal count followed by an ASCII byte.
#[no_mangle]
pub unsafe extern "C" fn run_length_encoding(input: *const i64, length: usize,
                                               output: *mut u8, output_capacity: usize) -> i64 {
    if length > 66 { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if !(1..=127).contains(&value) || (48..=57).contains(&value) { return -1; }
    }

    let mut encoded_length = 0usize;
    let mut index = 0usize;
    while index < length {
        let mut end = index + 1;
        while end < length && *input.add(end) == *input.add(index) { end += 1; }
        let count = end - index;
        encoded_length += if count >= 10 { 3 } else { 2 };
        index = end;
    }
    if output_capacity < encoded_length { return -2; }

    let mut write_index = 0usize;
    index = 0;
    while index < length {
        let mut end = index + 1;
        while end < length && *input.add(end) == *input.add(index) { end += 1; }
        let count = end - index;
        if count >= 10 {
            *output.add(write_index) = (48 + count / 10) as u8;
            write_index += 1;
        }
        *output.add(write_index) = (48 + count % 10) as u8;
        write_index += 1;
        *output.add(write_index) = *input.add(index) as u8;
        write_index += 1;
        index = end;
    }
    write_index as i64
}
