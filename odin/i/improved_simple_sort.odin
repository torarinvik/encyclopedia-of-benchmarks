package improved_simple_sort

import "core:c"

MAX_LENGTH :: 256
MIN_VALUE :: i64(-1_000_000)
MAX_VALUE :: i64(1_000_000)
CHECKSUM_OFFSET :: i64(1_000_001)
INVALID_RESULT :: i64(-1)

@(export)
improved_simple_sort :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length > c.size_t(MAX_LENGTH) || (length != 0 && values == nil) { return INVALID_RESULT }
    working: [MAX_LENGTH]i64 = {}
    input_length := int(length)
    for index := 0; index < input_length; index += 1 {
        if values[index] < MIN_VALUE || values[index] > MAX_VALUE { return INVALID_RESULT }
        working[index] = values[index]
    }

    for i := 1; i < input_length; i += 1 {
        for j := 0; j + 1 < input_length; j += 1 {
            if working[i] < working[j] {
                temporary := working[i]
                working[i] = working[j]
                working[j] = temporary
            }
        }
    }
    checksum := i64(0)
    for index := 0; index < input_length; index += 1 {
        checksum += i64(index + 1) * (working[index] + CHECKSUM_OFFSET)
    }
    return checksum
}
