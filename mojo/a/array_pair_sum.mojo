from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

fn pair_sift_down(mut values: List[Int64], root0: Int, count: Int):
    var root = root0
    while root * 2 + 1 < count:
        var child = root * 2 + 1
        if child + 1 < count and values[child] < values[child + 1]: child += 1
        if values[root] >= values[child]: return
        let temporary = values[root]
        values[root] = values[child]
        values[child] = temporary
        root = child

@export("array_pair_sum")
fn array_pair_sum(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length > 4096 or length % 2 != 0 or (length != 0 and input == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    var values = List[Int64](capacity=4096)
    for i in range(Int(length)):
        if input[i] < -2147483648 or input[i] > 2147483647: return -1
        values.append(input[i])
    for start in range(Int(length) / 2, 0, -1): pair_sift_down(values, start - 1, Int(length))
    for end in range(Int(length), 1, -1):
        let temporary = values[0]
        values[0] = values[end - 1]
        values[end - 1] = temporary
        pair_sift_down(values, 0, end - 1)
    var total: Int64 = 0
    for i in range(0, Int(length), 2): total += values[i]
    return total
