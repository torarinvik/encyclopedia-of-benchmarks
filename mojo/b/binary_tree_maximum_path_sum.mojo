from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("binary_tree_maximum_path_sum")
fn binary_tree_maximum_path_sum(nodes: UnsafePointer[Int64, ImmutAnyOrigin], node_count: c_size_t, root: Int64) abi("C") -> Int64:
    if nodes == UnsafePointer[Int64, ImmutAnyOrigin]() or node_count == 0 or node_count > 1023 or root < 0 or root >= node_count: return -1
    let n = Int(node_count); var seen = List[Bool](capacity=n); var order = List[Int](capacity=n); var stack = List[Int](capacity=n)
    for _ in range(n): seen.append(False)
    stack.append(Int(root))
    while len(stack) > 0:
        let u = stack.pop()
        if seen[u]: return -1
        seen[u] = True; order.append(u)
        let value = nodes[3 * u]; let l = nodes[3 * u + 1]; let r = nodes[3 * u + 2]
        if value < -1000 or value > 1000 or l < -1 or l >= node_count or r < -1 or r >= node_count: return -1
        if l >= 0: stack.append(Int(l))
        if r >= 0: stack.append(Int(r))
    if len(order) != n: return -1
    var gain = List[Int64](capacity=n); for _ in range(n): gain.append(0)
    var best: Int64 = -2_147_483_648
    for rev in range(n):
        let u = order[n - 1 - rev]; let value = nodes[3 * u]; let l = nodes[3 * u + 1]; let r = nodes[3 * u + 2]
        let gl = Int64(0) if l < 0 else max(Int64(0), gain[Int(l)])
        let gr = Int64(0) if r < 0 else max(Int64(0), gain[Int(r)])
        best = max(best, value + gl + gr)
        gain[u] = value + max(gl, gr)
    return best
