from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("bst_interleave_bound")
fn bst_interleave_bound(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 36: return -1
    let nv = input[0]
    let rootv = input[1]
    if nv < 1 or nv > 8 or rootv < 0 or rootv >= nv: return -1
    let n = Int(nv)
    let root = Int(rootv)
    if length < c_size_t(3+2*n): return -1
    var left = List[Int](capacity=8)
    var right = List[Int](capacity=8)
    var parent = List[Int](capacity=8)
    var parent_count = List[Int](capacity=8)
    for _ in range(8):
        left.append(-1); right.append(-1); parent.append(-1); parent_count.append(0)
    for node in range(n):
        let lv = input[2+2*node]
        let rv = input[3+2*node]
        if lv < -1 or lv >= nv or rv < -1 or rv >= nv or lv == Int64(node) or rv == Int64(node) or (lv >= 0 and lv == rv): return -1
        left[node] = Int(lv)
        right[node] = Int(rv)
        if lv >= 0:
            parent_count[Int(lv)] += 1
            parent[Int(lv)] = node
        if rv >= 0:
            parent_count[Int(rv)] += 1
            parent[Int(rv)] = node
    if parent_count[root] != 0: return -1
    for node in range(n):
        if node != root and parent_count[node] != 1: return -1
    let countv = input[2+2*n]
    if countv < 0 or countv > 16: return -1
    let count = Int(countv)
    if length != c_size_t(3+2*n+count): return -1
    for i in range(count):
        if input[3+2*n+i] < 0 or input[3+2*n+i] >= nv: return -1
    # Every key must be found by an ordinary BST search from the root.
    for key in range(n):
        var node = root
        var steps = 0
        while node >= 0 and node != key and steps < n:
            if key < node: node = left[node]
            else: node = right[node]
            steps += 1
        if node != key: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    var bound = Int64(0)
    for pivot in range(n):
        var previous = -1
        for i in range(count):
            let key = Int(input[3+2*n+i])
            var ancestor = key
            while ancestor >= 0 and ancestor != pivot: ancestor = parent[ancestor]
            if ancestor == pivot:
                var side = 0
                if key > pivot: side = 1
                if previous >= 0 and side != previous: bound += 1
                previous = side
    var bits = bitcast[UInt64](bound)
    for byte in range(8):
        output[byte] = UInt8(bits & UInt64(255))
        bits = bits >> 8
    return 8
