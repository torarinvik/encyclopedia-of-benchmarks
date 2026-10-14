package any_base_to_decimal

import "core:c"

// Fold most-significant-first digits in base 2 through 36 into i64.
@(export)
any_base_to_decimal :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length < 2 || length > 65 do return -1
    base := input[0]
    if base < 2 || base > 36 do return -1
    value: i64 = 0
    for index := c.size_t(1); index < length; index += 1 {
        digit := input[index]
        if digit < 0 || digit >= base do return -1
        if value > (9223372036854775807 - digit) / base do return -1
        value = value * base + digit
    }
    return value
}
