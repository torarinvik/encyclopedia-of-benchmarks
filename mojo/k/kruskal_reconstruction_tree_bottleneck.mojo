from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias KRT_MAX_N = 8
alias KRT_MAX_M = 16
alias KRT_MAX_Q = 8
alias KRT_MAX_TREE = 15
alias KRT_LEVELS = 4
alias KRT_MAX_INPUT = 67

fn krt_find(inout parent: InlineArray[Int64, KRT_MAX_N], vertex: Int) -> Int:
    var root = vertex
    while parent[root] != Int64(root): root = Int(parent[root])
    var cursor = vertex
    while parent[cursor] != Int64(cursor):
        let next = Int(parent[cursor])
        parent[cursor] = Int64(root)
        cursor = next
    return root

fn krt_lca(source_value: Int, destination_value: Int,
    depth: InlineArray[Int, KRT_MAX_TREE],
    ancestor: InlineArray[Int, KRT_LEVELS * KRT_MAX_TREE]) -> Int:
    var source = source_value
    var destination = destination_value
    if depth[source] < depth[destination]:
        let temporary = source
        source = destination
        destination = temporary
    var difference = depth[source] - depth[destination]
    var bit = 0
    while difference > 0:
        if (difference & 1) != 0:
            source = ancestor[bit * KRT_MAX_TREE + source]
        difference >>= 1
        bit += 1
    if source == destination: return source
    for level in range(KRT_LEVELS - 1, -1, -1):
        let source_ancestor = ancestor[level * KRT_MAX_TREE + source]
        let destination_ancestor = ancestor[level * KRT_MAX_TREE + destination]
        if source_ancestor != destination_ancestor:
            source = source_ancestor
            destination = destination_ancestor
    return ancestor[source]

@export("kruskal_reconstruction_tree_bottleneck")
fn kruskal_reconstruction_tree_bottleneck(input: UnsafePointer[Int64, ImmutAnyOrigin],
    length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > KRT_MAX_INPUT:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    let q_value = input[2]
    if n_value < 1 or n_value > KRT_MAX_N or m_value < 0 or m_value > KRT_MAX_M or
        q_value < 1 or q_value > KRT_MAX_Q:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    let q = Int(q_value)
    let query_start = 3 + 3 * m
    if length != c_size_t(query_start + 2 * q): return -1

    var edge_u = InlineArray[Int, KRT_MAX_M]()
    var edge_v = InlineArray[Int, KRT_MAX_M]()
    var edge_weight = InlineArray[Int64, KRT_MAX_M]()
    for edge in range(m):
        let u = input[3 + 3 * edge]
        let v = input[4 + 3 * edge]
        let weight = input[5 + 3 * edge]
        if u < 0 or u >= n_value or v < 0 or v >= n_value or weight < 0 or weight > 1_000_000:
            return -1
        edge_u[edge] = Int(u)
        edge_v[edge] = Int(v)
        edge_weight[edge] = weight
    for query in range(q):
        let source = input[query_start + 2 * query]
        let destination = input[query_start + 2 * query + 1]
        if source < 0 or source >= n_value or destination < 0 or destination >= n_value:
            return -1

    for edge in range(1, m):
        let u = edge_u[edge]
        let v = edge_v[edge]
        let weight = edge_weight[edge]
        var position = edge
        while position > 0 and edge_weight[position - 1] > weight:
            edge_u[position] = edge_u[position - 1]
            edge_v[position] = edge_v[position - 1]
            edge_weight[position] = edge_weight[position - 1]
            position -= 1
        edge_u[position] = u
        edge_v[position] = v
        edge_weight[position] = weight

    var dsu_parent = InlineArray[Int64, KRT_MAX_N]()
    var dsu_size = InlineArray[Int, KRT_MAX_N]()
    var component_tree = InlineArray[Int, KRT_MAX_N]()
    var tree_parent = InlineArray[Int64, KRT_MAX_TREE]()
    var tree_left = InlineArray[Int64, KRT_MAX_TREE]()
    var tree_right = InlineArray[Int64, KRT_MAX_TREE]()
    var tree_weight = InlineArray[Int64, KRT_MAX_TREE]()
    for node in range(KRT_MAX_TREE):
        tree_parent[node] = -1
        tree_left[node] = -1
        tree_right[node] = -1
    for vertex in range(n):
        dsu_parent[vertex] = Int64(vertex)
        dsu_size[vertex] = 1
        component_tree[vertex] = vertex

    var next_tree_node = n
    for edge in range(m):
        var root_u = krt_find(inout dsu_parent, edge_u[edge])
        var root_v = krt_find(inout dsu_parent, edge_v[edge])
        if root_u == root_v: continue
        let left = component_tree[root_u]
        let right = component_tree[root_v]
        let merge_node = next_tree_node
        next_tree_node += 1
        tree_left[merge_node] = Int64(left)
        tree_right[merge_node] = Int64(right)
        tree_weight[merge_node] = edge_weight[edge]
        tree_parent[left] = Int64(merge_node)
        tree_parent[right] = Int64(merge_node)
        if dsu_size[root_u] < dsu_size[root_v]:
            let temporary = root_u
            root_u = root_v
            root_v = temporary
        dsu_parent[root_v] = Int64(root_u)
        dsu_size[root_u] += dsu_size[root_v]
        component_tree[root_u] = merge_node

    var depth = InlineArray[Int, KRT_MAX_TREE]()
    var ancestor = InlineArray[Int, KRT_LEVELS * KRT_MAX_TREE]()
    for node in range(next_tree_node - 1, -1, -1):
        if tree_parent[node] < 0:
            ancestor[node] = node
        else:
            let parent = Int(tree_parent[node])
            ancestor[node] = parent
            depth[node] = depth[parent] + 1
    for level in range(1, KRT_LEVELS):
        for node in range(next_tree_node):
            let middle = ancestor[(level - 1) * KRT_MAX_TREE + node]
            ancestor[level * KRT_MAX_TREE + node] =
                ancestor[(level - 1) * KRT_MAX_TREE + middle]

    var checksum: Int64 = 0
    for query in range(q):
        let source = Int(input[query_start + 2 * query])
        let destination = Int(input[query_start + 2 * query + 1])
        var answer: Int64 = 0
        if source != destination:
            let root_u = krt_find(inout dsu_parent, source)
            let root_v = krt_find(inout dsu_parent, destination)
            if root_u != root_v:
                answer = -1
            else:
                let lca_node = krt_lca(source, destination, depth, ancestor)
                answer = tree_weight[lca_node]
        checksum += Int64(query + 1) * (answer + 2)
    return checksum
