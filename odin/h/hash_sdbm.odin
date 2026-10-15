package hash_sdbm

import "core:c"

MAX_BYTES :: 64
HIGH_BIT :: u64(1) << 63

signed_bits :: proc "contextless" (value: u64) -> i64 {
    if value < HIGH_BIT do return i64(value)
    return (-9223372036854775807 - 1) + i64(value - HIGH_BIT)
}

@(export)
hash_sdbm :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length == 0 || length > MAX_BYTES || input == nil do return -1
    hash: u64 = 0
    for index: c.size_t = 0; index < length; index += 1 {
        byte := input[index]
        if byte < 1 || byte > 127 do return -1
        value := u64(byte)
        hash = value + (hash << 6) + (hash << 16) - hash
    }
    return signed_bits(hash)
}
