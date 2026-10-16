package merge_sorted

import "core:c"

MAX_ARRAY_LENGTH :: 64
MAX_INPUT_LENGTH :: 2 + 2 * MAX_ARRAY_LENGTH
MAX_PARSEABLE_INPUT_LENGTH :: MAX_INPUT_LENGTH + 1
MIN_VALUE :: i64(-1_000_000)
MAX_VALUE :: i64(1_000_000)
CHECKSUM_OFFSET :: i64(1_000_001)

@(export)
merge_sorted :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
    if values[0] < 0 || values[0] > i64(MAX_ARRAY_LENGTH) ||
        values[1] < 0 || values[1] > i64(MAX_ARRAY_LENGTH) do return -1

    left_count := int(values[0])
    right_count := int(values[1])
    if length != c.size_t(2 + left_count + right_count) do return -1
    right_start := 2 + left_count

    for index := 0; index < left_count; index += 1 {
        value := values[2 + index]
        if value < MIN_VALUE || value > MAX_VALUE ||
            (index > 0 && values[2 + index - 1] > value) do return -1
    }
    for index := 0; index < right_count; index += 1 {
        value := values[right_start + index]
        if value < MIN_VALUE || value > MAX_VALUE ||
            (index > 0 && values[right_start + index - 1] > value) do return -1
    }

    left_index := 0
    right_index := 0
    output_index := i64(0)
    checksum := i64(0)
    for left_index < left_count && right_index < right_count {
        value := i64(0)
        if values[2 + left_index] <= values[right_start + right_index] {
            value = values[2 + left_index]
            left_index += 1
        } else {
            value = values[right_start + right_index]
            right_index += 1
        }
        checksum += (output_index + 1) * (value + CHECKSUM_OFFSET)
        output_index += 1
    }
    for left_index < left_count {
        value := values[2 + left_index]
        checksum += (output_index + 1) * (value + CHECKSUM_OFFSET)
        left_index += 1
        output_index += 1
    }
    for right_index < right_count {
        value := values[right_start + right_index]
        checksum += (output_index + 1) * (value + CHECKSUM_OFFSET)
        right_index += 1
        output_index += 1
    }
    return checksum
}
