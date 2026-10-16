/// Keep each value that is not smaller than the last retained value.
const MAX_INPUT_LENGTH: usize = 128;

unsafe fn store_i32_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as i32 as u32;
    for byte in 0..4 {
        *output.add(offset + byte) = (bits >> (byte * 8)) as u8;
    }
}

#[no_mangle]
pub extern "C" fn stalin_sort(values: *const i64, length: usize,
    output: *mut u8, output_capacity: usize) -> i64 {
    if length > MAX_INPUT_LENGTH || (length != 0 && values.is_null()) { return -1; }
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if value < i32::MIN as i64 || value > i32::MAX as i64 { return -1; }
    }

    let mut kept = 0usize;
    let mut last = 0i64;
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if kept == 0 || value >= last {
            kept += 1;
            last = value;
        }
    }
    let output_bytes = kept * 4;
    if output.is_null() || output_capacity < output_bytes { return -2; }

    let mut output_index = 0usize;
    last = 0;
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if output_index == 0 || value >= last {
            unsafe { store_i32_le(output, output_index * 4, value); }
            output_index += 1;
            last = value;
        }
    }
    output_bytes as i64
}
