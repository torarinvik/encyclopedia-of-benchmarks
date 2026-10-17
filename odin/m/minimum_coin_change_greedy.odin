package minimum_coin_change_greedy

import "core:c"

MIN_TARGET :: i64(-4096)
MAX_TARGET :: i64(4096)
MAX_DENOMINATIONS :: 32
MAX_INPUT_VALUES :: 2 + MAX_DENOMINATIONS
MAX_OUTPUT_BYTES :: (1 + 4096) * 4

write_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i32) {
    bits := u32(value)
    for byte := 0; byte < 4; byte += 1 {
        output[offset + byte] = u8(bits & 255)
        bits >>= 8
    }
}

@(export, link_name="minimum_coin_change_greedy")
minimum_coin_change_greedy :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
    target := input[0]
    count_value := input[1]
    if target < MIN_TARGET || target > MAX_TARGET || count_value < 0 || count_value > MAX_DENOMINATIONS do return -1
    denomination_count := int(count_value)
    if int(length) != 2 + denomination_count do return -1

    denominations: [MAX_DENOMINATIONS]i32
    previous: i64 = 0
    for index := 0; index < denomination_count; index += 1 {
        denomination := input[2 + index]
        if denomination < 1 || denomination > 4096 || denomination <= previous do return -1
        denominations[index] = i32(denomination)
        previous = denomination
    }

    chosen: [4096]i32
    chosen_count := 0
    if target > 0 {
        remaining := target
        index := denomination_count
        for index > 0 {
            index -= 1
            denomination := denominations[index]
            for remaining >= i64(denomination) {
                remaining -= i64(denomination)
                chosen[chosen_count] = denomination
                chosen_count += 1
            }
        }
    }

    needed := (1 + chosen_count) * 4
    if output == nil || capacity < c.size_t(needed) do return -2
    write_i32_le(output, 0, i32(chosen_count))
    for index := 0; index < chosen_count; index += 1 {
        write_i32_le(output, 4 + 4 * index, chosen[index])
    }
    return i64(needed)
}
