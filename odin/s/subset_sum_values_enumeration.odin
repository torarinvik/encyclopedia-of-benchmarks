package subset_sum_values_enumeration

import "core:c"

MAX_ITEMS :: 11
MAX_TARGET :: i64 = 256
MAX_ITEM :: i64 = 64

write_i64_le :: proc(output: [^]u8, position: ^c.size_t, value: i64) {
    bits := u64(value)
    for shift: u32 = 0; shift < 64; shift += 8 {
        output[position^] = u8((bits >> shift) & 0xff)
        position^ += 1
    }
}

enumerate :: proc "contextless" (items: [^]i64, item_count, index: int,
        target, total: i64, chosen: [^]i64, chosen_count: c.size_t,
        output: [^]u8, position: ^c.size_t, emit: bool) -> c.size_t {
    if total == target {
        if emit {
            write_i64_le(output, position, i64(chosen_count))
            for i: c.size_t = 0; i < chosen_count; i += 1 { write_i64_le(output, position, chosen[i]) }
        }
        return chosen_count + 1
    }
    if index == item_count || total > target do return 0
    chosen[chosen_count] = items[index + 1]
    include_slots := enumerate(items, item_count, index + 1, target,
        total + items[index + 1], chosen, chosen_count + 1, output, position, emit)
    exclude_slots := enumerate(items, item_count, index + 1, target,
        total, chosen, chosen_count, output, position, emit)
    return include_slots + exclude_slots
}

@(export)
subset_sum_values_enumeration :: proc "c" (input: [^]i64, length: c.size_t,
        output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length == 0 || length > MAX_ITEMS + 1 do return -1
    target := input[0]
    if target < 0 || target > MAX_TARGET do return -1
    items := int(length) - 1
    for index := 0; index < items; index += 1 {
        if input[index + 1] < 1 || input[index + 1] > MAX_ITEM do return -1
    }

    chosen: [MAX_ITEMS]i64 = {}
    dummy_position: c.size_t = 0
    slots := enumerate(input, items, 0, target, 0, &chosen[0], 0,
        output, &dummy_position, false)
    required := slots * 8
    if required == 0 do return 0
    if output == nil || output_capacity < required do return -2
    position: c.size_t = 0
    enumerate(input, items, 0, target, 0, &chosen[0], 0,
        output, &position, true)
    return i64(position)
}
