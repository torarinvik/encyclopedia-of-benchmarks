package lexicographical_numbers

import "core:c"

MAX_NUMBER :: i64(4096)
STACK_CAPACITY :: 4112

@(export)
lexicographical_numbers :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 1 || values[0] < 0 || values[0] > MAX_NUMBER do return -1
    stack: [STACK_CAPACITY]i64
    top := 1
    stack[0] = 1
    index := i64(0)
    checksum := i64(0)
    for top > 0 {
        top -= 1
        number := stack[top]
        if number <= values[0] {
            index += 1
            checksum += index * number
            if number % 10 != 9 { stack[top] = number + 1; top += 1 }
            stack[top] = number * 10
            top += 1
        }
    }
    return checksum
}
