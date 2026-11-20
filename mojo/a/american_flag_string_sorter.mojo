from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("american_flag_string_sorter")
fn american_flag_string_sorter(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 8450:
        return -1

    let item_count_value = input[0]
    if item_count_value < 0 or item_count_value > 256:
        return -1
    let item_count = Int(item_count_value)

    var string_lengths = InlineArray[Int, 256](fill=0)
    var string_bytes = InlineArray[Int, 8192](fill=0)
    var indices = InlineArray[Int, 256](fill=0)
    var input_position = 1
    for string_index in range(item_count):
        if input_position >= Int(length):
            return -1
        let string_length_value = input[input_position]
        if string_length_value < 0 or string_length_value > 32:
            return -1
        let string_length = Int(string_length_value)
        input_position += 1
        if input_position + string_length > Int(length):
            return -1
        string_lengths[string_index] = string_length
        indices[string_index] = string_index
        for byte_index in range(string_length):
            let byte_value = input[input_position + byte_index]
            if byte_value < 0 or byte_value > 255:
                return -1
            string_bytes[string_index * 32 + byte_index] = Int(byte_value)
        input_position += string_length
    if input_position != Int(length):
        return -1

    var stack_low = InlineArray[Int, 512](fill=0)
    var stack_high = InlineArray[Int, 512](fill=0)
    var stack_depth = InlineArray[Int, 512](fill=0)
    var stack_size = 1
    stack_low[0] = 0
    stack_high[0] = item_count
    stack_depth[0] = 0

    while stack_size > 0:
        stack_size -= 1
        let low = stack_low[stack_size]
        let high = stack_high[stack_size]
        let depth = stack_depth[stack_size]
        if high - low <= 1 or depth >= 32:
            continue

        var counts = InlineArray[Int, 257](fill=0)
        var starts = InlineArray[Int, 258](fill=0)
        var next = InlineArray[Int, 257](fill=0)
        for position in range(low, high):
            let string_index = indices[position]
            var key = 0
            if depth < string_lengths[string_index]:
                key = string_bytes[string_index * 32 + depth] + 1
            counts[key] += 1

        starts[0] = low
        for bucket in range(257):
            starts[bucket + 1] = starts[bucket] + counts[bucket]
            next[bucket] = starts[bucket]

        for bucket in range(257):
            while next[bucket] < starts[bucket + 1]:
                let position = next[bucket]
                let string_index = indices[position]
                var key = 0
                if depth < string_lengths[string_index]:
                    key = string_bytes[string_index * 32 + depth] + 1
                if key == bucket:
                    next[bucket] += 1
                else:
                    let destination = next[key]
                    let displaced = indices[destination]
                    indices[destination] = string_index
                    indices[position] = displaced
                    next[key] += 1

        var bucket = 256
        while bucket > 0:
            if counts[bucket] > 1:
                stack_low[stack_size] = starts[bucket]
                stack_high[stack_size] = starts[bucket + 1]
                stack_depth[stack_size] = depth + 1
                stack_size += 1
            bucket -= 1

    var checksum: Int64 = 0
    for rank in range(item_count):
        let string_index = indices[rank]
        let string_length = string_lengths[string_index]
        var contribution = Int64(string_length + 1)
        for byte_index in range(string_length):
            contribution += Int64(string_bytes[string_index * 32 + byte_index] + 1)
        checksum += Int64(rank + 1) * contribution
    return checksum
