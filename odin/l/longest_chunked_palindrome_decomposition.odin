package longest_chunked_palindrome_decomposition

import "core:c"

// Count chunks by peeling the shortest matching prefix and suffix.
@(export)
longest_chunked_palindrome_decomposition :: proc "c" (text: [^]i64, length: c.size_t) -> i64 {
    if length > 128 do return -1
    for index: c.size_t = 0; index < length; index += 1 {
        if text[index] < 1 || text[index] > 127 do return -1
    }
    left := c.size_t(0)
    right := length
    chunks := i64(0)
    for left < right {
        remaining := right - left
        size := c.size_t(1)
        matched := false
        for size <= remaining / 2 && !matched {
            equal := true
            for offset := c.size_t(0); offset < size; offset += 1 {
                if text[left + offset] != text[right - size + offset] { equal = false; break }
            }
            if equal {
                chunks += 2
                left += size
                right -= size
                matched = true
            } else {
                size += 1
            }
        }
        if !matched do return chunks + 1
    }
    return chunks
}
