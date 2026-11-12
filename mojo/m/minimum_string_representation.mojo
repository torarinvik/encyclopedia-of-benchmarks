from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("minimum_string_representation")
fn minimum_string_representation(
    values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if length > 4096:
        return -1
    if length == 0:
        return 0
    if values == UnsafePointer[Int64, ImmutAnyOrigin]():
        return -1
    let n = Int(length)
    for index in range(n):
        if values[index] < 0 or values[index] > 127:
            return -1

    var left = 0
    var right = 1
    var matched = 0
    while left < n and right < n and matched < n:
        let a = values[(left + matched) % n]
        let b = values[(right + matched) % n]
        if a == b:
            matched += 1
            continue
        if a > b:
            left += matched + 1
            if left == right:
                left += 1
        else:
            right += matched + 1
            if left == right:
                right += 1
        matched = 0
    return Int64(min(left, right))
