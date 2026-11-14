from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("johnson_trotter_adjacent_gray_code")
fn johnson_trotter_adjacent_gray_code(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 1: return -1
    let n0 = input[0]
    if n0 < 1 or n0 > 3: return -1
    let n = Int(n0)
    var rows = 1
    for i in range(2, n + 1): rows *= i
    let bytes = 8 * n * rows
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var permutation = List[Int](length=n, fill=0)
    var direction = List[Int](length=n + 1, fill=-1)
    for i in range(n): permutation[i] = i + 1
    var row = 0
    while True:
        for i in range(n):
            let value = Int64(permutation[i])
            for byte in range(8): output[8 * (row * n + i) + byte] = UInt8((value >> (8 * byte)) & 255)
        row += 1
        var largest = 0
        var position = -1
        for i in range(n):
            let value = permutation[i]
            let neighbor = i + direction[value]
            if neighbor >= 0 and neighbor < n and value > permutation[neighbor] and value > largest:
                largest = value
                position = i
        if position < 0: break
        let neighbor = position + direction[largest]
        permutation[position] = permutation[neighbor]
        permutation[neighbor] = largest
        for value in range(largest + 1, n + 1): direction[value] = -direction[value]
    return Int64(bytes)
