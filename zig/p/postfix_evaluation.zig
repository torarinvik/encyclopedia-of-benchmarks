/// Evaluate bounded integer postfix expressions with an explicit operand stack.
const invalid_result: i64 = -1_000_000_001;

fn applyOperator(opcode: i64, left: i64, right: i64) i64 {
    var value: i64 = undefined;
    switch (opcode) {
        1 => value = left + right,
        2 => value = left - right,
        3 => value = left * right,
        4 => {
            if (right == 0) return invalid_result;
            const magnitude_left = if (left < 0) -left else left;
            const magnitude_right = if (right < 0) -right else right;
            const quotient = @divTrunc(magnitude_left, magnitude_right);
            value = if ((left < 0) != (right < 0)) -quotient else quotient;
        },
        else => return invalid_result,
    }
    if (value < -1_000_000_000 or value > 1_000_000_000) return invalid_result;
    return value;
}

export fn postfix_evaluation(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 512 or length % 2 != 0) return invalid_result;
    const token_count = length / 2;
    var stack: [256]i64 = undefined;
    var top: usize = 0;
    for (0..token_count) |token| {
        const opcode = values[2 * token];
        const operand = values[2 * token + 1];
        if (opcode == 0) {
            if (operand < -1_000_000 or operand > 1_000_000) return invalid_result;
            stack[top] = operand;
            top += 1;
        } else {
            if (opcode < 1 or opcode > 4 or operand != 0 or top < 2) return invalid_result;
            top -= 1;
            const right = stack[top];
            top -= 1;
            const left = stack[top];
            const result = applyOperator(opcode, left, right);
            if (result == invalid_result) return invalid_result;
            stack[top] = result;
            top += 1;
        }
    }
    if (top != 1) return invalid_result;
    return stack[0];
}
