package shannon_fano_elias_symbol_codes

import "core:c"

@(export)
shannon_fano_elias_symbol_codes :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 10 { return -1 }
    raw_n := input[0]
    if raw_n < 1 || raw_n > 8 || length != c.size_t(raw_n + 1) { return -1 }
    n := int(raw_n)
    total: i64 = 0
    for i := 0; i < n; i += 1 {
        weight := input[1+i]
        if weight < 1 || weight > 15 { return -1 }
        total += weight
    }
    if total > 120 { return -1 }

    staged: [17]u8
    staged[0] = u8(n)
    prefix: i64 = 0
    for i := 0; i < n; i += 1 {
        weight := input[1+i]
        bits := 1
        for (i64(1) << (bits-1))*weight < total { bits += 1 }
        numerator := (2*prefix + weight) * (i64(1) << (bits-1))
        code := u8(numerator / total)
        staged[1+2*i] = u8(bits)
        staged[2+2*i] = code << u8(8-bits)
        prefix += weight
    }
    needed := 1 + 2*n
    if output == nil || capacity < c.size_t(needed) { return -2 }
    for i := 0; i < needed; i += 1 { output[i] = staged[i] }
    return i64(needed)
}
