from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("lucky_number_sieve")
fn lucky_number_sieve(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                      output: UnsafePointer[UInt8, MutAnyOrigin],
                      capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let mode = input[0]
    let bound = input[1]
    if (mode != 0 and mode != 1) or bound < 0 or bound > 4096: return -1

    var candidates = InlineArray[Int64, 2048](fill=0)
    var count = 0
    var first = 1
    if mode == 1: first = 2
    for value in range(first, Int(bound) + 1, 2):
        candidates[count] = Int64(value)
        count += 1

    var selected = 1
    while selected < count:
        let step = Int(candidates[selected])
        if step > count: break
        var write = 0
        var rank = 0
        for read in range(count):
            rank += 1
            if rank % step != 0:
                candidates[write] = candidates[read]
                write += 1
        count = write
        selected += 1

    let output_bytes = count * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes):
        return -2
    for index in range(count):
        let bits = UInt64(candidates[index])
        for byte in range(8):
            output[index * 8 + byte] = UInt8((bits >> (byte * 8)) & 255)
    return Int64(output_bytes)
