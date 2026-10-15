package max_sum_ksize_subarray

import "core:c"

// Maximum sum of a fixed-size window; the final packed value is k.
@(export)
max_sum_ksize_subarray :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length == 0 || length > 64 || values == nil do return -1
    array_length := length - 1
    k_value := values[array_length]
    if k_value < 0 || c.size_t(k_value) > array_length do return -1
    for index := c.size_t(0); index < array_length; index += 1 {
        if values[index] < -1000000 || values[index] > 1000000 do return -1
    }
    if k_value == 0 do return 0

    k := c.size_t(k_value)
    window_sum := i64(0)
    for index := c.size_t(0); index < k; index += 1 { window_sum += values[index] }
    maximum_sum := window_sum
    for index := k; index < array_length; index += 1 {
        window_sum += values[index] - values[index - k]
        if window_sum > maximum_sum do maximum_sum = window_sum
    }
    return maximum_sum
}
