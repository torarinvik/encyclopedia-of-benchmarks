package negative_binary_base_to_int

import "core:c"

// Interpret most-significant-first bits in radix -2 with checked i64 folding.
@(export)
negative_binary_base_to_int :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if length < 1 || length > 63 do return -1
    value: i64 = 0
    for index := c.size_t(0); index < length; index += 1 {
        bit := input[index]
        if bit != 0 && bit != 1 do return -1
        if value > 4611686018427387904 || value < -4611686018427387903 do return -1
        value = value * -2 + bit
    }
    return value
}
