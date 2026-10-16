package activity_selection

import "core:c"

// Count a maximum set of non-overlapping half-open activities.
@(export)
activity_selection :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length == 0 || input[0] < 0 || input[0] > 64 do return -1
    count := int(input[0])
    if length != c.size_t(1 + 2 * count) do return -1
    if count == 0 do return 0
    starts: [64]i64
    finishes: [64]i64
    for index := 0; index < count; index += 1 {
        starts[index] = input[1 + 2 * index]
        finishes[index] = input[2 + 2 * index]
        if starts[index] > finishes[index] do return -1
    }
    for index := 1; index < count; index += 1 {
        start := starts[index]
        finish := finishes[index]
        position := index
        for position > 0 && (finishes[position - 1] > finish ||
            (finishes[position - 1] == finish && starts[position - 1] > start)) {
            starts[position] = starts[position - 1]
            finishes[position] = finishes[position - 1]
            position -= 1
        }
        starts[position] = start
        finishes[position] = finish
    }
    selected := i64(1)
    last_finish := finishes[0]
    for index := 1; index < count; index += 1 {
        if starts[index] >= last_finish {
            selected += 1
            last_finish = finishes[index]
        }
    }
    return selected
}
