package pythagorean_triple

import "core:c"

// Check three signed integers with Java-compatible int-safe bounds.
@(export)
pythagorean_triple :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length != 3 do return -1
    a, b, c_value := values[0], values[1], values[2]
    if a < -32768 || a > 32767 || b < -32768 || b > 32767 || c_value < -32768 || c_value > 32767 do return -1
    if a <= 0 || b <= 0 || c_value <= 0 do return 0
    if a > b { a, b = b, a }
    if b > c_value { b, c_value = c_value, b }
    if a > b { a, b = b, a }
    if a * a + b * b == c_value * c_value do return 1
    return 0
}
