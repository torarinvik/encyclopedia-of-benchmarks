/// Encode each run as its ASCII byte and, when repeated, its decimal count.
#[no_mangle]
pub unsafe extern "C" fn string_compression(input: *const i64, length: usize,
                                               output: *mut u8, output_capacity: usize) -> i64 {
    if length > 64 || (length != 0 && input.is_null()) { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if !(0..=127).contains(&value) { return -1; }
    }

    let mut encoded_length = 0usize;
    let mut index = 0usize;
    while index < length {
        let mut end = index + 1;
        while end < length && *input.add(end) == *input.add(index) { end += 1; }
        let count = end - index;
        encoded_length += 1 + if count > 1 { if count >= 10 { 2 } else { 1 } } else { 0 };
        index = end;
    }
    if output_capacity < encoded_length || (encoded_length != 0 && output.is_null()) { return -2; }

    let mut write_index = 0usize;
    index = 0;
    while index < length {
        let mut end = index + 1;
        while end < length && *input.add(end) == *input.add(index) { end += 1; }
        let count = end - index;
        *output.add(write_index) = *input.add(index) as u8;
        write_index += 1;
        if count > 1 {
            if count >= 10 {
                *output.add(write_index) = (48 + count / 10) as u8;
                write_index += 1;
            }
            *output.add(write_index) = (48 + count % 10) as u8;
            write_index += 1;
        }
        index = end;
    }
    write_index as i64
}
