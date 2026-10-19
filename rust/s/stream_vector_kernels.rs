fn write_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        unsafe { *output.add(offset + byte) = (bits >> (byte * 8)) as u8; }
    }
}

#[no_mangle]
pub extern "C" fn stream_vector_kernels(input: *const i64, length: usize,
                                          output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length < 2 || length > 259 { return -1; }
    let mode = unsafe { *input };
    let count_value = unsafe { *input.add(1) };
    if !(0..=3).contains(&mode) || !(0..=128).contains(&count_value) { return -1; }
    let count = count_value as usize;
    let has_alpha = mode == 1 || mode == 3;
    let array_count = if mode == 0 || mode == 1 { 1usize } else { 2usize };
    let expected_length = 2 + (if has_alpha { 1 } else { 0 }) + array_count * count;
    if length != expected_length { return -1; }

    let mut a_start = 2usize;
    let mut alpha = 0i64;
    if has_alpha {
        alpha = unsafe { *input.add(2) };
        if !(-1000..=1000).contains(&alpha) { return -1; }
        a_start = 3;
    }
    let b_start = a_start + count;
    for index in 0..array_count * count {
        let value = unsafe { *input.add(a_start + index) };
        if !(-1000..=1000).contains(&value) { return -1; }
    }

    let mut staged = [0i64; 128];
    for index in 0..count {
        let a = unsafe { *input.add(a_start + index) };
        staged[index] = match mode {
            0 => a,
            1 => alpha * a,
            2 => a + unsafe { *input.add(b_start + index) },
            _ => a + alpha * unsafe { *input.add(b_start + index) },
        };
    }

    let output_bytes = count * 8;
    if output.is_null() || capacity < output_bytes { return -2; }
    for index in 0..count { write_i64_le(output, index * 8, staged[index]); }
    output_bytes as i64
}
