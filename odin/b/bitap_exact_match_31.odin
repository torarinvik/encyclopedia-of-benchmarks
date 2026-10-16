package bitap_exact_match_31

import "core:c"

MAX_TEXT_LENGTH :: 4096
MAX_PATTERN_LENGTH :: 31

@(export)
bitap_exact_match_31 :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || values[0] < 0 || values[0] > MAX_TEXT_LENGTH || values[1] < 0 || values[1] > MAX_PATTERN_LENGTH do return -2
    text_length := int(values[0]); pattern_length := int(values[1])
    if int(length) != 2 + text_length + pattern_length do return -2
    for i := 2; i < int(length); i += 1 { if values[i] < 97 || values[i] > 122 do return -2 }
    if pattern_length == 0 do return 0
    if pattern_length > text_length do return -1
    var masks: [26]u32
    for c := 0; c < 26; c += 1 { masks[c] = ~u32(0) }
    for i := 0; i < pattern_length; i += 1 {
        letter := int(values[2 + text_length + i] - 97)
        masks[letter] &= ~(u32(1) << u32(i))
    }
    state := ~u32(1)
    for i := 0; i < text_length; i += 1 {
        letter := int(values[2 + i] - 97)
        state |= masks[letter]
        state <<= 1
        if state&(u32(1)<<u32(pattern_length)) == 0 do return i64(i - pattern_length + 1)
    }
    return -1
}
