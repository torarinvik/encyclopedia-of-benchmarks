from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

comptime MAX_VERTICES = 8
comptime MAX_INPUT_LENGTH = 53
comptime MAX_FLOW = Int64(240)
comptime FREE_TREE = 0
comptime SOURCE_TREE = 1
comptime SINK_TREE = 2

struct BKState:
    var n: Int
    var source: Int
    var sink: Int
    var total_flow: Int64
    var residual: InlineArray[Int64, MAX_VERTICES * MAX_VERTICES]
    var tree: InlineArray[Int, MAX_VERTICES]
    var parent: InlineArray[Int, MAX_VERTICES]
    var active_queue: InlineArray[Int, MAX_VERTICES]
    var active_count: Int
    var is_active: InlineArray[Bool, MAX_VERTICES]

    fn __init__(out self):
        self.n = 0
        self.source = 0
        self.sink = 0
        self.total_flow = 0
        self.residual = InlineArray[Int64, MAX_VERTICES * MAX_VERTICES](fill=0)
        self.tree = InlineArray[Int, MAX_VERTICES](fill=FREE_TREE)
        self.parent = InlineArray[Int, MAX_VERTICES](fill=-1)
        self.active_queue = InlineArray[Int, MAX_VERTICES](fill=0)
        self.active_count = 0
        self.is_active = InlineArray[Bool, MAX_VERTICES](fill=False)

fn bk_capacity(state: BKState, kind: Int, parent: Int, child: Int) -> Int64:
    if kind == SOURCE_TREE:
        return state.residual[parent * MAX_VERTICES + child]
    return state.residual[child * MAX_VERTICES + parent]

fn bk_has_terminal_origin(state: BKState, candidate: Int, blocked: Int,
        kind: Int, root: Int, n: Int) -> Bool:
    var seen = InlineArray[Bool, MAX_VERTICES](fill=False)
    var current = candidate
    while True:
        if current == blocked or current < 0 or current >= n or state.tree[current] != kind:
            return False
        if current == root:
            return True
        if seen[current]:
            return False
        seen[current] = True
        let previous = state.parent[current]
        if previous < 0 or previous >= n or bk_capacity(state, kind, previous, current) <= 0:
            return False
        current = previous

fn bk_activate(inout state: BKState, vertex: Int):
    if state.is_active[vertex]:
        return
    state.active_queue[state.active_count] = vertex
    state.active_count += 1
    state.is_active[vertex] = True

fn bk_remove_active(inout state: BKState, vertex: Int):
    if not state.is_active[vertex]:
        return
    var kept = InlineArray[Int, MAX_VERTICES](fill=0)
    var kept_count = 0
    for index in range(state.active_count):
        let queued = state.active_queue[index]
        if queued != vertex:
            kept[kept_count] = queued
            kept_count += 1
    for index in range(kept_count):
        state.active_queue[index] = kept[index]
    state.active_count = kept_count
    state.is_active[vertex] = False

@export("boykov_kolmogorov_maxflow")
fn boykov_kolmogorov_maxflow(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let nv = input[0]
    let mv = input[1]
    let sv = input[2]
    let tv = input[3]
    if nv < 2 or nv > MAX_VERTICES or mv < 0 or mv > 16 or sv < 0 or sv >= nv or tv < 0 or tv >= nv or sv == tv:
        return -1
    let n = Int(nv)
    let m = Int(mv)
    let source = Int(sv)
    let sink = Int(tv)
    if length != c_size_t(4 + 3 * m):
        return -1

    var state = BKState()
    state.n = n
    state.source = source
    state.sink = sink
    for edge_index in range(m):
        let u_value = input[4 + 3 * edge_index]
        let v_value = input[5 + 3 * edge_index]
        let capacity = input[6 + 3 * edge_index]
        if u_value < 0 or u_value >= nv or v_value < 0 or v_value >= nv or u_value == v_value or capacity < 0 or capacity > 15:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        state.residual[u * MAX_VERTICES + v] += capacity

    state.tree[source] = SOURCE_TREE
    state.tree[sink] = SINK_TREE
    state.active_queue[0] = source
    state.active_queue[1] = sink
    state.active_count = 2
    state.is_active[source] = True
    state.is_active[sink] = True

    while state.active_count > 0:
        var bridge_source = -1
        var bridge_sink = -1
        var found_bridge = False
        while state.active_count > 0 and not found_bridge:
            let vertex = state.active_queue[0]
            for shift_index in range(1, state.active_count):
                state.active_queue[shift_index - 1] = state.active_queue[shift_index]
            state.active_count -= 1
            state.is_active[vertex] = False
            let kind = state.tree[vertex]
            for neighbor in range(n):
                if bk_capacity(state, kind, vertex, neighbor) <= 0:
                    continue
                if state.tree[neighbor] == FREE_TREE:
                    state.tree[neighbor] = kind
                    state.parent[neighbor] = vertex
                    bk_activate(state, neighbor)
                elif state.tree[neighbor] != kind:
                    if kind == SOURCE_TREE:
                        bridge_source = vertex
                        bridge_sink = neighbor
                    else:
                        bridge_source = neighbor
                        bridge_sink = vertex
                    bk_activate(state, vertex)
                    found_bridge = True
                    break
        if not found_bridge:
            break

        var source_reverse = InlineArray[Int, MAX_VERTICES](fill=0)
        var source_length = 0
        var current = bridge_source
        while current != source:
            source_reverse[source_length] = current
            source_length += 1
            let previous = state.parent[current]
            if previous < 0 or previous >= n:
                return -1
            current = previous

        var path_from = InlineArray[Int, MAX_VERTICES * 2](fill=0)
        var path_to = InlineArray[Int, MAX_VERTICES * 2](fill=0)
        var path_length = 0
        var previous = source
        while source_length > 0:
            source_length -= 1
            let next_vertex = source_reverse[source_length]
            path_from[path_length] = previous
            path_to[path_length] = next_vertex
            path_length += 1
            previous = next_vertex
        path_from[path_length] = bridge_source
        path_to[path_length] = bridge_sink
        path_length += 1
        current = bridge_sink
        while current != sink:
            let next_vertex = state.parent[current]
            if next_vertex < 0 or next_vertex >= n:
                return -1
            path_from[path_length] = current
            path_to[path_length] = next_vertex
            path_length += 1
            current = next_vertex

        var bottleneck = MAX_FLOW
        for index in range(path_length):
            let capacity = state.residual[path_from[index] * MAX_VERTICES + path_to[index]]
            if capacity < bottleneck:
                bottleneck = capacity
        if bottleneck <= 0:
            return -1
        for index in range(path_length):
            let from_vertex = path_from[index]
            let to_vertex = path_to[index]
            state.residual[from_vertex * MAX_VERTICES + to_vertex] -= bottleneck
            state.residual[to_vertex * MAX_VERTICES + from_vertex] += bottleneck
        state.total_flow += bottleneck

        var orphan_queue = InlineArray[Int, MAX_VERTICES](fill=0)
        var orphan_count = 0
        var is_orphan = InlineArray[Bool, MAX_VERTICES](fill=False)
        for index in range(path_length):
            let from_vertex = path_from[index]
            let to_vertex = path_to[index]
            if state.residual[from_vertex * MAX_VERTICES + to_vertex] != 0:
                continue
            if state.tree[from_vertex] == SOURCE_TREE and state.tree[to_vertex] == SOURCE_TREE and state.parent[to_vertex] == from_vertex:
                state.parent[to_vertex] = -1
                if not is_orphan[to_vertex]:
                    orphan_queue[orphan_count] = to_vertex
                    orphan_count += 1
                    is_orphan[to_vertex] = True
            elif state.tree[from_vertex] == SINK_TREE and state.tree[to_vertex] == SINK_TREE and state.parent[from_vertex] == to_vertex:
                state.parent[from_vertex] = -1
                if not is_orphan[from_vertex]:
                    orphan_queue[orphan_count] = from_vertex
                    orphan_count += 1
                    is_orphan[from_vertex] = True

        while orphan_count > 0:
            let orphan = orphan_queue[0]
            for shift_index in range(1, orphan_count):
                orphan_queue[shift_index - 1] = orphan_queue[shift_index]
            orphan_count -= 1
            is_orphan[orphan] = False
            let kind = state.tree[orphan]
            if kind == FREE_TREE:
                continue

            var replacement = -1
            for candidate in range(n):
                if candidate != orphan and state.tree[candidate] == kind and bk_capacity(state, kind, candidate, orphan) > 0 and bk_has_terminal_origin(state, candidate, orphan, kind, source if kind == SOURCE_TREE else sink, n):
                    replacement = candidate
                    break
            if replacement >= 0:
                state.parent[orphan] = replacement
                continue

            for neighbor in range(n):
                if state.tree[neighbor] != kind:
                    continue
                if bk_capacity(state, kind, neighbor, orphan) > 0:
                    bk_activate(state, neighbor)
                if state.parent[neighbor] == orphan:
                    state.parent[neighbor] = -1
                    if not is_orphan[neighbor]:
                        orphan_queue[orphan_count] = neighbor
                        orphan_count += 1
                        is_orphan[neighbor] = True
            state.tree[orphan] = FREE_TREE
            state.parent[orphan] = -1
            bk_remove_active(state, orphan)

    return state.total_flow
