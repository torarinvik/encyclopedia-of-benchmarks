from std.collections import List
from std.ffi import c_size_t
from std.memory import MutAnyOrigin, UnsafePointer

@export("shootout_strcat")
fn shootout_strcat(append_count: Int64, output: UnsafePointer[UInt8, MutAnyOrigin],
        capacity: c_size_t) abi("C") -> Int64:
    if append_count < 0 or append_count > 4096: return -1
    var text = List[UInt8](length=24577, fill=0)
    var length = 0
    var buffer_capacity = 32
    for _ in range(Int(append_count)):
        if buffer_capacity - length < 7: buffer_capacity *= 2
        text[length] = 104
        text[length + 1] = 101
        text[length + 2] = 108
        text[length + 3] = 108
        text[length + 4] = 111
        text[length + 5] = 10
        length += 6
        text[length] = 0
    var value = 0
    while text[value] != 0: value += 1
    var digits = List[UInt8]()
    while True:
        digits.append(UInt8(48 + value % 10))
        value //= 10
        if value == 0: break
    let size = len(digits) + 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(size): return -2
    for index in range(len(digits)):
        output[index] = digits[len(digits) - 1 - index]
    output[len(digits)] = 10
    return Int64(size)
