from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_N = 8
comptime MAX_M = 28
comptime MAX_INPUT = 67
comptime MAX_PIECES = 56
comptime MAX_SPLITS = 28
comptime MODULUS: Int64 = 998244353
comptime KIND_S = 1
comptime KIND_P = 2

@fieldwise_init
struct TvcEdge(Copyable):
    var u: Int
    var v: Int
    var pair_id: Int
    var real: Bool

@fieldwise_init
struct TvcPiece(Copyable):
    var edge_count: Int
    var edges: InlineArray[TvcEdge, MAX_M]

fn tvc_connected_without(adjacency: InlineArray[Bool, MAX_N * MAX_N], n: Int, removed: Int) -> Bool:
    var start = 0
    while start == removed: start += 1
    var seen = InlineArray[Bool, MAX_N](fill=False)
    var queue = InlineArray[Int, MAX_N]()
    seen[start] = True
    queue[0] = start
    var head = 0
    var tail = 1
    while head < tail:
        let u = queue[head]
        head += 1
        for v in range(n):
            if v != removed and adjacency[u * MAX_N + v] and not seen[v]:
                seen[v] = True
                queue[tail] = v
                tail += 1
    var reached = 0
    for v in range(n):
        if v != removed and seen[v]: reached += 1
    return reached == n - (1 if removed >= 0 else 0)

fn tvc_components_after_pair(piece: TvcPiece, n: Int, a: Int, b: Int,
                             inout component: InlineArray[Int, MAX_N], inout component_count: Int):
    for v in range(MAX_N): component[v] = -1
    component_count = 0
    var queue = InlineArray[Int, MAX_N]()
    for start in range(n):
        if start == a or start == b or component[start] >= 0: continue
        var head = 0
        var tail = 1
        component[start] = component_count
        queue[0] = start
        while head < tail:
            let u = queue[head]
            head += 1
            for edge_id in range(piece.edge_count):
                let edge = piece.edges[edge_id]
                if edge.u == a or edge.u == b or edge.v == a or edge.v == b: continue
                var other = -1
                if edge.u == u: other = edge.v
                elif edge.v == u: other = edge.u
                if other >= 0 and component[other] < 0:
                    component[other] = component_count
                    queue[tail] = other
                    tail += 1
        component_count += 1

fn tvc_find_split(piece: TvcPiece, n: Int, inout chosen_u: Int, inout chosen_v: Int,
                  inout left_edge: InlineArray[Bool, MAX_M]) -> Bool:
    for u in range(n):
        for v in range(u + 1, n):
            var component = InlineArray[Int, MAX_N]()
            var component_count = 0
            tvc_components_after_pair(piece, n, u, v, component, component_count)
            var edge_class = InlineArray[Int, MAX_M]()
            var sizes = InlineArray[Int, MAX_M]()
            var direct_count = 0
            for e in range(piece.edge_count):
                let edge = piece.edges[e]
                if (edge.u == u and edge.v == v) or (edge.u == v and edge.v == u):
                    edge_class[e] = component_count + direct_count
                    direct_count += 1
                else:
                    let endpoint = edge.u if edge.u != u and edge.u != v else edge.v
                    if component[endpoint] < 0: return False
                    edge_class[e] = component[endpoint]
                if edge_class[e] < 0 or edge_class[e] >= MAX_M: return False
                sizes[edge_class[e]] += 1
            let class_count = component_count + direct_count
            var selected = -1
            for c in range(class_count):
                if sizes[c] >= 2 and sizes[c] <= piece.edge_count - 2:
                    selected = c
                    break
            var use_first_two = selected < 0 and class_count >= 4 and class_count == piece.edge_count
            if use_first_two:
                for c in range(class_count):
                    if sizes[c] != 1: use_first_two = False
            if selected < 0 and not use_first_two: continue
            for e in range(piece.edge_count):
                left_edge[e] = edge_class[e] == selected if selected >= 0 else edge_class[e] < 2
            chosen_u = u
            chosen_v = v
            return True
    return False

fn tvc_piece_kind(piece: TvcPiece) -> Int:
    var present = InlineArray[Bool, MAX_N](fill=False)
    var vertex_count = 0
    for e in range(piece.edge_count):
        for k in range(2):
            let endpoint = piece.edges[e].u if k == 0 else piece.edges[e].v
            if not present[endpoint]:
                present[endpoint] = True
                vertex_count += 1
    if vertex_count == 2 and piece.edge_count >= 3: return KIND_P
    if vertex_count == 3 and piece.edge_count == 3:
        var pair = InlineArray[Bool, MAX_N * MAX_N](fill=False)
        for e in range(3):
            let edge = piece.edges[e]
            pair[edge.u * MAX_N + edge.v] = True
            pair[edge.v * MAX_N + edge.u] = True
        var count = 0
        for u in range(MAX_N):
            for v in range(u + 1, MAX_N):
                if pair[u * MAX_N + v]: count += 1
        if count == 3: return KIND_S
    return 3

fn tvc_find_root(inout parent: InlineArray[Int, MAX_PIECES], item: Int) -> Int:
    var current = item
    while parent[current] != current:
        parent[current] = parent[parent[current]]
        current = parent[current]
    return current

fn tvc_unite(inout parent: InlineArray[Int, MAX_PIECES], left: Int, right: Int):
    let a = tvc_find_root(parent, left)
    let b = tvc_find_root(parent, right)
    if a != b: parent[b] = a

fn tvc_pair_components(adjacency: InlineArray[Bool, MAX_N * MAX_N], n: Int, a: Int, b: Int) -> Int:
    var seen = InlineArray[Bool, MAX_N](fill=False)
    var queue = InlineArray[Int, MAX_N]()
    var count = 0
    for start in range(n):
        if start == a or start == b or seen[start]: continue
        count += 1
        var head = 0
        var tail = 1
        seen[start] = True
        queue[0] = start
        while head < tail:
            let u = queue[head]
            head += 1
            for v in range(n):
                if v != a and v != b and adjacency[u * MAX_N + v] and not seen[v]:
                    seen[v] = True
                    queue[tail] = v
                    tail += 1
    return count

@export("two_vertex_cuts_spqr")
fn two_vertex_cuts_spqr(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > MAX_INPUT: return -1
    let n_arg = input[0]
    let m_arg = input[1]
    if n_arg < 3 or n_arg > MAX_N or m_arg < 3 or m_arg > MAX_M: return -1
    let n = Int(n_arg)
    let m = Int(m_arg)
    if length != c_size_t(2 + n + 2 * m): return -1
    var weights = InlineArray[Int64, MAX_N]()
    for v in range(n):
        weights[v] = input[2 + v]
        if weights[v] < 0 or weights[v] > 1_000_000: return -1
    var adjacency = InlineArray[Bool, MAX_N * MAX_N](fill=False)
    var pieces = InlineArray[TvcPiece, MAX_PIECES]()
    for p in range(MAX_PIECES):
        var edge_array = InlineArray[TvcEdge, MAX_M]()
        for e in range(MAX_M): edge_array[e] = TvcEdge(0, 0, -1, True)
        pieces[p] = TvcPiece(0, edge_array)
    pieces[0].edge_count = m
    let offset = 2 + n
    for e in range(m):
        let a = input[offset + 2 * e]
        let b = input[offset + 2 * e + 1]
        if a < 0 or a >= n_arg or b < 0 or b >= n_arg or a == b: return -1
        let u = Int(a)
        let v = Int(b)
        if adjacency[u * MAX_N + v]: return -1
        adjacency[u * MAX_N + v] = True
        adjacency[v * MAX_N + u] = True
        pieces[0].edges[e] = TvcEdge(u, v, -1, True)
    if not tvc_connected_without(adjacency, n, -1): return -1
    for removed in range(n):
        if not tvc_connected_without(adjacency, n, removed): return -1

    var piece_count = 1
    var split_count = 0
    var pair_u = InlineArray[Int, MAX_SPLITS]()
    var pair_v = InlineArray[Int, MAX_SPLITS]()
    var is_leaf = InlineArray[Bool, MAX_PIECES](fill=False)
    var index = 0
    while index < piece_count:
        var left_edge = InlineArray[Bool, MAX_M](fill=False)
        var u = 0
        var v = 0
        if not tvc_find_split(pieces[index], n, u, v, left_edge):
            is_leaf[index] = True
            index += 1
            continue
        if split_count >= MAX_SPLITS or piece_count + 2 > MAX_PIECES: return -1
        let left_index = piece_count
        let right_index = piece_count + 1
        piece_count += 2
        for e in range(pieces[index].edge_count):
            let target = left_index if left_edge[e] else right_index
            let target_count = pieces[target].edge_count
            pieces[target].edges[target_count] = pieces[index].edges[e]
            pieces[target].edge_count += 1
        let pair_id = split_count
        pair_u[pair_id] = u
        pair_v[pair_id] = v
        split_count += 1
        pieces[left_index].edges[pieces[left_index].edge_count] = TvcEdge(u, v, pair_id, False)
        pieces[left_index].edge_count += 1
        pieces[right_index].edges[pieces[right_index].edge_count] = TvcEdge(u, v, pair_id, False)
        pieces[right_index].edge_count += 1
        if pieces[left_index].edge_count < 3 or pieces[right_index].edge_count < 3: return -1
        index += 1

    var kind = InlineArray[Int, MAX_PIECES]()
    var first_leaf = InlineArray[Int, MAX_SPLITS](fill=-1)
    var second_leaf = InlineArray[Int, MAX_SPLITS](fill=-1)
    var occurrences = InlineArray[Int, MAX_SPLITS]()
    var parent = InlineArray[Int, MAX_PIECES]()
    for p in range(piece_count):
        parent[p] = p
        if is_leaf[p]: kind[p] = tvc_piece_kind(pieces[p])
    for p in range(piece_count):
        if not is_leaf[p]: continue
        for e in range(pieces[p].edge_count):
            let edge = pieces[p].edges[e]
            if edge.real: continue
            if edge.pair_id < 0 or edge.pair_id >= split_count: return -1
            let id = edge.pair_id
            occurrences[id] += 1
            if occurrences[id] == 1: first_leaf[id] = p
            elif occurrences[id] == 2: second_leaf[id] = p
            else: return -1
    for id in range(split_count):
        if occurrences[id] != 2 or first_leaf[id] == second_leaf[id]: return -1
        let a = first_leaf[id]
        let b = second_leaf[id]
        if kind[a] == kind[b] and (kind[a] == KIND_S or kind[a] == KIND_P): tvc_unite(parent, a, b)

    var candidate = InlineArray[Bool, MAX_N * MAX_N](fill=False)
    for id in range(split_count): candidate[pair_u[id] * MAX_N + pair_v[id]] = True
    for leaf in range(piece_count):
        if not is_leaf[leaf] or tvc_find_root(parent, leaf) != leaf: continue
        if kind[leaf] == KIND_S:
            var in_group = InlineArray[Bool, MAX_N](fill=False)
            var skeleton = InlineArray[Bool, MAX_N * MAX_N](fill=False)
            for member in range(piece_count):
                if not is_leaf[member] or tvc_find_root(parent, member) != leaf: continue
                for e in range(pieces[member].edge_count):
                    let edge = pieces[member].edges[e]
                    if not edge.real:
                        let id = edge.pair_id
                        if tvc_find_root(parent, first_leaf[id]) == leaf and tvc_find_root(parent, second_leaf[id]) == leaf: continue
                    in_group[edge.u] = True
                    in_group[edge.v] = True
                    skeleton[edge.u * MAX_N + edge.v] = True
                    skeleton[edge.v * MAX_N + edge.u] = True
            for u in range(n):
                for v in range(u + 1, n):
                    if in_group[u] and in_group[v] and not skeleton[u * MAX_N + v]: candidate[u * MAX_N + v] = True
        elif kind[leaf] == KIND_P:
            var first = -1
            var second = -1
            for member in range(piece_count):
                if not is_leaf[member] or tvc_find_root(parent, member) != leaf: continue
                for e in range(pieces[member].edge_count):
                    for k in range(2):
                        let endpoint = pieces[member].edges[e].u if k == 0 else pieces[member].edges[e].v
                        if first < 0: first = endpoint
                        elif endpoint != first and second < 0: second = endpoint
                        elif endpoint != first and endpoint != second: return -1
            if first < 0 or second < 0: return -1
            let u = first if first < second else second
            let v = second if first < second else first
            candidate[u * MAX_N + v] = True

    var total: Int64 = 0
    for u in range(n):
        for v in range(u + 1, n):
            if candidate[u * MAX_N + v]:
                let components = tvc_pair_components(adjacency, n, u, v)
                if components > 1:
                    let term = (weights[u] % MODULUS) * (weights[v] % MODULUS) % MODULUS
                    total = (total + term * Int64(components - 1)) % MODULUS
    return total
