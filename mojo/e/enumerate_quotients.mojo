from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("enumerate_quotients")
fn enumerate_quotients(value: Int64, output: UnsafePointer[UInt8, MutAnyOrigin],
                       capacity: c_size_t) abi("C") -> Int64:
    if value < 1 or value > 100_000: return -1
    let n = UInt64(value)
    var count = 0
    var left = UInt64(1)
    while left <= n:
        let quotient = n // left
        count += 1
        left = n // quotient + 1
    let byte_count = (count + 1) * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(byte_count): return -2
    let count_word = UInt64(count)
    for byte in range(8): output[byte] = UInt8((count_word >> (byte * 8)) & UInt64(255))
    var index = 0
    left = 1
    while left <= n:
        let quotient = n // left
        for byte in range(8): output[(index + 1) * 8 + byte] = UInt8((quotient >> (byte * 8)) & UInt64(255))
        index += 1
        left = n // quotient + 1
    return Int64(byte_count)
