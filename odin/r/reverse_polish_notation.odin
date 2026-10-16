package reverse_polish_notation

import "core:c"

MAX_INPUT_LENGTH :: 255
MAX_PARSEABLE_INPUT_LENGTH :: 256
MAX_TOKEN_COUNT :: 63
MAX_OPERAND_MAGNITUDE :: i64(1_000_000)
MAX_INTERMEDIATE_MAGNITUDE :: f64(1.0e200)
INVALID_RESULT :: f64(-1.0e300)

@(export)
reverse_polish_notation :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length == 0 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) {
        return INVALID_RESULT
    }
    if length > c.size_t(MAX_INPUT_LENGTH) { return INVALID_RESULT }
    input_length := int(length)
    for index := 0; index < input_length; index += 1 {
        if values[index] < 0 || values[index] > 127 { return INVALID_RESULT }
    }

    stack: [MAX_TOKEN_COUNT]f64
    top := 0
    position := 0
    token_count := 0
    for position < input_length {
        token_start := position
        for position < input_length && values[position] != 32 do position += 1
        token_length := position - token_start
        if token_length == 0 { return INVALID_RESULT }
        token_count += 1
        if token_count > MAX_TOKEN_COUNT { return INVALID_RESULT }

        token := values[token_start]
        is_operator := token_length == 1 &&
            (token == 43 || token == 45 || token == 42 || token == 47)
        if is_operator {
            if top < 2 { return INVALID_RESULT }
            a := stack[top - 1]
            b := stack[top - 2]
            result := f64(0)
            if token == 43 {
                result = a + b
            } else if token == 45 {
                result = a - b
            } else if token == 42 {
                result = a * b
            } else {
                if a == 0 { return INVALID_RESULT }
                result = b / a
            }
            if result != result || result < -MAX_INTERMEDIATE_MAGNITUDE ||
                result > MAX_INTERMEDIATE_MAGNITUDE { return INVALID_RESULT }
            stack[top - 2] = result
            top -= 1
        } else {
            number_position := token_start
            negative := false
            if values[number_position] == 43 || values[number_position] == 45 {
                negative = values[number_position] == 45
                number_position += 1
            }
            if number_position == position { return INVALID_RESULT }

            magnitude := i64(0)
            for number_position < position {
                byte := values[number_position]
                number_position += 1
                if byte < 48 || byte > 57 { return INVALID_RESULT }
                digit := byte - 48
                if magnitude > (MAX_OPERAND_MAGNITUDE - digit) / 10 {
                    return INVALID_RESULT
                }
                magnitude = magnitude * 10 + digit
            }
            if top >= MAX_TOKEN_COUNT { return INVALID_RESULT }
            value := f64(magnitude)
            if negative { value = -value }
            stack[top] = value
            top += 1
        }

        if position < input_length {
            position += 1
            if position == input_length || values[position] == 32 { return INVALID_RESULT }
        }
    }
    if token_count == 0 || top != 1 { return INVALID_RESULT }
    result := stack[0]
    if result != result || result < -MAX_INTERMEDIATE_MAGNITUDE ||
        result > MAX_INTERMEDIATE_MAGNITUDE { return INVALID_RESULT }
    return result
}
