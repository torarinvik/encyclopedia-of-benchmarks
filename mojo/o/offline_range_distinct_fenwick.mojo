from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn ordf_add(mut tree: InlineArray[Int64, 65], n: Int, position: Int, delta: Int64):
    var i = position+1
    while i <= n:
        tree[i] += delta
        i += i & -i

fn ordf_prefix(tree: InlineArray[Int64, 65], end: Int) -> Int64:
    var i = end
    var total: Int64 = 0
    while i > 0:
        total += tree[i]
        i &= i-1
    return total

@export("offline_range_distinct_fenwick")
fn offline_range_distinct_fenwick(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 195: return -1
    let nr = input[0]
    let qr = input[1]
    if nr < 1 or nr > 64 or qr < 0 or qr > 64: return -1
    let n = Int(nr)
    let q = Int(qr)
    if length != c_size_t(2+n+2*q): return -1
    for i in range(n):
        if input[2+i] < 0 or input[2+i] > 255: return -1
    var head = InlineArray[Int, 65](fill=-1)
    var next = InlineArray[Int, 64](fill=-1)
    var last = InlineArray[Int, 256](fill=-1)
    var tree = InlineArray[Int64, 65](fill=0)
    for i in range(q):
        let left = input[2+n+2*i]
        let right = input[3+n+2*i]
        if left < 0 or left > right or right > nr: return -1
        next[i] = head[Int(right)]
        head[Int(right)] = i
    var result: Int64 = 0
    for right in range(n+1):
        if right > 0:
            let value = Int(input[1+right])
            if last[value] >= 0: ordf_add(tree, n, last[value], -1)
            ordf_add(tree, n, right-1, 1)
            last[value] = right-1
        var query = head[right]
        while query >= 0:
            let left = Int(input[2+n+2*query])
            result += Int64(query+1)*(ordf_prefix(tree,right)-ordf_prefix(tree,left))
            query = next[query]
    return result
