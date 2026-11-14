from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("merge_find_set")
fn merge_find_set(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 1028:
        return -1
    if input[0] < 1 or input[0] > 256 or input[1] < 0 or input[1] > 512:
        return -1
    let n = Int(input[0])
    let count = Int(input[1])
    if Int(length) != 2 * count + 3:
        return -1
    var parents = InlineArray[Int, 256](fill=0)
    var ranks = InlineArray[Int, 256](fill=0)
    for i in range(n): parents[i] = i
    for i in range(count):
        let x = input[2 + 2 * i]
        let y = input[3 + 2 * i]
        if x < 0 or x >= Int64(n) or y < 0 or y >= Int64(n):
            return -1
        var a = Int(x)
        var b = Int(y)
        while parents[a] != a: a = parents[a]
        while parents[b] != b: b = parents[b]
        if a != b:
            if ranks[a] < ranks[b]:
                parents[a] = b
            elif ranks[a] > ranks[b]:
                parents[b] = a
            else:
                parents[a] = b
                ranks[b] += 1
    let query = input[Int(length) - 1]
    if query < 0 or query >= Int64(n): return -1
    var root = Int(query)
    while parents[root] != root: root = parents[root]
    return Int64(root)
