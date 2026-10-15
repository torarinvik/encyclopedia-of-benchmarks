package modulo_power_of_two

import "core:c"

// Java-compatible low-bit mask for a signed 32-bit input and exponent 1..31.
@(export)
modulo_power_of_two :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 2 do return -1
    x := values[0]
    exponent := values[1]
    if x < -2_147_483_648 || x > 2_147_483_647 || exponent < 1 || exponent > 31 do return -1
    mask := (i64(1) << u32(exponent)) - 1
    return x & mask
}
