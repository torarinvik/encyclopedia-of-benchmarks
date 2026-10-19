const MAX_INPUT: usize = 4096;
const OFFSETS: [usize; 8] = [0, 5, 2, 7, 4, 1, 6, 3];

#[no_mangle]
pub unsafe extern "C" fn drop3(values: *const i64, length: usize) -> i64 {
    if length > MAX_INPUT + 1 || (length != 0 && values.is_null()) { return -1; }
    for index in 0..length {
        let value = unsafe { *values.add(index) };
        if !(0..=255).contains(&value) { return -1; }
    }
    if length > MAX_INPUT { return -1; }

    let mut output_size = 0i64;
    for _ in 0..20 {
        let mut input_index = 0usize;
        let mut remaining_bits = length * 8;
        let mut phase = 0usize;
        let mut bit_buffer = 0u16;
        let mut output_bits = 0usize;
        while remaining_bits >= 3 {
            remaining_bits -= 3;
            let offset = OFFSETS[phase];
            if offset < 3 {
                let value = unsafe { *values.add(input_index) } as u16;
                bit_buffer |= value << (8 - offset);
                input_index += 1;
            }
            let code = (bit_buffer >> 13) & 7;
            if code >= 4 { output_bits += 3; }
            bit_buffer = bit_buffer.wrapping_shl(3);
            phase = (phase + 1) & 7;
        }
        output_size = (output_bits >> 3) as i64;
    }
    output_size
}
