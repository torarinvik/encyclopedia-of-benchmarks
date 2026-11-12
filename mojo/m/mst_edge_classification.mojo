from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime MST_MAX_VERTICES = 12
comptime MST_MAX_EDGES = 24
comptime MST_MAX_INPUT = 2 + 3 * MST_MAX_EDGES + 1

fn mst_find_root(mut parent: InlineArray[Int, MST_MAX_VERTICES], vertex: Int) -> Int:
    var root = vertex
    while parent[root] != root:
        root = parent[root]
    var current = vertex
    while parent[current] != current:
        let next = parent[current]
        parent[current] = root
        current = next
    root

fn mst_join(mut parent: InlineArray[Int, MST_MAX_VERTICES], left: Int, right: Int):
    let a = mst_find_root(mut parent, left)
    let b = mst_find_root(mut parent, right)
    if a != b: parent[b] = a

fn mst_alternative_path_exists(left: InlineArray[Int, MST_MAX_EDGES],
        right: InlineArray[Int, MST_MAX_EDGES], edge_id: InlineArray[Int, MST_MAX_EDGES],
        edge_count: Int, omitted: Int, source: Int, target: Int) -> Bool:
    var seen = InlineArray[Bool, MST_MAX_VERTICES](fill=False)
    var queue = InlineArray[Int, MST_MAX_VERTICES](fill=0)
    var head = 0
    var tail = 0
    seen[source] = True
    queue[tail] = source
    tail += 1
    while head < tail:
        let vertex = queue[head]
        head += 1
        if vertex == target: return True
        for edge in range(edge_count):
            if edge_id[edge] == omitted: continue
            var neighbor = -1
            if left[edge] == vertex: neighbor = right[edge]
            elif right[edge] == vertex: neighbor = left[edge]
            if neighbor >= 0 and not seen[neighbor]:
                seen[neighbor] = True
                queue[tail] = neighbor
                tail += 1
    False

@export("mst_edge_classification")
fn mst_edge_classification(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MST_MAX_INPUT: return -1
    if input[0] < 1 or input[0] > MST_MAX_VERTICES or input[1] < 0 or input[1] > MST_MAX_EDGES: return -1
    let vertex_count = Int(input[0])
    let edge_count = Int(input[1])
    if Int(length) != 2 + 3 * edge_count: return -1

    var left = InlineArray[Int, MST_MAX_EDGES](fill=0)
    var right = InlineArray[Int, MST_MAX_EDGES](fill=0)
    var weight = InlineArray[Int, MST_MAX_EDGES](fill=0)
    var order = InlineArray[Int, MST_MAX_EDGES](fill=0)
    var classes = InlineArray[UInt8, MST_MAX_EDGES](fill=0)
    for edge in range(edge_count):
        let u = input[2 + 3 * edge]
        let v = input[3 + 3 * edge]
        let w = input[4 + 3 * edge]
        if u < 0 or u >= v or v >= vertex_count or w < 0 or w > 20: return -1
        left[edge] = Int(u)
        right[edge] = Int(v)
        weight[edge] = Int(w)
        order[edge] = edge
        for prior in range(edge):
            if left[prior] == left[edge] and right[prior] == right[edge]: return -1
    for i in range(1, edge_count):
        let item = order[i]
        var j = i
        while j > 0 and (weight[order[j - 1]] > weight[item] or
                (weight[order[j - 1]] == weight[item] and order[j - 1] > item)):
            order[j] = order[j - 1]
            j -= 1
        order[j] = item

    var parent = InlineArray[Int, MST_MAX_VERTICES](fill=0)
    for vertex in range(vertex_count): parent[vertex] = vertex
    var start = 0
    while start < edge_count:
        var stop = start + 1
        let group_weight = weight[order[start]]
        while stop < edge_count and weight[order[stop]] == group_weight: stop += 1
        var q_left = InlineArray[Int, MST_MAX_EDGES](fill=0)
        var q_right = InlineArray[Int, MST_MAX_EDGES](fill=0)
        var q_id = InlineArray[Int, MST_MAX_EDGES](fill=0)
        var q_count = 0
        for pos in range(start, stop):
            let id = order[pos]
            let a = mst_find_root(mut parent, left[id])
            let b = mst_find_root(mut parent, right[id])
            if a != b:
                q_left[q_count] = a
                q_right[q_count] = b
                q_id[q_count] = id
                q_count += 1
        for edge in range(q_count):
            if mst_alternative_path_exists(q_left, q_right, q_id, q_count,
                    q_id[edge], q_left[edge], q_right[edge]):
                classes[q_id[edge]] = 1
            else:
                classes[q_id[edge]] = 2
        for pos in range(start, stop):
            let id = order[pos]
            mst_join(mut parent, left[id], right[id])
        start = stop
    let representative = mst_find_root(mut parent, 0)
    for vertex in range(1, vertex_count):
        if mst_find_root(mut parent, vertex) != representative: return -1
    if capacity < c_size_t(edge_count) or
            (edge_count > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()): return -2
    for edge in range(edge_count): output[edge] = classes[edge]
    Int64(edge_count)
