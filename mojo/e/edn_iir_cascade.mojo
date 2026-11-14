# Independent bounded implementation of the documented Q15 cascade; see NOTICE.txt.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("edn_iir_cascade")
fn edn_iir_cascade(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > 50: return -1
    let count0 = input[0]
    if count0 < 1 or count0 > 8 or length != c_size_t(2 + 6 * count0): return -1
    let count = Int(count0)
    for i in range(1, 2 + 6 * count):
        if input[i] < -1024 or input[i] > 1023: return -1
    let bytes = 8 * (1 + 2 * count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var x = input[1]
    var state = List[Int64](length=2 * count, fill=0)
    for i in range(2 * count): state[i] = input[2 + 4 * count + i]
    for section in range(count):
        let offset = 2 + 4 * section
        let s0 = state[2 * section]
        let s1 = state[2 * section + 1]
        let t = x + ((input[offset + 2] * s0 + input[offset + 3] * s1) >> 15)
        x = t + ((input[offset] * s0 + input[offset + 1] * s1) >> 15)
        state[2 * section + 1] = s0
        state[2 * section] = t
    for word in range(1 + 2 * count):
        var value = x
        if word > 0: value = state[word - 1]
        for byte in range(8): output[8 * word + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(bytes)
