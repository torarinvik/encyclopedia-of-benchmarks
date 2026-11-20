from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

from std.collections import InlineArray


fn feasible(
    input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, m: Int,
    source: Int, sink: Int, flow_cap: Int64
) -> Bool:
    var residual = InlineArray[Int64, 64](fill=0)
    var balance = InlineArray[Int64, 6](fill=0)
    for index in range(m):
        let offset = 4 + 4 * index
        let u = Int(input[offset])
        let v = Int(input[offset + 1])
        let lower = input[offset + 2]
        let upper = input[offset + 3]
        residual[u * 8 + v] += upper - lower
        balance[u] -= lower
        balance[v] += lower
    residual[sink * 8 + source] += flow_cap

    let super_source = n
    let super_sink = n + 1
    let node_count = n + 2
    var demand: Int64 = 0
    for vertex in range(n):
        if balance[vertex] > 0:
            residual[super_source * 8 + vertex] += balance[vertex]
            demand += balance[vertex]
        elif balance[vertex] < 0:
            residual[vertex * 8 + super_sink] -= balance[vertex]

    var flow: Int64 = 0
    while flow < demand:
        var parent = InlineArray[Int, 8](fill=-1)
        var queue = InlineArray[Int, 8](fill=0)
        var head = 0
        var tail = 0
        parent[super_source] = super_source
        queue[tail] = super_source
        tail += 1
        while head < tail and parent[super_sink] < 0:
            let u = queue[head]
            head += 1
            for v in range(node_count):
                if residual[u * 8 + v] > 0 and parent[v] < 0:
                    parent[v] = u
                    queue[tail] = v
                    tail += 1
                    if v == super_sink:
                        break
        if parent[super_sink] < 0:
            break
        var amount = demand - flow
        var vertex = super_sink
        while vertex != super_source:
            let u = parent[vertex]
            if residual[u * 8 + vertex] < amount:
                amount = residual[u * 8 + vertex]
            vertex = u
        vertex = super_sink
        while vertex != super_source:
            let u = parent[vertex]
            residual[u * 8 + vertex] -= amount
            residual[vertex * 8 + u] += amount
            vertex = u
        flow += amount
    return flow == demand


@export("minimum_bounded_s_t_flow")
fn minimum_bounded_s_t_flow(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 37:
        return -1
    let n_value = input[0]
    let m_value = input[1]
    let source_value = input[2]
    let sink_value = input[3]
    if n_value < 2 or n_value > 6 or m_value < 0 or m_value > 8:
        return -1
    if source_value < 0 or source_value >= n_value or sink_value < 0 or
        sink_value >= n_value or source_value == sink_value:
        return -1
    let n = Int(n_value)
    let m = Int(m_value)
    let source = Int(source_value)
    let sink = Int(sink_value)
    if length != c_size_t(4 + 4 * m):
        return -1

    var upper_bound: Int64 = 0
    for index in range(m):
        let offset = 4 + 4 * index
        let u = input[offset]
        let v = input[offset + 1]
        let lower = input[offset + 2]
        let upper = input[offset + 3]
        if u < 0 or u >= n_value or v < 0 or v >= n_value or lower < 0 or
            upper < lower or upper > 2:
            return -1
        if Int(u) == source and Int(v) != source:
            upper_bound += upper

    var low: Int64 = 0
    var high = upper_bound + 1
    while low < high:
        let middle = low + (high - low) / 2
        if feasible(input, n, m, source, sink, middle):
            high = middle
        else:
            low = middle + 1
    return -2 if low > upper_bound else low
