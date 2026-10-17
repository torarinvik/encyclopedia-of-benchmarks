package matchdimensions

import "core:c"

@(export)
matchdimensions :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 4 do return -1
    for index := 0; index < 4; index += 1 {
        if values[index] < 0 || values[index] > 65535 do return -1
    }
    if values[0] == values[2] && values[1] == values[3] do return 1
    return 0
}
