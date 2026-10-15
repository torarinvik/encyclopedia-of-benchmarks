package findpalindrome
import "core:c"
MAX_LENGTH :: 4096
punctuation :: proc "contextless" (value: i64) -> bool { return (value>=33&&value<=47)||(value>=58&&value<=64)||(value>=91&&value<=96)||(value>=123&&value<=126) }
fold :: proc "contextless" (value: i64) -> i64 { if value>=65&&value<=90 do return value+32; return value }
@(export)
findpalindrome :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
    if length > c.size_t(MAX_LENGTH) do return -1
    for i := c.size_t(0); i < length; i += 1 { if input[i] < 32 || input[i] > 126 do return -1 }
    written := c.size_t(0); found := false; segment := c.size_t(0)
    for end := c.size_t(0); end <= length; end += 1 {
        if end < length && input[end] != 32 do continue
        token_length := c.size_t(0)
        for i := segment; i < end; i += 1 { if !punctuation(input[i]) do token_length += 1 }
        left, right := segment, end
        matched := true
        for left < right {
            for left < right && punctuation(input[left]) { left += 1 }
            for left < right && punctuation(input[right-1]) { right -= 1 }
            if left < right {
                if fold(input[left]) != fold(input[right-1]) { matched = false; break }
                left += 1; right -= 1
            }
        }
        if token_length > 1 && matched {
            needed := token_length
            if found do needed += 1
            if written + needed > output_capacity do return -2
            if found { output[written] = 0; written += 1 }
            for i := segment; i < end; i += 1 { if !punctuation(input[i]) { output[written] = u8(input[i]); written += 1 } }
            found = true
        }
        segment = end + 1
    }
    return i64(written)
}
