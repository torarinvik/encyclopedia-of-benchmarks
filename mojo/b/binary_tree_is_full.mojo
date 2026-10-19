from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("binary_tree_is_full")
fn binary_tree_is_full(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2: return -1
    let nv = input[0]; let rootv = input[1]
    if nv < 1 or nv > 1024 or rootv < 0 or rootv >= nv or length != c_size_t(2 + 2 * nv): return -1
    let n = Int(nv); let root = Int(rootv); var left = List[Int](capacity=n); var right = List[Int](capacity=n); var parents = List[Int](capacity=n)
    var full = True
    for _ in range(n): parents.append(0)
    for i in range(n):
        let l = input[2 + 2 * i]; let r = input[3 + 2 * i]
        if l < -1 or l >= nv or r < -1 or r >= nv or l == i or r == i: return -1
        left.append(Int(l)); right.append(Int(r))
        if l >= 0: parents[Int(l)] += 1
        if r >= 0: parents[Int(r)] += 1
        if (l < 0) != (r < 0): full = False
    if parents[root] != 0: return -1
    for i in range(n):
        if i != root and parents[i] != 1: return -1
    var seen = List[Bool](capacity=n); for _ in range(n): seen.append(False)
    var stack = List[Int](capacity=n); stack.append(root); var visited = 0
    while len(stack) > 0:
        let u = stack.pop()
        if seen[u]: return -1
        seen[u] = True; visited += 1
        if left[u] >= 0: stack.append(left[u])
        if right[u] >= 0: stack.append(right[u])
    if visited != n: return -1
    return 1 if full else 0
