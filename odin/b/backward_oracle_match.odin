package backward_oracle_match

import "core:c"

@(export)
backward_oracle_match :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 4161 || values[0] < 0 || values[0] > 4096 || values[1] < 0 || values[1] > 63 { return -2 }
    n, m := int(values[0]), int(values[1])
    if int(length) != 2 + n + m { return -2 }
    for i := 2; i < int(length); i += 1 {
        if values[i] < 97 || values[i] > 122 { return -2 }
    }
    if m == 0 { return 0 }
    if m > n { return -1 }
    next: [64][26]int
    suffix: [64]int
    for i := 0; i < 64; i += 1 {
        suffix[i] = -1
        for c := 0; c < 26; c += 1 { next[i][c] = -1 }
    }
    for i := 0; i < m; i += 1 {
        letter := int(values[2+n+m-1-i] - 97)
        next[i][letter] = i + 1
        k := suffix[i]
        for k >= 0 && next[k][letter] < 0 {
            next[k][letter] = i + 1
            k = suffix[k]
        }
        if k < 0 { suffix[i+1] = 0 } else { suffix[i+1] = next[k][letter] }
    }
    start := 0
    for start <= n-m {
        state, remaining, shift := 0, m, m
        for remaining > 0 {
            remaining -= 1
            state = next[state][int(values[2+start+remaining]-97)]
            if state < 0 { shift = remaining + 1; break }
            if remaining == 0 { return i64(start) }
        }
        start += shift
    }
    return -1
}
