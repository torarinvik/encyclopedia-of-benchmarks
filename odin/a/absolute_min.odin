package absolute_min

import "core:c"

MAX_VALUES :: 256
MAX_INPUT_VALUES :: MAX_VALUES + 1
VALUE_LIMIT :: i64(1_000_000_000)

magnitude :: proc "contextless" (value: i64) -> i64 {
    if value < 0 do return -value
    return value
}

select_absolute :: proc "contextless" (values: [^]i64, length: c.size_t, choose_max: bool) -> i64 {
    if length < 2 || length > MAX_INPUT_VALUES do return -1
    count_value := values[0]
    if count_value < 1 || count_value > MAX_VALUES || int(length) != int(count_value) + 1 do return -1
    for index := 1; index < int(length); index += 1 {
        if values[index] < -VALUE_LIMIT || values[index] > VALUE_LIMIT do return -1
    }
    best := values[1]
    for index := 2; index < int(length); index += 1 {
        candidate := values[index]
        if (choose_max && magnitude(candidate) > magnitude(best)) ||
           (choose_max && magnitude(candidate) == magnitude(best) && candidate > best) ||
           (!choose_max && magnitude(candidate) < magnitude(best)) ||
           (!choose_max && magnitude(candidate) == magnitude(best) && candidate < best) {
            best = candidate
        }
    }
    return best
}

@(export)
absolute_min_benchmark :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    return select_absolute(values, length, false)
}
