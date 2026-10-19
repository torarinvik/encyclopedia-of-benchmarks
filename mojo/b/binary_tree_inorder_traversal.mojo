from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("binary_tree_inorder_traversal")
fn binary_tree_inorder_traversal(nodes: UnsafePointer[Int64, ImmutAnyOrigin], node_count: c_size_t, root: Int64,
        output: UnsafePointer[Int64, MutAnyOrigin], output_capacity: c_size_t) abi("C") -> Int64:
    if node_count > 100 or output_capacity < node_count: return -1
    let n = Int(node_count)
    if n == 0: return 0 if root == -1 else -1
    if nodes == UnsafePointer[Int64, ImmutAnyOrigin]() or output == UnsafePointer[Int64, MutAnyOrigin]() or root < 0 or root >= n: return -1
    var parents = List[Int](capacity=n); for _ in range(n): parents.append(0)
    for i in range(n):
        let value = nodes[3 * i]; let l = nodes[3 * i + 1]; let r = nodes[3 * i + 2]
        if value < -100 or value > 100 or l < -1 or l >= n or r < -1 or r >= n: return -1
        if l >= 0: parents[Int(l)] += 1
        if r >= 0: parents[Int(r)] += 1
    for i in range(n):
        if parents[i] != (0 if i == Int(root) else 1): return -1
    var visited = List[Bool](capacity=n); for _ in range(n): visited.append(False)
    var stack = List[Int](capacity=n); stack.append(Int(root)); var seen_count = 0
    while len(stack) > 0:
        let u = stack.pop()
        if visited[u]: return -1
        visited[u] = True; seen_count += 1
        if nodes[3 * u + 1] >= 0: stack.append(Int(nodes[3 * u + 1]))
        if nodes[3 * u + 2] >= 0: stack.append(Int(nodes[3 * u + 2]))
    if seen_count != n: return -1
    var order = List[Int64](capacity=n); var path = List[Int](capacity=n); var cur = Int(root)
    while cur >= 0 or len(path) > 0:
        while cur >= 0: path.append(cur); cur = Int(nodes[3 * cur + 1])
        cur = path.pop(); order.append(nodes[3 * cur]); cur = Int(nodes[3 * cur + 2])
    for i in range(n): output[i] = order[i]
    return Int64(n)
