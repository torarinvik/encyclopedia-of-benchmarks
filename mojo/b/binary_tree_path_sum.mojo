from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("binary_tree_path_sum")
fn binary_tree_path_sum(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2: return -1
    let target = input[0]; let nv = input[1]
    if nv < 0 or nv > 63 or length != c_size_t(2 + 3 * nv): return -1
    let n = Int(nv)
    if n == 0: return 0
    var parents = List[Int](capacity=n)
    for _ in range(n): parents.append(0)
    for u in range(n):
        let value = input[2 + 3 * u]; let l = input[3 + 3 * u]; let r = input[4 + 3 * u]
        if value < -2_147_483_648 or value > 2_147_483_647 or l < -1 or l >= nv or r < -1 or r >= nv: return -1
        if l >= 0: parents[Int(l)] += 1
        if r >= 0: parents[Int(r)] += 1
    if parents[0] != 0: return -1
    for i in range(1, n):
        if parents[i] != 1: return -1
    var seen = List[Bool](capacity=n); for _ in range(n): seen.append(False)
    var order = List[Int](capacity=n); var stack = List[Int](capacity=n); stack.append(0)
    while len(stack) > 0:
        let u = stack.pop()
        if seen[u]: return -1
        seen[u] = True; order.append(u)
        let l = input[3 + 3 * u]; let r = input[4 + 3 * u]
        if l >= 0: stack.append(Int(l))
        if r >= 0: stack.append(Int(r))
    if len(order) != n: return -1
    var result: Int64 = 0
    for start in range(n):
        var nodes = List[Int](capacity=n); var sums = List[Int64](capacity=n)
        nodes.append(start); sums.append(input[2 + 3 * start])
        while len(nodes) > 0:
            let u = nodes.pop(); let sum = sums.pop()
            if sum == target: result += 1
            let l = input[3 + 3 * u]; let r = input[4 + 3 * u]
            if l >= 0: nodes.append(Int(l)); sums.append(sum + input[2 + 3 * Int(l)])
            if r >= 0: nodes.append(Int(r)); sums.append(sum + input[2 + 3 * Int(r)])
    return result
