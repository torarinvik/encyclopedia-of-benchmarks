const MAX_VALUES: usize = 256;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_VALUES + 2;
const MAX_OUTPUT_BYTES: usize = 3836;
const I32_MIN_VALUE: i64 = i32::MIN as i64;
const I32_MAX_VALUE: i64 = i32::MAX as i64;

fn append_decimal(buffer: &mut [u8; MAX_OUTPUT_BYTES], position: &mut usize, value: i64) {
    let mut digits = [0u8; 10];
    let mut count = 0usize;
    let mut magnitude: u64;
    if value < 0 {
        buffer[*position] = b'-';
        *position += 1;
        magnitude = (-value) as u64;
    } else {
        magnitude = value as u64;
    }
    loop {
        digits[count] = b'0' + (magnitude % 10) as u8;
        count += 1;
        magnitude /= 10;
        if magnitude == 0 { break; }
    }
    while count > 0 {
        count -= 1;
        buffer[*position] = digits[count];
        *position += 1;
    }
}

#[no_mangle]
pub unsafe extern "C" fn print_reverse(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if length > MAX_PARSEABLE_INPUT_LENGTH || length > MAX_VALUES { return -1; }
    if length > 0 && values.is_null() { return -1; }
    for index in 0..length {
        let value = *values.add(index);
        if !(I32_MIN_VALUE..=I32_MAX_VALUE).contains(&value) { return -1; }
    }

    let mut encoded = [0u8; MAX_OUTPUT_BYTES];
    let mut written = 0usize;
    for remaining in (1..=length).rev() {
        if written != 0 {
            encoded[written..written + 4].copy_from_slice(b" <- ");
            written += 4;
        }
        append_decimal(&mut encoded, &mut written, *values.add(remaining - 1));
    }

    if output.is_null() || output_capacity < written { return -2; }
    core::ptr::copy_nonoverlapping(encoded.as_ptr(), output, written);
    written as i64
}
