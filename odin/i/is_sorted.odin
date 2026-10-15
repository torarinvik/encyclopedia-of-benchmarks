package is_sorted

import "core:c"

@(export)
is_sorted :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 || (length > 0 && values == nil) do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if values[index] < -2147483648 || values[index] > 2147483647 do return -1
    }
    for index := c.size_t(1); index < length; index += 1 {
        if values[index] < values[index - 1] do return 0
    }
    return 1
}
