package hash_xor8

import "core:c"

@(export)
hash_xor8 :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 100001 || (values == nil && length != 0) do return -1
    for i := c.size_t(0); i < length; i += 1 {
        if values[i] == 0 do break
        if values[i] < 0 || values[i] > 127 do return -1
    }
    hash := u32(0)
    for i := c.size_t(0); i < length && values[i] != 0; i += 1 {
        hash = (hash + u32(values[i])) & 0xff
    }
    return i64(((hash ^ 0xff) + 1) & 0xff)
}
