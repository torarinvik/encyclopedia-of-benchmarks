/// Evaluate bounded fully-parenthesized integer expressions with two stacks.
const INVALID_RESULT: i64 = -1_000_000_001;

fn apply_operator(opcode: i64, left: i64, right: i64) -> i64 {
    let result = match opcode {
        43 => left + right,
        45 => left - right,
        42 => left * right,
        47 => {
            if right == 0 || left % right != 0 { return INVALID_RESULT; }
            left / right
        }
        _ => return INVALID_RESULT,
    };
    if !(-1_000_000_000..=1_000_000_000).contains(&result) { INVALID_RESULT } else { result }
}

#[no_mangle]
pub unsafe extern "C" fn dijkstras_two_stack_algorithm(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length == 0 || length > 511 { return INVALID_RESULT; }
    let mut operands = [0_i64; 256];
    let mut operators = [0_i64; 256];
    let (mut operand_top, mut operator_top, mut parentheses) = (0_usize, 0_usize, 0_usize);
    for index in 0..length {
        let token = *values.add(index);
        if (48..=57).contains(&token) {
            if operand_top == 256 { return INVALID_RESULT; }
            operands[operand_top] = token - 48;
            operand_top += 1;
        } else if token == 40 {
            parentheses += 1;
            if parentheses > 128 { return INVALID_RESULT; }
        } else if [43, 45, 42, 47].contains(&token) {
            if operator_top == 256 { return INVALID_RESULT; }
            operators[operator_top] = token;
            operator_top += 1;
        } else if token == 41 {
            if parentheses == 0 || operator_top == 0 || operand_top < 2 { return INVALID_RESULT; }
            parentheses -= 1;
            operator_top -= 1;
            let opcode = operators[operator_top];
            operand_top -= 1;
            let right = operands[operand_top];
            operand_top -= 1;
            let left = operands[operand_top];
            let result = apply_operator(opcode, left, right);
            if result == INVALID_RESULT { return INVALID_RESULT; }
            operands[operand_top] = result;
            operand_top += 1;
        } else { return INVALID_RESULT; }
    }
    if parentheses != 0 || operator_top != 0 || operand_top != 1 { return INVALID_RESULT; }
    operands[0]
}
