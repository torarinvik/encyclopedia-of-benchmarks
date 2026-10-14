module postfix_evaluation;

const long INVALID_RESULT = -1000000001;

// Apply one binary operation, checking the shared result range.
fn long apply(long opcode, long left, long right)
{
    long value;
    if (opcode == 1) { value = left + right; }
    else if (opcode == 2) { value = left - right; }
    else if (opcode == 3) { value = left * right; }
    else if (opcode == 4) {
        if (right == 0) return INVALID_RESULT;
        long magnitude_left = left < 0 ? -left : left;
        long magnitude_right = right < 0 ? -right : right;
        long quotient = magnitude_left / magnitude_right;
        value = ((left < 0) != (right < 0)) ? -quotient : quotient;
    } else { return INVALID_RESULT; }
    if (value < -1000000000 || value > 1000000000) return INVALID_RESULT;
    return value;
}

fn long postfix_evaluation(long* values, usz length) @export("postfix_evaluation")
{
    if (length < 2 || length > 512 || length % 2 != 0) return INVALID_RESULT;
    usz token_count = length / 2;
    long[256] stack;
    usz top = 0;
    for (usz token = 0; token < token_count; token++) {
        long opcode = values[2 * token];
        long operand = values[2 * token + 1];
        if (opcode == 0) {
            if (operand < -1000000 || operand > 1000000) return INVALID_RESULT;
            stack[top] = operand;
            top++;
        } else {
            if (opcode < 1 || opcode > 4 || operand != 0 || top < 2) return INVALID_RESULT;
            long right = stack[top - 1];
            long left = stack[top - 2];
            top -= 2;
            long result = apply(opcode, left, right);
            if (result == INVALID_RESULT) return INVALID_RESULT;
            stack[top] = result;
            top++;
        }
    }
    if (top != 1) return INVALID_RESULT;
    return stack[0];
}
