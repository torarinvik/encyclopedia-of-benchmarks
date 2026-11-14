from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn search_leg(input: UnsafePointer[Int64, ImmutAnyOrigin], edges: Int, labels: Int,
        signature: Int, signature_length: Int, node: Int, target_index: Int,
        mut visited: List[Bool]) -> Bool:
    if visited[node]: return False
    visited[node] = True
    let target_label = input[signature + target_index]
    for edge in range(edges):
        if input[3 + 2 * edge] != Int64(node): continue
        let target = Int(input[4 + 2 * edge])
        if input[labels + target] != target_label: continue
        if target_index + 1 == signature_length: return True
        var next_visited = List[Bool](length=10, fill=False)
        if search_leg(input, edges, labels, signature, signature_length, target, target_index + 1, next_visited): return True
    for edge in range(edges):
        if input[3 + 2 * edge] != Int64(node): continue
        let target = Int(input[4 + 2 * edge])
        if search_leg(input, edges, labels, signature, signature_length, target, target_index, visited): return True
    return False

@export("doe_pathfinder_signature_search")
fn doe_pathfinder_signature_search(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 217: return -2
    let n0 = input[0]
    let m0 = input[1]
    let s0 = input[2]
    if n0 < 1 or n0 > 10 or m0 < 0 or m0 > 100 or s0 < 2 or s0 > 4 or m0 > n0 * n0: return -2
    let n = Int(n0)
    let m = Int(m0)
    let s = Int(s0)
    if length != c_size_t(3 + 2 * m + n + s): return -2
    for edge in range(m):
        let source = input[3 + 2 * edge]
        let target = input[4 + 2 * edge]
        if source < 0 or source >= n0 or target < 0 or target >= n0: return -2
        for previous in range(edge):
            if input[3 + 2 * previous] == source and input[4 + 2 * previous] == target: return -2
    let labels = 3 + 2 * m
    let signature = labels + n
    for i in range(n):
        if input[labels + i] < -1 or input[labels + i] > 7: return -2
    for i in range(s):
        if input[signature + i] < 0 or input[signature + i] > 7: return -2
    for node in range(n):
        if input[labels + node] == input[signature]:
            var visited = List[Bool](length=10, fill=False)
            if search_leg(input, m, labels, signature, s, node, 1, visited): return 1
    return 0
