package interpolation_sequential_search

import "core:c"

MAX_N :: 64
MIN_VALUE :: -1_000_000
MAX_VALUE :: 1_000_000

@(export, link_name="interpolation_sequential_search")
interpolation_sequential_search :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > c.size_t(MAX_N + 3) do return -1
    count_value := input[0]
    target := input[1]
    if count_value < 0 || count_value > MAX_N || length != c.size_t(count_value + 2) do return -1
    if target < MIN_VALUE || target > MAX_VALUE do return -1
    count := int(count_value)
    for i := 0; i < count; i += 1 {
        value := input[i + 2]
        if value < MIN_VALUE || value > MAX_VALUE do return -1
        if i > 0 && input[i + 1] >= value do return -1
    }
    if count == 0 do return -1
    first := input[2]
    last := input[count + 1]
    if target < first || target > last do return -1
    if count == 1 {
        if first == target do return 0
        return -1
    }

    position := int((target - first) * i64(count - 1) / (last - first))
    estimated := input[position + 2]
    if estimated == target do return i64(position)
    if estimated < target {
        for i := position + 1; i < count; i += 1 {
            value := input[i + 2]
            if value >= target {
                if value == target do return i64(i)
                return -1
            }
        }
    } else {
        i := position
        for i > 0 {
            i -= 1
            value := input[i + 2]
            if value <= target {
                if value == target do return i64(i)
                return -1
            }
        }
    }
    return -1
}
