package elf_hash

import "core:c"

MAX_CODEPOINTS :: 8

@(export)
elf_hash :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length > MAX_CODEPOINTS || (input == nil && length != 0) do return -1
    hash: u64 = 0
    for index: c.size_t = 0; index < length; index += 1 {
        codepoint := input[index]
        if codepoint < 0 || codepoint > 127 do return -1
        hash = (hash << 4) + u64(codepoint)
        high := hash & 0xF0000000
        if high != 0 do hash = hash ^ (high >> 24)
        hash = hash ^ high
    }
    return i64(hash)
}
