/// Place evens first and fill the odd section from its end.
const MAX_ARRAY_LENGTH: usize = 5000;

#[no_mangle]
pub extern "C" fn sort_array_by_parity(input: *const i64, length: usize,
                                       output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_ARRAY_LENGTH || (length != 0 && input.is_null()) { return -1; }
    for index in 0..length {
        let value = unsafe { *input.add(index) };
        if !(0..=5000).contains(&value) { return -1; }
    }
    let output_bytes = length * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }

    let mut even_index = 0;
    let mut odd_index = length;
    for index in 0..length {
        let value = unsafe { *input.add(index) } as u32;
        let destination;
        if (value & 1) == 0 {
            destination = even_index;
            even_index += 1;
        } else {
            odd_index -= 1;
            destination = odd_index;
        }
        for byte in 0..4 {
            unsafe { *output.add(destination * 4 + byte) = (value >> (byte * 8)) as u8; }
        }
    }
    length as i64
}
