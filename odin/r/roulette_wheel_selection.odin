package roulette_wheel_selection

import "core:c"

MAX_INPUT_VALUES :: 131
MAX_VALIDATORS :: 128
MAX_STAKE :: i64(1_000_000)
MAX_TOTAL_STAKE :: i64(128_000_000)

@(export)
roulette_wheel_selection :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 3 || length > c.size_t(MAX_INPUT_VALUES) do return -1

    count_value := input[0]
    if count_value < 1 || count_value > MAX_VALIDATORS do return -1
    count := int(count_value)
    if length != c.size_t(count + 2) do return -1

    total := i64(0)
    for index := 0; index < count; index += 1 {
        stake := input[1 + index]
        if stake < 1 || stake > MAX_STAKE do return -1
        if total > MAX_TOTAL_STAKE - stake do return -1
        total += stake
    }

    ticket := input[1 + count]
    if ticket < 0 || ticket >= total do return -1

    cumulative := i64(0)
    for index := 0; index < count; index += 1 {
        cumulative += input[1 + index]
        if ticket < cumulative do return i64(index + 1)
    }
    return -1
}
