const MAX_WORDS: usize = 257;
const MAX_PAYLOAD: i64 = 255;
const MAX_OUTPUT: usize = 257;

#[no_mangle]
pub unsafe extern "C" fn consistent_overhead_byte_stuffing(
    raw_input: *const i64,
    length: usize,
    raw_output: *mut u8,
    capacity: usize,
) -> i64 {
    if raw_input.is_null() || length < 1 || length > MAX_WORDS { return -1; }
    let input = unsafe { std::slice::from_raw_parts(raw_input, length) };
    if input[0] < 0 || input[0] > MAX_PAYLOAD { return -1; }
    let payload_length = input[0] as usize;
    if length != payload_length + 1 { return -1; }
    if input[1..].iter().any(|&byte| !(0..=255).contains(&byte)) { return -1; }

    let mut staged = [0_u8; MAX_OUTPUT];
    let mut written = 1_usize;
    let mut code_position = 0_usize;
    let mut code = 1_u16;
    let mut omitted_terminal_code = false;
    for (index, &raw_byte) in input[1..].iter().enumerate() {
        let byte = raw_byte as u8;
        if byte == 0 {
            staged[code_position] = code as u8;
            code_position = written;
            written += 1;
            code = 1;
        } else {
            staged[written] = byte;
            written += 1;
            code += 1;
            if code == 255 {
                staged[code_position] = 255;
                if index + 1 == payload_length {
                    omitted_terminal_code = true;
                    break;
                }
                code_position = written;
                written += 1;
                code = 1;
            }
        }
    }
    if !omitted_terminal_code { staged[code_position] = code as u8; }
    if raw_output.is_null() || capacity < written { return -2; }
    let output = unsafe { std::slice::from_raw_parts_mut(raw_output, capacity) };
    output[..written].copy_from_slice(&staged[..written]);
    written as i64
}
