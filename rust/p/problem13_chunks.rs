const INVALID_RESULT: i64 = -1;
const CAPACITY_RESULT: i64 = -2;
const MAX_INPUT_BYTES: usize = 5000;
const MAX_INPUT_VALUES: usize = MAX_INPUT_BYTES + 1;
const CHUNK_WIDTH: usize = 50;
const MAX_OUTPUT_BYTES: usize = 10;

#[no_mangle]
pub unsafe extern "C" fn problem13_chunks(
    values: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if values.is_null() || length < 2 || length > MAX_INPUT_VALUES {
        return INVALID_RESULT;
    }
    let declared_length = *values;
    if !(1..=MAX_INPUT_BYTES as i64).contains(&declared_length)
        || declared_length as usize != length - 1
    {
        return INVALID_RESULT;
    }
    let byte_length = declared_length as usize;
    for index in 0..byte_length {
        let value = *values.add(index + 1);
        if !(48..=57).contains(&value) {
            return INVALID_RESULT;
        }
    }

    let width = byte_length.min(CHUNK_WIDTH);
    let mut reversed = [0u8; CHUNK_WIDTH + 2];
    let mut reversed_length = 0usize;
    let mut carry = 0i64;
    for remaining in (1..=width).rev() {
        let position = remaining - 1;
        let mut column = carry;
        let mut start = 0usize;
        while start < byte_length {
            let chunk_length = (byte_length - start).min(CHUNK_WIDTH);
            if position < chunk_length {
                column += *values.add(1 + start + position) - 48;
            }
            start += CHUNK_WIDTH;
        }
        reversed[reversed_length] = (column % 10) as u8;
        reversed_length += 1;
        carry = column / 10;
    }
    while carry > 0 {
        reversed[reversed_length] = (carry % 10) as u8;
        reversed_length += 1;
        carry /= 10;
    }

    let output_length = reversed_length.min(MAX_OUTPUT_BYTES);
    if output.is_null() || capacity < output_length {
        return CAPACITY_RESULT;
    }
    for index in 0..output_length {
        *output.add(index) = b'0' + reversed[reversed_length - 1 - index];
    }
    output_length as i64
}
