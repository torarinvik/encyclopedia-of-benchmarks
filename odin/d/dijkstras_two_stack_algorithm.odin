package dijkstras_two_stack_algorithm

import "core:c"

INVALID_RESULT :: i64(-1_000_000_001)

apply_operator :: proc "contextless" (opcode, left, right: i64) -> i64 {
    result: i64
    if opcode == 43 {
        result = left + right
    } else if opcode == 45 {
        result = left - right
    } else if opcode == 42 {
        result = left * right
    } else if opcode == 47 {
        if right == 0 || left % right != 0 do return INVALID_RESULT
        result = left / right
    } else {
        return INVALID_RESULT
    }
    if result < -1_000_000_000 || result > 1_000_000_000 do return INVALID_RESULT
    return result
}

@(export)
dijkstras_two_stack_algorithm :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length == 0 || length > 511 do return INVALID_RESULT
    operands: [256]i64
    operators: [256]i64
    operand_top: c.size_t = 0
    operator_top: c.size_t = 0
    parentheses: c.size_t = 0
    for index := c.size_t(0); index < length; index += 1 {
        token := values[index]
        if token >= 48 && token <= 57 {
            if operand_top == 256 do return INVALID_RESULT
            operands[operand_top] = token - 48
            operand_top += 1
        } else if token == 40 {
            parentheses += 1
            if parentheses > 128 do return INVALID_RESULT
        } else if token == 43 || token == 45 || token == 42 || token == 47 {
            if operator_top == 256 do return INVALID_RESULT
            operators[operator_top] = token
            operator_top += 1
        } else if token == 41 {
            if parentheses == 0 || operator_top == 0 || operand_top < 2 do return INVALID_RESULT
            parentheses -= 1
            operator_top -= 1
            opcode := operators[operator_top]
            operand_top -= 1
            right := operands[operand_top]
            operand_top -= 1
            left := operands[operand_top]
            result := apply_operator(opcode, left, right)
            if result == INVALID_RESULT do return INVALID_RESULT
            operands[operand_top] = result
            operand_top += 1
        } else {
            return INVALID_RESULT
        }
    }
    if parentheses != 0 || operator_top != 0 || operand_top != 1 do return INVALID_RESULT
    return operands[0]
}
