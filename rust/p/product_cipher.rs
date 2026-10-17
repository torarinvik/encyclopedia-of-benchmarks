const MAX_INPUT_VALUES: usize = 259;
const MAX_TEXT_LENGTH: usize = 256;
const MAX_COLUMNS: usize = 64;
const MAX_OUTPUT_BYTES: usize = 315;

#[no_mangle]
pub unsafe extern "C" fn product_cipher(
    input: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT_VALUES {
        return -1;
    }
    let columns_value = unsafe { *input };
    let text_length_value = unsafe { *input.add(1) };
    if !(1..=MAX_COLUMNS as i64).contains(&columns_value)
        || !(0..=MAX_TEXT_LENGTH as i64).contains(&text_length_value)
    {
        return -1;
    }
    let columns = columns_value as usize;
    let text_length = text_length_value as usize;
    if length != 2 + text_length {
        return -1;
    }
    for index in 0..text_length {
        let byte = unsafe { *input.add(2 + index) };
        if !(0..=127).contains(&byte) || byte == 10 || byte == 13 {
            return -1;
        }
    }

    let padded_length = if text_length == 0 {
        0
    } else {
        ((text_length + columns - 1) / columns) * columns
    };
    if padded_length > MAX_OUTPUT_BYTES {
        return -1;
    }
    if padded_length == 0 {
        return 0;
    }
    if output.is_null() || output_capacity < padded_length {
        return -2;
    }

    let mut padded = [0u8; MAX_OUTPUT_BYTES];
    for index in 0..text_length {
        padded[index] = (unsafe { *input.add(2 + index) } + 5) as u8;
    }
    padded[text_length..padded_length].fill(b'/');
    let rows = padded_length / columns;
    let mut written = 0;
    for column in 0..columns {
        for row in 0..rows {
            unsafe { *output.add(written) = padded[column + row * columns]; }
            written += 1;
        }
    }
    written as i64
}
