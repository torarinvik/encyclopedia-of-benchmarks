package ema_filter

import "core:c"

put_f64_le :: proc "contextless" (output: [^]u8, offset: usize, value: f64) {
    bits := transmute(u64)value
    for byte: u32 = 0; byte < 8; byte += 1 { output[offset + usize(byte)] = u8(bits >> (8 * byte)) }
}

// Apply the bounded Java EMAFilter recurrence to an integer sample stream.
@(export)
ema_filter :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 7 do return -1
    alpha_units, count_value := input[0], input[1]
    if alpha_units < 1 || alpha_units > 1024 || count_value < 0 || count_value > 4 ||
        length != c.size_t(2 + count_value) do return -1
    count := c.size_t(count_value)
    for index := c.size_t(0); index < count; index += 1 {
        if input[index + 2] < -1_000_000 || input[index + 2] > 1_000_000 do return -1
    }
    required := count * 8
    if output_capacity < required || (required > 0 && output == nil) do return -2

    alpha := f64(alpha_units) / 1024.0
    ema_value := f64(0)
    for index := c.size_t(0); index < count; index += 1 {
        sample := f64(input[index + 2])
        if index == 0 { ema_value = sample }
        else { ema_value = alpha * sample + (1.0 - alpha) * ema_value }
        put_f64_le(output, index * 8, ema_value)
    }
    return i64(required)
}
