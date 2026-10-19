from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("fibonacci_search")
fn fibonacci_search(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, target: Int64) abi("C") -> Int64:
    if length == 0: return -1
    var fm2: Int64 = 0
    var fm1: Int64 = 1
    var fib: Int64 = 1
    while fib < length:
        fm2 = fm1
        fm1 = fib
        fib = fm2 + fm1
    var offset: Int64 = 0
    while fib > 1:
        var index = offset + fm2 - 1
        if index >= length: index = Int64(length) - 1
        let value = values[index]
        if value == target: return index
        if value < target:
            fib = fm1
            fm1 = fm2
            fm2 = fib - fm1
            offset = index + 1
        else:
            fib = fm2
            fm1 -= fm2
            fm2 = fib - fm1
    if fm1 != 0 and offset < length and values[offset] == target: return offset
    return -1
