#[no_mangle]
pub unsafe extern "C" fn binary_to_hex(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if length > 4096 || (length != 0 && values.is_null()) {
        return -1;
    }
    for index in 0..length {
        let bit = *values.add(index);
        if bit != 48 && bit != 49 {
            return -1;
        }
    }

    let output_length = (length + 3) / 4;
    if output_length == 0 {
        return 0;
    }
    if output.is_null() || output_capacity < output_length {
        return -2;
    }

    let mut first_width = length % 4;
    if first_width == 0 {
        first_width = 4;
    }
    let mut start = 0;
    for group in 0..output_length {
        let width = if group == 0 { first_width } else { 4 };
        let mut nibble = 0i64;
        for offset in 0..width {
            nibble = nibble * 2 + (*values.add(start + offset) - 48);
        }
        *output.add(group) = if nibble < 10 {
            (48 + nibble) as u8
        } else {
            (55 + nibble) as u8
        };
        start += width;
    }
    output_length as i64
}
