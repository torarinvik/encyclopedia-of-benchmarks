package rgbhex

import "core:c"

@(export)
rgbhex :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != 4 do return -1
    op, x, y, z := input[0], input[1], input[2], input[3]
    if op == 0 {
        if x < 0 || x > 4294967295 || y != 0 || z != 0 do return -1
        return x & 0x00ffffff
    }
    if op == 1 {
        if x < 0 || x > 255 || y < 0 || y > 255 || z < 0 || z > 255 do return -1
        return (x << 16) | (y << 8) | z
    }
    return -1
}
