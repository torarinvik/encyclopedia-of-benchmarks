package permutation_unique_string

import "core:c"

MAX_LENGTH :: 5
MAX_INPUT :: 7
MAX_OUTPUT :: 601

@(export)
permutation_unique_string :: proc "c" (input: [^]i64, input_length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || input_length == 0 || input_length > MAX_INPUT do return -1
    if input[0] < 0 || input[0] > MAX_LENGTH || input_length != c.size_t(input[0] + 1) do return -1
    length := int(input[0])
    current: [MAX_LENGTH]u8
    for i in 0..<length {
        if input[i+1] < 32 || input[i+1] > 126 do return -1
        current[i] = u8(input[i+1])
    }
    for i in 1..<length {
        value := current[i]
        j := i
        for j > 0 && current[j-1] > value { current[j] = current[j-1]; j -= 1 }
        current[j] = value
    }
    staged: [MAX_OUTPUT]u8
    count := 0
    for {
        for i in 0..<length { staged[1 + count*length + i] = current[i] }
        count += 1
        if length < 2 do break
        pivot := length - 1
        for pivot > 0 && current[pivot-1] >= current[pivot] { pivot -= 1 }
        if pivot == 0 do break
        successor := length - 1
        for current[successor] <= current[pivot-1] { successor -= 1 }
        current[pivot-1], current[successor] = current[successor], current[pivot-1]
        left, right := pivot, length-1
        for left < right {
            current[left], current[right] = current[right], current[left]
            left += 1
            right -= 1
        }
    }
    staged[0] = u8(count)
    output_size := 1 + count*length
    if output == nil || capacity < c.size_t(output_size) do return -2
    for i in 0..<output_size { output[i] = staged[i] }
    return i64(output_size)
}
