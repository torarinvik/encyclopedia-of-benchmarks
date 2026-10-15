package characters_same

import "core:c"

@(export)
characters_same :: proc "contextless" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 256 || (length > 0 && values == nil) do return -1
    for index := c.size_t(0); index < length; index += 1 {
        if values[index] < 0 || values[index] > 127 do return -1
    }
    if length == 0 do return 1
    first := values[0]
    for index := c.size_t(1); index < length; index += 1 {
        if values[index] != first do return 0
    }
    return 1
}
