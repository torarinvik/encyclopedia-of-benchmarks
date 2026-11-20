package pratt_expression_evaluation

import "core:c"

INVALID_RESULT :: i64(-9223372036854775807 - 1)
MAX_TOKENS :: 15

Pratt_Parser :: struct {
    input: [^]i64,
    count: c.size_t,
    position: c.size_t,
    invalid: bool,
}

parse_expression :: proc(parser: ^Pratt_Parser, minimum_binding_power: i64) -> i64 {
    if parser.position >= parser.count {
        parser.invalid = true
        return 0
    }
    offset := c.size_t(1) + 2 * parser.position
    parser.position += 1
    kind := parser.input[offset]
    left: i64
    if kind == 1 {
        left = parser.input[offset + 1]
    } else if kind == 3 {
        left = -parse_expression(parser, 25)
    } else if kind == 5 {
        left = parse_expression(parser, 0)
        if parser.invalid || parser.position >= parser.count ||
            parser.input[1 + 2 * parser.position] != 6 {
            parser.invalid = true
            return 0
        }
        parser.position += 1
    } else {
        parser.invalid = true
        return 0
    }
    if parser.invalid do return 0

    for parser.position < parser.count {
        operator := parser.input[1 + 2 * parser.position]
        binding_power: i64 = -1
        if operator == 2 || operator == 3 {
            binding_power = 10
        } else if operator == 4 {
            binding_power = 20
        }
        if binding_power < minimum_binding_power do break
        parser.position += 1
        right := parse_expression(parser, binding_power + 1)
        if parser.invalid do return 0
        if operator == 2 {
            left += right
        } else if operator == 3 {
            left -= right
        } else {
            left *= right
        }
    }
    return left
}

@(export)
pratt_expression_evaluation :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 32 do return INVALID_RESULT
    count_value := input[0]
    if count_value < 1 || count_value > MAX_TOKENS do return INVALID_RESULT
    count := c.size_t(count_value)
    if length != 1 + 2 * count do return INVALID_RESULT
    for token := c.size_t(0); token < count; token += 1 {
        kind := input[1 + 2 * token]
        payload := input[2 + 2 * token]
        if kind == 1 {
            if payload < 0 || payload > 9 do return INVALID_RESULT
        } else if kind >= 2 && kind <= 6 {
            if payload != 0 do return INVALID_RESULT
        } else {
            return INVALID_RESULT
        }
    }
    parser := Pratt_Parser{input, count, 0, false}
    result := parse_expression(&parser, 0)
    if parser.invalid || parser.position != count do return INVALID_RESULT
    return result
}
