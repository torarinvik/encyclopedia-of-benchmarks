const MAX_APPEND_COUNT: i64 = 4096;
const MAX_TEXT_BYTES: usize = MAX_APPEND_COUNT as usize * 6;

#[no_mangle]
pub unsafe extern "C" fn shootout_strcat(
    append_count: i64,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if !(0..=MAX_APPEND_COUNT).contains(&append_count) { return -1; }
    let mut text = [0_u8; MAX_TEXT_BYTES + 1];
    let mut length = 0_usize;
    let mut buffer_capacity = 32_usize;
    const SUFFIX: [u8; 6] = *b"hello\n";
    for _ in 0..append_count {
        if buffer_capacity - length < SUFFIX.len() + 1 { buffer_capacity *= 2; }
        for (index, byte) in SUFFIX.iter().enumerate() { text[length + index] = *byte; }
        length += SUFFIX.len();
        text[length] = 0;
    }
    let mut staged = [0_u8; 6];
    let mut reversed = [0_u8; 5];
    let mut digit_count = 0_usize;
    let mut output_length = 0_usize;
    let mut value = length;
    loop {
        reversed[digit_count] = b'0' + (value % 10) as u8;
        digit_count += 1;
        value /= 10;
        if value == 0 { break; }
    }
    while digit_count > 0 {
        digit_count -= 1;
        staged[output_length] = reversed[digit_count];
        output_length += 1;
    }
    staged[output_length] = b'\n';
    output_length += 1;
    if output.is_null() || output_capacity < output_length { return -2; }
    for index in 0..output_length { *output.add(index) = staged[index]; }
    output_length as i64
}
