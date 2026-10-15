package maximum_bags_with_full_capacity

import "core:c"

sift_down :: proc "contextless" (values: [^]i64, root, finish: int) {
    current := root
    for current < finish / 2 {
        child := current * 2 + 1
        if child + 1 < finish && values[child] < values[child + 1] {
            child += 1
        }
        if values[current] >= values[child] { break }
        temporary := values[current]
        values[current] = values[child]
        values[child] = temporary
        current = child
    }
}

@(export)
maximum_bags_with_full_capacity :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 16_384 do return -1
    remaining := input[0]
    if remaining < 0 || remaining > 1_000_000_000 do return -1
    if input[1] < 0 || input[1] > 8_191 do return -1
    count := int(input[1])
    if int(length) != 2 + 2 * count do return -1
    deficits: [8_191]i64 = {}
    for index := 0; index < count; index += 1 {
        capacity := input[2 + index]
        rocks := input[2 + count + index]
        if capacity < 1 || capacity > 100_000 || rocks < 0 || rocks > capacity do return -1
        deficits[index] = capacity - rocks
    }
    start := count / 2
    for start > 0 {
        start -= 1
        sift_down(&deficits[0], start, count)
    }
    finish := count
    for finish > 1 {
        finish -= 1
        temporary := deficits[0]
        deficits[0] = deficits[finish]
        deficits[finish] = temporary
        sift_down(&deficits[0], 0, finish)
    }
    full_bags := i64(0)
    for index := 0; index < count; index += 1 {
        if deficits[index] > remaining do break
        remaining -= deficits[index]
        full_bags += 1
    }
    return full_bags
}
