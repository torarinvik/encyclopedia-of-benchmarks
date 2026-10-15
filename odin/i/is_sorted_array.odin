package is_sorted_array

import "core:c"

MAX_LENGTH :: 100000
MAX_SAFE_INTEGER :: i64(9007199254740991)

@(export)
is_sorted_array :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > c.size_t(MAX_LENGTH) || (length != 0 && values == nil) do return -1
    for index := 0; index < int(length); index += 1 {
        value := values[index]
        if value < -MAX_SAFE_INTEGER || value > MAX_SAFE_INTEGER do return -1
    }
    for index := 0; index + 1 < int(length); index += 1 {
        if values[index] >= values[index + 1] do return 0
    }
    return 1
}
