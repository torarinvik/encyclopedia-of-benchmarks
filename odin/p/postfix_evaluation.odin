package postfix_evaluation

import "core:c"

INVALID_RESULT :: i64(-1000000001)

apply_operator :: proc "contextless" (opcode, left, right: i64) -> i64 {
    value: i64
    if opcode == 1 {
        value = left + right
    } else if opcode == 2 {
        value = left - right
    } else if opcode == 3 {
        value = left * right
    } else if opcode == 4 {
        if right == 0 do return INVALID_RESULT
        magnitude_left := left
        magnitude_right := right
        if magnitude_left < 0 do magnitude_left = -magnitude_left
        if magnitude_right < 0 do magnitude_right = -magnitude_right
        quotient := magnitude_left / magnitude_right
        value = quotient
        if (left < 0) != (right < 0) do value = -quotient
    } else {
        return INVALID_RESULT
    }
    if value < -1000000000 || value > 1000000000 do return INVALID_RESULT
    return value
}

@(export)
postfix_evaluation :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length < 2 || length > 512 || length % 2 != 0 do return INVALID_RESULT
    token_count := length / 2
    stack: [256]i64
    top: c.size_t = 0
    for token := c.size_t(0); token < token_count; token += 1 {
        opcode := values[2 * token]
        operand := values[2 * token + 1]
        if opcode == 0 {
            if operand < -1000000 || operand > 1000000 do return INVALID_RESULT
            stack[top] = operand
            top += 1
        } else {
            if opcode < 1 || opcode > 4 || operand != 0 || top < 2 do return INVALID_RESULT
            right := stack[top - 1]
            left := stack[top - 2]
            top -= 2
            result := apply_operator(opcode, left, right)
            if result == INVALID_RESULT do return INVALID_RESULT
            stack[top] = result
            top += 1
        }
    }
    if top != 1 do return INVALID_RESULT
    return stack[0]
}
