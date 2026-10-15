package polynomial_evaluation

import "core:c"

INVALID_RESULT :: -9223372036854775807 - 1

// Bounded integer port of the pinned floating-point Horner routine.
@(export)
polynomial_evaluation :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > 10 do return INVALID_RESULT
    count := values[0]
    x := values[1]
    if count < 0 || count > 8 || length != c.size_t(count + 2) do return INVALID_RESULT
    if x < -10 || x > 10 do return INVALID_RESULT
    for index := c.size_t(0); index < c.size_t(count); index += 1 {
        coefficient := values[index + 2]
        if coefficient < -1000 || coefficient > 1000 do return INVALID_RESULT
    }
    result: i64 = 0
    for index := c.size_t(count); index > 0; index -= 1 {
        result = result * x + values[index + 1]
    }
    return result
}
