package permute_string

import "core:c"

MAX_N :: 7
MAX_INPUT_LENGTH :: 9
MAX_OUTPUT_BYTES :: 35280

factorial :: proc "contextless" (value: int) -> int {
    result := 1
    for factor := 2; factor <= value; factor += 1 { result *= factor }
    return result
}

unique_permutation_count :: proc "contextless" (values: [^]u8, length: int) -> int {
    if length == 0 do return 0
    frequencies: [128]int
    for index := 0; index < length; index += 1 { frequencies[int(values[index])] += 1 }
    count := factorial(length)
    for frequency in frequencies { count /= factorial(frequency) }
    return count
}

next_permutation :: proc "contextless" (values: [^]u8, length: int) -> bool {
    if length < 2 do return false
    pivot := length - 1
    for pivot > 0 && values[pivot - 1] >= values[pivot] { pivot -= 1 }
    if pivot == 0 do return false
    successor := length - 1
    for values[successor] <= values[pivot - 1] { successor -= 1 }
    values[pivot - 1], values[successor] = values[successor], values[pivot - 1]
    left, right := pivot, length - 1
    for left < right {
        values[left], values[right] = values[right], values[left]
        left += 1
        right -= 1
    }
    return true
}

@(export)
permute_string :: proc "c" (input: [^]i64, input_length: c.size_t,
                             output: [^]u8, output_capacity: c.size_t) -> i64 {
    if input == nil || input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
    if input[0] < 0 || input[0] > MAX_N do return -1
    character_count := int(input[0])
    if int(input_length) != character_count + 1 do return -1

    values: [MAX_N]u8
    for index := 0; index < character_count; index += 1 {
        value := input[index + 1]
        if value < 0 || value > 127 do return -1
        values[index] = u8(value)
    }
    for index := 1; index < character_count; index += 1 {
        value := values[index]
        position := index
        for position > 0 && values[position - 1] > value {
            values[position] = values[position - 1]
            position -= 1
        }
        values[position] = value
    }

    permutation_count := unique_permutation_count(&values[0], character_count)
    output_bytes := permutation_count * character_count
    if output == nil || output_capacity < output_bytes do return -2
    for row := 0; row < permutation_count; row += 1 {
        for column := 0; column < character_count; column += 1 {
            output[row * character_count + column] = values[column]
        }
        if row + 1 < permutation_count { _ = next_permutation(&values[0], character_count) }
    }
    return i64(output_bytes)
}
