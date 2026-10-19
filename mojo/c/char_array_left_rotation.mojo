from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("char_array_left_rotation")
fn char_array_left_rotation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 259: return -1
    let n = input[0]
    let rotation = input[1]
    if n < 0 or n > 256 or rotation < 0 or rotation > n or length != n + 2: return -1
    for i in range(n):
        if input[i + 2] < 0 or input[i + 2] > 127: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < n: return -2
    var staged = InlineArray[UInt8, 256](0)
    for i in range(n): staged[i] = UInt8(input[i + 2])
    if rotation > 0:
        var left: Int64 = 0
        var right = rotation - 1
        while left < right:
            let temp = staged[left]
            staged[left] = staged[right]
            staged[right] = temp
            left += 1
            right -= 1
    if rotation < n:
        var left = rotation
        var right = n - 1
        while left < right:
            let temp = staged[left]
            staged[left] = staged[right]
            staged[right] = temp
            left += 1
            right -= 1
    if n > 0:
        var left: Int64 = 0
        var right = n - 1
        while left < right:
            let temp = staged[left]
            staged[left] = staged[right]
            staged[right] = temp
            left += 1
            right -= 1
    for i in range(n): output[i] = staged[i]
    return n
