package check_snake_case

import "core:c"

MAX_LENGTH :: 4096

@(export)
check_snake_case :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > c.size_t(MAX_LENGTH) || (length != 0 && values == nil) do return -2
    found := i64(0)
    for index := 0; index < int(length); index += 1 {
        value := values[index]
        if value < 32 || value > 126 do return -2
        if value == 95 do found = 1
    }
    return found
}
