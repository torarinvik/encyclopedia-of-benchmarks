package knuth_morris_pratt

import "core:c"

// Return the first byte match index, or -1 when there is no match.
@(export)
knuth_morris_pratt :: proc "c" (packed: [^]i64, length: c.size_t) -> i64 {
    if packed == nil || length < 2 || length > 8194 do return -1
    if packed[0] < 0 || packed[0] > 4096 || packed[1] < 0 || packed[1] > 4096 do return -1
    text_length := c.size_t(packed[0])
    pattern_length := c.size_t(packed[1])
    if length != 2 + text_length + pattern_length do return -1
    for index := c.size_t(0); index < text_length + pattern_length; index += 1 {
        if packed[2 + index] < 0 || packed[2 + index] > 127 do return -1
    }
    if pattern_length == 0 do return 0

    pattern_start := 2 + text_length
    prefix: [4096]c.size_t
    prefix[0] = 0
    index := c.size_t(1)
    matched := c.size_t(0)
    for ; index < pattern_length; index += 1 {
        for matched > 0 && packed[pattern_start + index] != packed[pattern_start + matched] {
            matched = prefix[matched - 1]
        }
        if packed[pattern_start + index] == packed[pattern_start + matched] do matched += 1
        prefix[index] = matched
    }

    index = 0
    matched = 0
    for ; index < text_length; index += 1 {
        for matched > 0 && packed[2 + index] != packed[pattern_start + matched] {
            matched = prefix[matched - 1]
        }
        if packed[2 + index] == packed[pattern_start + matched] do matched += 1
        if matched == pattern_length do return i64(index + 1 - pattern_length)
    }
    return -1
}
