module main

const max_input_length = 255
const max_parseable_input_length = 256
const max_token_count = 63
const max_operand_magnitude = i64(1_000_000)
const max_intermediate_magnitude = f64(1.0e200)
const invalid_result = f64(-1.0e300)

@[export: 'reverse_polish_notation']
pub fn reverse_polish_notation(input &i64, length usize) f64 {
    unsafe {
        if input == nil || length == 0 || length > max_parseable_input_length {
            return invalid_result
        }
        if length > max_input_length {
            return invalid_result
        }
        for index in 0 .. int(length) {
            if input[index] < 0 || input[index] > 127 {
                return invalid_result
            }
        }

        mut stack := []f64{len: max_token_count, init: 0.0}
        mut top := 0
        mut position := 0
        mut token_count := 0
        for position < int(length) {
            token_start := position
            for position < int(length) && input[position] != 32 {
                position++
            }
            token_length := position - token_start
            if token_length == 0 {
                return invalid_result
            }
            token_count++
            if token_count > max_token_count {
                return invalid_result
            }

            token := input[token_start]
            is_operator := token_length == 1 &&
                (token == 43 || token == 45 || token == 42 || token == 47)
            if is_operator {
                if top < 2 {
                    return invalid_result
                }
                a := stack[top - 1]
                b := stack[top - 2]
                mut result := f64(0.0)
                if token == 43 {
                    result = a + b
                } else if token == 45 {
                    result = a - b
                } else if token == 42 {
                    result = a * b
                } else {
                    if a == 0.0 {
                        return invalid_result
                    }
                    result = b / a
                }
                if result != result || result < -max_intermediate_magnitude ||
                    result > max_intermediate_magnitude {
                    return invalid_result
                }
                stack[top - 2] = result
                top--
            } else {
                mut number_position := token_start
                mut negative := false
                if input[number_position] == 43 || input[number_position] == 45 {
                    negative = input[number_position] == 45
                    number_position++
                }
                if number_position == position {
                    return invalid_result
                }

                mut magnitude := i64(0)
                for number_position < position {
                    byte := input[number_position]
                    number_position++
                    if byte < 48 || byte > 57 {
                        return invalid_result
                    }
                    digit := byte - 48
                    if magnitude > (max_operand_magnitude - digit) / 10 {
                        return invalid_result
                    }
                    magnitude = magnitude * 10 + digit
                }
                if top >= max_token_count {
                    return invalid_result
                }
                mut value := f64(magnitude)
                if negative {
                    value = -value
                }
                stack[top] = value
                top++
            }

            if position < int(length) {
                position++
                if position == int(length) || input[position] == 32 {
                    return invalid_result
                }
            }
        }
        if token_count == 0 || top != 1 {
            return invalid_result
        }
        result := stack[0]
        if result != result || result < -max_intermediate_magnitude ||
            result > max_intermediate_magnitude {
            return invalid_result
        }
        return result
    }
}
