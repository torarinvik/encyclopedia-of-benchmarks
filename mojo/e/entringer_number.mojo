from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("entringer_number")
fn entringer_number(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let n = values[0]
    let target = values[1]
    if n < 0 or n > 12 or target < 0 or target > n: return -1
    var previous = InlineArray[Int64, 13]()
    var current = InlineArray[Int64, 13]()
    previous[0] = 1
    for row in range(1, Int(n) + 1):
        current[0] = 0
        for col in range(1, row + 1):
            current[col] = current[col - 1] + previous[row - col]
        for i in range(13):
            previous[i] = current[i]
            current[i] = 0
    return previous[Int(target)]
