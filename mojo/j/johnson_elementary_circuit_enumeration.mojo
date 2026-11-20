from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

comptime MAX_VERTICES = 8
comptime MAX_EDGES = 24
comptime MAX_INPUT_LENGTH = 51
comptime COUNT_SCALE = Int64(1000000000000)

struct JohnsonState:
    var n: Int
    var start: Int
    var depth: Int
    var edge: InlineArray[Bool, 64]
    var inside: InlineArray[Bool, 8]
    var blocked: InlineArray[Bool, 8]
    var dependency: InlineArray[Bool, 64]
    var path: InlineArray[Int, 8]
    var count: Int64
    var code_sum: Int64

    fn __init__(out self):
        self.n = 0
        self.start = 0
        self.depth = 0
        self.edge = InlineArray[Bool, 64](fill=False)
        self.inside = InlineArray[Bool, 8](fill=False)
        self.blocked = InlineArray[Bool, 8](fill=False)
        self.dependency = InlineArray[Bool, 64](fill=False)
        self.path = InlineArray[Int, 8](fill=0)
        self.count = 0
        self.code_sum = 0

struct JohnsonSccState:
    var n: Int
    var lower_bound: Int
    var next_index: Int
    var component_count: Int
    var stack_length: Int
    var edge: InlineArray[Bool, 64]
    var index: InlineArray[Int, 8]
    var low_link: InlineArray[Int, 8]
    var component_id: InlineArray[Int, 8]
    var on_stack: InlineArray[Bool, 8]
    var stack: InlineArray[Int, 8]
    var component_size: InlineArray[Int, 8]
    var component_minimum: InlineArray[Int, 8]

    fn __init__(out self):
        self.n = 0
        self.lower_bound = 0
        self.next_index = 0
        self.component_count = 0
        self.stack_length = 0
        self.edge = InlineArray[Bool, 64](fill=False)
        self.index = InlineArray[Int, 8](fill=-1)
        self.low_link = InlineArray[Int, 8](fill=0)
        self.component_id = InlineArray[Int, 8](fill=-1)
        self.on_stack = InlineArray[Bool, 8](fill=False)
        self.stack = InlineArray[Int, 8](fill=0)
        self.component_size = InlineArray[Int, 8](fill=0)
        self.component_minimum = InlineArray[Int, 8](fill=0)

fn johnson_strong_connect(inout state: JohnsonSccState, vertex: Int):
    state.index[vertex] = state.next_index
    state.low_link[vertex] = state.next_index
    state.next_index += 1
    state.stack[state.stack_length] = vertex
    state.stack_length += 1
    state.on_stack[vertex] = True

    for neighbor in range(state.lower_bound, state.n):
        if not state.edge[vertex * MAX_VERTICES + neighbor]: continue
        if state.index[neighbor] < 0:
            johnson_strong_connect(state, neighbor)
            if state.low_link[neighbor] < state.low_link[vertex]:
                state.low_link[vertex] = state.low_link[neighbor]
        elif state.on_stack[neighbor] and state.index[neighbor] < state.low_link[vertex]:
            state.low_link[vertex] = state.index[neighbor]

    if state.low_link[vertex] != state.index[vertex]: return
    let component = state.component_count
    var size = 0
    var minimum = state.n
    while True:
        state.stack_length -= 1
        let member = state.stack[state.stack_length]
        state.on_stack[member] = False
        state.component_id[member] = component
        size += 1
        if member < minimum: minimum = member
        if member == vertex: break
    state.component_size[component] = size
    state.component_minimum[component] = minimum
    state.component_count += 1

fn johnson_unblock(inout state: JohnsonState, vertex: Int):
    if not state.blocked[vertex]: return
    state.blocked[vertex] = False
    for dependent in range(state.n):
        let slot = vertex * MAX_VERTICES + dependent
        if state.dependency[slot]:
            state.dependency[slot] = False
            if state.blocked[dependent]: johnson_unblock(state, dependent)

fn johnson_record_cycle(inout state: JohnsonState):
    var code: Int64 = 0
    var place: Int64 = 1
    for index in range(state.depth):
        code += Int64(state.path[index] + 1) * place
        place *= 9
    state.count += 1
    state.code_sum += code

fn johnson_circuit(inout state: JohnsonState, vertex: Int) -> Bool:
    state.path[state.depth] = vertex
    state.depth += 1
    state.blocked[vertex] = True
    var found = False
    for neighbor in range(state.n):
        let edge_slot = vertex * MAX_VERTICES + neighbor
        if not state.inside[neighbor] or not state.edge[edge_slot]: continue
        if neighbor == state.start:
            johnson_record_cycle(state)
            found = True
        elif not state.blocked[neighbor] and johnson_circuit(state, neighbor):
            found = True
    if found:
        johnson_unblock(state, vertex)
    else:
        for neighbor in range(state.n):
            let edge_slot = vertex * MAX_VERTICES + neighbor
            if state.inside[neighbor] and state.edge[edge_slot]:
                state.dependency[neighbor * MAX_VERTICES + vertex] = True
    state.depth -= 1
    return found

@export("johnson_elementary_circuit_enumeration")
fn johnson_elementary_circuit_enumeration(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > c_size_t(MAX_INPUT_LENGTH):
        return -1
    let n_value = input[0]
    let m_value = input[1]
    if n_value < 1 or n_value > MAX_VERTICES or m_value < 0 or m_value > MAX_EDGES:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    if length != c_size_t(2 + 2 * m): return -1

    var edge = InlineArray[Bool, 64](fill=False)
    for e in range(m):
        let u_value = input[2 + 2 * e]
        let v_value = input[3 + 2 * e]
        if u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value:
            return -1
        let slot = Int(u_value) * MAX_VERTICES + Int(v_value)
        if edge[slot]: return -1
        edge[slot] = True

    var total_count: Int64 = 0
    var total_code_sum: Int64 = 0
    var lower_bound = 0
    while lower_bound < n:
        var scc = JohnsonSccState()
        scc.n = n
        scc.lower_bound = lower_bound
        for u in range(lower_bound, n):
            for v in range(lower_bound, n):
                scc.edge[u * MAX_VERTICES + v] = edge[u * MAX_VERTICES + v]
        for vertex in range(lower_bound, n):
            if scc.index[vertex] < 0: johnson_strong_connect(scc, vertex)

        var start = n
        var selected_component = -1
        for component in range(scc.component_count):
            if scc.component_size[component] > 1 and scc.component_minimum[component] < start:
                start = scc.component_minimum[component]
                selected_component = component
        if selected_component < 0: break

        var state = JohnsonState()
        state.n = n
        state.start = start
        for u in range(lower_bound, n):
            state.inside[u] = scc.component_id[u] == selected_component
            for v in range(n): state.edge[u * MAX_VERTICES + v] = edge[u * MAX_VERTICES + v]
        _ = johnson_circuit(state, start)
        total_count += state.count
        total_code_sum += state.code_sum
        lower_bound = start + 1
    return total_count * COUNT_SCALE + total_code_sum
