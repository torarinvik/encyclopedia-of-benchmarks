from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_NODE_COUNT = 1023

fn tree_height(nodes: UnsafePointer[Int64, ImmutAnyOrigin], node_count: Int, node: Int64) -> Int64:
    if node == -1: return 0
    if node < 0 or node >= node_count: return -1
    let index = Int(node)
    let left = nodes[3 * index + 1]
    let right = nodes[3 * index + 2]
    if left < -1 or (left >= 0 and left >= node_count) or right < -1 or (right >= 0 and right >= node_count): return -1
    let left_height = tree_height(nodes, node_count, left)
    if left_height < 0: return -1
    let right_height = tree_height(nodes, node_count, right)
    if right_height < 0: return -1
    return 1 + max(left_height, right_height)

fn balanced_visit(nodes: UnsafePointer[Int64, ImmutAnyOrigin], node_count: Int, node: Int64) -> Int64:
    if node == -1: return 1
    if node < 0 or node >= node_count: return -1
    let index = Int(node)
    let left = nodes[3 * index + 1]
    let right = nodes[3 * index + 2]
    if left < -1 or (left >= 0 and left >= node_count) or right < -1 or (right >= 0 and right >= node_count): return -1
    let lh = tree_height(nodes, node_count, left)
    if lh < 0: return -1
    let rh = tree_height(nodes, node_count, right)
    if rh < 0: return -1
    if abs(lh - rh) > 1: return 0
    let left_result = balanced_visit(nodes, node_count, left)
    if left_result <= 0: return left_result
    return balanced_visit(nodes, node_count, right)

@export("balanced_binary_tree")
fn balanced_binary_tree(nodes: UnsafePointer[Int64, ImmutAnyOrigin], node_count: c_size_t,
                        root_index: Int64) abi("C") -> Int64:
    if node_count > MAX_NODE_COUNT: return -1
    if node_count == 0: return 1 if root_index == -1 else -1
    let count = Int(node_count)
    if nodes == UnsafePointer[Int64, ImmutAnyOrigin]() or root_index < 0 or root_index >= count: return -1
    return balanced_visit(nodes, count, root_index)
