/// Sort a bounded copy and emit sorted duplicate values as little-endian i32s.
const MAX_LENGTH: usize = 100000;

#[no_mangle]
pub extern "C" fn find_all_duplicates_in_array(
    values: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if length > MAX_LENGTH || (length != 0 && values.is_null()) { return -1; }
    if length == 0 { return 0; }

    let mut sorted = Vec::with_capacity(length);
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if value < 1 || value > length as i64 { return -1; }
        sorted.push(value as i32);
    }
    sorted.sort_unstable();

    let mut duplicate_count = 0usize;
    let mut index = 0usize;
    while index < length {
        let mut end = index + 1;
        while end < length && sorted[end] == sorted[index] { end += 1; }
        let frequency = end - index;
        if frequency > 2 { return -1; }
        if frequency == 2 { duplicate_count += 1; }
        index = end;
    }
    let output_bytes = duplicate_count * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }
    let mut destination = 0usize;
    index = 0;
    while index < length {
        let mut end = index + 1;
        while end < length && sorted[end] == sorted[index] { end += 1; }
        if end - index == 2 {
            let bytes = sorted[index].to_le_bytes();
            for (byte, value) in bytes.iter().enumerate() {
                unsafe { *output.add(destination * 4 + byte) = *value; }
            }
            destination += 1;
        }
        index = end;
    }
    duplicate_count as i64
}
