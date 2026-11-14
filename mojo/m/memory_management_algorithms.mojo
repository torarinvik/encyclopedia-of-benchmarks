from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("memory_management_algorithms")
fn memory_management_algorithms(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 52:
        return -1
    let policy = input[0]
    if policy < 0 or policy > 3 or input[1] < 1 or input[1] > 16 or input[2] < 0 or input[2] > 32:
        return -1
    let block_count = Int(input[1])
    let process_count = Int(input[2])
    if Int(length) != 3 + block_count + process_count:
        return -1
    var blocks = InlineArray[Int64, 16](fill=0)
    for i in range(block_count):
        if input[3 + i] < 1 or input[3 + i] > 10000: return -1
        blocks[i] = input[3 + i]
    for i in range(process_count):
        if input[3 + block_count + i] < 1 or input[3 + block_count + i] > 10000: return -1
    var result = InlineArray[Int64, 32](fill=0)
    var counter = 0
    for p in range(process_count):
        let size = input[3 + block_count + p]
        var selected = -1
        if policy == 0:
            for i in range(block_count):
                if blocks[i] >= size:
                    selected = i
                    break
        elif policy == 1:
            for i in range(block_count):
                if blocks[i] >= size:
                    if selected < 0:
                        selected = i
                    elif blocks[i] < blocks[selected]:
                        selected = i
        elif policy == 2:
            var largest = 0
            for i in range(1, block_count):
                if blocks[i] > blocks[largest]: largest = i
            if blocks[largest] >= size: selected = largest
        else:
            for offset in range(block_count):
                if counter + offset >= block_count: counter = -offset
                let index = counter + offset
                if blocks[index] >= size:
                    counter += offset
                    selected = counter
                    break
            if selected < 0: counter += block_count
        if selected < 0:
            result[p] = -255
        else:
            result[p] = Int64(selected)
            blocks[selected] -= size
    let bytes = process_count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes):
        return -2
    for i in range(process_count):
        for byte in range(8):
            output[8 * i + byte] = UInt8((result[i] >> (8 * byte)) & 255)
    return Int64(bytes)
