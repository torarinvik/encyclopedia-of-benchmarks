/// Bounded AddPadding, RemovePadding, and GetPaddingCount source extraction.
#[no_mangle]
pub unsafe extern "C" fn pkcs7_padding(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 || length > 69 { return -1; }
    let operation = *input;
    let block_arg = *input.add(1);
    let offset_arg = *input.add(2);
    let data_arg = *input.add(3);
    if operation < 0 || operation > 2 || block_arg < 1 || block_arg > 16
        || data_arg < 1 || data_arg > 64
        || (operation == 0 && (offset_arg < 0 || offset_arg > data_arg))
        || length != data_arg as usize + 4 { return -1; }
    let block_size = block_arg as usize;
    let offset = if operation == 0 { offset_arg as usize } else { 0 };
    let data_length = data_arg as usize;
    for index in 0..data_length {
        let value = *input.add(index + 4);
        if !(0..=255).contains(&value) { return -1; }
    }

    let (padding_count, output_length) = if operation == 0 {
        let count = block_size - data_length % block_size;
        if offset + count > data_length { return -1; }
        (count, data_length + 1)
    } else if operation == 1 {
        if data_length % block_size != 0 { return -1; }
        let count = *input.add(data_length + 3) as usize;
        if count == 0 || count > block_size { return -1; }
        for index in data_length - count..data_length {
            if *input.add(index + 4) as usize != count { return -1; }
        }
        (count, data_length - count)
    } else {
        let count = *input.add(data_length + 3) as usize;
        let padding_start = data_length as i64 - count as i64;
        let mut failed = (padding_start | (count as i64 - 1)) >> 31;
        for index in 0..data_length {
            let mask = !((index as i64 - padding_start) >> 31);
            failed |= (*input.add(index + 4) ^ count as i64) & mask;
        }
        if failed != 0 { return -1; }
        (count, 1)
    };
    if output.is_null() || output_capacity < output_length { return -2; }
    if operation == 0 {
        *output = padding_count as u8;
        for index in 0..data_length {
            let value = if index >= offset && index < offset + padding_count {
                padding_count as u8
            } else {
                *input.add(index + 4) as u8
            };
            *output.add(index + 1) = value;
        }
    } else if operation == 1 {
        for index in 0..output_length {
            *output.add(index) = *input.add(index + 4) as u8;
        }
    } else {
        *output = padding_count as u8;
    }
    output_length as i64
}
