package power_using_recursion

import "core:c"

power_recursive :: proc(base, exponent: i64) -> i64 {
    if exponent == 0 do return 1
    return base * power_recursive(base, exponent - 1)
}

@(export, link_name="power_using_recursion")
power_using_recursion :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length != 2 do return -1
    base := input[0]
    exponent := input[1]
    if base < -10 || base > 10 || exponent < 0 || exponent > 15 do return -1
    return power_recursive(base, exponent)
}
