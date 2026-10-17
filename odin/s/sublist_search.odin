package sublist_search

import "core:c"

MAX_LIST_LENGTH :: 64
MAX_INPUT_LENGTH :: 130
MAX_VALUE :: i64(2147483647)

@(export)
sublist_search :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1
    main_count_value := values[0]
    pattern_count_value := values[1]
    if main_count_value < 0 || main_count_value > MAX_LIST_LENGTH ||
        pattern_count_value < 0 || pattern_count_value > MAX_LIST_LENGTH do return -1
    main_count := int(main_count_value)
    pattern_count := int(pattern_count_value)
    if length != c.size_t(2 + main_count + pattern_count) do return -1
    for i in 0..<main_count + pattern_count {
        value := values[2 + i]
        if value < 0 || value > MAX_VALUE do return -1
    }

    if main_count == 0 || pattern_count == 0 || pattern_count > main_count do return 0
    pattern_offset := 2 + main_count
    for start in 0..<main_count - pattern_count + 1 {
        matched := 0
        for matched < pattern_count && values[2 + start + matched] == values[pattern_offset + matched] {
            matched += 1
        }
        if matched == pattern_count do return 1
    }
    return 0
}
