const MAX_INPUT_LENGTH: usize = 64;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 65;
const INVALID_RESULT: i64 = -2_147_483_649;

#[no_mangle]
pub unsafe extern "C" fn hexa_decimal_to_decimal(input: *const i64, length: usize) -> i64 {
    if length > MAX_PARSEABLE_INPUT_LENGTH { return INVALID_RESULT; }
    if length == 0 { return 0; }
    if length > MAX_INPUT_LENGTH || input.is_null() { return INVALID_RESULT; }

    let mut accumulator = 0_u64;
    for index in 0..length {
        let code = *input.add(index);
        let digit = if (48..=57).contains(&code) { code - 48 }
            else if (65..=70).contains(&code) { code - 55 }
            else if (97..=102).contains(&code) { code - 87 }
            else { return INVALID_RESULT };
        accumulator = (accumulator * 16 + digit as u64) % (1_u64 << 32);
    }
    if accumulator <= i32::MAX as u64 { return accumulator as i64; }
    accumulator as i64 - (1_i64 << 32)
}
