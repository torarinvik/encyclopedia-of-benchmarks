package parity_outlier

import "core:c"

@(export)
parity_outlier :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 1 || values[0] < 3 || values[0] > 65 || (values[0] & 1) == 0 do return -1
    count := values[0]
    if length != c.size_t(count + 1) do return -1
    evens, odds := i64(0), i64(0)
    even_value, odd_value := i64(0), i64(0)
    for i := i64(0); i < count; i += 1 {
        value := values[i + 1]
        if value < 0 || value > 2147483647 do return -1
        if (value & 1) == 0 {
            evens += 1
            even_value = value
        } else {
            odds += 1
            odd_value = value
        }
    }
    if evens == 1 && odds >= 2 do return even_value
    if odds == 1 && evens >= 2 do return odd_value
    return -1
}
