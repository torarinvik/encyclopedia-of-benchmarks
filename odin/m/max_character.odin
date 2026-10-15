package max_character

import "core:c"

@(export)
max_character :: proc "contextless" (values: [^]i64, length: c.size_t) -> i64 {
    if length == 0 || length > 256 || values == nil do return -1
    counts: [26]i64 = {}
    for i := c.size_t(0); i < length; i += 1 {
        if values[i] < 97 || values[i] > 122 do return -1
        counts[values[i] - 97] += 1
    }
    best: i64 = 0
    code: i64 = -1
    tied := false
    for i in 0 ..< 26 {
        if counts[i] > best {
            best = counts[i]
            code = 97 + i64(i)
            tied = false
        } else if counts[i] == best && best != 0 {
            tied = true
        }
    }
    if tied do return -1
    return code
}
