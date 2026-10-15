/// Shunting-yard conversion with right-associative exponentiation.
const MAX_EXPRESSION: usize = 256;
const MAX_OUTPUT: usize = 512;

fn is_operand(ch: i64) -> bool {
    (48..=57).contains(&ch) || (65..=90).contains(&ch) || (97..=122).contains(&ch)
}
fn is_operator(ch: i64) -> bool { matches!(ch, 43 | 45 | 42 | 47 | 94) }
fn precedence(ch: i64) -> i64 {
    if ch == 43 || ch == 45 { 1 } else if ch == 42 || ch == 47 { 2 } else { 3 }
}
fn emit_token(result: &mut [u8; MAX_OUTPUT], count: &mut usize, token: u8) {
    if *count > 0 { result[*count] = b' '; *count += 1; }
    result[*count] = token;
    *count += 1;
}

#[no_mangle]
pub extern "C" fn infix_to_postfix_conversion(input: *const i64, length: usize,
                                                output: *mut u8, output_capacity: usize) -> i64 {
    if input.is_null() || length < 1 { return -1; }
    let expression_length = unsafe { *input };
    if expression_length < 0 || expression_length > MAX_EXPRESSION as i64 ||
        length != 1 + expression_length as usize { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    let mut stack = [0u8; MAX_EXPRESSION];
    let mut result = [0u8; MAX_OUTPUT];
    let mut top = 0usize;
    let mut count = 0usize;
    let mut expect_operand = true;
    for &ch in &input[1..] {
        if is_operand(ch) {
            if !expect_operand { return -1; }
            emit_token(&mut result, &mut count, ch as u8);
            expect_operand = false;
        } else if ch == 40 {
            if !expect_operand || top == MAX_EXPRESSION { return -1; }
            stack[top] = b'('; top += 1;
        } else if ch == 41 {
            if expect_operand { return -1; }
            while top > 0 && stack[top - 1] != b'(' {
                top -= 1;
                emit_token(&mut result, &mut count, stack[top]);
            }
            if top == 0 { return -1; }
            top -= 1;
            expect_operand = false;
        } else if is_operator(ch) {
            if expect_operand { return -1; }
            while top > 0 && stack[top - 1] != b'(' &&
                (precedence(ch) < precedence(stack[top - 1] as i64) ||
                 (precedence(ch) == precedence(stack[top - 1] as i64) && ch != 94)) {
                top -= 1;
                emit_token(&mut result, &mut count, stack[top]);
            }
            if top == MAX_EXPRESSION { return -1; }
            stack[top] = ch as u8; top += 1;
            expect_operand = true;
        } else { return -1; }
    }
    if expression_length != 0 && expect_operand { return -1; }
    while top > 0 {
        top -= 1;
        if stack[top] == b'(' { return -1; }
        emit_token(&mut result, &mut count, stack[top]);
    }
    result[count] = 0; count += 1;
    if output.is_null() || output_capacity < count { return -2; }
    unsafe { std::ptr::copy_nonoverlapping(result.as_ptr(), output, count); }
    count as i64
}
