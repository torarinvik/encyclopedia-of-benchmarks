package infix_to_postfix

import "core:c"

MAX_EXPRESSION :: 24
MAX_STACK :: 10

is_operand :: proc "contextless" (ch: i64) -> bool {
    return (ch >= 48 && ch <= 57) || (ch >= 65 && ch <= 90) || (ch >= 97 && ch <= 122)
}
is_operator :: proc "contextless" (ch: i64) -> bool {
    return ch == 43 || ch == 45 || ch == 42 || ch == 47 || ch == 94
}
precedence :: proc "contextless" (ch: i64) -> i64 {
    if ch == 43 || ch == 45 do return 1
    if ch == 42 || ch == 47 do return 2
    return 3
}

@(export)
infix_to_postfix :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length == 0 || length > MAX_EXPRESSION do return -1
    stack: [MAX_STACK]u8
    result: [MAX_EXPRESSION + 1]u8
    top, count: int = 0, 0
    expect_operand := true
    for index: c.size_t = 0; index < length; index += 1 {
        ch := input[index]
        if is_operand(ch) {
            if !expect_operand do return -1
            result[count] = u8(ch); count += 1; expect_operand = false
        } else if ch == 40 {
            if !expect_operand || top == MAX_STACK do return -1
            stack[top] = 40; top += 1
        } else if ch == 41 {
            for top > 0 && stack[top-1] != 40 {
                top -= 1; result[count] = stack[top]; count += 1
            }
            if top > 0 do top -= 1
            expect_operand = false
        } else if is_operator(ch) {
            if expect_operand do return -1
            for top > 0 && stack[top-1] != 40 && precedence(ch) <= precedence(i64(stack[top-1])) {
                top -= 1; result[count] = stack[top]; count += 1
            }
            if top == MAX_STACK do return -1
            stack[top] = u8(ch); top += 1; expect_operand = true
        } else do return -1
    }
    if expect_operand do return -1
    for top > 0 {
        top -= 1
        if stack[top] == 40 do return -1
        result[count] = stack[top]; count += 1
    }
    result[count] = 0; count += 1
    if output == nil || output_capacity < c.size_t(count) do return -2
    for index := 0; index < count; index += 1 { output[index] = result[index] }
    return i64(count)
}
