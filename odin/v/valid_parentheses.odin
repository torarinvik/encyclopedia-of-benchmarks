package valid_parentheses

import "core:c"

// Check bracket nesting with a bounded stack.
@(export)
valid_parentheses :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length > 256 do return -1
    for index := 0; index < int(length); index += 1 {
        value := input[index]
        if value != 40 && value != 41 && value != 91 && value != 93 && value != 123 && value != 125 do return -1
    }
    stack: [256]u8 = {}
    top := 0
    for index := 0; index < int(length); index += 1 {
        value := u8(input[index])
        if value == u8('(') || value == u8('[') || value == u8('{') {
            stack[top] = value
            top += 1
        } else {
            if top == 0 do return 0
            top -= 1
            expected := u8('{')
            if value == u8(')') do expected = u8('(')
            if value == u8(']') do expected = u8('[')
            if stack[top] != expected do return 0
        }
    }
    if top == 0 do return 1
    return 0
}
