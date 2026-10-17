package pipeline

import "core:c"

MAX_STAGE_COUNT :: 32
MAX_INPUT_LENGTH :: 2 + 2 * MAX_STAGE_COUNT

@(export)
pipeline :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > MAX_INPUT_LENGTH do return -1

    initial := values[0]
    stage_count := values[1]
    if initial < 0 || initial > 2 || stage_count < 1 || stage_count > MAX_STAGE_COUNT do return -1
    if length != c.size_t(2 + 2 * stage_count) do return -1

    result := initial
    for index := 0; index < int(stage_count); index += 1 {
        operation := values[2 + 2 * index]
        argument := values[3 + 2 * index]
        if argument < 0 || argument > 2 do return -1
        if operation == 0 do result += argument
        else if operation == 1 do result *= argument
        else do return -1
    }
    return result
}
