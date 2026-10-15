package is_pangram

import "core:c"

// ASCII pangram predicate: ignore nonletters and ASCII letter case.
@(export)
is_pangram :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 || (length > 0 && values == nil) do return -1
    seen: [26]bool
    found := 0
    for index := c.size_t(0); index < length; index += 1 {
        value := values[index]
        if value < 0 || value > 127 do return -1
        if value >= 65 && value <= 90 do value += 32
        if value >= 97 && value <= 122 {
            letter := int(value - 97)
            if !seen[letter] {
                seen[letter] = true
                found += 1
            }
        }
    }
    return i64(found == 26)
}
