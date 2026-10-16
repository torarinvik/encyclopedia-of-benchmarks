package substring_end

import "core:c"

MAX_TEXT_LENGTH :: 128
CHECKSUM_BASE :: i64(1100000)

@(export)
substring_end :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 1 || length > MAX_TEXT_LENGTH + 1 do return -1
    text_length := int(length) - 1
    start := values[0]
    if start < 0 || start > i64(text_length) do return -1
    for i in 0 ..< text_length { if values[i + 1] < 1 || values[i + 1] > 127 do return -1 }
    count := text_length - int(start)
    checksum := i64(0)
    for i in 0 ..< count { checksum += i64(i + 1) * values[int(start) + i + 1] }
    return i64(count) * CHECKSUM_BASE + checksum
}
