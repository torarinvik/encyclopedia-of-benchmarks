package hyperloglog_raw_estimate

import "core:c"

gcd :: proc(a0, b0: u64) -> u64 {
    a, b := a0, b0
    for b != 0 { r := a % b; a = b; b = r }
    return a
}

@(export)
hyperloglog_raw_estimate :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 130 do return -1
    raw := input[0]
    if raw < 0 || raw > 128 || length != c.size_t(raw+1) do return -1
    registers: [16]u32
    for i := 0; i < int(raw); i += 1 {
        value := input[i+1]
        if value < 0 || value > 4294967295 do return -1
        hash := u32(value)
        bucket := int(hash >> 28)
        suffix := hash & 0x0fffffff
        rank: u32 = 1
        mask: u32 = 1 << 27
        for mask != 0 && suffix & mask == 0 { rank += 1; mask >>= 1 }
        if rank > registers[bucket] { registers[bucket] = rank }
    }
    sum: u64 = 0
    for rank in registers { sum += u64(1) << (29-rank) }
    numerator: u64 = 673*256*(u64(1)<<29)
    denominator: u64 = 1000*sum
    factor := gcd(numerator, denominator)
    numerator /= factor; denominator /= factor
    if output == nil || capacity < 144 do return -2
    words: [18]u64
    words[0] = numerator; words[1] = denominator
    for i := 0; i < 16; i += 1 { words[i+2] = u64(registers[i]) }
    staged: [144]u8
    for i := 0; i < 18; i += 1 {
        bits := words[i]
        for b := 0; b < 8; b += 1 { staged[8*i+b] = u8((bits >> (8*b)) & 255) }
    }
    for i := 0; i < 144; i += 1 { output[i] = staged[i] }
    return 144
}
