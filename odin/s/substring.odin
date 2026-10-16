package substring

import "core:c"

MAX_TEXT_LENGTH :: 128
MAX_REQUESTED_COUNT :: i64(64)
CHECKSUM_BASE :: i64(300000)

@(export)
substring :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > MAX_TEXT_LENGTH + 2 do return -1
    text_length := int(length) - 2
    start := values[0]
    requested := values[1]
    if start < 0 || start > i64(text_length) || requested < 0 || requested > MAX_REQUESTED_COUNT do return -1
    for i in 0 ..< text_length { if values[i + 2] < 1 || values[i + 2] > 127 do return -1 }
    remaining := text_length - int(start)
    count := int(requested)
    if count == 0 && remaining > 0 { count = 1 }
    if count > remaining { count = remaining }
    checksum := i64(0)
    for i in 0 ..< count { checksum += i64(i + 1) * values[int(start) + i + 2] }
    return i64(count) * CHECKSUM_BASE + checksum
}
