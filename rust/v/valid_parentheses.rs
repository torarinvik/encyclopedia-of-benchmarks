fn bracket_closer(value: i64) -> u8 {
    match value {
        40 => b')',
        91 => b']',
        123 => b'}',
        41 | 93 | 125 => 0,
        _ => u8::MAX,
    }
}

fn invalid_suffix(input: &[i64]) -> i64 {
    if input.iter().any(|&value| bracket_closer(value) == u8::MAX) { -1 } else { 0 }
}

fn check_brackets(input: &[i64], pending: &mut [u8]) -> i64 {
    let mut top = 0;
    for (index, &value) in input.iter().enumerate() {
        match bracket_closer(value) {
            u8::MAX => return -1,
            0 => {
                if top == 0 || i64::from(pending[top - 1]) != value {
                    return invalid_suffix(&input[index + 1..]);
                }
                top -= 1;
            }
            closer => {
                if top >= input.len() / 2 {
                    return invalid_suffix(&input[index + 1..]);
                }
                pending[top] = closer;
                top += 1;
            }
        }
    }
    i64::from(top == 0)
}

/// Check bracket nesting with a bounded stack.
#[no_mangle]
pub unsafe extern "C" fn valid_parentheses(input: *const i64, length: usize) -> i64 {
    if length > 256 || (length != 0 && input.is_null()) { return -1; }
    if length == 0 { return 1; }
    let values = std::slice::from_raw_parts(input, length);
    if length & 1 != 0 { return invalid_suffix(values); }
    if length <= 32 {
        return check_brackets(values, &mut [0; 16]);
    }
    check_brackets(values, &mut [0; 128])
}
