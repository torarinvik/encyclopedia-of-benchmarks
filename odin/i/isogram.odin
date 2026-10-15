package isogram

import "core:c"

// Check whether ASCII letters form an isogram, ignoring case and spaces.
@(export)
isogram :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > 4096 || (length > 0 && values == nil) do return -1
    seen: [26]bool
    for letter := 0; letter < 26; letter += 1 { seen[letter] = false }
    for index := c.size_t(0); index < length; index += 1 {
        value := values[index]
        if value == 32 do continue
        if value >= 65 && value <= 90 do value += 32
        if value < 97 || value > 122 do return -1
        letter := int(value - 97)
        if seen[letter] do return 0
        seen[letter] = true
    }
    return 1
}
