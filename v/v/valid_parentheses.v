module valid_parentheses

fn bracket_closer(value i64) u8 {
    return match value {
        40 { u8(41) }
        91 { u8(93) }
        123 { u8(125) }
        41, 93, 125 { u8(0) }
        else { u8(255) }
    }
}

fn invalid_suffix(input &i64, start usize, length usize) i64 {
    for index in start .. length {
        if bracket_closer(unsafe { input[index] }) == 255 { return -1 }
    }
    return 0
}

fn check_brackets(input &i64, length usize, pending &u8) i64 {
    mut top := usize(0)
    for index in 0 .. length {
        value := unsafe { input[index] }
        closer := bracket_closer(value)
        if closer == 255 { return -1 }
        if closer != 0 {
            if top >= length / 2 { return invalid_suffix(input, index + 1, length) }
            unsafe { pending[top] = closer }
            top++
        } else {
            if top == 0 { return invalid_suffix(input, index + 1, length) }
            top--
            if i64(unsafe { pending[top] }) != value {
                return invalid_suffix(input, index + 1, length)
            }
        }
    }
    return if top == 0 { 1 } else { 0 }
}

// Check bracket nesting with a bounded stack.
@[export: 'valid_parentheses']
pub fn valid_parentheses(input &i64, length usize) i64 {
    if length > 256 { return -1 }
    if length == 0 { return 1 }
    if length & 1 != 0 { return invalid_suffix(input, 0, length) }
    if length <= 32 {
        mut pending := [16]u8{}
        return check_brackets(input, length, &pending[0])
    }
    mut pending := [128]u8{}
    return check_brackets(input, length, &pending[0])
}
