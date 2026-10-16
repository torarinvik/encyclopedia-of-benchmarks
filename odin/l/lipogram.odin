package lipogram

import "core:c"

@(export)
lipogram :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil do return -1
    if length < 2 || length > 1026 || input[0] < 0 || input[0] > 1024 || int(length) != int(input[0]) + 2 do return -1
    n := int(input[0])
    expected := input[int(length) - 1]
    if expected < 0 || expected > 67108863 do return -1
    seen: [26]bool = {}
    for i := 0; i < n; i += 1 {
        ch := input[i + 1]
        if ch >= 65 && ch <= 90 do ch += 32
        if ch >= 97 && ch <= 122 {
            seen[int(ch - 97)] = true
        } else if ch != 9 && ch != 10 && ch != 11 && ch != 12 && ch != 13 && ch != 32 do return -1
    }
    missing: i64 = 0
    bit: i64 = 1
    for i := 0; i < 26; i += 1 {
        if !seen[i] do missing += bit
        bit *= 2
    }
    return 1 if missing == expected else 0
}
