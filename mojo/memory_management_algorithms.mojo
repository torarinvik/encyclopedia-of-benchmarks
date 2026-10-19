from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MAX_BLOCKS = 16
comptime MAX_PROCESSES = 32
comptime MAX_INPUT_LENGTH = 52


fn write_i64_le(
    output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64
):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> (byte * 8)) & UInt64(255))


@export("memory_management_algorithms")
fn memory_management_algorithms(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let policy = input[0]
    let block_count = input[1]
    let process_count = input[2]
    if policy < 0 or policy > 3 or block_count < 1 or block_count > MAX_BLOCKS or process_count < 0 or process_count > MAX_PROCESSES:
        return -1
    if Int(length) != 3 + Int(block_count) + Int(process_count):
        return -1

    var blocks = InlineArray[Int64, MAX_BLOCKS](fill=0)
    for index in range(Int(block_count)):
        let size = input[3 + index]
        if size < 1 or size > 10000:
            return -1
        blocks[index] = size
    for index in range(Int(process_count)):
        let size = input[3 + Int(block_count) + index]
        if size < 1 or size > 10000:
            return -1

    var results = InlineArray[Int64, MAX_PROCESSES](fill=0)
    var counter: Int64 = 0
    for process_index in range(Int(process_count)):
        let request = input[3 + Int(block_count) + process_index]
        var selected: Int64 = -255
        if policy == 0:
            for block_index in range(Int(block_count)):
                if blocks[block_index] >= request:
                    selected = Int64(block_index)
                    blocks[block_index] -= request
                    break
        elif policy == 1:
            var smallest_leftover: Int64 = 10001
            for block_index in range(Int(block_count)):
                if blocks[block_index] >= request:
                    let leftover = blocks[block_index] - request
                    if leftover < smallest_leftover:
                        smallest_leftover = leftover
                        selected = Int64(block_index)
            if selected >= 0:
                blocks[Int(selected)] -= request
        elif policy == 2:
            var largest: Int64 = -1
            var largest_index = 0
            for block_index in range(Int(block_count)):
                if blocks[block_index] > largest:
                    largest = blocks[block_index]
                    largest_index = block_index
            if largest >= request:
                selected = Int64(largest_index)
                blocks[largest_index] -= request
        else:
            for offset in range(Int(block_count)):
                if counter + Int64(offset) >= block_count:
                    counter = -Int64(offset)
                let block_index = Int(Int64(offset) + counter)
                if blocks[block_index] >= request:
                    counter += Int64(offset)
                    selected = counter
                    blocks[block_index] -= request
                    break
            if selected == -255:
                counter += block_count
        results[process_index] = selected

    let output_bytes = Int(process_count) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for index in range(Int(process_count)):
        write_i64_le(output, index * 8, results[index])
    return Int64(output_bytes)
