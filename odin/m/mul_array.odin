package mul_array

import "core:c"

MAX_INPUT_LENGTH :: 9

@(export)
mul_array :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > MAX_INPUT_LENGTH do return -1
    if length == 0 do return 1
    if values == nil do return -1

    product := i64(1)
    for index := 0; index < int(length); index += 1 {
        value := values[index]
        if value < 0 || value > 99 do return -1
        product *= value
    }
    return product
}
