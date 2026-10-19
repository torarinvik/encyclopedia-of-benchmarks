from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

comptime INVALID_RESULT: Int64 = -9_000_000_000_000_000_000
@export("binary_tree_node_sum")
fn binary_tree_node_sum(nodes: UnsafePointer[Int64, ImmutAnyOrigin], node_count: c_size_t, root: Int64) abi("C") -> Int64:
    if nodes == UnsafePointer[Int64, ImmutAnyOrigin]() or node_count == 0 or node_count > 900 or root < 0 or root >= node_count: return INVALID_RESULT
    let n = Int(node_count); var seen = List[Bool](capacity=n); for _ in range(n): seen.append(False)
    var stack = List[Int](capacity=n); stack.append(Int(root)); var total: Int64 = 0
    while len(stack) > 0:
        let u = stack.pop()
        if seen[u]: return INVALID_RESULT
        seen[u] = True
        let value = nodes[3 * u]; let l = nodes[3 * u + 1]; let r = nodes[3 * u + 2]
        if value < -1_000_000_000 or value > 1_000_000_000 or l < -1 or l >= node_count or r < -1 or r >= node_count: return INVALID_RESULT
        total += value
        if l >= 0: stack.append(Int(l))
        if r >= 0: stack.append(Int(r))
    return total
