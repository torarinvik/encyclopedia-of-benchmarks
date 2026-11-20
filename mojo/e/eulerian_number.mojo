from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_N = 20

@export("eulerian_number")
fn eulerian_number(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let n = values[0]
    let target = values[1]
    if n < 0 or n > MAX_N or target < 0 or (n == 0 and target != 0) or (n > 0 and target >= n):
        return -1

    var previous = InlineArray[Int64, 21]()
    var current = InlineArray[Int64, 21]()
    previous[0] = 1
    for row in range(1, Int(n) + 1):
        for k in range(row):
            let same = previous[k]
            let fewer = previous[k - 1] if k > 0 else 0
            current[k] = Int64(k + 1) * same + Int64(row - k) * fewer
        for index in range(21):
            previous[index] = current[index]
            current[index] = 0
    return previous[Int(target)]
