from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("connected_components_with_dsu")
fn connected_components_with_dsu(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or input[0] < 0 or input[0] > 256 or input[1] < 0 or input[1] > 2047: return -1
    let n = input[0]
    let m = input[1]
    if length != 2 + 2 * m: return -1
    var parent = InlineArray[Int64, 257](0)
    var sizes = InlineArray[Int64, 257](0)
    for node in range(1, n + 1):
        parent[node] = node
        sizes[node] = 1
    var components = n
    for e in range(m):
        let a = input[2 + 2 * e]
        let b = input[3 + 2 * e]
        if a < 1 or a > n or b < 1 or b > n: return -1
        var left = a
        while parent[left] != left:
            parent[left] = parent[parent[left]]
            left = parent[left]
        var right = b
        while parent[right] != right:
            parent[right] = parent[parent[right]]
            right = parent[right]
        if left == right: continue
        if sizes[left] < sizes[right]:
            let temp = left
            left = right
            right = temp
        parent[right] = left
        sizes[left] += sizes[right]
        components -= 1
    return components
