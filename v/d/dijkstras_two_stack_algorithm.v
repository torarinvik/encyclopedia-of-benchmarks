module dijkstras_two_stack_algorithm

const invalid_result = -1_000_000_001

fn apply_operator(opcode i64, left i64, right i64) i64 {
    mut result := i64(0)
    if opcode == 43 {
        result = left + right
    } else if opcode == 45 {
        result = left - right
    } else if opcode == 42 {
        result = left * right
    } else if opcode == 47 {
        if right == 0 || left % right != 0 { return invalid_result }
        result = left / right
    } else {
        return invalid_result
    }
    if result < -1_000_000_000 || result > 1_000_000_000 { return invalid_result }
    return result
}

@[export: 'dijkstras_two_stack_algorithm']
pub fn dijkstras_two_stack_algorithm(values &i64, length usize) i64 {
    if length == 0 || length > 511 { return invalid_result }
    mut operands := [256]i64{init: 0}
    mut operators := [256]i64{init: 0}
    mut operand_top := 0
    mut operator_top := 0
    mut parentheses := 0
    for index in 0 .. length {
        token := unsafe { values[index] }
        if token >= 48 && token <= 57 {
            if operand_top == 256 { return invalid_result }
            operands[operand_top] = token - 48
            operand_top++
        } else if token == 40 {
            parentheses++
            if parentheses > 128 { return invalid_result }
        } else if token == 43 || token == 45 || token == 42 || token == 47 {
            if operator_top == 256 { return invalid_result }
            operators[operator_top] = token
            operator_top++
        } else if token == 41 {
            if parentheses == 0 || operator_top == 0 || operand_top < 2 { return invalid_result }
            parentheses--
            operator_top--
            opcode := operators[operator_top]
            operand_top--
            right := operands[operand_top]
            operand_top--
            left := operands[operand_top]
            result := apply_operator(opcode, left, right)
            if result == invalid_result { return invalid_result }
            operands[operand_top] = result
            operand_top++
        } else {
            return invalid_result
        }
    }
    if parentheses != 0 || operator_top != 0 || operand_top != 1 { return invalid_result }
    return operands[0]
}
