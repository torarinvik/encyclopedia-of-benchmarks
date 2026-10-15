package balanced_parentheses

import "core:c"

// Check (), [], and {} nesting; ignore other character codes.
@(export)
balanced_parentheses :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 do return -1
    stack: [4096]i64
    top := c.size_t(0)
    for index := c.size_t(0); index < length; index += 1 {
        value := values[index]
        if value == 40 || value == 91 || value == 123 {
            stack[top] = value
            top += 1
        } else if value == 41 || value == 93 || value == 125 {
            if top == 0 do return 0
            top -= 1
            opener := stack[top]
            if (value == 41 && opener != 40) || (value == 93 && opener != 91) || (value == 125 && opener != 123) do return 0
        }
    }
    return i64(top == 0)
}
