from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("myrvold_ruskey_permutation_unrank")
fn myrvold_ruskey_permutation_unrank(
    input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin],
    capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 3:
        return -1
    if length != 2:
        return -1
    let n_value = input[0]
    let rank_value = input[1]
    if n_value < 0 or n_value > 8 or rank_value < 0:
        return -1
    let n = Int(n_value)
    var factorial = Int64(1)
    var factor = 2
    while factor <= n:
        factorial *= Int64(factor)
        factor += 1
    if rank_value >= factorial:
        return -1

    let required = 8 * n
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required):
        return -2
    var permutation = List[Int64](capacity=8)
    for i in range(n):
        permutation.append(Int64(i))
    var remainder = rank_value
    var size = n
    while size > 0:
        let choice = Int(remainder % Int64(size))
        remainder = remainder // Int64(size)
        let held = permutation[size - 1]
        permutation[size - 1] = permutation[choice]
        permutation[choice] = held
        size -= 1

    for i in range(n):
        let value = UInt64(permutation[i])
        for byte in range(8):
            output[8 * i + byte] = UInt8((value >> (8 * byte)) & 255)
    return Int64(required)
