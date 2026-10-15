/// Swap adjacent node values in a bounded array representation of a list.
const MAX_LENGTH: usize = 1024;

#[no_mangle]
pub extern "C" fn swap_pairs(input: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_LENGTH || (length != 0 && input.is_null()) { return -1; }
    for index in 0..length {
        let value = unsafe { *input.add(index) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
    }
    let output_bytes = length * 4;
    if output_capacity < output_bytes || (output_bytes != 0 && output.is_null()) { return -2; }

    for index in 0..length {
        let pair_start = (index / 2) * 2;
        let source_index = if index % 2 == 0 && pair_start + 1 < length { pair_start + 1 } else { pair_start };
        let value = unsafe { *input.add(source_index) } as i32 as u32;
        for byte in 0..4 {
            unsafe { *output.add(index * 4 + byte) = (value >> (byte * 8)) as u8; }
        }
    }
    length as i64
}
