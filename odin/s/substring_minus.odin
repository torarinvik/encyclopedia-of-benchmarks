package substring_minus

import "core:c"

MAX_TEXT_LENGTH :: 128
CHECKSUM_BASE :: i64(1100000)

@(export)
substring_minus :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 1 || length > MAX_TEXT_LENGTH do return -1
    for i in 0 ..< int(length) { if values[i] < 1 || values[i] > 127 do return -1 }
    count := int(length) - 1
    checksum := i64(0)
    for i in 0 ..< count { checksum += i64(i + 1) * values[i] }
    return i64(count) * CHECKSUM_BASE + checksum
}
