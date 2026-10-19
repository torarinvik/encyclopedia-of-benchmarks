const MAX_INPUT_BYTES: usize = 4096;
const HEADER: &[u8] = b"begin 640 uuencode.c \n";
const TRAILER: &[u8] = b" \nend";

fn emit_group(input: &[i64], start: usize, end: usize, out: &mut [u8], cursor: &mut usize) {
    let a = input[start] as u32;
    let b_present = start + 1 < end;
    let c_present = start + 2 < end;
    let b = if b_present { input[start + 1] as u32 } else { 0 };
    let c = if c_present { input[start + 2] as u32 } else { 0 };
    let symbol = |value: u32| (32 + (value & 63)) as u8;
    out[*cursor] = symbol(a >> 2); *cursor += 1;
    out[*cursor] = symbol((a << 4) | (b >> 4)); *cursor += 1;
    out[*cursor] = if b_present { symbol((b << 2) | (c >> 6)) } else { b'=' }; *cursor += 1;
    out[*cursor] = if c_present { symbol(c) } else { b'=' }; *cursor += 1;
}

#[no_mangle]
pub unsafe extern "C" fn uuencode(input: *const i64, length: usize,
                                    output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length > MAX_INPUT_BYTES { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values.iter().any(|value| !(0..=255).contains(value)) { return -1; }
    let needed = HEADER.len() + 4 * ((length + 2) / 3) + 2 * ((length + 44) / 45) + TRAILER.len();
    if output.is_null() || capacity < needed { return -2; }
    let out = std::slice::from_raw_parts_mut(output, capacity);
    let mut cursor = 0;
    out[..HEADER.len()].copy_from_slice(HEADER);
    cursor += HEADER.len();
    let mut start = 0;
    while start < length {
        let line_len = (length - start).min(45);
        let end = start + line_len;
        out[cursor] = (32 + line_len) as u8;
        cursor += 1;
        let mut index = start;
        while index < end {
            emit_group(values, index, end, out, &mut cursor);
            index += 3;
        }
        out[cursor] = b'\n';
        cursor += 1;
        start = end;
    }
    out[cursor..cursor + TRAILER.len()].copy_from_slice(TRAILER);
    cursor += TRAILER.len();
    cursor as i64
}
