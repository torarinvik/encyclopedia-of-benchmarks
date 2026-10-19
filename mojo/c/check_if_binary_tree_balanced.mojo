from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn balanced_height(nodes: UnsafePointer[Int64, ImmutAnyOrigin], count: Int64, node: Int64) -> Int64:
    if node == -1: return 0
    if node < 0 or node >= count: return -1
    let left = nodes[3 * node + 1]
    let right = nodes[3 * node + 2]
    if left < -1 or left >= count or right < -1 or right >= count: return -1
    let left_height = balanced_height(nodes, count, left)
    if left_height == -1: return -1
    if left_height == -2: return -2
    let right_height = balanced_height(nodes, count, right)
    if right_height == -1: return -1
    if right_height == -2: return -2
    let difference = left_height - right_height if left_height >= right_height else right_height - left_height
    if difference > 1: return -2
    return 1 + (left_height if left_height > right_height else right_height)

@export("check_if_binary_tree_balanced")
fn check_if_binary_tree_balanced(nodes: UnsafePointer[Int64, ImmutAnyOrigin], node_count: c_size_t, root_index: Int64) abi("C") -> Int64:
    if node_count > 1023: return -1
    if node_count == 0: return 1 if root_index == -1 else -1
    if nodes == UnsafePointer[Int64, ImmutAnyOrigin]() or root_index < 0 or root_index >= node_count: return -1
    let height = balanced_height(nodes, Int64(node_count), root_index)
    if height == -1: return -1
    return 0 if height == -2 else 1
