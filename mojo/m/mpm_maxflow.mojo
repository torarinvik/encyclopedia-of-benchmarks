from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

alias MAX_VERTICES = 8
alias MAX_EDGES = 24
alias MAX_INPUT_VALUES = 4 + 3 * MAX_EDGES + 1
alias FLOW_INFINITY = 2401

fn mpm_maxflow_push_forward(vertex: Int, sink: Int, amount: Int64, n: Int,
    mut residual: InlineArray[Int64, MAX_VERTICES * MAX_VERTICES],
    mut active: InlineArray[Bool, MAX_VERTICES * MAX_VERTICES],
    mut incoming: InlineArray[Int64, MAX_VERTICES],
    mut outgoing: InlineArray[Int64, MAX_VERTICES]) -> Int64:
    if vertex == sink:
        return amount
    var remaining = amount
    for next in range(n):
        if remaining == 0:
            break
        let edge = vertex * MAX_VERTICES + next
        if not active[edge] or residual[edge] == 0:
            continue
        let limit = remaining if remaining < residual[edge] else residual[edge]
        let pushed = mpm_maxflow_push_forward(next, sink, limit, n,
            mut residual, mut active, mut incoming, mut outgoing)
        if pushed == 0:
            continue
        residual[edge] -= pushed
        residual[next * MAX_VERTICES + vertex] += pushed
        outgoing[vertex] -= pushed
        incoming[next] -= pushed
        remaining -= pushed
        if residual[edge] == 0:
            active[edge] = False
    return amount - remaining

fn mpm_maxflow_push_backward(vertex: Int, source: Int, amount: Int64, n: Int,
    mut residual: InlineArray[Int64, MAX_VERTICES * MAX_VERTICES],
    mut active: InlineArray[Bool, MAX_VERTICES * MAX_VERTICES],
    mut incoming: InlineArray[Int64, MAX_VERTICES],
    mut outgoing: InlineArray[Int64, MAX_VERTICES]) -> Int64:
    if vertex == source:
        return amount
    var remaining = amount
    for previous in range(n):
        if remaining == 0:
            break
        let edge = previous * MAX_VERTICES + vertex
        if not active[edge] or residual[edge] == 0:
            continue
        let limit = remaining if remaining < residual[edge] else residual[edge]
        let pushed = mpm_maxflow_push_backward(previous, source, limit, n,
            mut residual, mut active, mut incoming, mut outgoing)
        if pushed == 0:
            continue
        residual[edge] -= pushed
        residual[vertex * MAX_VERTICES + previous] += pushed
        incoming[vertex] -= pushed
        outgoing[previous] -= pushed
        remaining -= pushed
        if residual[edge] == 0:
            active[edge] = False
    return amount - remaining

fn mpm_maxflow_remove_vertex(vertex: Int, n: Int,
    residual: InlineArray[Int64, MAX_VERTICES * MAX_VERTICES],
    mut active: InlineArray[Bool, MAX_VERTICES * MAX_VERTICES],
    mut incoming: InlineArray[Int64, MAX_VERTICES],
    mut outgoing: InlineArray[Int64, MAX_VERTICES],
    mut alive: InlineArray[Bool, MAX_VERTICES]):
    for other in range(n):
        let in_edge = other * MAX_VERTICES + vertex
        if active[in_edge]:
            let capacity = residual[in_edge]
            outgoing[other] -= capacity
            incoming[vertex] -= capacity
            active[in_edge] = False
        let out_edge = vertex * MAX_VERTICES + other
        if active[out_edge]:
            let capacity = residual[out_edge]
            outgoing[vertex] -= capacity
            incoming[other] -= capacity
            active[out_edge] = False
    alive[vertex] = False

@export("mpm_maxflow")
fn mpm_maxflow(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > MAX_INPUT_VALUES:
        return -1
    let n_value = input[0]
    let edge_count_value = input[1]
    let source_value = input[2]
    let sink_value = input[3]
    if n_value < 2 or n_value > MAX_VERTICES or edge_count_value < 0 or
        edge_count_value > MAX_EDGES or source_value < 1 or source_value > n_value or
        sink_value < 1 or sink_value > n_value or source_value == sink_value:
        return -1
    let n = Int(n_value)
    let edge_count = Int(edge_count_value)
    let source = Int(source_value - 1)
    let sink = Int(sink_value - 1)
    if length != c_size_t(4 + 3 * edge_count):
        return -1

    var residual = InlineArray[Int64, MAX_VERTICES * MAX_VERTICES]()
    for edge in range(edge_count):
        let from_value = input[4 + 3 * edge]
        let to_value = input[5 + 3 * edge]
        let capacity = input[6 + 3 * edge]
        if from_value < 1 or from_value > n_value or to_value < 1 or to_value > n_value or
            from_value == to_value or capacity < 0 or capacity > 100:
            return -1
        let from = Int(from_value - 1)
        let to = Int(to_value - 1)
        residual[from * MAX_VERTICES + to] += capacity

    var total_flow: Int64 = 0
    while True:
        var level = InlineArray[Int, MAX_VERTICES](fill=-1)
        var queue = InlineArray[Int, MAX_VERTICES]()
        var head = 0
        var tail = 0
        level[source] = 0
        queue[tail] = source
        tail += 1
        while head < tail:
            let vertex = queue[head]
            head += 1
            for next in range(n):
                if residual[vertex * MAX_VERTICES + next] > 0 and level[next] < 0:
                    level[next] = level[vertex] + 1
                    queue[tail] = next
                    tail += 1
        if level[sink] < 0:
            break

        var incoming = InlineArray[Int64, MAX_VERTICES]()
        var outgoing = InlineArray[Int64, MAX_VERTICES]()
        var active = InlineArray[Bool, MAX_VERTICES * MAX_VERTICES]()
        var alive = InlineArray[Bool, MAX_VERTICES]()
        for vertex in range(n):
            alive[vertex] = level[vertex] >= 0 and level[vertex] <= level[sink]
        for from in range(n):
            for to in range(n):
                let edge = from * MAX_VERTICES + to
                if level[from] >= 0 and level[from] < level[sink] and
                    level[to] == level[from] + 1 and residual[edge] > 0:
                    active[edge] = True
                    outgoing[from] += residual[edge]
                    incoming[to] += residual[edge]
        incoming[source] = FLOW_INFINITY
        outgoing[sink] = FLOW_INFINITY

        while True:
            var reference = -1
            var least_potential: Int64 = FLOW_INFINITY + 1
            for vertex in range(n):
                if not alive[vertex]:
                    continue
                let potential = incoming[vertex] if incoming[vertex] < outgoing[vertex] else outgoing[vertex]
                if potential < least_potential:
                    least_potential = potential
                    reference = vertex
            if reference < 0:
                break
            if least_potential > 0:
                total_flow += least_potential
                let _ = mpm_maxflow_push_backward(reference, source, least_potential, n,
                    mut residual, mut active, mut incoming, mut outgoing)
                let _ = mpm_maxflow_push_forward(reference, sink, least_potential, n,
                    mut residual, mut active, mut incoming, mut outgoing)
            mpm_maxflow_remove_vertex(reference, n, residual, mut active,
                mut incoming, mut outgoing, mut alive)
    return total_flow
