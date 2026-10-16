package find_min_iterator

import "core:c"

@(export)
find_min_iterator :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 129 do return -1
    if input[0] < 0 || input[0] > 128 || length != c.size_t(input[0]) + 1 do return -1
    count := int(input[0])
    if count == 0 do return -1
    minimum: i64 = 2_147_483_647
    for i := 0; i < count; i += 1 {
        value := input[i + 1]
        if value < 0 || value > 2_147_483_647 do return -1
        if value < minimum do minimum = value
    }
    return minimum
}
