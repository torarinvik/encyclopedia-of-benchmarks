/// Encode bytes as uppercase Base16 or decode uppercase Base16 bytes.
#[no_mangle]
pub unsafe extern "C" fn base16(input: *const i64, length: usize,
                                  output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || !(1..=65).contains(&length) { return -1; }
    let mode = *input;
    if mode == 0 {
        let count = length - 1;
        let output_length = count * 2;
        for index in 1..length {
            let byte = *input.add(index);
            if !(0..=255).contains(&byte) { return -1; }
        }
        if output.is_null() && output_length > 0 || output_capacity < output_length { return -2; }
        for index in 0..count {
            let byte = *input.add(index + 1) as u8;
            *output.add(2 * index) = b"0123456789ABCDEF"[(byte >> 4) as usize];
            *output.add(2 * index + 1) = b"0123456789ABCDEF"[(byte & 15) as usize];
        }
        return output_length as i64;
    }
    if mode != 1 { return -1; }
    let encoded_length = length - 1;
    if encoded_length % 2 != 0 { return -1; }
    for index in 1..length { if nibble(*input.add(index)) < 0 { return -1; } }
    let output_length = encoded_length / 2;
    if output.is_null() && output_length > 0 || output_capacity < output_length { return -2; }
    for index in 0..output_length {
        *output.add(index) = (nibble(*input.add(1 + 2 * index)) * 16 + nibble(*input.add(2 + 2 * index))) as u8;
    }
    output_length as i64
}
fn nibble(byte: i64) -> i64 {
    if (b'0' as i64..=b'9' as i64).contains(&byte) { return byte - b'0' as i64; }
    if (b'A' as i64..=b'F' as i64).contains(&byte) { return byte - b'A' as i64 + 10; }
    -1
}
