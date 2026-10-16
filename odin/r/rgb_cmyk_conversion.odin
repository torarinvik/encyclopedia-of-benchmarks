package rgb_cmyk_conversion

import "core:c"
import "core:math"

OUTPUT_LENGTH :: 4

round_ties_to_even :: proc "contextless" (value: f64) -> i64 {
    lower := math.floor(value)
    fraction := value - lower
    base := i64(lower)
    if fraction < 0.5 do return base
    if fraction > 0.5 do return base + 1
    if base % 2 == 0 do return base
    return base + 1
}

@(export)
rgb_cmyk_conversion :: proc "c" (input: [^]i64, length: c.size_t,
                                   output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length != 3 do return -1
    for i in 0 ..< 3 { if input[i] < 0 || input[i] > 255 do return -1 }
    if output == nil || capacity < OUTPUT_LENGTH do return -2
    red, green, blue := f64(input[0])/255.0, f64(input[1])/255.0, f64(input[2])/255.0
    maximum := max(max(red, green), blue)
    key := 1.0 - maximum
    if key == 1.0 { output[0] = 0; output[1] = 0; output[2] = 0; output[3] = 100; return OUTPUT_LENGTH }
    denominator := 1.0 - key
    output[0] = u8(round_ties_to_even(100.0 * (1.0 - red - key) / denominator))
    output[1] = u8(round_ties_to_even(100.0 * (1.0 - green - key) / denominator))
    output[2] = u8(round_ties_to_even(100.0 * (1.0 - blue - key) / denominator))
    output[3] = u8(round_ties_to_even(100.0 * key))
    return OUTPUT_LENGTH
}
