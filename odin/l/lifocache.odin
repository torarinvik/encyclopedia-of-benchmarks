package lifocache

import "core:c"

@(export)
lifocache :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 194 do return -1
    capacity_value := input[0]
    operation_count_value := input[1]
    if capacity_value < 1 || capacity_value > 16 || operation_count_value < 1 || operation_count_value > 64 do return -1
    capacity := int(capacity_value)
    operations := int(operation_count_value)
    if length != c.size_t(2 + 3 * operations) do return -1
    for i := 0; i < operations; i += 1 {
        op := input[2 + 3 * i]
        key := input[3 + 3 * i]
        value := input[4 + 3 * i]
        if op < 0 || op > 6 do return -1
        if op <= 2 {
            if key < -2_147_483_648 || key > 2_147_483_647 do return -1
            if op == 0 {
                if value < -2_147_483_648 || value > 2_147_483_647 do return -1
            } else if value != 0 do return -1
        } else if key != 0 || value != 0 do return -1
    }

    required := operations * 16
    if output == nil || output_capacity < c.size_t(required) do return -2
    keys: [16]i64 = {}
    values: [16]i64 = {}
    count := 0
    hits := i64(0)
    misses := i64(0)
    for i := 0; i < operations; i += 1 {
        op := input[2 + 3 * i]
        key := input[3 + 3 * i]
        value := input[4 + 3 * i]
        first := i64(0)
        second := i64(0)
        if op == 0 {
            found := count
            for j := 0; j < count; j += 1 { if keys[j] == key { found = j; break } }
            if found < count {
                for j := found; j + 1 < count; j += 1 { keys[j] = keys[j + 1]; values[j] = values[j + 1] }
                count -= 1
            }
            if count == capacity do count -= 1
            keys[count] = key
            values[count] = value
            count += 1
            first = 1
        } else if op == 1 {
            found := count
            for j := 0; j < count; j += 1 { if keys[j] == key { found = j; break } }
            if found < count { hits += 1; first = 1; second = values[found] } else { misses += 1 }
        } else if op == 2 {
            found := count
            for j := 0; j < count; j += 1 { if keys[j] == key { found = j; break } }
            if found < count {
                first = 1
                second = values[found]
                for j := found; j + 1 < count; j += 1 { keys[j] = keys[j + 1]; values[j] = values[j + 1] }
                count -= 1
            }
        } else if op == 3 { first = i64(count) }
        else if op == 4 { first = hits }
        else if op == 5 { first = misses }
        else { count = 0; hits = 0; misses = 0; first = 1 }
        first_bits := u64(first)
        second_bits := u64(second)
        for byte := 0; byte < 8; byte += 1 {
            output[i * 16 + byte] = u8((first_bits >> (8 * byte)) & 255)
            output[i * 16 + 8 + byte] = u8((second_bits >> (8 * byte)) & 255)
        }
    }
    return i64(2 * operations)
}
