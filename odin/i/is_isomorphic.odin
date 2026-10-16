package is_isomorphic

import "core:c"

MAX_CODEPOINTS :: 8
MAX_INPUT_LENGTH :: 2 + 2 * MAX_CODEPOINTS + 2

@(export)
is_isomorphic :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
    source_length := input[0]
    target_length := input[1]
    if source_length < 0 || source_length > MAX_CODEPOINTS || target_length < 0 || target_length > MAX_CODEPOINTS do return -1
    source_count := c.size_t(source_length)
    target_count := c.size_t(target_length)
    if length != 2 + source_count + target_count do return -1
    for index: c.size_t = 2; index < length; index += 1 {
        if input[index] < 0 || input[index] > 127 do return -1
    }
    if source_count != target_count do return 0

    source_to_target: [128]i64
    target_to_source: [128]i64
    for index := 0; index < 128; index += 1 {
        source_to_target[index] = -1
        target_to_source[index] = -1
    }
    for index: c.size_t = 0; index < source_count; index += 1 {
        source := input[2 + index]
        target := input[2 + source_count + index]
        if (source_to_target[source] != -1 && source_to_target[source] != target) ||
            (target_to_source[target] != -1 && target_to_source[target] != source) do return 0
        source_to_target[source] = target
        target_to_source[target] = source
    }
    return 1
}
