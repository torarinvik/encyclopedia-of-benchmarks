package counting_bloom_filter_operation_trace

import "core:c"

Max_Operations :: 64
Max_Parseable_Length :: 130
Counter_Count :: 67
Hash_Count :: 4

hash_positions :: proc(key: i64) -> [Hash_Count]int {
    first := (17 * key + 3) % i64(Counter_Count)
    step := 1 + ((5 * key + 3) % i64(Counter_Count - 1))
    positions: [Hash_Count]int
    for index := 0; index < Hash_Count; index += 1 {
        positions[index] = int((first + i64(index) * step) % i64(Counter_Count))
    }
    return positions
}

@(export)
counting_bloom_filter_operation_trace :: proc "c" (
    input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > Max_Parseable_Length do return -1
    q_value := input[0]
    if q_value < 0 || q_value > Max_Operations do return -1
    q := int(q_value)
    if length != c.size_t(1 + 2*q) do return -1

    for operation_index := 0; operation_index < q; operation_index += 1 {
        opcode := input[1 + 2*operation_index]
        key := input[2 + 2*operation_index]
        if opcode < 0 || opcode > 2 || key < 0 || key > 65535 do return -1
    }
    if output == nil || capacity < c.size_t(q) do return -2

    counters: [Counter_Count]u8
    for operation_index := 0; operation_index < q; operation_index += 1 {
        opcode := input[1 + 2*operation_index]
        key := input[2 + 2*operation_index]
        positions := hash_positions(key)
        if opcode == 0 {
            for position in positions do counters[position] += 1
            output[operation_index] = 1
        } else if opcode == 1 {
            // The caller guarantees each deletion targets a live key.
            for position in positions do counters[position] -= 1
            output[operation_index] = 1
        } else {
            present := true
            for position in positions {
                if counters[position] == 0 do present = false
            }
            if present { output[operation_index] = 1 }
            else { output[operation_index] = 0 }
        }
    }
    return i64(q)
}
