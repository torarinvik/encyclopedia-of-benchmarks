from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer


fn dlh_before(left_distance: Int64, left_vertex: Int, right_distance: Int64, right_vertex: Int) -> Bool:
    return left_distance < right_distance or (left_distance == right_distance and left_vertex < right_vertex)


fn dlh_push(inout heap_distance: InlineArray[Int64, 257], inout heap_vertex: InlineArray[Int, 257], inout count: Int, distance: Int64, vertex: Int):
    var position = count
    count += 1
    while position > 0:
        let parent = (position - 1) // 2
        if not dlh_before(distance, vertex, heap_distance[parent], heap_vertex[parent]):
            break
        heap_distance[position] = heap_distance[parent]
        heap_vertex[position] = heap_vertex[parent]
        position = parent
    heap_distance[position] = distance
    heap_vertex[position] = vertex


fn dlh_pop(inout heap_distance: InlineArray[Int64, 257], inout heap_vertex: InlineArray[Int, 257], inout count: Int) -> (Int64, Int):
    let result = (heap_distance[0], heap_vertex[0])
    count -= 1
    if count > 0:
        let last_distance = heap_distance[count]
        let last_vertex = heap_vertex[count]
        var position = 0
        while 2 * position + 1 < count:
            var child = 2 * position + 1
            if child + 1 < count and dlh_before(heap_distance[child + 1], heap_vertex[child + 1], heap_distance[child], heap_vertex[child]):
                child += 1
            if not dlh_before(heap_distance[child], heap_vertex[child], last_distance, last_vertex):
                break
            heap_distance[position] = heap_distance[child]
            heap_vertex[position] = heap_vertex[child]
            position = child
        heap_distance[position] = last_distance
        heap_vertex[position] = last_vertex
    return result


@export("dijkstra_lazy_heap")
fn dijkstra_lazy_heap(edges: UnsafePointer[Int64, ImmutAnyOrigin], vertices: c_size_t, edge_count: c_size_t,
    source: c_size_t, distances: UnsafePointer[Int64, MutAnyOrigin], reachable: UnsafePointer[UInt8, MutAnyOrigin]) abi("C") -> Int64:
    if vertices > 64 or edge_count > 256:
        return -3
    if vertices == 0:
        return 0 if source == 0 and edge_count == 0 else -3
    if source >= vertices:
        return -3

    let n = Int(vertices)
    let m = Int(edge_count)
    let start = Int(source)
    for edge in range(m):
        let origin = edges[3 * edge]
        let destination = edges[3 * edge + 1]
        let weight = edges[3 * edge + 2]
        if origin < 0 or destination < 0 or origin >= Int64(n) or destination >= Int64(n):
            return -3
        if weight < 0:
            return -4

    var head = InlineArray[Int, 64](fill=256)
    var tail = InlineArray[Int, 64](fill=256)
    var next = InlineArray[Int, 256](fill=256)
    for edge in range(m):
        let origin = Int(edges[3 * edge])
        if head[origin] == 256:
            head[origin] = edge
        else:
            next[tail[origin]] = edge
        tail[origin] = edge

    for vertex in range(n):
        distances[vertex] = 0
        reachable[vertex] = 0
    var heap_distance = InlineArray[Int64, 257]()
    var heap_vertex = InlineArray[Int, 257]()
    var heap_count = 0
    distances[start] = 0
    reachable[start] = 1
    dlh_push(heap_distance, heap_vertex, heap_count, 0, start)

    while heap_count > 0:
        let (current, origin) = dlh_pop(heap_distance, heap_vertex, heap_count)
        if current != distances[origin] or reachable[origin] == 2:
            continue
        reachable[origin] = 2
        var edge = head[origin]
        while edge != 256:
            let destination = Int(edges[3 * edge + 1])
            let weight = edges[3 * edge + 2]
            if current > 9223372036854775807 - weight:
                return -2
            let candidate = current + weight
            if reachable[destination] != 2 and (reachable[destination] == 0 or candidate < distances[destination]):
                distances[destination] = candidate
                reachable[destination] = 1
                dlh_push(heap_distance, heap_vertex, heap_count, candidate, destination)
            edge = next[edge]

    for vertex in range(n):
        if reachable[vertex] == 2:
            reachable[vertex] = 1
    return 0
