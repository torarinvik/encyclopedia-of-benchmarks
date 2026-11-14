from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s256_array_expansion")
fn tsvc_s256_array_expansion(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 5 or length > 530: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 16 or input[1] < -1000 or input[1] > 1000: return -1
    let n = Int(n0)
    let cells = n * n
    if length != c_size_t(2 + n + 2 * cells): return -1
    for i in range(2, 2 + n + cells):
        if input[i] < -1000 or input[i] > 1000: return -1
    for i in range(2 + n + cells, 2 + n + 2 * cells):
        if input[i] < -1000000 or input[i] > 1000000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8 * (n + cells)): return -2
    var a = List[Int64](length=n, fill=0)
    var c = List[Int64](length=cells, fill=0)
    a[0] = input[1]
    for i in range(cells):
        c[i] = input[2 + n + cells + i]
    for column in range(n):
        for row in range(1, n):
            a[row] = 1 - a[row - 1]
            let cell = row * n + column
            c[cell] = a[row] + input[2 + n + cell] * input[2 + row]
    for i in range(n + cells):
        var value: Int64 = 0
        if i < n:
            value = a[i]
        else:
            value = c[i - n]
        for byte in range(8): output[8 * i + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(n + cells)
