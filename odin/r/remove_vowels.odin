package remove_vowels
import "core:c"

@(export)
remove_vowels :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if values == nil || length < 1 || values[0] < 0 || values[0] > 4096 do return -1
    n := int(values[0])
    if length != c.size_t(n + 1) do return -1
    result := 0
    for i := 0; i < n; i += 1 {
        if values[i+1] < 0 || values[i+1] > 127 do return -1
        cval := int(values[i+1]); if cval >= 65 && cval <= 90 do cval += 32
        if cval != 97 && cval != 101 && cval != 105 && cval != 111 && cval != 117 do result += 1
    }
    if c.size_t(result) > capacity || (result > 0 && output == nil) do return -2
    written := 0
    for i := 0; i < n; i += 1 {
        cval := int(values[i+1]); if cval >= 65 && cval <= 90 do cval += 32
        if cval != 97 && cval != 101 && cval != 105 && cval != 111 && cval != 117 { output[written] = u8(cval); written += 1 }
    }
    return i64(written)
}
