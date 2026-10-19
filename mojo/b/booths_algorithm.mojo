from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("booths_algorithm")
fn booths_algorithm(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length == 0 or length > 256: return -1
    let n = Int(length)
    for i in range(n):
        if input[i] < 0 or input[i] > 127: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < length: return -2
    var i = 0; var j = 1; var k = 0
    while i < n and j < n and k < n:
        let a = input[(i + k) % n]; let b = input[(j + k) % n]
        if a == b: k += 1
        elif a > b:
            i += k + 1
            if i <= j: i = j + 1
            k = 0
        else:
            j += k + 1
            if j <= i: j = i + 1
            k = 0
    let start = min(i, j)
    for x in range(n): output[x] = UInt8(input[(start + x) % n])
    return Int64(n)
