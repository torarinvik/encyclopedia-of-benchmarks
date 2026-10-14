/// Evaluate bounded integer postfix expressions with an explicit operand stack.
const INVALID_RESULT: i64 = -1_000_000_001;

fn apply_operator(opcode: i64, left: i64, right: i64) -> i64 {
    let value = match opcode {
        1 => left + right,
        2 => left - right,
        3 => left * right,
        4 => {
            if right == 0 { return INVALID_RESULT; }
            let magnitude_left = if left < 0 { -left } else { left };
            let magnitude_right = if right < 0 { -right } else { right };
            let quotient = magnitude_left / magnitude_right;
            if (left < 0) != (right < 0) { -quotient } else { quotient }
        }
        _ => return INVALID_RESULT,
    };
    if !(-1_000_000_000..=1_000_000_000).contains(&value) { INVALID_RESULT } else { value }
}

#[no_mangle]
pub unsafe extern "C" fn postfix_evaluation(values: *const i64, length: usize) -> i64 {
    if length < 2 || length > 512 || length % 2 != 0 { return INVALID_RESULT; }
    let token_count = length / 2;
    let mut stack = [0_i64; 256];
    let mut top = 0;
    for token in 0..token_count {
        let opcode = *values.add(2 * token);
        let operand = *values.add(2 * token + 1);
        if opcode == 0 {
            if !(-1_000_000..=1_000_000).contains(&operand) { return INVALID_RESULT; }
            stack[top] = operand;
            top += 1;
        } else {
            if !(1..=4).contains(&opcode) || operand != 0 || top < 2 { return INVALID_RESULT; }
            top -= 1;
            let right = stack[top];
            top -= 1;
            let left = stack[top];
            let result = apply_operator(opcode, left, right);
            if result == INVALID_RESULT { return INVALID_RESULT; }
            stack[top] = result;
            top += 1;
        }
    }
    if top != 1 { return INVALID_RESULT; }
    stack[0]
}
