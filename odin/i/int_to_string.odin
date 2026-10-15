package int_to_string

import "core:c"

MAX_VALUE :: 65535

@(export)
int_to_string :: proc "c" (packed: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if packed < 0 do return -1
    value := packed / 15
    base := packed % 15 + 2
    if value > MAX_VALUE do return -1
    symbols := "0123456789abcdef"
    digits: [16]u8
    count := 0
    remaining := value
    for {
        digits[count] = symbols[remaining % base]
        count += 1
        remaining /= base
        if remaining == 0 do break
    }
    required := count + 1
    if output == nil || output_capacity < c.size_t(required) do return -2
    for index := 0; index < count; index += 1 { output[index] = digits[count-index-1] }
    output[count] = 0
    return i64(required)
}
