from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn allocation_append_number(mut output: List[UInt8], value0: Int64):
    var value = value0
    var digits = List[UInt8](capacity=20)
    while True:
        digits.append(UInt8(48 + value % 10))
        value /= 10
        if value == 0:
            break
    for i in range(len(digits)):
        output.append(digits[len(digits) - 1 - i])

@export("allocation_number")
fn allocation_number(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                     output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2 or values[0] < 1 or values[0] > 1000000 or values[1] < 1 or values[1] > 128 or values[1] > values[0]:
        return -1
    let total = values[0]
    let partitions = values[1]
    let block = total / partitions
    var encoded = List[UInt8](capacity=1024)
    for i in range(partitions):
        let start = i * block + 1
        var end = (i + 1) * block
        if i + 1 == partitions:
            end = total
        if i != 0:
            encoded.append(44)
        allocation_append_number(encoded, start)
        encoded.append(45)
        allocation_append_number(encoded, end)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(len(encoded)):
        return -2
    for i in range(len(encoded)):
        output[i] = encoded[i]
    return Int64(len(encoded))
