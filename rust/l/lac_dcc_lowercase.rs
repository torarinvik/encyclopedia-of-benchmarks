const MAX_CHARACTERS: usize = 31;
const MAX_OUTPUT_BYTES: usize = 1 + 2 * MAX_CHARACTERS;

#[no_mangle]
pub unsafe extern "C" fn misc_lowercase(
    input: *const i64,
    input_length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || input_length < 1 || input_length > MAX_CHARACTERS + 2 { return -1; }
    let raw_length = unsafe { *input };
    if raw_length < 0 || raw_length > MAX_CHARACTERS as i64 || input_length != raw_length as usize + 1 {
        return -1;
    }
    let length = raw_length as usize;
    let mut lowered = [0_u16; MAX_CHARACTERS];
    let mut ascii_flag = 1_u8;
    for index in 0..length {
        let raw = unsafe { *input.add(index + 1) };
        if !(0..=65535).contains(&raw) { return -1; }
        let value = raw as u16;
        if value > 0x7f { ascii_flag = 0; }
        lowered[index] = if value >= b'A' as u16 && value <= b'Z' as u16 {
            value + 32
        } else {
            value
        };
    }
    let required = 1 + 2 * length;
    if output.is_null() || output_capacity < required { return -2; }
    let mut staged = [0_u8; MAX_OUTPUT_BYTES];
    staged[0] = ascii_flag;
    for index in 0..length {
        staged[1 + 2 * index] = lowered[index] as u8;
        staged[2 + 2 * index] = (lowered[index] >> 8) as u8;
    }
    for index in 0..required { unsafe { *output.add(index) = staged[index]; } }
    required as i64
}
