from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("binary_tree_postorder_traversal")
fn binary_tree_postorder_traversal(nodes: UnsafePointer[Int64, ImmutAnyOrigin], node_count: c_size_t, root: Int64,
        output: UnsafePointer[Int64, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if node_count > 100 or output_capacity < node_count: return -1
    let n = Int(node_count)
    if n == 0: return 0 if root == -1 else -1
    if nodes == UnsafePointer[Int64, ImmutAnyOrigin]() or output == UnsafePointer[Int64, MutAnyOrigin]() or root < 0 or root >= n: return -1
    var parents = List[Int](capacity=n); for _ in range(n): parents.append(0)
    for i in range(n):
        let l = nodes[3 * i + 1]; let r = nodes[3 * i + 2]
        if l < -1 or l >= n or r < -1 or r >= n: return -1
        if l >= 0: parents[Int(l)] += 1
        if r >= 0: parents[Int(r)] += 1
    for i in range(n):
        if parents[i] != (0 if i == Int(root) else 1): return -1
    var visited = List[Bool](capacity=n); for _ in range(n): visited.append(False)
    var stack = List[Int](capacity=n); stack.append(Int(root)); var order = List[Int64](capacity=n)
    while len(stack) > 0:
        let u = stack.pop()
        if visited[u]: return -1
        visited[u] = True; order.append(nodes[3 * u])
        let l = nodes[3 * u + 1]; let r = nodes[3 * u + 2]
        if l >= 0: stack.append(Int(l))
        if r >= 0: stack.append(Int(r))
    if len(order) != n: return -1
    for i in range(n // 2):
        let t = order[i]; order[i] = order[n - 1 - i]; order[n - 1 - i] = t
    for i in range(n): output[i] = order[i]
    return Int64(n)
