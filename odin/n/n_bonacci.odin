package n_bonacci

import "core:c"

// Return the final term of a bounded N-bonacci sequence.
@(export)
n_bonacci :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 2 do return -1
    order_value := values[0]
    count_value := values[1]
    if order_value < 1 || count_value <= order_value || count_value > 64 do return -1
    order := int(order_value)
    count := int(count_value)
    terms: [64]i64
    terms[order - 1] = 1
    terms[order] = 1
    for index := order + 1; index < count; index += 1 {
        terms[index] = 2 * terms[index - 1] - terms[index - 1 - order]
    }
    return terms[count - 1]
}
