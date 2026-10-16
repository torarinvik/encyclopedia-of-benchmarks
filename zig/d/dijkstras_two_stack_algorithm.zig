/// Evaluate bounded fully-parenthesized integer expressions with two stacks.
const invalid_result: i64 = -1_000_000_001;

fn applyOperator(opcode: i64, left: i64, right: i64) i64 {
    var result: i64 = undefined;
    switch (opcode) {
        43 => result = left + right,
        45 => result = left - right,
        42 => result = left * right,
        47 => {
            if (right == 0 or @rem(left, right) != 0) return invalid_result;
            result = @divTrunc(left, right);
        },
        else => return invalid_result,
    }
    if (result < -1_000_000_000 or result > 1_000_000_000) return invalid_result;
    return result;
}

export fn dijkstras_two_stack_algorithm(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 511) return invalid_result;
    var operands: [256]i64 = undefined;
    var operators: [256]i64 = undefined;
    var operand_top: usize = 0;
    var operator_top: usize = 0;
    var parentheses: usize = 0;
    for (0..length) |index| {
        const token = values[index];
        if (token >= 48 and token <= 57) {
            if (operand_top == 256) return invalid_result;
            operands[operand_top] = token - 48;
            operand_top += 1;
        } else if (token == 40) {
            parentheses += 1;
            if (parentheses > 128) return invalid_result;
        } else if (token == 43 or token == 45 or token == 42 or token == 47) {
            if (operator_top == 256) return invalid_result;
            operators[operator_top] = token;
            operator_top += 1;
        } else if (token == 41) {
            if (parentheses == 0 or operator_top == 0 or operand_top < 2) return invalid_result;
            parentheses -= 1;
            operator_top -= 1;
            const opcode = operators[operator_top];
            operand_top -= 1;
            const right = operands[operand_top];
            operand_top -= 1;
            const left = operands[operand_top];
            const result = applyOperator(opcode, left, right);
            if (result == invalid_result) return invalid_result;
            operands[operand_top] = result;
            operand_top += 1;
        } else return invalid_result;
    }
    if (parentheses != 0 or operator_top != 0 or operand_top != 1) return invalid_result;
    return operands[0];
}
