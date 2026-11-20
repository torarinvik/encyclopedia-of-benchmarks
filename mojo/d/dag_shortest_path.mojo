from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

const MAX_VERTICES = 12
const MAX_EDGES = 66
const MAX_LENGTH = 203
const DISTANCE_OFFSET: Int64 = 100000
const INFINITY_DISTANCE: Int64 = 1 << 60

@export("dag_shortest_path")
fn dag_shortest_path(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > MAX_LENGTH:
        return -1
    if input[0] < 1 or input[0] > MAX_VERTICES or input[1] < 0 or input[1] > MAX_EDGES:
        return -1
    let vertex_count = Int(input[0])
    let edge_count = Int(input[1])
    if length != c_size_t(4 + 3 * edge_count):
        return -1
    if input[2] < 0 or input[2] >= vertex_count or input[3] < 0 or input[3] >= vertex_count:
        return -1
    var from = InlineArray[Int64, MAX_EDGES](fill=0)
    var to = InlineArray[Int64, MAX_EDGES](fill=0)
    var weight = InlineArray[Int64, MAX_EDGES](fill=0)
    var indegree = InlineArray[Int64, MAX_VERTICES](fill=0)
    var queue = InlineArray[Int, MAX_VERTICES](fill=0)
    var order = InlineArray[Int, MAX_VERTICES](fill=0)
    for edge in range(edge_count):
        let start = input[4 + 3 * edge]
        let finish = input[5 + 3 * edge]
        let cost = input[6 + 3 * edge]
        if start < 0 or start >= vertex_count or finish < 0 or finish >= vertex_count:
            return -1
        if start == finish or cost < -1000 or cost > 1000:
            return -1
        for previous in range(edge):
            if from[previous] == start and to[previous] == finish:
                return -1
        from[edge] = start
        to[edge] = finish
        weight[edge] = cost
        indegree[Int(finish)] += 1
    var head = 0
    var tail = 0
    for vertex in range(vertex_count):
        if indegree[vertex] == 0:
            queue[tail] = vertex
            tail += 1
    var order_count = 0
    while head < tail:
        let vertex = queue[head]
        head += 1
        order[order_count] = vertex
        order_count += 1
        for edge in range(edge_count):
            if from[edge] == vertex:
                let finish = Int(to[edge])
                indegree[finish] -= 1
                if indegree[finish] == 0:
                    queue[tail] = finish
                    tail += 1
    if order_count != vertex_count:
        return -1
    var distance = InlineArray[Int64, MAX_VERTICES](fill=INFINITY_DISTANCE)
    distance[Int(input[2])] = 0
    for position in range(vertex_count):
        let vertex = order[position]
        if distance[vertex] == INFINITY_DISTANCE:
            continue
        for edge in range(edge_count):
            if from[edge] == vertex:
                let finish = Int(to[edge])
                let candidate = distance[vertex] + weight[edge]
                if candidate < distance[finish]:
                    distance[finish] = candidate
    let answer = distance[Int(input[3])]
    if answer == INFINITY_DISTANCE:
        return 0
    return DISTANCE_OFFSET + answer
