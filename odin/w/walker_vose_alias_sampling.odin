package walker_vose_alias_sampling

import "core:c"

@(export)
walker_vose_alias_sampling :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 3 || length > 83 do return -1
    nr, qr := input[0], input[1]
    if nr < 1 || nr > 16 || qr < 0 || qr > 32 do return -1
    n, q := int(nr), int(qr)
    if length != c.size_t(2+n+2*q) do return -1
    total: i64 = 0
    for i := 0; i < n; i += 1 {
        w := input[2+i]
        if w < 0 || w > 100 do return -1
        total += w
    }
    if total == 0 do return -1
    for i := 0; i < q; i += 1 {
        col, ticket := input[2+n+2*i], input[3+n+2*i]
        if col < 0 || col >= nr || ticket < 0 || ticket >= total do return -1
    }
    if q == 0 do return 0
    if output == nil || capacity < c.size_t(8*q) do return -2
    mass, threshold: [16]i64
    aliases, small, large: [16]int
    ns, nl := 0, 0
    for i := 0; i < n; i += 1 {
        mass[i] = nr*input[2+i]; threshold[i] = total; aliases[i] = i
        if mass[i] < total { small[ns] = i; ns += 1 } else { large[nl] = i; nl += 1 }
    }
    for ns > 0 && nl > 0 {
        ns -= 1; nl -= 1
        low, high := small[ns], large[nl]
        threshold[low] = mass[low]; aliases[low] = high
        mass[high] -= total-mass[low]
        if mass[high] < total { small[ns] = high; ns += 1 } else { large[nl] = high; nl += 1 }
    }
    staged: [256]u8
    for i := 0; i < q; i += 1 {
        col := int(input[2+n+2*i])
        chosen := aliases[col]
        if input[3+n+2*i] < threshold[col] { chosen = col }
        bits := u64(chosen)
        for b := 0; b < 8; b += 1 { staged[8*i+b] = u8((bits >> (8*b)) & 255) }
    }
    for i := 0; i < 8*q; i += 1 { output[i] = staged[i] }
    return i64(8*q)
}
