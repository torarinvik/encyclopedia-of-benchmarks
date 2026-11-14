package backward_nondeterministic_dawg_match

import "core:c"

@(export)
backward_nondeterministic_dawg_match :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 4161 || values[0] < 0 || values[0] > 4096 || values[1] < 0 || values[1] > 63 { return -2 }
    n, m := int(values[0]), int(values[1])
    if int(length) != 2 + n + m { return -2 }
    for i := 2; i < int(length); i += 1 {
        if values[i] < 97 || values[i] > 122 { return -2 }
    }
    if m == 0 { return 0 }
    if m > n { return -1 }
    masks: [26]u64
    for i := 0; i < m; i += 1 {
        masks[int(values[2+n+i]-97)] |= u64(1) << u64(m-1-i)
    }
    start := 0
    for start <= n-m {
        remaining, shift := m, m
        states := ~u64(0)
        for remaining > 0 && states != 0 {
            remaining -= 1
            states &= masks[int(values[2+start+remaining]-97)]
            if states != 0 {
                if remaining == 0 { return i64(start) }
                shift = remaining
            }
            states <<= 1
        }
        start += shift
    }
    return -1
}
