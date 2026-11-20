from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

from std.collections import InlineArray

@export("lower_bound_circulation_feasibility")
fn lower_bound_circulation_feasibility(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 35:
        return -1
    if input[0] < 1 or input[0] > 6 or input[1] < 0 or input[1] > 8:
        return -1
    let n = Int(input[0])
    let m = Int(input[1])
    if length != c_size_t(2 + 4 * m):
        return -1

    var residual = InlineArray[Int64, 64](fill=0)
    var balance = InlineArray[Int64, 6](fill=0)
    for index in range(m):
        let offset = 2 + 4 * index
        let u_value = input[offset]
        let v_value = input[offset + 1]
        let lower = input[offset + 2]
        let upper = input[offset + 3]
        if u_value < 0 or u_value >= input[0] or v_value < 0 or v_value >= input[0]
            or lower < 0 or upper < lower or upper > 2:
            return -1
        let u = Int(u_value)
        let v = Int(v_value)
        residual[u * 8 + v] += upper - lower
        balance[u] -= lower
        balance[v] += lower

    let source = n
    let sink = n + 1
    let node_count = n + 2
    var demand: Int64 = 0
    for vertex in range(n):
        if balance[vertex] > 0:
            residual[source * 8 + vertex] += balance[vertex]
            demand += balance[vertex]
        elif balance[vertex] < 0:
            residual[vertex * 8 + sink] -= balance[vertex]

    var flow: Int64 = 0
    while flow < demand:
        var parent = InlineArray[Int, 8](fill=-1)
        var queue = InlineArray[Int, 8](fill=0)
        var head = 0
        var tail = 0
        parent[source] = source
        queue[tail] = source
        tail += 1
        while head < tail and parent[sink] < 0:
            let u = queue[head]
            head += 1
            for v in range(node_count):
                if residual[u * 8 + v] > 0 and parent[v] < 0:
                    parent[v] = u
                    queue[tail] = v
                    tail += 1
                    if v == sink:
                        break
        if parent[sink] < 0:
            break
        var amount = demand - flow
        var vertex = sink
        while vertex != source:
            let u = parent[vertex]
            if residual[u * 8 + vertex] < amount:
                amount = residual[u * 8 + vertex]
            vertex = u
        vertex = sink
        while vertex != source:
            let u = parent[vertex]
            residual[u * 8 + vertex] -= amount
            residual[vertex * 8 + u] += amount
            vertex = u
        flow += amount
    return 1 if flow == demand else 0
