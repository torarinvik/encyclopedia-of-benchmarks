module postfix_evaluation

const invalid_result = -1000000001

fn apply_operator(opcode i64, left i64, right i64) i64 {
    mut value := i64(0)
    if opcode == 1 {
        value = left + right
    } else if opcode == 2 {
        value = left - right
    } else if opcode == 3 {
        value = left * right
    } else if opcode == 4 {
        if right == 0 { return invalid_result }
        mut magnitude_left := left
        mut magnitude_right := right
        if magnitude_left < 0 { magnitude_left = -magnitude_left }
        if magnitude_right < 0 { magnitude_right = -magnitude_right }
        quotient := magnitude_left / magnitude_right
        value = quotient
        if (left < 0) != (right < 0) { value = -quotient }
    } else {
        return invalid_result
    }
    if value < -1000000000 || value > 1000000000 { return invalid_result }
    return value
}

@[export: 'postfix_evaluation']
pub fn postfix_evaluation(values &i64, length usize) i64 {
    if length < 2 || length > 512 || length % 2 != 0 { return invalid_result }
    token_count := length / 2
    mut stack := [256]i64{init: 0}
    mut top := 0
    for token in 0 .. token_count {
        opcode := unsafe { values[2 * token] }
        operand := unsafe { values[2 * token + 1] }
        if opcode == 0 {
            if operand < -1000000 || operand > 1000000 { return invalid_result }
            stack[top] = operand
            top++
        } else {
            if opcode < 1 || opcode > 4 || operand != 0 || top < 2 { return invalid_result }
            right := stack[top - 1]
            left := stack[top - 2]
            top -= 2
            result := apply_operator(opcode, left, right)
            if result == invalid_result { return invalid_result }
            stack[top] = result
            top++
        }
    }
    if top != 1 { return invalid_result }
    return stack[0]
}
