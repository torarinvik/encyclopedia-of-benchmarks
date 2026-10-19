package shootout_random

import "core:c"

MAX_CALL_COUNT :: 1_000_000
MODULUS :: 139_968
FRACTION_SCALE :: 1_000_000_000
MAX_OUTPUT_BYTES :: 13

@(export, link_name="shootout_random")
shootout_random :: proc "c" (call_count: i64, output: [^]u8,
    output_capacity: c.size_t) -> i64 {
    if call_count < 1 || call_count > i64(MAX_CALL_COUNT) do return -1

    state := i64(42)
    for call := i64(0); call < call_count; call += 1 {
        state = (state * 3877 + 29_573) % MODULUS
    }

    scaled := (100 * state * FRACTION_SCALE + MODULUS / 2) / MODULUS
    whole := scaled / FRACTION_SCALE
    fraction := scaled % FRACTION_SCALE
    staged: [MAX_OUTPUT_BYTES]u8
    reversed_digits: [3]u8
    digit_count := 0
    for {
        reversed_digits[digit_count] = u8(48 + whole % 10)
        digit_count += 1
        whole /= 10
        if whole == 0 do break
    }

    used := 0
    for digit_count > 0 {
        digit_count -= 1
        staged[used] = reversed_digits[digit_count]
        used += 1
    }
    staged[used] = u8('.')
    used += 1
    for place := i64(100_000_000); place > 0; place /= 10 {
        staged[used] = u8(48 + fraction / place)
        used += 1
        fraction %= place
    }
    staged[used] = 10
    used += 1

    if output == nil || output_capacity < c.size_t(used) do return -2
    for index := 0; index < used; index += 1 do output[index] = staged[index]
    return i64(used)
}
