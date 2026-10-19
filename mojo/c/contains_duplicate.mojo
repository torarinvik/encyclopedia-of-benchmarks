from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn duplicate_sift_down(values_arg: InlineArray[Int64, 1024], root_arg: Int64, length: Int64) -> InlineArray[Int64, 1024]:
    var values = values_arg
    var root = root_arg
    while root < length / 2:
        var child = root * 2 + 1
        if child + 1 < length and values[child] < values[child + 1]: child += 1
        if values[root] >= values[child]: break
        let temp = values[root]
        values[root] = values[child]
        values[child] = temp
        root = child
    return values

@export("contains_duplicate")
fn contains_duplicate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 1024 or (length != 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var values = InlineArray[Int64, 1024](0)
    for i in range(length):
        if input[i] < -2147483648 or input[i] > 2147483647: return -1
        values[i] = input[i]
    var start = Int64(length) / 2
    while start > 0:
        start -= 1
        values = duplicate_sift_down(values, start, Int64(length))
    var end = Int64(length)
    while end > 1:
        let temp = values[0]
        values[0] = values[end - 1]
        values[end - 1] = temp
        end -= 1
        values = duplicate_sift_down(values, 0, end)
    for i in range(1, length):
        if values[i - 1] == values[i]: return 1
    return 0
