from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("charoccurrence")
fn charoccurrence(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if length > 128 or (length != 0 and values == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var counts = InlineArray[Int64, 128](0)
    for i in range(length):
        if values[i] < 0 or values[i] > 127: return -1
        counts[values[i]] += 1
    var encoded = InlineArray[UInt8, 1024](0)
    var used: Int64 = 0
    for codepoint in range(128):
        if counts[codepoint] == 0: continue
        if used != 0:
            encoded[used] = 44
            used += 1
        for number in range(2):
            var value = codepoint if number == 0 else counts[codepoint]
            var digits = InlineArray[UInt8, 3](0)
            var digit_count: Int64 = 0
            while True:
                digits[digit_count] = UInt8(48 + value % 10)
                digit_count += 1
                value //= 10
                if value == 0: break
            while digit_count > 0:
                digit_count -= 1
                encoded[used] = digits[digit_count]
                used += 1
            if number == 0:
                encoded[used] = 61
                used += 1
    if used > output_capacity or (used != 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    for i in range(used): output[i] = encoded[i]
    return used
