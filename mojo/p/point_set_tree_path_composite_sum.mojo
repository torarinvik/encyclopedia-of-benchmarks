from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime PTS_MAX_N = 16
comptime PTS_MAX_Q = 32
comptime PTS_MAX_E = PTS_MAX_N - 1
comptime PTS_MAX_CLUSTERS = 75
comptime PTS_MAX_INPUT = 238
comptime PTS_MOD: Int64 = 998244353
comptime PTS_VERTEX: Int16 = 0
comptime PTS_EDGE: Int16 = 1
comptime PTS_RAKE: Int16 = 2
comptime PTS_BRANCH: Int16 = 3
comptime PTS_ATTACH: Int16 = 4
comptime PTS_COMPRESS: Int16 = 5

@fieldwise_init
struct Affine(Copyable):
    var mul: Int64
    var add: Int64

@fieldwise_init
struct Cluster(Copyable):
    var kind: Int16
    var a: Int16
    var b: Int16
    var parent: Int16
    var shared: Int16
    var boundary0: Int16
    var boundary1: Int16
    var boundary_count: Int16
    var edge: Int16
    var has0: Bool
    var has1: Bool
    var mask: UInt16
    var count: Int32
    var sum0: Int64
    var sum1: Int64
    var forward: Affine
    var reverse: Affine

@fieldwise_init
struct Outside(Copyable):
    var sum0: Int64
    var count0: Int64
    var sum1: Int64
    var count1: Int64

@fieldwise_init
struct SumCount(Copyable):
    var sum: Int64
    var count: Int64

@fieldwise_init
struct Context(Copyable):
    var nodes: InlineArray[Cluster, PTS_MAX_CLUSTERS]
    var values: InlineArray[Int64, PTS_MAX_N]
    var edge_map: InlineArray[Affine, PTS_MAX_E]
    var edge_u: InlineArray[Int16, PTS_MAX_E]
    var edge_v: InlineArray[Int16, PTS_MAX_E]
    var vertex_leaf: InlineArray[Int16, PTS_MAX_N]
    var edge_leaf: InlineArray[Int16, PTS_MAX_E]
    var adjacency: InlineArray[Bool, PTS_MAX_N * PTS_MAX_N]
    var edge_cluster: InlineArray[Int16, PTS_MAX_N * PTS_MAX_N]
    var active: InlineArray[Bool, PTS_MAX_N]
    var branches: InlineArray[Int16, PTS_MAX_N * PTS_MAX_N]
    var branch_count: InlineArray[Int, PTS_MAX_N]
    var node_count: Int

fn pts_norm(value: Int64) -> Int64:
    let remainder = value % PTS_MOD
    if remainder < 0: return remainder + PTS_MOD
    return remainder

fn pts_identity() -> Affine:
    return Affine(1, 0)

fn pts_compose(outer: Affine, inner: Affine) -> Affine:
    return Affine(outer.mul * inner.mul % PTS_MOD,
                  (outer.mul * inner.add + outer.add) % PTS_MOD)

fn pts_apply(mapping: Affine, sum: Int64, count: Int64) -> Int64:
    return (mapping.mul * sum + mapping.add * count) % PTS_MOD

fn pts_boundary_index(node: Cluster, vertex: Int16) -> Int16:
    if node.boundary0 == vertex: return 0
    if node.boundary_count == 2 and node.boundary1 == vertex: return 1
    return -1

fn pts_has(node: Cluster, vertex: Int16) -> Bool:
    let index = pts_boundary_index(node, vertex)
    if index == 0: return node.has0
    if index == 1: return node.has1
    return False

fn pts_sum_at(node: Cluster, vertex: Int16) -> Int64:
    if pts_boundary_index(node, vertex) == 0: return node.sum0
    return node.sum1

fn pts_map_at(node: Cluster, from: Int16, to: Int16) -> Affine:
    if from == to or node.boundary_count != 2: return pts_identity()
    if node.boundary0 == from and node.boundary1 == to: return node.forward
    return node.reverse

fn pts_recalculate(mut context: Context, id: Int):
    let kind = context.nodes[id].kind
    if kind == PTS_VERTEX:
        let vertex = Int(context.nodes[id].boundary0)
        context.nodes[id].count = 1
        context.nodes[id].mask = UInt16(1) << UInt(vertex)
        context.nodes[id].sum0 = context.values[vertex]
        context.nodes[id].has0 = True
        return
    if kind == PTS_EDGE:
        let edge = Int(context.nodes[id].edge)
        context.nodes[id].forward = context.edge_map[edge]
        context.nodes[id].reverse = context.edge_map[edge]
        return

    let parent = context.nodes[id]
    let a = context.nodes[Int(parent.a)]
    let b = context.nodes[Int(parent.b)]
    let shared = parent.shared
    let overlap = pts_has(a, shared) and pts_has(b, shared)
    let duplicate_count = 1 if overlap else 0
    var duplicate: Int64 = 0
    if overlap: duplicate = context.values[Int(shared)]
    context.nodes[id].count = Int32(Int(a.count) + Int(b.count) - duplicate_count)
    context.nodes[id].mask = a.mask | b.mask

    for index in range(Int(parent.boundary_count)):
        let boundary = parent.boundary0 if index == 0 else parent.boundary1
        var total: Int64 = 0
        if boundary == shared:
            total = pts_norm(pts_sum_at(a, shared) + pts_sum_at(b, shared) - duplicate)
        elif pts_boundary_index(a, boundary) >= 0:
            let sibling = pts_norm(pts_sum_at(b, shared) - duplicate)
            total = (pts_sum_at(a, boundary) +
                pts_apply(pts_map_at(a, boundary, shared), sibling,
                          Int64(Int(b.count) - duplicate_count))) % PTS_MOD
        else:
            let sibling = pts_norm(pts_sum_at(a, shared) - duplicate)
            total = (pts_sum_at(b, boundary) +
                pts_apply(pts_map_at(b, boundary, shared), sibling,
                          Int64(Int(a.count) - duplicate_count))) % PTS_MOD
        let boundary_has = pts_has(a, boundary) or pts_has(b, boundary)
        if index == 0:
            context.nodes[id].sum0 = total
            context.nodes[id].has0 = boundary_has
        else:
            context.nodes[id].sum1 = total
            context.nodes[id].has1 = boundary_has

    if parent.boundary_count == 2:
        let u = parent.boundary0
        let v = parent.boundary1
        let a_has_u = pts_boundary_index(a, u) >= 0
        let a_has_v = pts_boundary_index(a, v) >= 0
        let b_has_u = pts_boundary_index(b, u) >= 0
        let b_has_v = pts_boundary_index(b, v) >= 0
        var forward = pts_identity()
        var reverse = pts_identity()
        if a_has_u and a_has_v:
            forward = pts_map_at(a, u, v)
            reverse = pts_map_at(a, v, u)
        elif b_has_u and b_has_v:
            forward = pts_map_at(b, u, v)
            reverse = pts_map_at(b, v, u)
        else:
            forward = pts_compose(pts_map_at(a, u, shared), pts_map_at(b, shared, v))
            reverse = pts_compose(pts_map_at(b, v, shared), pts_map_at(a, shared, u))
        context.nodes[id].forward = forward
        context.nodes[id].reverse = reverse

fn pts_append(mut context: Context, kind: Int16, a_id: Int16, b_id: Int16,
              shared: Int16) -> Int16:
    if context.node_count >= PTS_MAX_CLUSTERS: return -1
    let id = context.node_count
    context.node_count += 1
    context.nodes[id].kind = kind
    context.nodes[id].a = a_id
    context.nodes[id].b = b_id
    context.nodes[id].parent = -1
    context.nodes[id].shared = shared
    context.nodes[id].boundary0 = -1
    context.nodes[id].boundary1 = -1
    context.nodes[id].boundary_count = 1
    context.nodes[id].edge = -1
    context.nodes[id].has0 = False
    context.nodes[id].has1 = False
    context.nodes[id].mask = 0
    context.nodes[id].count = 0
    context.nodes[id].sum0 = 0
    context.nodes[id].sum1 = 0
    context.nodes[id].forward = pts_identity()
    context.nodes[id].reverse = pts_identity()

    if kind == PTS_VERTEX:
        context.nodes[id].boundary0 = shared
    elif kind == PTS_EDGE:
        context.nodes[id].boundary0 = a_id
        context.nodes[id].boundary1 = b_id
        context.nodes[id].boundary_count = 2
        context.nodes[id].edge = shared
    else:
        let a = context.nodes[Int(a_id)]
        let b = context.nodes[Int(b_id)]
        let a_other = a.boundary1 if a.boundary_count == 2 and a.boundary0 == shared else a.boundary0
        let b_other = b.boundary1 if b.boundary_count == 2 and b.boundary0 == shared else b.boundary0
        if kind == PTS_RAKE:
            context.nodes[id].boundary0 = shared
        elif kind == PTS_BRANCH:
            context.nodes[id].boundary0 = a_other
        elif kind == PTS_ATTACH:
            context.nodes[id].boundary0 = a.boundary0
            context.nodes[id].boundary1 = a.boundary1
            context.nodes[id].boundary_count = 2
        else:
            context.nodes[id].boundary0 = a_other
            context.nodes[id].boundary1 = b_other
            context.nodes[id].boundary_count = 2
        context.nodes[Int(a_id)].parent = Int16(id)
        context.nodes[Int(b_id)].parent = Int16(id)
    pts_recalculate(mut context, id)
    return Int16(id)

fn pts_make_rake(mut context: Context, base: Int16, vertex: Int) -> Int16:
    var level = InlineArray[Int16, PTS_MAX_N + 1](fill=-1)
    var next = InlineArray[Int16, PTS_MAX_N + 1](fill=-1)
    var count = 1
    level[0] = base
    for i in range(context.branch_count[vertex]):
        level[count] = context.branches[vertex * PTS_MAX_N + i]
        count += 1
    while count > 1:
        var next_count = 0
        var i = 0
        while i < count:
            if i + 1 == count:
                next[next_count] = level[i]
                next_count += 1
            else:
                let shared = context.nodes[Int(level[i])].boundary0
                let merged = pts_append(mut context, PTS_RAKE, level[i], level[i + 1], shared)
                if merged < 0: return -1
                next[next_count] = merged
                next_count += 1
            i += 2
        for j in range(next_count): level[j] = next[j]
        count = next_count
    return level[0]

fn pts_neighbor_count(context: Context, n: Int, vertex: Int,
                      mut output: InlineArray[Int16, 2]) -> Int:
    var count = 0
    for other in range(n):
        let edge_at = vertex * PTS_MAX_N + other
        if context.active[other] and context.adjacency[edge_at]:
            if count < 2: output[count] = Int16(other)
            count += 1
    return count

fn pts_find(mut parent: InlineArray[Int32, PTS_MAX_N], initial: Int) -> Int:
    var vertex = initial
    while Int(parent[vertex]) != vertex:
        parent[vertex] = parent[Int(parent[vertex])]
        vertex = Int(parent[vertex])
    return vertex

fn pts_context_at(parent: Cluster, outside: Outside, vertex: Int16) -> SumCount:
    let index = pts_boundary_index(parent, vertex)
    if index == 0: return SumCount(outside.sum0, outside.count0)
    if index == 1: return SumCount(outside.sum1, outside.count1)
    return SumCount(0, 0)

fn pts_child_context(context: Context, parent_id: Int, child_id: Int,
                     outside: Outside, values: InlineArray[Int64, PTS_MAX_N]) -> Outside:
    let parent = context.nodes[parent_id]
    let child = context.nodes[child_id]
    let sibling_id = parent.b if child_id == Int(parent.a) else parent.a
    let sibling = context.nodes[Int(sibling_id)]
    let shared = parent.shared
    let overlap = pts_has(child, shared) and pts_has(sibling, shared)
    let duplicate_count = 1 if overlap else 0
    var duplicate: Int64 = 0
    if overlap: duplicate = values[Int(shared)]
    var count_at_shared = Int64(Int(sibling.count) - duplicate_count)
    var sum_at_shared = pts_norm(pts_sum_at(sibling, shared) - duplicate)
    for index in range(Int(sibling.boundary_count)):
        let boundary = sibling.boundary0 if index == 0 else sibling.boundary1
        if pts_boundary_index(parent, boundary) < 0: continue
        let inherited = pts_context_at(parent, outside, boundary)
        sum_at_shared = (sum_at_shared + pts_apply(
            pts_map_at(sibling, shared, boundary), inherited.sum, inherited.count)) % PTS_MOD
        count_at_shared += inherited.count

    var result = Outside(0, 0, 0, 0)
    for index in range(Int(child.boundary_count)):
        let boundary = child.boundary0 if index == 0 else child.boundary1
        var out_sum = sum_at_shared
        var out_count = count_at_shared
        if boundary != shared:
            out_sum = pts_apply(pts_map_at(child, boundary, shared), sum_at_shared, count_at_shared)
            if pts_boundary_index(parent, boundary) >= 0:
                let inherited = pts_context_at(parent, outside, boundary)
                out_sum = (out_sum + inherited.sum) % PTS_MOD
                out_count += inherited.count
        if index == 0:
            result.sum0 = out_sum
            result.count0 = out_count
        else:
            result.sum1 = out_sum
            result.count1 = out_count
    return result

fn pts_query(context: Context, root: Int, vertex: Int) -> Int64:
    var path = InlineArray[Int16, PTS_MAX_CLUSTERS](fill=-1)
    var path_length = 1
    path[0] = context.vertex_leaf[vertex]
    while Int(path[path_length - 1]) != root and path_length < PTS_MAX_CLUSTERS:
        let parent = context.nodes[Int(path[path_length - 1])].parent
        if parent < 0: return -1
        path[path_length] = parent
        path_length += 1
    if Int(path[path_length - 1]) != root: return -1
    var outside = Outside(0, 0, 0, 0)
    var step = path_length - 1
    while step > 0:
        outside = pts_child_context(context, Int(path[step]), Int(path[step - 1]),
                                   outside, context.values)
        step -= 1
    let leaf = Int(context.vertex_leaf[vertex])
    return (context.nodes[leaf].sum0 + outside.sum0) % PTS_MOD

fn pts_store(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits = bitcast[UInt64](value)
    for byte in range(8): output[offset + byte] = UInt8((bits >> (8 * byte)) & 255)

@export("point_set_tree_path_composite_sum")
fn point_set_tree_path_composite_sum(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > PTS_MAX_INPUT: return -1
    let n_value = input[0]
    let q_value = input[1]
    if n_value < 1 or n_value > PTS_MAX_N or q_value < 1 or q_value > PTS_MAX_Q: return -1
    let n = Int(n_value)
    let q = Int(q_value)
    var context = Context(
        InlineArray[Cluster, PTS_MAX_CLUSTERS](fill=Cluster(
            PTS_VERTEX, -1, -1, -1, -1, -1, -1, 0, -1,
            False, False, 0, 0, 0, 0, pts_identity(), pts_identity())),
        InlineArray[Int64, PTS_MAX_N](fill=0),
        InlineArray[Affine, PTS_MAX_E](fill=pts_identity()),
        InlineArray[Int16, PTS_MAX_E](fill=0),
        InlineArray[Int16, PTS_MAX_E](fill=0),
        InlineArray[Int16, PTS_MAX_N](fill=-1),
        InlineArray[Int16, PTS_MAX_E](fill=-1),
        InlineArray[Bool, PTS_MAX_N * PTS_MAX_N](fill=False),
        InlineArray[Int16, PTS_MAX_N * PTS_MAX_N](fill=-1),
        InlineArray[Bool, PTS_MAX_N](fill=False),
        InlineArray[Int16, PTS_MAX_N * PTS_MAX_N](fill=-1),
        InlineArray[Int, PTS_MAX_N](fill=0),
        0,
    )
    var cursor = 2
    for vertex in range(n):
        if cursor >= Int(length): return -1
        let value = input[cursor]
        cursor += 1
        if value < 0 or value >= PTS_MOD: return -1
        context.values[vertex] = value

    var dsu = InlineArray[Int32, PTS_MAX_N](fill=0)
    for vertex in range(n): dsu[vertex] = Int32(vertex)
    for edge in range(n - 1):
        if cursor + 4 > Int(length): return -1
        let u_value = input[cursor]
        let v_value = input[cursor + 1]
        let multiplier = input[cursor + 2]
        let addend = input[cursor + 3]
        cursor += 4
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value: return -1
        if multiplier < 1 or multiplier >= PTS_MOD or addend < 0 or addend >= PTS_MOD: return -1
        let u = Int(u_value)
        let v = Int(v_value)
        let root_u = pts_find(mut dsu, u)
        let root_v = pts_find(mut dsu, v)
        if root_u == root_v: return -1
        dsu[root_u] = Int32(root_v)
        context.edge_u[edge] = Int16(u)
        context.edge_v[edge] = Int16(v)
        context.edge_map[edge] = Affine(multiplier, addend)
    let root0 = pts_find(mut dsu, 0)
    for vertex in range(1, n):
        if pts_find(mut dsu, vertex) != root0: return -1

    var op_code = InlineArray[Int16, PTS_MAX_Q](fill=0)
    var op_item = InlineArray[Int16, PTS_MAX_Q](fill=0)
    var op_root = InlineArray[Int16, PTS_MAX_Q](fill=0)
    var op_first = InlineArray[Int64, PTS_MAX_Q](fill=0)
    var op_second = InlineArray[Int64, PTS_MAX_Q](fill=0)
    for operation in range(q):
        if cursor >= Int(length): return -1
        let opcode = input[cursor]
        cursor += 1
        if opcode == 0:
            if cursor + 3 > Int(length): return -1
            let item = input[cursor]
            let value = input[cursor + 1]
            let root = input[cursor + 2]
            cursor += 3
            if item < 0 or item >= n_value or value < 0 or value >= PTS_MOD or root < 0 or root >= n_value: return -1
            op_code[operation] = 0
            op_item[operation] = Int16(item)
            op_first[operation] = value
            op_root[operation] = Int16(root)
        elif opcode == 1:
            if cursor + 4 > Int(length): return -1
            let item = input[cursor]
            let multiplier = input[cursor + 1]
            let addend = input[cursor + 2]
            let root = input[cursor + 3]
            cursor += 4
            if item < 0 or item >= n_value - 1 or multiplier < 1 or multiplier >= PTS_MOD or addend < 0 or addend >= PTS_MOD or root < 0 or root >= n_value: return -1
            op_code[operation] = 1
            op_item[operation] = Int16(item)
            op_first[operation] = multiplier
            op_second[operation] = addend
            op_root[operation] = Int16(root)
        else:
            return -1
    if cursor != Int(length): return -1
    let required = 8 * q
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(required): return -2

    context.node_count = 0
    for index in range(PTS_MAX_N * PTS_MAX_N): context.edge_cluster[index] = -1
    for vertex in range(n):
        let leaf = pts_append(mut context, PTS_VERTEX, -1, -1, Int16(vertex))
        if leaf < 0: return -1
        context.vertex_leaf[vertex] = leaf
    for edge in range(n - 1):
        let u = Int(context.edge_u[edge])
        let v = Int(context.edge_v[edge])
        let leaf = pts_append(mut context, PTS_EDGE, Int16(u), Int16(v), Int16(edge))
        if leaf < 0: return -1
        context.edge_leaf[edge] = leaf
        context.adjacency[u * PTS_MAX_N + v] = True
        context.adjacency[v * PTS_MAX_N + u] = True
        context.edge_cluster[u * PTS_MAX_N + v] = leaf
        context.edge_cluster[v * PTS_MAX_N + u] = leaf
    for vertex in range(n): context.active[vertex] = True
    var active_count = n
    while active_count > 1:
        if active_count == 2:
            var pair = InlineArray[Int, 2](fill=0)
            var found = 0
            for vertex in range(n):
                if context.active[vertex]:
                    pair[found] = vertex
                    found += 1
            let x = pair[0]
            let y = pair[1]
            let local = pts_make_rake(mut context, context.vertex_leaf[x], x)
            if local < 0: return -1
            let edge = context.edge_cluster[x * PTS_MAX_N + y]
            let branch = pts_append(mut context, PTS_BRANCH, edge, local, Int16(x))
            if branch < 0 or context.branch_count[y] >= PTS_MAX_N: return -1
            context.branches[y * PTS_MAX_N + context.branch_count[y]] = branch
            context.branch_count[y] += 1
            context.adjacency[x * PTS_MAX_N + y] = False
            context.adjacency[y * PTS_MAX_N + x] = False
            context.edge_cluster[x * PTS_MAX_N + y] = -1
            context.edge_cluster[y * PTS_MAX_N + x] = -1
            context.active[x] = False
            active_count -= 1
            break

        var leaves = InlineArray[Int, PTS_MAX_N](fill=0)
        var leaf_neighbors = InlineArray[Int, PTS_MAX_N](fill=0)
        var leaf_count = 0
        for vertex in range(n):
            if context.active[vertex]:
                var adjacent = InlineArray[Int16, 2](fill=0)
                if pts_neighbor_count(context, n, vertex, mut adjacent) == 1:
                    leaves[leaf_count] = vertex
                    leaf_neighbors[leaf_count] = Int(adjacent[0])
                    leaf_count += 1
        for i in range(leaf_count):
            let x = leaves[i]
            let y = leaf_neighbors[i]
            let local = pts_make_rake(mut context, context.vertex_leaf[x], x)
            if local < 0: return -1
            let edge = context.edge_cluster[x * PTS_MAX_N + y]
            let branch = pts_append(mut context, PTS_BRANCH, edge, local, Int16(x))
            if branch < 0 or context.branch_count[y] >= PTS_MAX_N: return -1
            context.branches[y * PTS_MAX_N + context.branch_count[y]] = branch
            context.branch_count[y] += 1
        for i in range(leaf_count):
            let x = leaves[i]
            let y = leaf_neighbors[i]
            context.adjacency[x * PTS_MAX_N + y] = False
            context.adjacency[y * PTS_MAX_N + x] = False
            context.edge_cluster[x * PTS_MAX_N + y] = -1
            context.edge_cluster[y * PTS_MAX_N + x] = -1
            context.active[x] = False
            active_count -= 1
        if active_count <= 1: break

        var chosen = InlineArray[Bool, PTS_MAX_N](fill=False)
        var compress_vertices = InlineArray[Int, PTS_MAX_N](fill=0)
        var compress_count = 0
        for x in range(n):
            if context.active[x]:
                var adjacent = InlineArray[Int16, 2](fill=0)
                if pts_neighbor_count(context, n, x, mut adjacent) != 2: continue
                let y = Int(adjacent[0])
                let z = Int(adjacent[1])
                if not chosen[y] and not chosen[z]:
                    chosen[x] = True
                    compress_vertices[compress_count] = x
                    compress_count += 1

        var pending_x = InlineArray[Int, PTS_MAX_N](fill=0)
        var pending_y = InlineArray[Int, PTS_MAX_N](fill=0)
        var pending_z = InlineArray[Int, PTS_MAX_N](fill=0)
        var pending_cluster = InlineArray[Int16, PTS_MAX_N](fill=-1)
        for i in range(compress_count):
            let x = compress_vertices[i]
            var adjacent = InlineArray[Int16, 2](fill=0)
            _ = pts_neighbor_count(context, n, x, mut adjacent)
            let y = Int(adjacent[0])
            let z = Int(adjacent[1])
            let local = pts_make_rake(mut context, context.vertex_leaf[x], x)
            if local < 0: return -1
            let first_edge = context.edge_cluster[y * PTS_MAX_N + x]
            let second_edge = context.edge_cluster[x * PTS_MAX_N + z]
            let attached = pts_append(mut context, PTS_ATTACH, first_edge, local, Int16(x))
            if attached < 0: return -1
            let compressed = pts_append(mut context, PTS_COMPRESS, attached, second_edge, Int16(x))
            if compressed < 0: return -1
            pending_x[i] = x
            pending_y[i] = y
            pending_z[i] = z
            pending_cluster[i] = compressed
        for i in range(compress_count):
            let x = pending_x[i]
            let y = pending_y[i]
            let z = pending_z[i]
            context.adjacency[y * PTS_MAX_N + x] = False
            context.adjacency[x * PTS_MAX_N + y] = False
            context.adjacency[x * PTS_MAX_N + z] = False
            context.adjacency[z * PTS_MAX_N + x] = False
            context.edge_cluster[y * PTS_MAX_N + x] = -1
            context.edge_cluster[x * PTS_MAX_N + y] = -1
            context.edge_cluster[x * PTS_MAX_N + z] = -1
            context.edge_cluster[z * PTS_MAX_N + x] = -1
            context.active[x] = False
            active_count -= 1
        for i in range(compress_count):
            let y = pending_y[i]
            let z = pending_z[i]
            context.adjacency[y * PTS_MAX_N + z] = True
            context.adjacency[z * PTS_MAX_N + y] = True
            context.edge_cluster[y * PTS_MAX_N + z] = pending_cluster[i]
            context.edge_cluster[z * PTS_MAX_N + y] = pending_cluster[i]

    var root_vertex = 0
    while not context.active[root_vertex]: root_vertex += 1
    let root = pts_make_rake(mut context, context.vertex_leaf[root_vertex], root_vertex)
    if root < 0: return -1
    var answers = InlineArray[Int64, PTS_MAX_Q](fill=0)
    for operation in range(q):
        let item = Int(op_item[operation])
        var node_id = 0
        if op_code[operation] == 0:
            context.values[item] = op_first[operation]
            node_id = Int(context.vertex_leaf[item])
            pts_recalculate(mut context, node_id)
        else:
            context.edge_map[item] = Affine(op_first[operation], op_second[operation])
            node_id = Int(context.edge_leaf[item])
            pts_recalculate(mut context, node_id)
        var ancestor = context.nodes[node_id].parent
        while ancestor >= 0:
            node_id = Int(ancestor)
            pts_recalculate(mut context, node_id)
            ancestor = context.nodes[node_id].parent
        let answer = pts_query(context, Int(root), Int(op_root[operation]))
        if answer < 0: return -1
        answers[operation] = answer
    for operation in range(q): pts_store(output, 8 * operation, answers[operation])
    return Int64(required)
