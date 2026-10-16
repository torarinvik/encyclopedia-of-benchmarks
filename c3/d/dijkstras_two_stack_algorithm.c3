module dijkstras_two_stack_algorithm;

const long INVALID_RESULT = -1000000001;

fn long apply_operator(long opcode, long left, long right)
{
    long result;
    if (opcode == '+') result = left + right;
    else if (opcode == '-') result = left - right;
    else if (opcode == '*') result = left * right;
    else if (opcode == '/') {
        if (right == 0 || left % right != 0) return INVALID_RESULT;
        result = left / right;
    } else return INVALID_RESULT;
    if (result < -1000000000 || result > 1000000000) return INVALID_RESULT;
    return result;
}

fn long dijkstras_two_stack_algorithm(long* values, usz length) @export("dijkstras_two_stack_algorithm")
{
    if (values == null || length == 0 || length > 511) return INVALID_RESULT;
    long[256] operands, operators;
    usz operand_top = 0, operator_top = 0, parentheses = 0;
    for (usz index = 0; index < length; index++) {
        long token = values[index];
        if (token >= '0' && token <= '9') {
            if (operand_top == 256) return INVALID_RESULT;
            operands[operand_top++] = token - '0';
        } else if (token == '(') {
            parentheses++;
            if (parentheses > 128) return INVALID_RESULT;
        } else if (token == '+' || token == '-' || token == '*' || token == '/') {
            if (operator_top == 256) return INVALID_RESULT;
            operators[operator_top++] = token;
        } else if (token == ')') {
            if (parentheses == 0 || operator_top == 0 || operand_top < 2) return INVALID_RESULT;
            parentheses--;
            long opcode = operators[--operator_top];
            long right = operands[--operand_top];
            long left = operands[--operand_top];
            long result = apply_operator(opcode, left, right);
            if (result == INVALID_RESULT) return INVALID_RESULT;
            operands[operand_top++] = result;
        } else return INVALID_RESULT;
    }
    if (parentheses != 0 || operator_top != 0 || operand_top != 1) return INVALID_RESULT;
    return operands[0];
}
