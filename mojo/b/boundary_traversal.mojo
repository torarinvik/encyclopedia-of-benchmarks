from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

fn boundary_leaf(input: UnsafePointer[Int64, ImmutAnyOrigin], node: Int) -> Bool:
    return input[node * 3 + 1] == -1 and input[node * 3 + 2] == -1

@export("boundary_traversal")
fn boundary_traversal(nodes: UnsafePointer[Int64, ImmutAnyOrigin], node_count: c_size_t, root: Int64, output: UnsafePointer[Int64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if node_count > 100 or capacity < node_count: return -1
    let n = Int(node_count)
    if n == 0: return 0 if root == -1 else -1
    if nodes == UnsafePointer[Int64, ImmutAnyOrigin]() or output == UnsafePointer[Int64, MutAnyOrigin]() or root < 0 or root >= node_count: return -1
    var parents = List[Int](capacity=n); var seen = List[Bool](capacity=n)
    for _ in range(n): parents.append(0); seen.append(False)
    for i in range(n):
        let val = nodes[3 * i]; let l = nodes[3 * i + 1]; let r = nodes[3 * i + 2]
        if val < -2_147_483_648 or val > 2_147_483_647 or l < -1 or l >= node_count or r < -1 or r >= node_count: return -1
        if l >= 0: parents[Int(l)] += 1
        if r >= 0: parents[Int(r)] += 1
    for i in range(n):
        if parents[i] != (0 if i == Int(root) else 1): return -1
    var todo = List[Int](capacity=n); todo.append(Int(root)); var visited = 0
    while len(todo) > 0:
        let u = todo.pop()
        if seen[u]: return -1
        seen[u] = True; visited += 1
        let l = nodes[3 * u + 1]; let r = nodes[3 * u + 2]
        if l >= 0: todo.append(Int(l))
        if r >= 0: todo.append(Int(r))
    if visited != n: return -1
    var result = List[Int64](capacity=n); let ri = Int(root)
    if not boundary_leaf(nodes, ri): result.append(nodes[3 * ri])
    var cur = Int(nodes[3 * ri + 1])
    if cur == -1 and nodes[3 * ri + 2] != -1: cur = Int(nodes[3 * ri + 2])
    while cur >= 0:
        if not boundary_leaf(nodes, cur): result.append(nodes[3 * cur])
        let l = nodes[3 * cur + 1]; let r = nodes[3 * cur + 2]
        cur = Int(l if l != -1 else r)
    var stack = List[Int](capacity=n); stack.append(ri)
    while len(stack) > 0:
        let u = stack.pop()
        if boundary_leaf(nodes, u): result.append(nodes[3 * u])
        else:
            let r = nodes[3 * u + 2]; let l = nodes[3 * u + 1]
            if r >= 0: stack.append(Int(r))
            if l >= 0: stack.append(Int(l))
    if nodes[3 * ri + 1] == -1 and nodes[3 * ri + 2] != -1:
        for i in range(len(result)): output[i] = result[i]
        return Int64(len(result))
    var right_boundary = List[Int64](capacity=n); cur = Int(nodes[3 * ri + 2])
    while cur >= 0:
        if not boundary_leaf(nodes, cur): right_boundary.append(nodes[3 * cur])
        let l = nodes[3 * cur + 1]; let r = nodes[3 * cur + 2]
        cur = Int(r if r != -1 else l)
    var j = len(right_boundary) - 1
    while j >= 0: result.append(right_boundary[j]); j -= 1
    for i in range(len(result)): output[i] = result[i]
    return Int64(len(result))
