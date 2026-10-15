/// Check bracket nesting with a bounded stack.
#[no_mangle]
pub unsafe extern "C" fn valid_parentheses(input: *const i64, length: usize) -> i64 {
    if length > 256 || (length != 0 && input.is_null()) { return -1; }
    for index in 0..length {
        let value = *input.add(index);
        if ![40, 41, 91, 93, 123, 125].contains(&value) { return -1; }
    }
    let mut stack = [0u8; 256];
    let mut top = 0usize;
    for index in 0..length {
        let value = *input.add(index) as u8;
        if value == b'(' || value == b'[' || value == b'{' {
            stack[top] = value;
            top += 1;
        } else {
            if top == 0 { return 0; }
            top -= 1;
            let expected = if value == b')' { b'(' } else if value == b']' { b'[' } else { b'{' };
            if stack[top] != expected { return 0; }
        }
    }
    if top == 0 { 1 } else { 0 }
}
