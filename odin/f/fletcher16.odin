package fletcher16

import "core:c"

MAX_BYTES :: 4096

@(export)
fletcher16 :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length > MAX_BYTES || (length != 0 && input == nil) do return -1
    sum1: u32 = 0
    sum2: u32 = 0
    for index: c.size_t = 0; index < length; index += 1 {
        byte := input[index]
        if byte < 0 || byte > 127 do return -1
        sum1 = (sum1 + u32(byte)) % 255
        sum2 = (sum2 + sum1) % 255
    }
    return i64((sum2 << 8) | sum1)
}
