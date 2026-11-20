from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime FR_MAX_N = 12
comptime FR_MAX_ARCS = 60
comptime FR_MAX_PIECES = 119
comptime FR_MAX_BOUNDARY = 12
comptime FR_MAX_BLOCKS = 44
comptime FR_MAX_UNION_NODES = 24
comptime FR_MAX_BASE_ARCS = 3
comptime FR_MAX_INPUT = 2088
comptime FR_MAX_WEIGHT = 100
comptime FR_INF: Int64 = Int64(1) << 60

struct FrState:
    var n: Int
    var m: Int
    var source: Int
    var piece_count: Int
    var arc_tail: InlineArray[Int, FR_MAX_ARCS]
    var arc_head: InlineArray[Int, FR_MAX_ARCS]
    var arc_weight: InlineArray[Int64, FR_MAX_ARCS]
    var piece_left: InlineArray[Int, FR_MAX_PIECES]
    var piece_right: InlineArray[Int, FR_MAX_PIECES]
    var piece_boundary_count: InlineArray[Int, FR_MAX_PIECES]
    var piece_arc_mask: InlineArray[Int64, FR_MAX_PIECES]
    var piece_vertex_mask: InlineArray[Int, FR_MAX_PIECES]
    var boundary: InlineArray[Int, FR_MAX_PIECES * FR_MAX_BOUNDARY]
    var ddg: InlineArray[Int64, FR_MAX_PIECES * FR_MAX_N * FR_MAX_N]
    var potential: InlineArray[Int64, FR_MAX_PIECES * FR_MAX_N]
    var block_child: InlineArray[Int, FR_MAX_BLOCKS]
    var block_row_count: InlineArray[Int, FR_MAX_BLOCKS]
    var block_column_count: InlineArray[Int, FR_MAX_BLOCKS]
    var block_rows: InlineArray[Int, FR_MAX_BLOCKS * FR_MAX_BOUNDARY]
    var block_columns: InlineArray[Int, FR_MAX_BLOCKS * FR_MAX_BOUNDARY]
    var block_weights: InlineArray[Int64, FR_MAX_BLOCKS * FR_MAX_BOUNDARY * FR_MAX_BOUNDARY]
    var block_best_value: InlineArray[Int64, FR_MAX_BLOCKS * FR_MAX_BOUNDARY]
    var block_best_row: InlineArray[Int, FR_MAX_BLOCKS * FR_MAX_BOUNDARY]
    var temp_tail: InlineArray[Int, 2 * FR_MAX_BOUNDARY * FR_MAX_BOUNDARY]
    var temp_head: InlineArray[Int, 2 * FR_MAX_BOUNDARY * FR_MAX_BOUNDARY]
    var temp_weight: InlineArray[Int64, 2 * FR_MAX_BOUNDARY * FR_MAX_BOUNDARY]
    var temp_count: Int

    fn __init__(out self):
        self.n = 0
        self.m = 0
        self.source = 0
        self.piece_count = 0
        self.arc_tail = InlineArray[Int, FR_MAX_ARCS](fill=0)
        self.arc_head = InlineArray[Int, FR_MAX_ARCS](fill=0)
        self.arc_weight = InlineArray[Int64, FR_MAX_ARCS](fill=0)
        self.piece_left = InlineArray[Int, FR_MAX_PIECES](fill=-1)
        self.piece_right = InlineArray[Int, FR_MAX_PIECES](fill=-1)
        self.piece_boundary_count = InlineArray[Int, FR_MAX_PIECES](fill=0)
        self.piece_arc_mask = InlineArray[Int64, FR_MAX_PIECES](fill=0)
        self.piece_vertex_mask = InlineArray[Int, FR_MAX_PIECES](fill=0)
        self.boundary = InlineArray[Int, FR_MAX_PIECES * FR_MAX_BOUNDARY](fill=0)
        self.ddg = InlineArray[Int64, FR_MAX_PIECES * FR_MAX_N * FR_MAX_N](fill=FR_INF)
        self.potential = InlineArray[Int64, FR_MAX_PIECES * FR_MAX_N](fill=0)
        self.block_child = InlineArray[Int, FR_MAX_BLOCKS](fill=0)
        self.block_row_count = InlineArray[Int, FR_MAX_BLOCKS](fill=0)
        self.block_column_count = InlineArray[Int, FR_MAX_BLOCKS](fill=0)
        self.block_rows = InlineArray[Int, FR_MAX_BLOCKS * FR_MAX_BOUNDARY](fill=0)
        self.block_columns = InlineArray[Int, FR_MAX_BLOCKS * FR_MAX_BOUNDARY](fill=0)
        self.block_weights = InlineArray[Int64, FR_MAX_BLOCKS * FR_MAX_BOUNDARY * FR_MAX_BOUNDARY](fill=FR_INF)
        self.block_best_value = InlineArray[Int64, FR_MAX_BLOCKS * FR_MAX_BOUNDARY](fill=FR_INF)
        self.block_best_row = InlineArray[Int, FR_MAX_BLOCKS * FR_MAX_BOUNDARY](fill=FR_MAX_N + 1)
        self.temp_tail = InlineArray[Int, 2 * FR_MAX_BOUNDARY * FR_MAX_BOUNDARY](fill=0)
        self.temp_head = InlineArray[Int, 2 * FR_MAX_BOUNDARY * FR_MAX_BOUNDARY](fill=0)
        self.temp_weight = InlineArray[Int64, 2 * FR_MAX_BOUNDARY * FR_MAX_BOUNDARY](fill=0)
        self.temp_count = 0

fn fr_ddg_index(piece: Int, u: Int, v: Int) -> Int:
    return piece * FR_MAX_N * FR_MAX_N + u * FR_MAX_N + v

fn fr_potential_index(piece: Int, vertex: Int) -> Int:
    return piece * FR_MAX_N + vertex

fn fr_boundary_index(piece: Int, offset: Int) -> Int:
    return piece * FR_MAX_BOUNDARY + offset

fn fr_block_entry(block: Int, offset: Int) -> Int:
    return block * FR_MAX_BOUNDARY + offset

fn fr_block_weight(block: Int, row: Int, column: Int) -> Int:
    return block * FR_MAX_BOUNDARY * FR_MAX_BOUNDARY + row * FR_MAX_BOUNDARY + column

fn fr_arc_bit(edge: Int) -> Int64:
    return Int64(1) << edge

fn fr_popcount(value: Int64) -> Int:
    var bits = value
    var count = 0
    while bits != 0:
        count += Int(bits & 1)
        bits >>= 1
    return count

fn fr_piece_connected(state: FrState, mask: Int64, vertex_mask: Int) -> Bool:
    if vertex_mask == 0: return False
    var start = 0
    while start < state.n and (vertex_mask & (1 << start)) == 0: start += 1
    if start >= state.n: return False
    var reached = 1 << start
    var changed = True
    while changed:
        changed = False
        for edge in range(state.m):
            if (mask & fr_arc_bit(edge)) == 0: continue
            let u = state.arc_tail[edge]
            let v = state.arc_head[edge]
            let ub = 1 << u
            let vb = 1 << v
            if (reached & ub) != 0 and (reached & vb) == 0:
                reached |= vb
                changed = True
            if (reached & vb) != 0 and (reached & ub) == 0:
                reached |= ub
                changed = True
    return reached == vertex_mask

fn fr_vertex_mask_for_arcs(state: FrState, mask: Int64) -> Int:
    var result = 0
    for edge in range(state.m):
        if (mask & fr_arc_bit(edge)) != 0:
            result |= (1 << state.arc_tail[edge]) | (1 << state.arc_head[edge])
    return result

fn fr_parse(inout state: FrState, input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) -> Bool:
    if length < c_size_t(4) or length > c_size_t(FR_MAX_INPUT): return False
    let n_value = input[0]
    let m_value = input[1]
    let source_value = input[2]
    let piece_count_value = input[3]
    if n_value < 2 or n_value > FR_MAX_N or m_value < 1 or m_value > FR_MAX_ARCS or source_value < 0 or source_value >= n_value or piece_count_value < 1 or piece_count_value > FR_MAX_PIECES or piece_count_value % 2 == 0:
        return False
    state.n = Int(n_value)
    state.m = Int(m_value)
    state.source = Int(source_value)
    state.piece_count = Int(piece_count_value)

    var seen_arc = InlineArray[Bool, FR_MAX_N * FR_MAX_N](fill=False)
    var seen_pair = InlineArray[Bool, FR_MAX_N * FR_MAX_N](fill=False)
    var undirected_edges = 0
    var offset = 4
    for edge in range(state.m):
        if offset + 3 > Int(length): return False
        let u_value = input[offset]
        let v_value = input[offset + 1]
        let weight = input[offset + 2]
        offset += 3
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value or weight < -FR_MAX_WEIGHT or weight > FR_MAX_WEIGHT:
            return False
        let u = Int(u_value)
        let v = Int(v_value)
        if seen_arc[u * FR_MAX_N + v]: return False
        seen_arc[u * FR_MAX_N + v] = True
        if not seen_pair[u * FR_MAX_N + v]:
            seen_pair[u * FR_MAX_N + v] = True
            seen_pair[v * FR_MAX_N + u] = True
            undirected_edges += 1
        state.arc_tail[edge] = u
        state.arc_head[edge] = v
        state.arc_weight[edge] = weight
    let simple_edge_limit = 1 if state.n == 2 else 3 * state.n - 6
    if undirected_edges > simple_edge_limit or state.m > 2 * simple_edge_limit: return False

    var visited = InlineArray[Bool, FR_MAX_N](fill=False)
    var queue = InlineArray[Int, FR_MAX_N](fill=0)
    var head = 0
    var tail = 0
    visited[0] = True
    queue[tail] = 0
    tail += 1
    while head < tail:
        let u = queue[head]
        head += 1
        for edge in range(state.m):
            var next_vertex = -1
            if state.arc_tail[edge] == u: next_vertex = state.arc_head[edge]
            elif state.arc_head[edge] == u: next_vertex = state.arc_tail[edge]
            if next_vertex >= 0 and not visited[next_vertex]:
                visited[next_vertex] = True
                queue[tail] = next_vertex
                tail += 1
    for vertex in range(state.n):
        if not visited[vertex]: return False

    var parent_count = InlineArray[Int, FR_MAX_PIECES](fill=0)
    var leaf_union: Int64 = 0
    var leaf_count = 0
    let full_arc_mask = (Int64(1) << state.m) - 1
    for index in range(state.piece_count):
        if offset + 4 > Int(length): return False
        let left_value = input[offset]
        let right_value = input[offset + 1]
        let mask_value = input[offset + 2]
        let boundary_count_value = input[offset + 3]
        offset += 4
        if boundary_count_value < 1 or boundary_count_value > FR_MAX_BOUNDARY or boundary_count_value > state.n or offset + Int(boundary_count_value) > Int(length):
            return False
        let boundary_count = Int(boundary_count_value)
        state.piece_boundary_count[index] = boundary_count
        var listed_boundary = 0
        for i in range(boundary_count):
            let vertex_value = input[offset]
            offset += 1
            if vertex_value < 0 or vertex_value >= Int64(state.n): return False
            let vertex = Int(vertex_value)
            let bit = 1 << vertex
            if (listed_boundary & bit) != 0: return False
            listed_boundary |= bit
            state.boundary[fr_boundary_index(index, i)] = vertex

        if left_value == -1 and right_value == -1:
            if mask_value <= 0: return False
            let mask = mask_value
            if (mask & (~full_arc_mask)) != 0 or fr_popcount(mask) > FR_MAX_BASE_ARCS or (leaf_union & mask) != 0: return False
            state.piece_left[index] = -1
            state.piece_right[index] = -1
            state.piece_arc_mask[index] = mask
            leaf_union |= mask
            leaf_count += 1
            state.piece_vertex_mask[index] = fr_vertex_mask_for_arcs(state, mask)
            if not fr_piece_connected(state, mask, state.piece_vertex_mask[index]): return False
        else:
            if left_value < 0 or right_value < 0 or left_value >= Int64(index) or right_value >= Int64(index) or left_value == right_value or mask_value != -1:
                return False
            let left = Int(left_value)
            let right = Int(right_value)
            if parent_count[left] != 0 or parent_count[right] != 0: return False
            parent_count[left] = 1
            parent_count[right] = 1
            if (state.piece_arc_mask[left] & state.piece_arc_mask[right]) != 0: return False
            state.piece_left[index] = left
            state.piece_right[index] = right
            state.piece_arc_mask[index] = state.piece_arc_mask[left] | state.piece_arc_mask[right]
            state.piece_vertex_mask[index] = state.piece_vertex_mask[left] | state.piece_vertex_mask[right]
            let parent_vertices = fr_popcount(Int64(state.piece_vertex_mask[index]))
            let max_child_vertices = (2 * parent_vertices + 2) // 3
            if fr_popcount(Int64(state.piece_vertex_mask[left])) > max_child_vertices or fr_popcount(Int64(state.piece_vertex_mask[right])) > max_child_vertices or (state.piece_vertex_mask[left] & state.piece_vertex_mask[right]) == 0:
                return False

        var expected_boundary = 0
        for vertex in range(state.n):
            let bit = 1 << vertex
            if (state.piece_vertex_mask[index] & bit) == 0: continue
            if vertex == state.source:
                expected_boundary |= bit
                continue
            for edge in range(state.m):
                if (state.piece_arc_mask[index] & fr_arc_bit(edge)) == 0 and (state.arc_tail[edge] == vertex or state.arc_head[edge] == vertex):
                    expected_boundary |= bit
                    break
        if listed_boundary != expected_boundary or not fr_piece_connected(state, state.piece_arc_mask[index], state.piece_vertex_mask[index]): return False
        if index == state.piece_count - 1 and (state.piece_arc_mask[index] != full_arc_mask or state.piece_vertex_mask[index] != (1 << state.n) - 1):
            return False
    if offset != Int(length) or leaf_count == 0 or state.piece_count != 2 * leaf_count - 1 or leaf_union != full_arc_mask or parent_count[state.piece_count - 1] != 0:
        return False
    for i in range(state.piece_count - 1):
        if parent_count[i] != 1: return False
    return state.piece_boundary_count[state.piece_count - 1] == 1 and state.boundary[fr_boundary_index(state.piece_count - 1, 0)] == state.source

fn fr_bellman_ford_all(inout state: FrState, nodes: InlineArray[Int, FR_MAX_UNION_NODES], node_count: Int, inout labels: InlineArray[Int64, FR_MAX_N]) -> Bool:
    labels = InlineArray[Int64, FR_MAX_N](fill=0)
    for i in range(node_count): labels[nodes[i]] = 0
    for pass in range(max(0, node_count - 1)):
        var changed = False
        for edge in range(state.temp_count):
            let u = state.temp_tail[edge]
            let v = state.temp_head[edge]
            let candidate = labels[u] + state.temp_weight[edge]
            if candidate < labels[v]: labels[v] = candidate; changed = True
        if not changed: break
    for edge in range(state.temp_count):
        let u = state.temp_tail[edge]
        let v = state.temp_head[edge]
        if labels[u] + state.temp_weight[edge] < labels[v]: return False
    return True

fn fr_bellman_ford_seeded(inout state: FrState, seeds: InlineArray[Int64, FR_MAX_N], inout labels: InlineArray[Int64, FR_MAX_N]) -> Bool:
    labels = seeds
    for pass in range(max(0, state.n - 1)):
        var changed = False
        for edge in range(state.temp_count):
            let u = state.temp_tail[edge]
            let v = state.temp_head[edge]
            if labels[u] == FR_INF: continue
            let candidate = labels[u] + state.temp_weight[edge]
            if candidate < labels[v]: labels[v] = candidate; changed = True
        if not changed: break
    for edge in range(state.temp_count):
        let u = state.temp_tail[edge]
        let v = state.temp_head[edge]
        if labels[u] != FR_INF and labels[u] + state.temp_weight[edge] < labels[v]: return False
    return True

fn fr_collect_leaf_arcs(inout state: FrState, mask: Int64):
    state.temp_count = 0
    for edge in range(state.m):
        if (mask & fr_arc_bit(edge)) != 0:
            let index = state.temp_count
            state.temp_tail[index] = state.arc_tail[edge]
            state.temp_head[index] = state.arc_head[edge]
            state.temp_weight[index] = state.arc_weight[edge]
            state.temp_count += 1

fn fr_monge_sum(a: Int64, b: Int64) -> Int64:
    if a == FR_INF or b == FR_INF: return FR_INF
    return a + b

fn fr_check_monge_rec(state: FrState, piece: Int, lo: Int, hi: Int) -> Bool:
    if hi - lo <= 1: return True
    let middle = (lo + hi) // 2
    for direction in range(2):
        let row_lo = lo if direction == 0 else middle
        let row_hi = middle if direction == 0 else hi
        let col_lo = middle if direction == 0 else lo
        let col_hi = hi if direction == 0 else middle
        for i in range(row_lo, row_hi):
            for i2 in range(i + 1, row_hi):
                for j in range(col_lo, col_hi):
                    for j2 in range(j + 1, col_hi):
                        let u = state.boundary[fr_boundary_index(piece, i)]
                        let u2 = state.boundary[fr_boundary_index(piece, i2)]
                        let v = state.boundary[fr_boundary_index(piece, j)]
                        let v2 = state.boundary[fr_boundary_index(piece, j2)]
                        let lhs = fr_monge_sum(state.ddg[fr_ddg_index(piece, u, v)], state.ddg[fr_ddg_index(piece, u2, v2)])
                        let rhs = fr_monge_sum(state.ddg[fr_ddg_index(piece, u, v2)], state.ddg[fr_ddg_index(piece, u2, v)])
                        if lhs > rhs: return False
    return fr_check_monge_rec(state, piece, lo, middle) and fr_check_monge_rec(state, piece, middle, hi)

fn fr_add_block(inout state: FrState, child: Int, row_start: Int, row_count: Int, column_start: Int, column_count: Int, potential_piece: Int, inout block_count: Int):
    if row_count == 0 or column_count == 0 or block_count >= FR_MAX_BLOCKS: return
    let block = block_count
    state.block_child[block] = child
    state.block_row_count[block] = row_count
    state.block_column_count[block] = column_count
    for i in range(row_count):
        let u = state.boundary[fr_boundary_index(child, row_start + i)]
        state.block_rows[fr_block_entry(block, i)] = u
    for j in range(column_count):
        let v = state.boundary[fr_boundary_index(child, column_start + j)]
        state.block_columns[fr_block_entry(block, j)] = v
    for i in range(row_count):
        let u = state.block_rows[fr_block_entry(block, i)]
        for j in range(column_count):
            let v = state.block_columns[fr_block_entry(block, j)]
            let distance = state.ddg[fr_ddg_index(child, u, v)]
            let value = FR_INF if distance == FR_INF else distance + state.potential[fr_potential_index(potential_piece, u)] - state.potential[fr_potential_index(potential_piece, v)]
            state.block_weights[fr_block_weight(block, i, j)] = value
    block_count += 1

fn fr_build_blocks_rec(inout state: FrState, child: Int, lo: Int, hi: Int, potential_piece: Int, inout block_count: Int):
    if hi - lo <= 1: return
    let middle = (lo + hi) // 2
    fr_add_block(inout state, child, lo, middle - lo, middle, hi - middle, potential_piece, inout block_count)
    fr_add_block(inout state, child, middle, hi - middle, lo, middle - lo, potential_piece, inout block_count)
    fr_build_blocks_rec(inout state, child, lo, middle, potential_piece, inout block_count)
    fr_build_blocks_rec(inout state, child, middle, hi, potential_piece, inout block_count)

fn fr_activate(inout state: FrState, vertex: Int, value: Int64, block_count: Int, settled: InlineArray[Bool, FR_MAX_N]):
    for block in range(block_count):
        let rows = state.block_row_count[block]
        let columns = state.block_column_count[block]
        for i in range(rows):
            if state.block_rows[fr_block_entry(block, i)] != vertex: continue
            for j in range(columns):
                let target = state.block_columns[fr_block_entry(block, j)]
                let weight = state.block_weights[fr_block_weight(block, i, j)]
                if settled[target] or weight == FR_INF: continue
                let candidate = value + weight
                let best_index = fr_block_entry(block, j)
                if candidate < state.block_best_value[best_index] or (candidate == state.block_best_value[best_index] and vertex < state.block_best_row[best_index]):
                    state.block_best_value[best_index] = candidate
                    state.block_best_row[best_index] = vertex

fn fr_settle(inout state: FrState, vertex: Int, block_count: Int, inout settled: InlineArray[Bool, FR_MAX_N]):
    settled[vertex] = True
    for block in range(block_count):
        for j in range(state.block_column_count[block]):
            let best_index = fr_block_entry(block, j)
            if state.block_columns[best_index] == vertex:
                state.block_best_value[best_index] = FR_INF
                state.block_best_row[best_index] = FR_MAX_N + 1

fn fr_run_dijkstra(inout state: FrState, nodes: InlineArray[Int, FR_MAX_UNION_NODES], node_count: Int, block_count: Int, seed_vertices: InlineArray[Int, FR_MAX_BOUNDARY], seed_values: InlineArray[Int64, FR_MAX_BOUNDARY], seed_count: Int, inout labels: InlineArray[Int64, FR_MAX_N]):
    var settled = InlineArray[Bool, FR_MAX_N](fill=False)
    labels = InlineArray[Int64, FR_MAX_N](fill=FR_INF)
    for block in range(block_count):
        for j in range(state.block_column_count[block]):
            let best_index = fr_block_entry(block, j)
            state.block_best_value[best_index] = FR_INF
            state.block_best_row[best_index] = FR_MAX_N + 1
    for i in range(seed_count):
        let vertex = seed_vertices[i]
        if seed_values[i] < labels[vertex]: labels[vertex] = seed_values[i]
    for i in range(node_count):
        let vertex = nodes[i]
        if labels[vertex] != FR_INF: fr_activate(inout state, vertex, labels[vertex], block_count, settled)
    while True:
        var best_value = FR_INF
        var best_vertex = -1
        var best_row = FR_MAX_N + 1
        for i in range(node_count):
            let vertex = nodes[i]
            let value = labels[vertex]
            if settled[vertex] or value == FR_INF: continue
            if value < best_value or (value == best_value and (best_vertex < 0 or vertex < best_vertex)) or (value == best_value and vertex == best_vertex and -1 < best_row):
                best_value = value
                best_vertex = vertex
                best_row = -1
        for block in range(block_count):
            for j in range(state.block_column_count[block]):
                let best_index = fr_block_entry(block, j)
                let vertex = state.block_columns[best_index]
                let value = state.block_best_value[best_index]
                let row = state.block_best_row[best_index]
                if settled[vertex] or value == FR_INF: continue
                if value < best_value or (value == best_value and (best_vertex < 0 or vertex < best_vertex)) or (value == best_value and vertex == best_vertex and row < best_row):
                    best_value = value
                    best_vertex = vertex
                    best_row = row
        if best_vertex < 0: break
        if best_value < labels[best_vertex]: labels[best_vertex] = best_value
        fr_settle(inout state, best_vertex, block_count, inout settled)
        fr_activate(inout state, best_vertex, labels[best_vertex], block_count, settled)

fn fr_unique_child_nodes(state: FrState, left: Int, right: Int, inout nodes: InlineArray[Int, FR_MAX_UNION_NODES]) -> Int:
    var present = InlineArray[Bool, FR_MAX_N](fill=False)
    for child in range(2):
        let piece = left if child == 0 else right
        for i in range(state.piece_boundary_count[piece]):
            let vertex = state.boundary[fr_boundary_index(piece, i)]
            present[vertex] = True
    var count = 0
    for vertex in range(state.n):
        if present[vertex]: nodes[count] = vertex; count += 1
    return count

fn fr_build_piece(inout state: FrState, index: Int) -> Int:
    for u in range(state.n):
        for v in range(state.n): state.ddg[fr_ddg_index(index, u, v)] = FR_INF
    if state.piece_left[index] == -1:
        let mask = state.piece_arc_mask[index]
        fr_collect_leaf_arcs(inout state, mask)
        var nodes = InlineArray[Int, FR_MAX_UNION_NODES](fill=0)
        var node_count = 0
        for vertex in range(state.n):
            if (state.piece_vertex_mask[index] & (1 << vertex)) != 0:
                nodes[node_count] = vertex
                node_count += 1
        var potential = InlineArray[Int64, FR_MAX_N](fill=0)
        if not fr_bellman_ford_all(inout state, nodes, node_count, inout potential): return -1
        for i in range(state.piece_boundary_count[index]):
            var seeds = InlineArray[Int64, FR_MAX_N](fill=FR_INF)
            var labels = InlineArray[Int64, FR_MAX_N](fill=FR_INF)
            let source = state.boundary[fr_boundary_index(index, i)]
            seeds[source] = 0
            if not fr_bellman_ford_seeded(inout state, seeds, inout labels): return -1
            for j in range(state.piece_boundary_count[index]):
                let target = state.boundary[fr_boundary_index(index, j)]
                state.ddg[fr_ddg_index(index, source, target)] = labels[target]
        return 0

    let left = state.piece_left[index]
    let right = state.piece_right[index]
    var nodes = InlineArray[Int, FR_MAX_UNION_NODES](fill=0)
    let node_count = fr_unique_child_nodes(state, left, right, inout nodes)
    var in_union = InlineArray[Bool, FR_MAX_N](fill=False)
    for i in range(node_count): in_union[nodes[i]] = True
    for i in range(state.piece_boundary_count[index]):
        if not in_union[state.boundary[fr_boundary_index(index, i)]]: return -1

    state.temp_count = 0
    for child_index in range(2):
        let child = left if child_index == 0 else right
        for i in range(state.piece_boundary_count[child]):
            for j in range(state.piece_boundary_count[child]):
                let u = state.boundary[fr_boundary_index(child, i)]
                let v = state.boundary[fr_boundary_index(child, j)]
                let weight = state.ddg[fr_ddg_index(child, u, v)]
                if u != v and weight != FR_INF:
                    let edge = state.temp_count
                    state.temp_tail[edge] = u
                    state.temp_head[edge] = v
                    state.temp_weight[edge] = weight
                    state.temp_count += 1
    var potential = InlineArray[Int64, FR_MAX_N](fill=0)
    if not fr_bellman_ford_all(inout state, nodes, node_count, inout potential): return -1
    for edge in range(state.temp_count):
        let u = state.temp_tail[edge]
        let v = state.temp_head[edge]
        if state.temp_weight[edge] + potential[u] - potential[v] < 0: return -1
    for vertex in range(state.n): state.potential[fr_potential_index(index, vertex)] = potential[vertex]

    if not fr_check_monge_rec(state, left, 0, state.piece_boundary_count[left]): return -1
    if not fr_check_monge_rec(state, right, 0, state.piece_boundary_count[right]): return -1
    var block_count = 0
    fr_build_blocks_rec(inout state, left, 0, state.piece_boundary_count[left], index, inout block_count)
    fr_build_blocks_rec(inout state, right, 0, state.piece_boundary_count[right], index, inout block_count)
    if block_count > FR_MAX_BLOCKS: return -1
    for i in range(state.piece_boundary_count[index]):
        let source = state.boundary[fr_boundary_index(index, i)]
        var seed_vertices = InlineArray[Int, FR_MAX_BOUNDARY](fill=0)
        var seed_values = InlineArray[Int64, FR_MAX_BOUNDARY](fill=0)
        seed_vertices[0] = source
        var labels = InlineArray[Int64, FR_MAX_N](fill=FR_INF)
        fr_run_dijkstra(inout state, nodes, node_count, block_count, seed_vertices, seed_values, 1, inout labels)
        for j in range(state.piece_boundary_count[index]):
            let target = state.boundary[fr_boundary_index(index, j)]
            let value = labels[target]
            state.ddg[fr_ddg_index(index, source, target)] = FR_INF if value == FR_INF else value - potential[source] + potential[target]
    return 0

fn fr_expand(inout state: FrState, index: Int, known: InlineArray[Int64, FR_MAX_N], inout result: InlineArray[Int64, FR_MAX_N]):
    if state.piece_left[index] == -1:
        fr_collect_leaf_arcs(inout state, state.piece_arc_mask[index])
        var labels = InlineArray[Int64, FR_MAX_N](fill=FR_INF)
        if not fr_bellman_ford_seeded(inout state, known, inout labels): return
        for vertex in range(state.n):
            if (state.piece_vertex_mask[index] & (1 << vertex)) != 0 and labels[vertex] < result[vertex]:
                result[vertex] = labels[vertex]
        return

    let left = state.piece_left[index]
    let right = state.piece_right[index]
    var nodes = InlineArray[Int, FR_MAX_UNION_NODES](fill=0)
    let node_count = fr_unique_child_nodes(state, left, right, inout nodes)
    var block_count = 0
    fr_build_blocks_rec(inout state, left, 0, state.piece_boundary_count[left], index, inout block_count)
    fr_build_blocks_rec(inout state, right, 0, state.piece_boundary_count[right], index, inout block_count)
    var seed_vertices = InlineArray[Int, FR_MAX_BOUNDARY](fill=0)
    var seed_values = InlineArray[Int64, FR_MAX_BOUNDARY](fill=0)
    var seed_count = 0
    for i in range(state.piece_boundary_count[index]):
        let vertex = state.boundary[fr_boundary_index(index, i)]
        if known[vertex] != FR_INF:
            seed_vertices[seed_count] = vertex
            seed_values[seed_count] = known[vertex] - state.potential[fr_potential_index(index, vertex)]
            seed_count += 1
    var reduced = InlineArray[Int64, FR_MAX_N](fill=FR_INF)
    fr_run_dijkstra(inout state, nodes, node_count, block_count, seed_vertices, seed_values, seed_count, inout reduced)
    var raw = InlineArray[Int64, FR_MAX_N](fill=FR_INF)
    for vertex in range(state.n):
        raw[vertex] = FR_INF if reduced[vertex] == FR_INF else reduced[vertex] + state.potential[fr_potential_index(index, vertex)]
    for child_index in range(2):
        let child = left if child_index == 0 else right
        var child_known = InlineArray[Int64, FR_MAX_N](fill=FR_INF)
        for j in range(state.piece_boundary_count[child]):
            let vertex = state.boundary[fr_boundary_index(child, j)]
            child_known[vertex] = raw[vertex]
        fr_expand(inout state, child, child_known, inout result)

@export("fakcharoenphol_rao_planar_sssp")
fn fakcharoenphol_rao_planar_sssp(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < c_size_t(4) or length > c_size_t(FR_MAX_INPUT): return -1
    var state = FrState()
    if not fr_parse(inout state, input, length): return -1

    var nodes = InlineArray[Int, FR_MAX_UNION_NODES](fill=0)
    for vertex in range(state.n): nodes[vertex] = vertex
    state.temp_count = state.m
    for edge in range(state.m):
        state.temp_tail[edge] = state.arc_tail[edge]
        state.temp_head[edge] = state.arc_head[edge]
        state.temp_weight[edge] = state.arc_weight[edge]
    var global_potential = InlineArray[Int64, FR_MAX_N](fill=0)
    if not fr_bellman_ford_all(inout state, nodes, state.n, inout global_potential): return -1

    for piece in range(state.piece_count):
        if fr_build_piece(inout state, piece) != 0: return -1
    var result = InlineArray[Int64, FR_MAX_N](fill=FR_INF)
    var known = InlineArray[Int64, FR_MAX_N](fill=FR_INF)
    known[state.source] = 0
    fr_expand(inout state, state.piece_count - 1, known, inout result)

    let output_bytes = state.n * 8
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(output_bytes): return -2
    for vertex in range(state.n):
        let value = Int64(0x7FFFFFFFFFFFFFFF) if result[vertex] == FR_INF else result[vertex]
        let bits = UInt64(value)
        for byte in range(8): output[vertex * 8 + byte] = UInt8((bits >> UInt(8 * byte)) & UInt64(255))
    return Int64(output_bytes)
