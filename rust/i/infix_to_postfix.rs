/// Convert a bounded ASCII infix expression with the source's operator stack.
const MAX_EXPRESSION: usize = 24;
const MAX_STACK: usize = 10;
fn is_operand(ch: i64) -> bool { (48..=57).contains(&ch) || (65..=90).contains(&ch) || (97..=122).contains(&ch) }
fn is_operator(ch: i64) -> bool { matches!(ch, 43 | 45 | 42 | 47 | 94) }
fn precedence(ch: i64) -> i64 { if matches!(ch, 43 | 45) { 1 } else if matches!(ch, 42 | 47) { 2 } else { 3 } }

#[no_mangle]
pub unsafe extern "C" fn infix_to_postfix(input: *const i64, length: usize,
                                               output: *mut u8, capacity: usize) -> i64 {
    if input.is_null() || length == 0 || length > MAX_EXPRESSION { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let mut stack = [0u8; MAX_STACK];
    let mut result = [0u8; MAX_EXPRESSION + 1];
    let (mut top, mut count) = (0usize, 0usize);
    let mut expect_operand = true;
    for &ch in values {
        if is_operand(ch) {
            if !expect_operand { return -1; }
            result[count] = ch as u8; count += 1; expect_operand = false;
        } else if ch == 40 {
            if !expect_operand || top == MAX_STACK { return -1; }
            stack[top] = b'('; top += 1;
        } else if ch == 41 {
            while top > 0 && stack[top - 1] != b'(' { top -= 1; result[count] = stack[top]; count += 1; }
            if top > 0 { top -= 1; }
            expect_operand = false;
        } else if is_operator(ch) {
            if expect_operand { return -1; }
            while top > 0 && stack[top - 1] != b'(' && precedence(ch) <= precedence(stack[top - 1] as i64) {
                top -= 1; result[count] = stack[top]; count += 1;
            }
            if top == MAX_STACK { return -1; }
            stack[top] = ch as u8; top += 1; expect_operand = true;
        } else { return -1; }
    }
    if expect_operand { return -1; }
    while top > 0 {
        top -= 1;
        if stack[top] == b'(' { return -1; }
        result[count] = stack[top]; count += 1;
    }
    result[count] = 0; count += 1;
    if output.is_null() || capacity < count { return -2; }
    std::ptr::copy_nonoverlapping(result.as_ptr(), output, count);
    count as i64
}
