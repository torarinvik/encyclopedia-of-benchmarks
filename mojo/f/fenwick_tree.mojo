from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn fenwick_prefix(tree: InlineArray[Int64, 257], count: Int64) -> Int64:
    var n = count
    var sum: Int64 = 0
    while n > 0:
        sum += tree[n]
        n -= n & (-n)
    return sum

@export("fenwick_tree_benchmark")
fn fenwick_tree_benchmark(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 1538: return -1
    let n = values[0]
    let ops = values[1]
    if n < 1 or n > 256 or ops < 0 or ops > 512 or length != 2 + 3 * ops: return -1
    for op in range(ops):
        let pos = 2 + 3 * op
        let code = values[pos]
        let first = values[pos + 1]
        let second = values[pos + 2]
        if code == 0:
            if first < 0 or first >= n or second < -1000000 or second > 1000000: return -1
        elif code == 1:
            if first < 0 or second < first or second >= n: return -1
        else: return -1
    var data = InlineArray[Int64, 256](0)
    var tree = InlineArray[Int64, 257](0)
    var checksum: Int64 = 0
    for op in range(ops):
        let pos = 2 + 3 * op
        let code = values[pos]
        let first = values[pos + 1]
        let second = values[pos + 2]
        if code == 0:
            data[first] += second
            var index = first + 1
            while index <= n:
                tree[index] += second
                index += index & (-index)
        else:
            let result = fenwick_prefix(tree, second + 1) - fenwick_prefix(tree, first)
            checksum += (op + 1) * (result + 131072000001)
    for i in range(n): checksum += (ops + i + 1) * (data[i] + 512000001)
    return checksum
