package rabin_content_defined_chunking

import "core:c"

cdc_reduce :: proc(value: u32) -> u16 {
    remainder := value
    for step := 0; step < 16; step += 1 {
        bit := 31 - step
        if remainder & (u32(1) << u32(bit)) != 0 do remainder ~= u32(0x1100b) << u32(bit - 16)
    }
    return u16(remainder)
}

@(export)
rabin_content_defined_chunking :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > 65 do return -1
    if input[0] < 0 || input[0] > 64 do return -1
    n := int(input[0])
    if length != c.size_t(n + 1) do return -1
    for i := 0; i < n; i += 1 do if input[i+1] < 0 || input[i+1] > 255 do return -1
    outgoing: [256]u16
    for i := 0; i < 256; i += 1 do outgoing[i] = cdc_reduce(u32(i) << 24)
    fingerprint: u16 = 0
    boundaries: [64]u8
    count := 0
    for i := 0; i < n; i += 1 {
        fingerprint = cdc_reduce((u32(fingerprint) << 8) | u32(input[i+1]))
        if i >= 4 do fingerprint ~= outgoing[int(input[i-3])]
        if fingerprint & 7 == 0 { boundaries[count] = u8(i+1); count += 1 }
    }
    if n > 0 && (count == 0 || int(boundaries[count-1]) != n) {
        boundaries[count] = u8(n); count += 1
    }
    if output == nil || capacity < c.size_t(count) do return -2
    for i := 0; i < count; i += 1 do output[i] = boundaries[i]
    return i64(count)
}
