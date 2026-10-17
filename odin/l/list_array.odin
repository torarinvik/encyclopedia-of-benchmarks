package list_array

import "core:c"

@(export)
list_array :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 130 do return -1
    capacity_value := input[0]
    operation_count_value := input[1]
    if capacity_value < 1 || capacity_value > 16 || operation_count_value < 1 || operation_count_value > 64 do return -1
    capacity := int(capacity_value)
    operations := int(operation_count_value)
    if length != c.size_t(2 + 2 * operations) do return -1

    opcodes: [64]i64 = {}
    arguments: [64]i64 = {}
    sorted := false
    for i := 0; i < operations; i += 1 {
        opcode := input[2 + 2 * i]
        argument := input[3 + 2 * i]
        if opcode == 0 {
            if sorted || argument < 0 do return -1
        } else if opcode == 1 {
            if sorted || argument != 0 do return -1
            sorted = true
        } else if opcode == 2 || opcode == 3 {
            if !sorted || argument < 0 do return -1
        } else do return -1
        opcodes[i] = opcode
        arguments[i] = argument
    }
    if !sorted do return -1

    items: [16]u64 = {}
    results: [64]i64 = {}
    output_words: [65]i64 = {}
    count := 0
    result_count := 0
    for i := 0; i < operations; i += 1 {
        opcode := opcodes[i]
        argument := arguments[i]
        if opcode == 0 {
            if count == capacity do return -1
            items[count] = u64(argument)
            count += 1
        } else if opcode == 1 {
            for a := 0; a < count; a += 1 {
                minimum := a
                for b := a + 1; b < count; b += 1 { if items[b] < items[minimum] do minimum = b }
                value := items[minimum]
                items[minimum] = items[a]
                items[a] = value
            }
        } else {
            if count == 0 || u64(argument) < items[0] do return -1
            if opcode == 3 && count >= capacity do return -1
            first := 0
            last := count - 1
            position := i64(-1)
            for first <= last {
                middle := (first + last) / 2
                value := items[middle]
                if value == u64(argument) {
                    position = i64(middle)
                    break
                } else if u64(argument) < value {
                    last = middle - 1
                } else {
                    first = middle + 1
                }
            }
            results[result_count] = position
            result_count += 1
            if opcode == 3 && position >= 0 {
                for j := int(position); j < count; j += 1 { items[j] = items[j + 1] }
                count -= 1
            }
        }
    }

    word_count := 0
    output_words[word_count] = i64(result_count)
    word_count += 1
    for i := 0; i < result_count; i += 1 {
        output_words[word_count] = results[i]
        word_count += 1
    }
    output_words[word_count] = i64(count)
    word_count += 1
    for i := 0; i < count; i += 1 {
        output_words[word_count] = i64(items[i])
        word_count += 1
    }
    required := word_count * 8
    if output == nil || output_capacity < c.size_t(required) do return -2
    for i := 0; i < word_count; i += 1 {
        bits := u64(output_words[i])
        for byte := 0; byte < 8; byte += 1 { output[i * 8 + byte] = u8((bits >> (8 * byte)) & 255) }
    }
    return i64(required)
}
